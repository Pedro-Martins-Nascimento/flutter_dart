// Estatística da turma (RF17/RF18), calculada em cima das correções salvas.
// São funções puras: quem chama busca as correções no CorrecaoRepository
// (Firestore) e passa a lista, então não há cache nem estado para dessincronizar.

import '../models/correcao.dart';

/// Percentual de acerto de uma questão do banco, com o enunciado para exibir.
typedef AcertoQuestao = ({
  String questaoId,
  String enunciado,
  String materiaId,
  double percentual,
  int respostas,
});

typedef AcertoAluno = ({String aluno, double media, int quantidade});

/// Quantas vezes cada alternativa de uma questão do banco foi marcada (RF18).
///
/// Os índices de [contagem], [correta] e [maisMarcadas] seguem a ordem da
/// questão no banco (0 = A), não a ordem impressa em cada versão.
/// [alternativas] são os textos guardados na correção, como estavam na prova
/// aplicada (nulo se as correções não guardaram).
typedef DistribuicaoQuestao = ({
  String questaoId,
  String enunciado,
  List<String>? alternativas,
  String materiaId,
  List<int> contagem,
  int? correta,
  List<int> maisMarcadas,
  int respostas,
});

class EstatisticaService {
  const EstatisticaService._();

  /// Média das notas de todas as correções; 0 se não há nenhuma.
  static double mediaGeral(List<Correcao> correcoes) {
    if (correcoes.isEmpty) return 0;
    return correcoes.fold<double>(0, (soma, c) => soma + c.nota) /
        correcoes.length;
  }

  /// Percentual de acerto por matéria (chave = id da matéria), somando todas
  /// as respostas de todas as correções.
  static Map<String, double> percentualAcertoPorMateria(
    List<Correcao> correcoes,
  ) => percentualAcertoPorGrupo(correcoes, (materiaId) => materiaId);

  /// Percentual de acerto juntando as respostas pela chave que [grupo] dá ao
  /// `materiaId` de cada uma (por exemplo, o nome da disciplina).
  static Map<String, double> percentualAcertoPorGrupo(
    List<Correcao> correcoes,
    String Function(String materiaId) grupo,
  ) {
    final acertos = <String, int>{};
    final totais = <String, int>{};
    for (final c in correcoes) {
      for (final r in c.respostas) {
        final chave = grupo(r.materiaId);
        totais[chave] = (totais[chave] ?? 0) + 1;
        if (r.correta) acertos[chave] = (acertos[chave] ?? 0) + 1;
      }
    }
    return {
      for (final id in totais.keys) id: (acertos[id] ?? 0) / totais[id]! * 100,
    };
  }

  /// Percentual de acerto por questão, da que mais derruba a turma (menor
  /// acerto) para a que menos derruba. Empates ficam em ordem alfabética do
  /// enunciado, para o resultado ser estável.
  static List<AcertoQuestao> percentualAcertoPorQuestao(
    List<Correcao> correcoes,
  ) {
    final acertos = <String, int>{};
    final totais = <String, int>{};
    final enunciados = <String, String>{};
    final materias = <String, String>{};
    for (final c in correcoes) {
      for (final r in c.respostas) {
        totais[r.questaoId] = (totais[r.questaoId] ?? 0) + 1;
        enunciados[r.questaoId] = r.enunciado;
        materias[r.questaoId] = r.materiaId;
        if (r.correta) {
          acertos[r.questaoId] = (acertos[r.questaoId] ?? 0) + 1;
        }
      }
    }
    final lista = [
      for (final id in totais.keys)
        (
          questaoId: id,
          enunciado: enunciados[id]!,
          materiaId: materias[id]!,
          percentual: (acertos[id] ?? 0) / totais[id]! * 100,
          respostas: totais[id]!,
        ),
    ];
    lista.sort((a, b) {
      final porPercentual = a.percentual.compareTo(b.percentual);
      return porPercentual != 0
          ? porPercentual
          : a.enunciado.compareTo(b.enunciado);
    });
    return lista;
  }

  /// Distribuição das alternativas marcadas por questão do banco, para a
  /// análise pedagógica dos erros: quantos alunos marcaram cada alternativa,
  /// qual é a certa e qual foi a mais marcada (mais de uma, se empatarem).
  ///
  /// Só entram respostas com `ordemNoBanco` (as versões embaralham as
  /// alternativas de jeitos diferentes, então sem ela não dá para juntar).
  /// A ordem da lista é a mesma de [percentualAcertoPorQuestao]: menor acerto
  /// primeiro, empates pelo enunciado.
  ///
  /// Se a questão foi editada entre uma aplicação e outra, cada conjunto de
  /// textos guardado nas correções vira um grupo separado: assim a contagem
  /// de um texto antigo não aparece com o texto novo.
  static List<DistribuicaoQuestao> distribuicaoAlternativas(
    List<Correcao> correcoes,
  ) {
    final contagens = <String, List<int>>{};
    final ids = <String, String>{};
    final textos = <String, List<String>?>{};
    final corretas = <String, int>{};
    final enunciados = <String, String>{};
    final materias = <String, String>{};
    for (final c in correcoes) {
      for (final r in c.respostas) {
        final marcada = r.marcadaNoBanco;
        if (marcada == null) continue;
        final alternativas = r.alternativasNoBanco;
        final chave = alternativas == null
            ? r.questaoId
            : '${r.questaoId}\u0000${alternativas.join('\u0001')}';
        final tamanho = r.ordemNoBanco!.length;
        final contagem = contagens.putIfAbsent(chave, () => []);
        while (contagem.length < tamanho) {
          contagem.add(0);
        }
        contagem[marcada]++;
        ids[chave] = r.questaoId;
        textos[chave] = alternativas;
        enunciados[chave] = r.enunciado;
        materias[chave] = r.materiaId;
        if (r.corretaNoBanco case final correta?) {
          corretas[chave] = correta;
        }
      }
    }

    final lista = [
      for (final MapEntry(key: chave, value: contagem) in contagens.entries)
        () {
          final respostas = contagem.fold<int>(0, (soma, n) => soma + n);
          final maximo = contagem.fold<int>(0, (m, n) => n > m ? n : m);
          return (
            questaoId: ids[chave]!,
            enunciado: enunciados[chave]!,
            alternativas: textos[chave],
            materiaId: materias[chave]!,
            contagem: List<int>.unmodifiable(contagem),
            correta: corretas[chave],
            maisMarcadas: [
              for (var i = 0; i < contagem.length; i++)
                if (contagem[i] == maximo) i,
            ],
            respostas: respostas,
          );
        }(),
    ];

    double acerto(DistribuicaoQuestao d) =>
        d.correta == null ? 0 : d.contagem[d.correta!] / d.respostas;
    lista.sort((a, b) {
      final porAcerto = acerto(a).compareTo(acerto(b));
      return porAcerto != 0 ? porAcerto : a.enunciado.compareTo(b.enunciado);
    });
    return lista;
  }

  /// Ranking de alunos pela média das notas, do melhor para o pior. Só entra
  /// quem tem correção com aluno vinculado; alunos são agrupados pelo id (ou
  /// pelo nome, se a correção não tiver id).
  static List<AcertoAluno> rankingAlunos(List<Correcao> correcoes) {
    final porAluno = <String, List<Correcao>>{};
    for (final c in correcoes) {
      final chave = c.alunoId ?? c.alunoNome;
      if (chave == null) continue;
      porAluno.putIfAbsent(chave, () => []).add(c);
    }
    final ranking = [
      for (final lista in porAluno.values)
        (
          aluno: lista.first.alunoNome ?? lista.first.alunoId!,
          media: mediaGeral(lista),
          quantidade: lista.length,
        ),
    ];
    ranking.sort((a, b) {
      final porMedia = b.media.compareTo(a.media);
      return porMedia != 0 ? porMedia : a.aluno.compareTo(b.aluno);
    });
    return ranking;
  }

  /// Correções agrupadas por prova (id da prova), para mostrar a média de
  /// cada uma.
  static Map<String, List<Correcao>> porProva(List<Correcao> correcoes) {
    final grupos = <String, List<Correcao>>{};
    for (final c in correcoes) {
      grupos.putIfAbsent(c.provaId, () => []).add(c);
    }
    return grupos;
  }
}

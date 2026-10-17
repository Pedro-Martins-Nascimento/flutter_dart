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
  ) {
    final acertos = <String, int>{};
    final totais = <String, int>{};
    for (final c in correcoes) {
      for (final r in c.respostas) {
        totais[r.materiaId] = (totais[r.materiaId] ?? 0) + 1;
        if (r.correta) acertos[r.materiaId] = (acertos[r.materiaId] ?? 0) + 1;
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

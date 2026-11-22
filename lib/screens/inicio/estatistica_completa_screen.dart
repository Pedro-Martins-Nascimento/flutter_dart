// Estatística agregada da turma: acerto por disciplina, questões que mais
// derrubam a turma, alternativas marcadas por questão, média por prova e
// ranking de alunos.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/correcao.dart';
import '../../models/questao.dart';
import '../../services/correcao_repository.dart';
import '../../services/estatistica_service.dart';
import '../../services/nome_da_disciplina.dart';
import '../../services/questoes_repository.dart';
import '../../services/turmas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class EstatisticaCompletaScreen extends StatelessWidget {
  final CorrecaoRepository correcoes;

  const EstatisticaCompletaScreen({super.key, required this.correcoes});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Correcao>>(
      stream: correcoes.observar(),
      builder: (context, snapshot) =>
          _conteudo(context, snapshot.data ?? const <Correcao>[]),
    );
  }

  Widget _conteudo(BuildContext context, List<Correcao> correcoes) {
    if (correcoes.isEmpty) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Estatística completa')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Nenhuma correção com nota calculada ainda. Assim que corrigir '
              'a primeira folha em "Corrigir", a estatística aparece aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    final acertoPorDisciplina = EstatisticaService.percentualAcertoPorGrupo(
      correcoes,
      nomeDaDisciplina(
        context.watch<QuestoesRepository>(),
        context.watch<TurmasRepository>().disciplinas,
      ),
    );
    final disciplinasOrdenadas = [
      for (final e in acertoPorDisciplina.entries) (e.key, e.value),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    final questoes = EstatisticaService.percentualAcertoPorQuestao(correcoes);
    final distribuicao = EstatisticaService.distribuicaoAlternativas(correcoes);
    final banco = {
      for (final q in context.watch<QuestoesRepository>().questoes) q.id: q,
    };
    final porProva = EstatisticaService.porProva(correcoes);
    final ranking = EstatisticaService.rankingAlunos(correcoes);

    return AppScaffold(
      appBar: AppBar(title: const Text('Estatística completa')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          AppCard(
            child: Row(
              children: [
                _numero('Correções', '${correcoes.length}'),
                const SizedBox(width: AppSpacing.s6),
                _numero(
                  'Média geral',
                  EstatisticaService.mediaGeral(correcoes)
                      .toStringAsFixed(1)
                      .replaceAll('.', ','),
                ),
              ],
            ),
          ),
          _secao('ACERTO POR DISCIPLINA', [
            for (final (nome, acerto) in disciplinasOrdenadas)
              _linhaPercentual(nome, acerto),
          ]),
          _secao('QUESTÕES QUE MAIS DERRUBAM A TURMA', [
            for (final questao in questoes.take(10))
              _linhaTexto(
                questao.enunciado,
                '${questao.percentual.round()}%',
                destaque: questao.percentual < 50,
              ),
          ]),
          _secao('ALTERNATIVAS MARCADAS POR QUESTÃO', [
            for (final (indice, questao) in distribuicao.indexed) ...[
              if (indice > 0) const Divider(height: AppSpacing.s5),
              _distribuicaoQuestao(questao, banco[questao.questaoId]),
            ],
            if (distribuicao.isEmpty)
              const Text(
                'As correções salvas ainda não guardam a ordem das '
                'alternativas. A distribuição aparece a partir das próximas '
                'correções.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
          ]),
          _secao('MÉDIA POR PROVA', [
            for (final grupo in porProva.values)
              _linhaTexto(
                grupo.first.provaNome,
                '${EstatisticaService.mediaGeral(grupo).toStringAsFixed(1)} · '
                '${grupo.length} corrigida(s)',
              ),
          ]),
          _secao('RANKING DE ALUNOS', [
            for (final (indice, aluno) in ranking.indexed)
              _linhaTexto(
                '${indice + 1}º  ${aluno.aluno}',
                '${aluno.media.toStringAsFixed(1)} · ${aluno.quantidade} prova(s)',
              ),
            if (ranking.isEmpty)
              const Text(
                'Nenhuma correção com aluno vinculado ainda.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _secao(String titulo, List<Widget> linhas) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: AppTheme.kicker),
          const SizedBox(height: AppSpacing.s3),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: linhas,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaTexto(String esquerda, String direita, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              esquerda,
              style: const TextStyle(fontSize: 13, color: AppColors.text),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Text(
            direita,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: destaque ? AppColors.accent : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  /// Uma questão com uma barra por alternativa (A a E). A certa fica em
  /// verde; a mais marcada, quando é errada, fica em destaque, que é o erro
  /// que a turma mais cometeu.
  Widget _distribuicaoQuestao(DistribuicaoQuestao questao, Questao? doBanco) {
    final errosMaisMarcados = [
      for (final i in questao.maisMarcadas)
        if (i != questao.correta) letraAlternativa(i),
    ];
    return Column(
      key: ValueKey('distribuicao_${questao.questaoId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          questao.enunciado,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${questao.respostas} resposta(s)'
          '${questao.correta != null ? ' · certa: ${letraAlternativa(questao.correta!)}' : ''}'
          '${errosMaisMarcados.isNotEmpty ? ' · mais marcada: ${errosMaisMarcados.join(', ')}' : ''}',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.s2),
        for (var i = 0; i < questao.contagem.length; i++)
          _barraAlternativa(
            questao,
            i,
            doBanco != null && i < doBanco.alternativas.length
                ? doBanco.alternativas[i]
                : null,
          ),
      ],
    );
  }

  Widget _barraAlternativa(
    DistribuicaoQuestao questao,
    int indice,
    String? texto,
  ) {
    final quantidade = questao.contagem[indice];
    final fracao = questao.respostas == 0
        ? 0.0
        : quantidade / questao.respostas;
    final certa = indice == questao.correta;
    final maisMarcada = questao.maisMarcadas.contains(indice) && quantidade > 0;
    final cor = certa
        ? AppColors.success
        : maisMarcada
        ? AppColors.accent
        : AppColors.neutral400;
    final letra = letraAlternativa(indice);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              texto == null ? letra : '$letra) $texto',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: certa || maisMarcada
                    ? FontWeight.w700
                    : FontWeight.normal,
                color: certa || maisMarcada ? cor : AppColors.neutral600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Container(
              height: 6,
              color: AppColors.neutral200,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fracao,
                child: Container(color: cor),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          SizedBox(
            width: 64,
            child: Text(
              '$quantidade · ${(fracao * 100).round()}%',
              key: ValueKey('contagem_${questao.questaoId}_$letra'),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaPercentual(String rotulo, double percentual) {
    final cor = percentual < 50 ? AppColors.accent : AppColors.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Container(
              height: 4,
              color: AppColors.neutral200,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: percentual / 100,
                child: Container(color: cor),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          SizedBox(
            width: 38,
            child: Text(
              '${percentual.round()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numero(String rotulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

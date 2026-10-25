// Estatística agregada da turma: acerto por matéria, questões que mais
// derrubam a turma, média por prova e ranking de alunos.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/correcao.dart';
import '../../services/correcao_repository.dart';
import '../../services/estatistica_service.dart';
import '../../services/questoes_repository.dart';
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

    final materias = context.watch<QuestoesRepository>().materias;
    final acertoPorMateria = EstatisticaService.percentualAcertoPorMateria(
      correcoes,
    );
    final materiasOrdenadas = [
      for (final materia in materias)
        if (acertoPorMateria[materia.id] case final acerto?)
          (materia.nome, acerto),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    final questoes = EstatisticaService.percentualAcertoPorQuestao(correcoes);
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
          _secao('ACERTO POR MATÉRIA', [
            for (final (nome, acerto) in materiasOrdenadas)
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

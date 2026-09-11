// lib/screens/inicio/estatistica_completa_screen.dart
//
// Estatística agregada da turma (RF18): acerto por matéria, questões que
// mais derrubam a turma e média por prova já corrigida.

import 'package:flutter/material.dart';

import '../../models/questao.dart';
import '../../services/correcoes_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class EstatisticaCompletaScreen extends StatelessWidget {
  const EstatisticaCompletaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CorrecoesRepository.instance,
      builder: (context, _) => _conteudo(context),
    );
  }

  Widget _conteudo(BuildContext context) {
    final repo = CorrecoesRepository.instance;
    final correcoes = repo.correcoes;

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

    final acertoPorMateria = repo.percentualAcertoPorMateria();
    final acertoPorQuestao = repo.percentualAcertoPorQuestao();
    final porProva = repo.porNomeDeProva();

    final materiasOrdenadas = [
      for (final materia in materiasMock)
        if (acertoPorMateria[materia.id] case final acerto?) (materia, acerto),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    final questoesOrdenadas = acertoPorQuestao.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final ranking = repo.rankingAlunos();

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
                _numero('Média geral', repo.mediaGeral.toStringAsFixed(1).replaceAll('.', ',')),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s6),
          Text('ACERTO POR MATÉRIA', style: AppTheme.kicker),
          const SizedBox(height: AppSpacing.s3),
          AppCard(
            child: Column(
              children: [
                for (final (materia, acerto) in materiasOrdenadas)
                  _linhaPercentual(materia.nome, acerto),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s6),
          Text('QUESTÕES QUE MAIS DERRUBAM A TURMA', style: AppTheme.kicker),
          const SizedBox(height: AppSpacing.s3),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in questoesOrdenadas.take(10))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key.enunciado,
                            style: const TextStyle(fontSize: 13, color: AppColors.text),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Text(
                          '${entry.value.round()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: entry.value < 50 ? AppColors.accent : AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s6),
          Text('MÉDIA POR PROVA', style: AppTheme.kicker),
          const SizedBox(height: AppSpacing.s3),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final grupo in porProva.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            grupo.key,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Text(
                          '${_mediaDoGrupo(grupo.value).toStringAsFixed(1)} · ${grupo.value.length} corrigida(s)',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s6),
          Text('RANKING DE ALUNOS', style: AppTheme.kicker),
          const SizedBox(height: AppSpacing.s3),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in ranking.asMap().entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${entry.key + 1}º',
                            style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.aluno,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Text(
                          '${entry.value.media.toStringAsFixed(1)} · ${entry.value.quantidade} prova(s)',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                if (ranking.isEmpty)
                  const Text(
                    'Nenhuma correção com aluno vinculado ainda.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _mediaDoGrupo(List<Correcao> correcoes) {
    if (correcoes.isEmpty) return 0;
    return correcoes.fold<double>(0, (acc, c) => acc + c.nota) / correcoes.length;
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
        Text(rotulo, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
      ],
    );
  }
}

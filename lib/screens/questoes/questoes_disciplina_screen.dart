import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/questao.dart';
import '../../models/turma.dart';
import '../../services/questoes_repository.dart';
import '../../services/turmas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'disciplinas_questoes_screen.dart' show semDisciplina;

/// Questões de uma disciplina (ou do grupo [semDisciplina], das questões
/// antigas que ainda não estão em nenhuma).
class QuestoesDisciplinaScreen extends StatefulWidget {
  final String disciplinaId;

  const QuestoesDisciplinaScreen({super.key, required this.disciplinaId});

  @override
  State<QuestoesDisciplinaScreen> createState() =>
      _QuestoesDisciplinaScreenState();
}

class _QuestoesDisciplinaScreenState extends State<QuestoesDisciplinaScreen> {
  bool get _semDisciplina => widget.disciplinaId == semDisciplina;

  void _abrirFormulario([Questao? questao]) {
    context.push(
      '/questoes/disciplina/${widget.disciplinaId}/questao',
      extra: questao,
    );
  }

  Future<void> _mover(Questao questao) async {
    final disciplinas = context.read<TurmasRepository>().disciplinas;
    if (disciplinas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crie uma disciplina antes de mover a questão.'),
        ),
      );
      return;
    }
    final escolhida = await showDialog<Disciplina>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Mover questão para'),
        children: [
          for (final disciplina in disciplinas)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(disciplina),
              child: Text(disciplina.nome),
            ),
        ],
      ),
    );
    if (escolhida == null || !mounted) return;
    await context.read<QuestoesRepository>().moverQuestao(
      questao.id,
      escolhida.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Questão movida para ${escolhida.nome}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repositorio = context.watch<QuestoesRepository>();
    final disciplina = _semDisciplina
        ? null
        : context.watch<TurmasRepository>().disciplinaPorId(
            widget.disciplinaId,
          );
    final titulo = _semDisciplina
        ? 'Sem disciplina'
        : (disciplina?.nome ?? 'Disciplina não encontrada');
    final questoes = repositorio.questoesDaDisciplina(
      _semDisciplina ? null : widget.disciplinaId,
    );

    return AppScaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s3,
                AppSpacing.s4,
                AppSpacing.s6,
                AppSpacing.s4,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.text),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/questoes'),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Questões', style: AppTheme.kicker),
                        const SizedBox(height: 2),
                        Text(
                          titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // No grupo "Sem disciplina" não se cria questão: ela já
                  // nasce dentro de uma disciplina.
                  if (!_semDisciplina) ...[
                    const SizedBox(width: AppSpacing.s3),
                    OutlinedButton(
                      onPressed: _abrirFormulario,
                      child: const Text('+ Questão'),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: questoes.isEmpty
                  ? _vazio()
                  : ListView.separated(
                      itemCount: questoes.length,
                      padding: EdgeInsets.zero,
                      separatorBuilder: (context, indice) =>
                          const Divider(height: 1),
                      itemBuilder: (context, indice) => _QuestaoItem(
                        numero: indice + 1,
                        questao: questoes[indice],
                        onTap: () => _abrirFormulario(questoes[indice]),
                        onMover: _semDisciplina
                            ? () => _mover(questoes[indice])
                            : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s8 + AppSpacing.s6,
        AppSpacing.s6,
        AppSpacing.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nenhuma questão aqui',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          const SizedBox(
            width: 260,
            child: Text(
              'As questões desta disciplina alimentam as provas embaralhadas.',
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (!_semDisciplina) ...[
            const SizedBox(height: AppSpacing.s5),
            ElevatedButton(
              onPressed: _abrirFormulario,
              child: const Text('Criar questão'),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestaoItem extends StatelessWidget {
  final int numero;
  final Questao questao;
  final VoidCallback onTap;

  /// Só nas questões sem disciplina: mostra o botão de mover.
  final VoidCallback? onMover;

  const _QuestaoItem({
    required this.numero,
    required this.questao,
    required this.onTap,
    this.onMover,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s6,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$numero',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questao.enunciado,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Wrap(
                    spacing: AppSpacing.s3,
                    runSpacing: AppSpacing.s1,
                    children: [
                      Text(
                        'Correta ${letraAlternativa(questao.respostaCorreta)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                      Text(
                        '${questao.alternativas.length} alternativas',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onMover case final mover?)
              TextButton.icon(
                onPressed: mover,
                icon: const Icon(Icons.drive_file_move_outline, size: 18),
                label: const Text('Mover para disciplina'),
              ),
          ],
        ),
      ),
    );
  }
}

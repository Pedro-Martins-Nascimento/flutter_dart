import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/questao.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class QuestoesMateriaScreen extends StatefulWidget {
  final String materiaId;

  const QuestoesMateriaScreen({super.key, required this.materiaId});

  @override
  State<QuestoesMateriaScreen> createState() => _QuestoesMateriaScreenState();
}

class _QuestoesMateriaScreenState extends State<QuestoesMateriaScreen> {
  Materia get _materia => materiasMock.firstWhere(
    (m) => m.id == widget.materiaId,
    orElse: () => Materia(id: widget.materiaId, nome: 'Matéria'),
  );

  List<Questao> get _questoes =>
      questoesMock.where((q) => q.materiaId == widget.materiaId).toList();

  Future<void> _abrirFormulario([Questao? questao]) async {
    await context.push('/questoes/${widget.materiaId}/questao', extra: questao);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final questoes = _questoes;

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
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Questões', style: AppTheme.kicker),
                        const SizedBox(height: 2),
                        Text(
                          _materia.nome,
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
                  const SizedBox(width: AppSpacing.s3),
                  OutlinedButton(
                    onPressed: _abrirFormulario,
                    child: const Text('+ Questão'),
                  ),
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
              'As questões desta matéria alimentam as provas embaralhadas.',
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
          ElevatedButton(
            onPressed: _abrirFormulario,
            child: const Text('Criar questão'),
          ),
        ],
      ),
    );
  }
}

class _QuestaoItem extends StatelessWidget {
  final int numero;
  final Questao questao;
  final VoidCallback onTap;

  const _QuestaoItem({
    required this.numero,
    required this.questao,
    required this.onTap,
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
          ],
        ),
      ),
    );
  }
}

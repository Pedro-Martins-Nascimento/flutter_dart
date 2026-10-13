import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/turma.dart';
import '../../services/turmas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class CriarTurmaScreen extends StatelessWidget {
  const CriarTurmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final turmas = context.watch<TurmasRepository>().turmas;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFaixa(
              bordaBase: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s6,
                vertical: AppSpacing.s6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Turmas', style: AppTheme.kicker),
                        const SizedBox(height: 4),
                        Text(
                          'Minhas turmas',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),

                  InkWell(
                    onTap: () => context.push('/turmas/nova'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: AppMaxWidth(
                child: ListView.separated(
                  itemCount: turmas.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 0),
                  itemBuilder: (context, index) {
                    final turma = turmas[index];
                    return _TurmaItem(
                      turma: turma,
                      onTap: () => context.push('/turmas/${turma.id}'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TurmaItem extends StatelessWidget {
  final Turma turma;
  final VoidCallback onTap;

  const _TurmaItem({required this.turma, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s6,
          vertical: AppSpacing.s5,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turma.nome,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${turma.alunos.length} alunos',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.neutral400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class NovaTurmaScreen extends StatefulWidget {
  const NovaTurmaScreen({super.key});

  @override
  State<NovaTurmaScreen> createState() => _NovaTurmaScreenState();
}

class _NovaTurmaScreenState extends State<NovaTurmaScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _periodoController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _periodoController.dispose();
    super.dispose();
  }

  void _salvar() {
    final nome = _nomeController.text.trim();
    final periodo = _periodoController.text.trim();

    if (nome.isEmpty) return;

    context.read<TurmasRepository>().criar(
      periodo.isNotEmpty ? '$nome — $periodo' : nome,
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Nova turma'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nome da turma',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                hintText: '3º ano B — Matutino',
                hintStyle: TextStyle(color: AppColors.neutral400),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Período',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _periodoController,
              decoration: const InputDecoration(
                hintText: '2026.2',
                hintStyle: TextStyle(color: AppColors.neutral400),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _salvar,
              child: const Text('Salvar turma'),
            ),
          ],
        ),
      ),
    );
  }
}

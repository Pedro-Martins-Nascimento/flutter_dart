import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/turma.dart';
import '../../services/turmas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/cartoes_quadrados.dart';

/// Uma disciplina: quadradinhos das turmas dela, com o de "+" para criar
/// outra. Tocar numa turma abre os alunos e as provas dela.
class DisciplinaScreen extends StatelessWidget {
  final String disciplinaId;

  const DisciplinaScreen({super.key, required this.disciplinaId});

  @override
  Widget build(BuildContext context) {
    final disciplina = context.watch<TurmasRepository>().disciplinaPorId(
      disciplinaId,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/turmas'),
        ),
        centerTitle: false,
        actions: [
          if (disciplina != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s4),
              child: IconButton(
                tooltip: 'Excluir disciplina',
                onPressed: () => _excluir(context, disciplina),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ),
        ],
      ),
      body: AppMaxWidth(
        child: disciplina == null
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.s6),
                child: Text(
                  'Disciplina não encontrada.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s6,
                  0,
                  AppSpacing.s6,
                  AppSpacing.s8,
                ),
                children: [
                  Text('Disciplina', style: AppTheme.kicker),
                  const SizedBox(height: 4),
                  Text(
                    disciplina.nome,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  Text('TURMAS', style: AppTheme.kicker),
                  const SizedBox(height: AppSpacing.s3),
                  GradeDeCartoes(
                    children: [
                      CartaoAdicionar(
                        rotulo: 'Nova turma',
                        onTap: () => _novaTurma(context, disciplina),
                      ),
                      for (final turma in disciplina.turmas)
                        CartaoItem(
                          titulo: turma.nome,
                          subtitulo: turma.qtdAlunos == 0
                              ? 'Sem alunos'
                              : '${turma.qtdAlunos} '
                                    '${turma.qtdAlunos == 1 ? 'aluno' : 'alunos'}',
                          onTap: () => context.push(
                            '/turmas/${disciplina.id}/turma/${turma.id}',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _novaTurma(BuildContext context, Disciplina disciplina) async {
    final nome = await pedirNome(
      context,
      titulo: 'Nova turma',
      rotulo: 'Nome da turma',
      dica: '3º ano B',
    );
    if (nome == null || !context.mounted) return;
    await context.read<TurmasRepository>().criarTurma(disciplina.id, nome);
  }

  Future<void> _excluir(BuildContext context, Disciplina disciplina) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir disciplina'),
        content: Text(
          'Tem certeza que deseja excluir "${disciplina.nome}"? As turmas e '
          'os alunos dela também saem da lista.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    context.read<TurmasRepository>().excluirDisciplina(disciplina.id);
    context.canPop() ? context.pop() : context.go('/turmas');
  }
}

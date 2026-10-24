import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/questao.dart';
import '../../services/questoes_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class MateriasScreen extends StatefulWidget {
  const MateriasScreen({super.key});

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  Future<void> _novaMateria() async {
    final controller = TextEditingController();

    final nome = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova matéria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da matéria'),
          onSubmitted: (valor) => Navigator.of(dialogContext).pop(valor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (nome == null || nome.trim().isEmpty) return;

    if (!mounted) return;
    context.read<QuestoesRepository>().criarMateria(nome.trim());
  }

  Future<void> _excluirMateria(Materia materia, int totalQuestoes) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Excluir ${materia.nome}?'),
        content: Text(
          totalQuestoes == 0
              ? 'A matéria sai do banco.'
              : 'A matéria sai do banco junto com as $totalQuestoes questões '
                    'dela. Provas já geradas não mudam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    context.read<QuestoesRepository>().excluirMateria(materia.id);
  }

  @override
  Widget build(BuildContext context) {
    final repositorio = context.watch<QuestoesRepository>();
    final materias = repositorio.materias;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
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
                        Text('Banco de questões', style: AppTheme.kicker),
                        const SizedBox(height: 4),
                        Text(
                          'Matérias',
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
                    onTap: _novaMateria,
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
                child: materias.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.s6),
                        child: Text(
                          'Nenhuma matéria ainda. Toque em + para criar a primeira.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: materias.length,
                        padding: EdgeInsets.zero,
                        separatorBuilder: (context, indice) =>
                            const Divider(height: 1),
                        itemBuilder: (context, indice) {
                          final materia = materias[indice];
                          final total = repositorio
                              .questoesDaMateria(materia.id)
                              .length;

                          return _MateriaItem(
                            nome: materia.nome,
                            onExcluir: () => _excluirMateria(materia, total),
                            meta: total == 0
                                ? 'Nenhuma questão'
                                : '$total ${total == 1 ? 'questão' : 'questões'}',
                            onTap: () =>
                                context.push('/questoes/${materia.id}'),
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

class _MateriaItem extends StatelessWidget {
  final String nome;
  final String meta;
  final VoidCallback onTap;
  final VoidCallback onExcluir;

  const _MateriaItem({
    required this.nome,
    required this.meta,
    required this.onTap,
    required this.onExcluir,
  });

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
                    nome,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<void>(
              tooltip: 'Excluir matéria',
              icon: const Icon(
                Icons.more_vert,
                size: 20,
                color: AppColors.neutral500,
              ),
              itemBuilder: (context) => [
                PopupMenuItem<void>(
                  onTap: onExcluir,
                  child: const Text(
                    'Excluir matéria',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
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

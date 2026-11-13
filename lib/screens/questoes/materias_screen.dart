import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/questao.dart';
import '../../services/questoes_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page.dart';

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
            AppPageHeader(
              kicker: 'Banco de questões',
              titulo: 'Matérias',
              acao: AppNovoButton(
                rotulo: 'Nova matéria',
                onPressed: _novaMateria,
              ),
            ),
            Expanded(
              child: AppMaxWidth(
                child: materias.isEmpty
                    ? AppEstadoVazio(
                        icone: Icons.quiz_outlined,
                        titulo: 'Nenhuma matéria ainda',
                        mensagem: 'Nenhuma matéria ainda. Toque em + para criar a primeira.',
                        acao: AppNovoButton(
                          rotulo: 'Nova matéria',
                          onPressed: _novaMateria,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s4,
                          AppSpacing.s2,
                          AppSpacing.s4,
                          AppSpacing.s8,
                        ),
                        children: [
                          AppListGroup(
                            children: [
                              for (final materia in materias)
                                _linhaMateria(repositorio, materia),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaMateria(QuestoesRepository repositorio, Materia materia) {
    final total = repositorio.questoesDaMateria(materia.id).length;
    return AppListRow(
      titulo: materia.nome,
      subtitulo: total == 0
          ? 'Nenhuma questão'
          : '$total ${total == 1 ? 'questão' : 'questões'}',
      onTap: () => context.push('/questoes/${materia.id}'),
      menu: AppMenuMais(
        tooltip: 'Excluir matéria',
        itens: (context) => [
          PopupMenuItem<void>(
            onTap: () => _excluirMateria(materia, total),
            child: const Text(
              'Excluir matéria',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

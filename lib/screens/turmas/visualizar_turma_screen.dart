import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/persistencia_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'criar_turma_screen.dart';

class VisualizarTurmaScreen extends StatefulWidget {
  final String turmaId;

  const VisualizarTurmaScreen({super.key, required this.turmaId});

  @override
  State<VisualizarTurmaScreen> createState() => _VisualizarTurmaScreenState();
}

class _VisualizarTurmaScreenState extends State<VisualizarTurmaScreen> {
  late Turma turma;

  @override
  void initState() {
    super.initState();
    _carregarTurma();
  }

  void _carregarTurma() {
    turma = turmasMock.firstWhere(
      (t) => t.id == widget.turmaId,
      orElse: () => Turma(
        id: '0',
        nome: 'Turma não encontrada',
        qtdAlunos: 0,
        qtdProvas: 0,
      ),
    );
  }

  Future<void> _deletarTurma() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Excluir Turma',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tem certeza que deseja excluir a turma "${turma.nome}"?',
                style: const TextStyle(color: AppColors.text, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Esta ação não pode ser desfeita e todos os dados vinculados serão perdidos.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Excluir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar == true) {
      setState(() {
        turmasMock.removeWhere((t) => t.id == widget.turmaId);
      });
      PersistenciaService.instance.salvar();
      if (mounted) context.pop();
    }
  }

  Future<void> _editarAluno(AlunoTurma aluno) async {
    final nomeController = TextEditingController(text: aluno.nome);
    final matriculaController = TextEditingController(text: aluno.matricula);

    final atualizado = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Editar Aluno',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nome do aluno',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Matrícula',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              TextField(
                controller: matriculaController,
                decoration: const InputDecoration(
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (atualizado == true) {
      setState(() {
        final index = turma.alunos.indexOf(aluno);
        if (index != -1) {
          turma.alunos[index] = AlunoTurma(
            id: aluno.id,
            nome: nomeController.text.trim(),
            matricula: matriculaController.text.trim(),
          );
        }
      });
      PersistenciaService.instance.salvar();
    }
  }

  Future<void> _removerAluno(AlunoTurma aluno) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Remover Aluno',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Deseja remover o aluno ${aluno.nome} desta turma?',
                style: const TextStyle(color: AppColors.text, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Remover'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar == true) {
      setState(() {
        turma.alunos.remove(aluno);
      });
      PersistenciaService.instance.salvar();
    }
  }

  Future<void> _adicionarAluno() async {
    final nomeController = TextEditingController();
    final matriculaController = TextEditingController();

    final criado = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Novo Aluno',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nome do aluno',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              TextField(
                controller: nomeController,
                autofocus: true,
                decoration: const InputDecoration(
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Matrícula',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              TextField(
                controller: matriculaController,
                decoration: const InputDecoration(
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Criar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (criado == true && nomeController.text.trim().isNotEmpty) {
      setState(() {
        turma.alunos.add(
          AlunoTurma(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            nome: nomeController.text.trim(),
            matricula: matriculaController.text.trim(),
          ),
        );
      });
      PersistenciaService.instance.salvar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        centerTitle: false,
      ),
      body: AppMaxWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alunos', style: AppTheme.kicker),
                  const SizedBox(height: 4),
                  Text(
                    turma.nome,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          context.push('/turmas/${turma.id}/importar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s1,
                        ),
                        minimumSize: const Size(0, 44),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      child: const Text('Importar lista'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _adicionarAluno,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s1,
                        ),
                        minimumSize: const Size(0, 44),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      child: const Text('Novo Aluno'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  InkWell(
                    onTap: _deletarTurma,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s6,
                vertical: AppSpacing.s2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${turma.alunos.length} ALUNOS', style: AppTheme.kicker),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView.separated(
                itemCount: turma.alunos.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 0),
                itemBuilder: (context, index) {
                  final aluno = turma.alunos[index];
                  return _AlunoItem(
                    aluno: aluno,
                    onEdit: () => _editarAluno(aluno),
                    onDelete: () => _removerAluno(aluno),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlunoItem extends StatelessWidget {
  final AlunoTurma aluno;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AlunoItem({
    required this.aluno,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aluno.nome,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aluno.matricula,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.neutral400,
              size: 20,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.neutral400,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

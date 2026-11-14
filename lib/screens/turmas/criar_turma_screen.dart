import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/turmas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page.dart';

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
            AppPageHeader(
              kicker: 'Turmas',
              titulo: 'Minhas turmas',
              acao: AppNovoButton(
                rotulo: 'Nova turma',
                onPressed: () => context.push('/turmas/nova'),
              ),
            ),
            Expanded(
              child: AppMaxWidth(
                child: turmas.isEmpty
                    ? AppEstadoVazio(
                        icone: Icons.groups_outlined,
                        titulo: 'Nenhuma turma ainda',
                        mensagem: 'Crie uma turma para cadastrar os alunos e vincular as provas.',
                        acao: AppNovoButton(
                          rotulo: 'Nova turma',
                          onPressed: () => context.push('/turmas/nova'),
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
                              for (final turma in turmas)
                                AppListRow(
                                  titulo: turma.nome,
                                  subtitulo:
                                      '${turma.alunos.length} ${turma.alunos.length == 1 ? 'aluno' : 'alunos'}',
                                  onTap: () =>
                                      context.push('/turmas/${turma.id}'),
                                ),
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

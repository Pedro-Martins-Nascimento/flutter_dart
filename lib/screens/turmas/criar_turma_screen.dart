// lib/screens/turmas/criar_turma_screen.dart
//
// Tela "Minhas Turmas" (Seguindo o protótipo da imagem)
// Exibe a lista de turmas cadastradas com atalho para criar novas.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

// ---------------------------------------------------------------------
// MODELO MOCK
// ---------------------------------------------------------------------

class Turma {
  final String id;
  final String nome;
  final int qtdAlunos;
  final int qtdProvas;

  Turma({
    required this.id,
    required this.nome,
    required this.qtdAlunos,
    required this.qtdProvas,
  });
}

// ---------------------------------------------------------------------
// DADOS MOCK (Transformado em lista mutável para teste N1)
// ---------------------------------------------------------------------

List<Turma> turmasMock = [
  Turma(id: '1', nome: '3º ano B — Matutino', qtdAlunos: 32, qtdProvas: 3),
  Turma(id: '2', nome: '2º ano A — Matutino', qtdAlunos: 28, qtdProvas: 1),
  Turma(id: '3', nome: 'Redes de Computadores — Noturno', qtdAlunos: 41, qtdProvas: 5),
  Turma(id: '4', nome: 'Turma piloto (OMR)', qtdAlunos: 6, qtdProvas: 2),
];

// ---------------------------------------------------------------------
// TELA PRINCIPAL (LISTA)
// ---------------------------------------------------------------------

class CriarTurmaScreen extends StatefulWidget {
  const CriarTurmaScreen({super.key});

  @override
  State<CriarTurmaScreen> createState() => _CriarTurmaScreenState();
}

class _CriarTurmaScreenState extends State<CriarTurmaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho conforme protótipo
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s6,
                vertical: AppSpacing.s6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Turmas', style: AppTheme.kicker),
                      const SizedBox(height: 4),
                      Text(
                        'Minhas turmas',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  // Botão "+" em caixa
                  InkWell(
                    onTap: () async {
                      // RF: Espera o retorno da tela de criação para atualizar a lista
                      await context.push('/criar-turma/nova');
                      setState(() {});
                    },
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

            const Divider(height: 1),

            // Lista de turmas
            Expanded(
              child: ListView.separated(
                itemCount: turmasMock.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 0),
                itemBuilder: (context, index) {
                  final turma = turmasMock[index];
                  return _TurmaItem(turma: turma);
                },
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

  const _TurmaItem({required this.turma});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Detalhes da turma
      },
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
                    '${turma.qtdAlunos} alunos · ${turma.qtdProvas} provas',
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

// ---------------------------------------------------------------------
// TELA NOVA TURMA (Formulário)
// ---------------------------------------------------------------------

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

    // Adiciona na lista mock global (como primeira da lista)
    setState(() {
      turmasMock.insert(
        0,
        Turma(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          nome: periodo.isNotEmpty ? '$nome — $periodo' : nome,
          qtdAlunos: 0, // Inicia com zero
          qtdProvas: 0, // Inicia com zero
        ),
      );
    });

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
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
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
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

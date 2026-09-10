// lib/screens/provas/criar_prova_screen.dart
//
// Tela "Criar Prova" (N1 - dados mock, sem Firebase ainda)
// RF08 — Criar prova selecionando matéria(s) e questões do banco
// RF09 — Escolher modo: mesma prova embaralhada por versão, ou conjuntos
//        de questões diferentes
//
// Matérias e questões vêm do banco real (lib/models/questao.dart, com
// alternativas e gabarito). Turma vem do módulo de turmas
// (lib/screens/turmas/criar_turma_screen.dart) — mesma fonte de dados
// usada em "Minhas Turmas", pra uma turma criada aqui aparecer lá também.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/questao.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../turmas/criar_turma_screen.dart' show Turma, turmasMock;

// (Gerar Provas) via `extra:` do go_router.
class DadosProva {
  final String nomeProva;
  final List<Materia> materias;
  final Turma? turma; // opcional — nem toda prova precisa estar presa a uma turma
  final List<Questao> questoes;
  final ModoProva modo;

  DadosProva({
    required this.nomeProva,
    required this.materias,
    required this.turma,
    required this.questoes,
    required this.modo,
  });

  String get materiasResumo => materias.map((m) => m.nome).join(', ');
}

class CriarProvaScreen extends StatefulWidget {
  const CriarProvaScreen({super.key});

  @override
  State<CriarProvaScreen> createState() => _CriarProvaScreenState();
}

class _CriarProvaScreenState extends State<CriarProvaScreen> {
  // Getters (não cópia local) pra sempre refletir turmas/matérias criadas
  // em outras telas (ex: "Minhas Turmas") sem precisar sincronizar estado.
  List<Materia> get _materiasDisponiveis => materiasMock;
  List<Turma> get _turmasDisponiveis => turmasMock;

  final Set<String> materiasSelecionadas = {};
  String? turmaSelecionadaId; 
  final Set<String> questoesSelecionadas = {};
  ModoProva modoSelecionado = ModoProva.mesmaEmbaralhada;

  // NOVO
  final TextEditingController nomeProvaController = TextEditingController();

  @override
  void dispose() {
    nomeProvaController.dispose();
    super.dispose();
  }

  List<Questao> get questoesDisponiveis {
    if (materiasSelecionadas.isEmpty) return [];
    return questoesMock
        .where((q) => materiasSelecionadas.contains(q.materiaId))
        .toList();
  }

  void _toggleMateria(String materiaId, bool? selecionado) {
    setState(() {
      if (selecionado == true) {
        materiasSelecionadas.add(materiaId);
      } else {
        materiasSelecionadas.remove(materiaId);
        questoesSelecionadas.removeWhere((qId) {
          final questao = questoesMock.firstWhere((q) => q.id == qId);
          return questao.materiaId == materiaId;
        });
      }
    });
  }

  // NOVO
  void _toggleTurma(String? turmaId) {
    setState(() => turmaSelecionadaId = turmaId);
  }

  void _toggleQuestao(String questaoId, bool selecionado) {
    setState(() {
      if (selecionado) {
        questoesSelecionadas.add(questaoId);
      } else {
        questoesSelecionadas.remove(questaoId);
      }
    });
  }

  
  Future<String?> _mostrarDialogoNovoItem({
    required String titulo,
    required String label,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
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
        );
      },
    );
  }

  Future<void> _criarNovaMateria() async {
    final nome = await _mostrarDialogoNovoItem(
      titulo: 'Nova matéria',
      label: 'Nome da matéria',
    );
    if (nome == null || nome.trim().isEmpty) return;

    final novaMateria = Materia(
      id: 'mat_${DateTime.now().millisecondsSinceEpoch}',
      nome: nome.trim(),
    );
    setState(() {
      _materiasDisponiveis.add(novaMateria);
      // já seleciona a matéria recém-criada, pra economizar um toque
      materiasSelecionadas.add(novaMateria.id);
    });
  }

  Future<void> _criarNovaTurma() async {
    final nome = await _mostrarDialogoNovoItem(
      titulo: 'Nova turma',
      label: 'Nome da turma',
    );
    if (nome == null || nome.trim().isEmpty) return;

    final novaTurma = Turma(
      id: 'turma_${DateTime.now().millisecondsSinceEpoch}',
      nome: nome.trim(),
      qtdAlunos: 0,
      qtdProvas: 0,
      alunos: [],
    );
    setState(() {
      // Insere na lista real (compartilhada com "Minhas Turmas"), não
      // numa cópia local — turma criada aqui aparece lá também.
      turmasMock.insert(0, novaTurma);
      turmaSelecionadaId = novaTurma.id;
    });
  }

  bool get podeAvancar =>
      questoesSelecionadas.isNotEmpty && nomeProvaController.text.trim().isNotEmpty;

  void _avancarParaGeracao() {
    Turma? turmaEscolhida;
    if (turmaSelecionadaId != null) {
      turmaEscolhida = _turmasDisponiveis.firstWhere((t) => t.id == turmaSelecionadaId);
    }

    final dados = DadosProva(
      nomeProva: nomeProvaController.text.trim(),
      materias: _materiasDisponiveis
          .where((m) => materiasSelecionadas.contains(m.id))
          .toList(),
      turma: turmaEscolhida,
      questoes: questoesMock.where((q) => questoesSelecionadas.contains(q.id)).toList(),
      modo: modoSelecionado,
    );

    context.push('/gerar-provas', extra: dados);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Prova'),
        // NOVO: acesso rápido ao histórico de provas já geradas.
        actions: [
          IconButton(
            tooltip: 'Provas geradas',
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/provas-geradas'),
          ),
        ],
      ),
      body: AppMaxWidth(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // NOVO: nome da prova
          Text('NOME DA PROVA', style: AppTheme.kicker),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: TextField(
              controller: nomeProvaController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Ex: Avaliação bimestral — 2º bimestre',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 24),
          Text('1. SELECIONE A(S) MATÉRIA(S)', style: AppTheme.kicker),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._materiasDisponiveis.map((materia) {
                final selecionada = materiasSelecionadas.contains(materia.id);
                return FilterChip(
                  label: Text(materia.nome),
                  selected: selecionada,
                  onSelected: (val) => _toggleMateria(materia.id, val),
                );
              }),
              // NOVO
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Nova matéria'),
                onPressed: _criarNovaMateria,
              ),
            ],
          ),

          // NOVO: seção de turma
          const SizedBox(height: 24),
          Text('2. SELECIONE A TURMA (OPCIONAL)', style: AppTheme.kicker),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._turmasDisponiveis.map((turma) {
                final selecionada = turmaSelecionadaId == turma.id;
                return ChoiceChip(
                  label: Text(turma.nome),
                  selected: selecionada,
                  // toca de novo na mesma turma pra desmarcar
                  onSelected: (val) => _toggleTurma(val ? turma.id : null),
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Nova turma'),
                onPressed: _criarNovaTurma,
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text('3. SELECIONE AS QUESTÕES DO BANCO', style: AppTheme.kicker),
          const SizedBox(height: 8),

          if (questoesDisponiveis.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Selecione uma matéria acima para ver as questões disponíveis.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            ...questoesDisponiveis.map((questao) {
              final materia = _materiasDisponiveis.firstWhere(
                (m) => m.id == questao.materiaId,
                orElse: () => Materia(id: questao.materiaId, nome: '—'),
              );
              final selecionada = questoesSelecionadas.contains(questao.id);

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: AppListItem(
                  selected: selecionada,
                  leading: AppLeadingIcon(
                    icon: selecionada ? Icons.check : Icons.quiz_outlined,
                    background: selecionada ? AppColors.accent : AppColors.neutral100,
                    color: selecionada ? Colors.white : AppColors.textMuted,
                  ),
                  title: questao.enunciado,
                  subtitle: materia.nome,
                  trailing: Checkbox(
                    value: selecionada,
                    onChanged: (val) => _toggleQuestao(questao.id, val ?? false),
                  ),
                  onTap: () => _toggleQuestao(questao.id, !selecionada),
                ),
              );
            }),

          const SizedBox(height: 24),
          Text('4. MODO DE GERAÇÃO', style: AppTheme.kicker),
          RadioGroup<ModoProva>(
            groupValue: modoSelecionado,
            onChanged: (val) => setState(() => modoSelecionado = val!),
            child: Column(
              children: [
                RadioListTile<ModoProva>(
                  title: const Text('Mesma prova, embaralhada por versão'),
                  value: ModoProva.mesmaEmbaralhada,
                ),
                RadioListTile<ModoProva>(
                  title: const Text('Conjuntos de questões diferentes'),
                  value: ModoProva.conjuntosDiferentes,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: podeAvancar ? _avancarParaGeracao : null,
            child: const Text('Avançar para geração de provas'),
          ),
        ],
        ),
      ),
    );
  }
}

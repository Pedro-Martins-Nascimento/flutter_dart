// lib/screens/provas/criar_prova_screen.dart
//
// Tela "Criar Prova" (RF08/RF09): seleciona matéria(s), questões do
// banco e o modo de geração da prova.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/questao.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class CriarProvaScreen extends StatefulWidget {
  const CriarProvaScreen({super.key});

  @override
  State<CriarProvaScreen> createState() => _CriarProvaScreenState();
}

class _CriarProvaScreenState extends State<CriarProvaScreen> {
  final Set<String> materiasSelecionadas = {};
  final Set<String> questoesSelecionadas = {};
  ModoProva modoSelecionado = ModoProva.mesmaEmbaralhada;

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

  void _toggleQuestao(String questaoId, bool selecionado) {
    setState(() {
      if (selecionado) {
        questoesSelecionadas.add(questaoId);
      } else {
        questoesSelecionadas.remove(questaoId);
      }
    });
  }

  bool get podeAvancar => questoesSelecionadas.isNotEmpty;

  void _avancarParaGeracao() {
    final questoesEscolhidas =
        questoesMock.where((q) => questoesSelecionadas.contains(q.id)).toList();

    context.go(
      '/gerar-provas',
      extra: ProvaConfig(questoes: questoesEscolhidas, modo: modoSelecionado),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Prova')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('1. SELECIONE A(S) MATÉRIA(S)', style: AppTheme.kicker),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: materiasMock.map((materia) {
              final selecionada = materiasSelecionadas.contains(materia.id);
              return FilterChip(
                label: Text(materia.nome),
                selected: selecionada,
                onSelected: (val) => _toggleMateria(materia.id, val),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          Text('2. SELECIONE AS QUESTÕES DO BANCO', style: AppTheme.kicker),
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
              final materia = materiasMock.firstWhere((m) => m.id == questao.materiaId);
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
          Text('3. MODO DE GERAÇÃO', style: AppTheme.kicker),
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
    );
  }
}

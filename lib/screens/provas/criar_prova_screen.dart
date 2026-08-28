// lib/screens/provas/criar_prova_screen.dart
//
// Tela "Criar Prova" (N1 - dados mock, sem Firebase ainda)
// RF08 — Criar prova selecionando matéria(s) e questões do banco
// RF09 — Escolher modo: mesma prova embaralhada por versão, ou conjuntos
//        de questões diferentes
//
// ALTERADO (revisão de UI): a lista de questões (item 2) agora usa
// AppListItem em vez de CheckboxListTile puro — cada questão vira um
// card clicável, com um ícone à esquerda que muda de cor quando
// selecionada (mesmo tint do bordô usado nos chips), seguindo o
// visual soft/iOS-like do resto do app.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

// ---------------------------------------------------------------------
// MODELOS MOCK
// Depois (N2) isso vira classe real em lib/models/, vindo do Firestore.
// Por enquanto é só pra ter algo pra exibir na tela.
// ---------------------------------------------------------------------

class Materia {
  final String id;
  final String nome;

  Materia({required this.id, required this.nome});
}

class Questao {
  final String id;
  final String materiaId;
  final String enunciado;

  Questao({
    required this.id,
    required this.materiaId,
    required this.enunciado,
  });
}

// Modo de geração da prova (RF09)
enum ModoProva {
  mesmaEmbaralhada, // mesma prova, ordem das questões/alternativas embaralhada por versão
  conjuntosDiferentes, // versões com questões diferentes entre si
}

// ---------------------------------------------------------------------
// DADOS MOCK (fixos, só pra N1 funcionar sem banco)
// ---------------------------------------------------------------------

final List<Materia> materiasMock = [
  Materia(id: 'mat1', nome: 'Matemática'),
  Materia(id: 'mat2', nome: 'História'),
  Materia(id: 'mat3', nome: 'Biologia'),
];

final List<Questao> questoesMock = [
  Questao(id: 'q1', materiaId: 'mat1', enunciado: 'Quanto é 7 x 8?'),
  Questao(id: 'q2', materiaId: 'mat1', enunciado: 'Qual a raiz quadrada de 144?'),
  Questao(id: 'q3', materiaId: 'mat1', enunciado: 'Resolva: 2x + 4 = 10'),
  Questao(id: 'q4', materiaId: 'mat2', enunciado: 'Em que ano começou a 2ª Guerra Mundial?'),
  Questao(id: 'q5', materiaId: 'mat2', enunciado: 'Quem proclamou a independência do Brasil?'),
  Questao(id: 'q6', materiaId: 'mat3', enunciado: 'O que é fotossíntese?'),
  Questao(id: 'q7', materiaId: 'mat3', enunciado: 'Qual a função das mitocôndrias?'),
];

// ---------------------------------------------------------------------
// TELA
// ---------------------------------------------------------------------

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
    // TODO (revisão): a tela de geração ainda não recebe
    // questoesSelecionadas/modoSelecionado — ok pra N1, mas quando
    // entrar o banco real de questões (N2) precisamos passar isso pra
    // frente, provavelmente via `extra:` do go_router.
    context.go('/gerar-provas');
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
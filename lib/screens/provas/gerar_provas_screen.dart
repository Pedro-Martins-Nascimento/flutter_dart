// lib/screens/provas/gerar_provas_screen.dart
//
// Tela "Gerar Provas" (RF10/RF11/RF12): gera N versões da prova, cada
// uma com QR code, alternativas embaralhadas e gabarito próprios.
// O QR code é só um placeholder visual (trocar pelo pacote qr_flutter
// quando integrar).

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/questao.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class Aluno {
  final String id;
  final String nome;

  Aluno({required this.id, required this.nome});
}

// Questão já embaralhada dentro de uma versão específica: alternativas na
// ordem impressa e `respostaCorreta` recalculado pra essa ordem — é o
// gabarito daquela versão.
class QuestaoNaVersao {
  final Questao questao;
  final List<String> alternativas;
  final int respostaCorreta;

  QuestaoNaVersao({
    required this.questao,
    required this.alternativas,
    required this.respostaCorreta,
  });
}

class VersaoProva {
  final String id;
  final String qrCode;
  String? alunoId;
  final List<QuestaoNaVersao> questoes;
  final String materia;
  final String professor;

  VersaoProva({
    required this.id,
    required this.qrCode,
    required this.questoes,
    this.alunoId,
    this.materia = 'Matemática',
    this.professor = 'Prof. responsável',
  });
}

final List<Aluno> alunosMock = [
  Aluno(id: 'al1', nome: 'Bruno Oliveira'),
  Aluno(id: 'al2', nome: 'Carla Menezes'),
  Aluno(id: 'al3', nome: 'Diego Farias'),
];

class GerarProvasScreen extends StatefulWidget {
  final ProvaConfig? config;

  const GerarProvasScreen({super.key, this.config});

  @override
  State<GerarProvasScreen> createState() => _GerarProvasScreenState();
}

class _GerarProvasScreenState extends State<GerarProvasScreen> {
  final TextEditingController quantidadeController =
      TextEditingController(text: '3');
  final Random _random = Random();

  List<VersaoProva> versoes = [];

  List<Questao> get _bancoSelecionado {
    final questoes = widget.config?.questoes ?? const [];
    return questoes.isNotEmpty ? questoes : questoesMock.take(8).toList();
  }

  ModoProva get _modo => widget.config?.modo ?? ModoProva.mesmaEmbaralhada;

  void _gerarVersoes() {
    final quantidade = int.tryParse(quantidadeController.text) ?? 0;
    if (quantidade <= 0) return;

    final banco = _bancoSelecionado;
    final modo = _modo;

    setState(() {
      versoes = List.generate(quantidade, (i) {
        final numero = i + 1;
        return VersaoProva(
          id: 'v$numero',
          qrCode: 'PROVA-2026-V$numero-${(1000 + numero * 37)}',
          questoes: _materializarQuestoes(banco, modo),
        );
      });
    });
  }

  // Mesma embaralhada: todas as versões levam o conjunto completo, só a
  // ordem muda. Conjuntos diferentes: cada versão sorteia ~70% do banco.
  List<Questao> _questoesParaVersao(List<Questao> banco, ModoProva modo) {
    final embaralhado = List<Questao>.from(banco)..shuffle(_random);
    if (modo == ModoProva.mesmaEmbaralhada || banco.length <= 2) {
      return embaralhado;
    }
    final tamanho = (banco.length * 0.7).ceil().clamp(1, banco.length);
    return embaralhado.take(tamanho).toList();
  }

  // Embaralha as alternativas de cada questão e recalcula o índice da
  // correta na nova ordem — isso vira o gabarito daquela versão.
  List<QuestaoNaVersao> _materializarQuestoes(List<Questao> banco, ModoProva modo) {
    return _questoesParaVersao(banco, modo).map((questao) {
      final ordem = List<int>.generate(questao.alternativas.length, (i) => i)
        ..shuffle(_random);
      return QuestaoNaVersao(
        questao: questao,
        alternativas: ordem.map((i) => questao.alternativas[i]).toList(),
        respostaCorreta: ordem.indexOf(questao.respostaCorreta),
      );
    }).toList();
  }

  void _vincularAluno(VersaoProva versao, String? alunoId) {
    setState(() {
      versao.alunoId = alunoId;
    });
  }

  void _exportarPdf() {
    context.push('/gerar-provas/preview', extra: versoes);
  }

  @override
  void dispose() {
    quantidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerar Provas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('QUANTAS VERSÕES VOCÊ QUER GERAR?', style: AppTheme.kicker),
          const SizedBox(height: 8),
          AppCard(
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: quantidadeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _gerarVersoes,
                  child: const Text('Gerar versões'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (versoes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Nenhuma versão gerada ainda.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...versoes.map((versao) => _VersaoCard(
                  versao: versao,
                  onAlunoChanged: (alunoId) => _vincularAluno(versao, alunoId),
                )),

          const SizedBox(height: 24),
          if (versoes.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _exportarPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exportar PDF pronto para impressão'),
            ),
        ],
      ),
    );
  }
}

class _VersaoCard extends StatelessWidget {
  final VersaoProva versao;
  final ValueChanged<String?> onAlunoChanged;

  const _VersaoCard({required this.versao, required this.onAlunoChanged});

  @override
  Widget build(BuildContext context) {
    final vinculado = versao.alunoId != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: AppListItem(
        leading: const AppLeadingIcon(icon: Icons.qr_code_2),
        title: versao.id.toUpperCase(),
        subtitle: '${versao.qrCode} · ${versao.questoes.length} questões',
        trailing: Icon(
          vinculado ? Icons.link : Icons.link_off,
          size: 18,
          color: vinculado ? AppColors.accent : AppColors.neutral400,
        ),
        footer: DropdownButtonFormField<String?>(
          initialValue: versao.alunoId,
          decoration: const InputDecoration(
            labelText: 'Vincular aluno (opcional)',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Nenhum vínculo'),
            ),
            ...alunosMock.map(
              (aluno) => DropdownMenuItem<String?>(
                value: aluno.id,
                child: Text(aluno.nome),
              ),
            ),
          ],
          onChanged: onAlunoChanged,
        ),
      ),
    );
  }
}

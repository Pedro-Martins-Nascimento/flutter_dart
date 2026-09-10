// lib/screens/corrigir/corrigir_versao_screen.dart
//
// Depois que CorrigirScreen lê o QR de verdade (RF13) e acha a versão
// correspondente no histórico de provas, esta tela cobre RF14/RF15/RF16:
// como a leitura das marcações (OMR) ainda não existe, ela SIMULA uma
// detecção por questão (com chance de "não identificado") e deixa o
// professor confirmar ou corrigir cada alternativa manualmente antes de
// calcular a nota.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/questao.dart';
import '../../services/correcoes_repository.dart';
import '../../services/provas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../provas/gerar_provas_screen.dart';

class CorrigirVersaoScreen extends StatefulWidget {
  final ProvaGerada prova;
  final VersaoProva versao;

  const CorrigirVersaoScreen({
    super.key,
    required this.prova,
    required this.versao,
  });

  @override
  State<CorrigirVersaoScreen> createState() => _CorrigirVersaoScreenState();
}

class _CorrigirVersaoScreenState extends State<CorrigirVersaoScreen> {
  final Random _random = Random();
  late final List<int?> _respostasDetectadas;

  @override
  void initState() {
    super.initState();
    _respostasDetectadas = widget.versao.questoes.map((q) {
      final sorteio = _random.nextDouble();
      if (sorteio < 0.10) return null;
      if (sorteio < 0.22) {
        final erradas = List.generate(q.alternativas.length, (i) => i)
          ..remove(q.respostaCorreta);
        return erradas[_random.nextInt(erradas.length)];
      }
      return q.respostaCorreta;
    }).toList();
  }

  bool get _podeConfirmar => _respostasDetectadas.every((r) => r != null);

  void _confirmar() {
    final respostas = List.generate(widget.versao.questoes.length, (i) {
      final marcada = _respostasDetectadas[i]!;
      return RespostaQuestao(
        alternativaMarcada: marcada,
        correta: marcada == widget.versao.questoes[i].respostaCorreta,
      );
    });

    final correcao = Correcao(
      id: 'cor_${DateTime.now().millisecondsSinceEpoch}',
      versao: widget.versao,
      provaNome: widget.prova.nome,
      materia: widget.prova.materia,
      turma: widget.prova.turma,
      alunoNome: _nomeAluno(widget.versao.alunoId),
      corrigidoEm: DateTime.now(),
      respostas: respostas,
    );
    CorrecoesRepository.instance.salvar(correcao);

    context.pushReplacement('/corrigir/resultado', extra: correcao);
  }

  String? _nomeAluno(String? alunoId) {
    if (alunoId == null) return null;
    for (final aluno in alunosMock) {
      if (aluno.id == alunoId) return aluno.nome;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text('Corrigir ${widget.versao.id.toUpperCase()}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          AppCard(
            child: Row(
              children: [
                const AppLeadingIcon(icon: Icons.qr_code_2),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.prova.nome,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${widget.versao.qrCode} · ${_nomeAluno(widget.versao.alunoId) ?? 'Sem aluno vinculado'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
          Text(
            'ALTERNATIVAS DETECTADAS · REVISE ANTES DE CONFIRMAR',
            style: AppTheme.kicker,
          ),
          const SizedBox(height: AppSpacing.s3),
          ...List.generate(widget.versao.questoes.length, (i) {
            final questao = widget.versao.questoes[i];
            final detectada = _respostasDetectadas[i];
            final naoIdentificada = detectada == null;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: AppCard(
                border: naoIdentificada
                    ? Border.all(color: AppColors.warning, width: 1.2)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Q${(i + 1).toString().padLeft(2, '0')} · ${questao.questao.enunciado}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        if (naoIdentificada)
                          const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
                      ],
                    ),
                    if (naoIdentificada)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Não foi possível identificar — selecione manualmente.',
                          style: TextStyle(fontSize: 11, color: AppColors.warning),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.s2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(questao.alternativas.length, (alt) {
                        final selecionada = detectada == alt;
                        return ChoiceChip(
                          label: Text(letraAlternativa(alt)),
                          selected: selecionada,
                          onSelected: (_) => setState(() => _respostasDetectadas[i] = alt),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.s4),
          ElevatedButton.icon(
            onPressed: _podeConfirmar ? _confirmar : null,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar correção'),
          ),
        ],
      ),
    );
  }
}

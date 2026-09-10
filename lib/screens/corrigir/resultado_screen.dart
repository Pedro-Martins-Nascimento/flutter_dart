// lib/screens/corrigir/resultado_screen.dart
//
// Resultado de uma correção já concluída (RF16/RF17): nota final e, por
// questão, qual alternativa foi marcada e se bateu com o gabarito.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/questao.dart';
import '../../services/correcoes_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class ResultadoScreen extends StatelessWidget {
  final Correcao correcao;

  const ResultadoScreen({super.key, required this.correcao});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/corrigir'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(correcao.provaNome, style: AppTheme.kicker),
                const SizedBox(height: 4),
                Text(
                  '${correcao.versao.id.toUpperCase()} · ${correcao.alunoNome ?? 'Sem aluno vinculado'}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.s4),
                Row(
                  children: [
                    _numero('Nota', correcao.nota.toStringAsFixed(1)),
                    const SizedBox(width: AppSpacing.s6),
                    _numero('Acertos', '${correcao.acertos}/${correcao.total}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
          Text('GABARITO POR QUESTÃO', style: AppTheme.kicker),
          const SizedBox(height: AppSpacing.s3),
          ...List.generate(correcao.versao.questoes.length, (i) {
            final questao = correcao.versao.questoes[i];
            final resposta = correcao.respostas[i];

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: AppCard(
                child: Row(
                  children: [
                    AppLeadingIcon(
                      icon: resposta.correta ? Icons.check : Icons.close,
                      background: resposta.correta ? AppColors.accent100 : AppColors.warning100,
                      color: resposta.correta ? AppColors.accent : AppColors.warning,
                      size: 36,
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${(i + 1).toString().padLeft(2, '0')} · ${questao.questao.enunciado}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Marcada: ${letraAlternativa(resposta.alternativaMarcada)} · Certa: ${letraAlternativa(questao.respostaCorreta)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _numero(String rotulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
      ],
    );
  }
}

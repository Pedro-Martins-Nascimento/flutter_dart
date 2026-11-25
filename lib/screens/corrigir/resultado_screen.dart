// Resultado de uma correção já concluída: nota final, a foto da folha (se
// foi guardada) e, por questão, qual alternativa foi marcada e se bateu com
// o gabarito.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../models/correcao.dart';
import '../../models/questao.dart';
import '../../services/correcao_repository.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class ResultadoScreen extends StatelessWidget {
  final Correcao correcao;

  /// De onde vem a foto da folha. Sem ele, o botão da foto não aparece.
  final CorrecaoRepository? correcoes;

  const ResultadoScreen({super.key, required this.correcao, this.correcoes});

  Future<void> _verFoto(BuildContext context, CorrecaoRepository correcoes) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.s4),
        child: FutureBuilder<Uint8List?>(
          future: correcoes.buscarFoto(correcao.id),
          builder: (context, snapshot) {
            final Widget conteudo;
            if (snapshot.connectionState != ConnectionState.done) {
              conteudo = const Center(child: CircularProgressIndicator());
            } else if (snapshot.data case final foto?) {
              conteudo = InteractiveViewer(
                maxScale: 5,
                child: Image.memory(foto, key: const ValueKey('foto_folha')),
              );
            } else {
              conteudo = Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s5),
                  child: Text(
                    snapshot.hasError
                        ? 'Não foi possível carregar a foto.'
                        : 'Esta correção não tem foto guardada.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(child: conteudo),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _exportarBoletim() async {
    final bytes = await PdfService().gerarBoletimAluno(correcao);
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'boletim-${correcao.versaoId}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          // Aberto pelo histórico ou pela disciplina, volta para lá; vindo da
          // correção (que troca a tela), volta para a câmera.
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/corrigir'),
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
                  '${correcao.versaoId.toUpperCase()} · ${correcao.alunoNome ?? 'Sem aluno vinculado'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
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
          const SizedBox(height: AppSpacing.s3),
          OutlinedButton.icon(
            onPressed: _exportarBoletim,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar boletim (PDF)'),
          ),
          if (correcoes case final correcoes?) ...[
            const SizedBox(height: AppSpacing.s2),
            OutlinedButton.icon(
              onPressed: () => _verFoto(context, correcoes),
              icon: const Icon(Icons.photo_outlined),
              label: const Text('Ver foto da folha'),
            ),
          ],
          const SizedBox(height: AppSpacing.s5),
          Text('GABARITO POR QUESTÃO', style: AppTheme.kicker),
          const SizedBox(height: AppSpacing.s3),
          for (var i = 0; i < correcao.respostas.length; i++)
            _questao(i, correcao.respostas[i]),
        ],
      ),
    );
  }

  Widget _questao(int indice, RespostaQuestao resposta) {
    final certa = resposta.correta;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: AppCard(
        child: Row(
          children: [
            AppLeadingIcon(
              icon: certa ? Icons.check : Icons.close,
              background: certa ? AppColors.accent100 : AppColors.warning100,
              color: certa ? AppColors.accent : AppColors.warning,
              size: 36,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${(indice + 1).toString().padLeft(2, '0')} · ${resposta.enunciado}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Marcada: ${letraAlternativa(resposta.alternativaMarcada)} · Certa: ${letraAlternativa(resposta.respostaCorreta)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numero(String rotulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

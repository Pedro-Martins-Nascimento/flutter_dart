// lib/screens/provas/preview_layout_screen.dart
//
// Prévia do layout impresso da prova (RF12 + RNF04). Carrossel: cada
// versão é um card com seu próprio PdfPreview e botão de exportar.

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../services/pdf_service.dart';
import 'gerar_provas_screen.dart';

class PreviewLayoutScreen extends StatefulWidget {
  final List<VersaoProva> versoes;

  const PreviewLayoutScreen({super.key, required this.versoes});

  @override
  State<PreviewLayoutScreen> createState() => _PreviewLayoutScreenState();
}

class _PreviewLayoutScreenState extends State<PreviewLayoutScreen> {
  final PdfService _pdfService = PdfService();
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _paginaAtual = 0;

  // Só pra testar a paginação (RNF04) manualmente; não é opção do app final.
  late int _quantidadeQuestoesTeste;

  @override
  void initState() {
    super.initState();
    final primeiraVersao = widget.versoes.isNotEmpty ? widget.versoes.first : null;
    final quantidadeReal = primeiraVersao?.questoes.length ?? 8;
    _quantidadeQuestoesTeste = quantidadeReal.clamp(1, 30);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final versoes = widget.versoes;

    return Scaffold(
      appBar: AppBar(
        title: Text('Prévia — V${_paginaAtual + 1} de ${versoes.length}'),
      ),
      body: Column(
        children: [
          _buildControleTeste(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: versoes.length,
              onPageChanged: (i) => setState(() => _paginaAtual = i),
              itemBuilder: (context, index) {
                final versao = versoes[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: _VersaoPreviewCard(
                    // Muda quando a quantidade de teste muda, forçando o
                    // PdfPreview a recalcular em vez de usar o PDF antigo.
                    key: ValueKey('${versao.id}-$_quantidadeQuestoesTeste'),
                    versao: versao,
                    pdfService: _pdfService,
                    forcarQuantidadeParaTeste: _quantidadeQuestoesTeste,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControleTeste() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Text('Questões (teste):', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Slider(
              value: _quantidadeQuestoesTeste.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              label: '$_quantidadeQuestoesTeste',
              onChanged: (v) => setState(() => _quantidadeQuestoesTeste = v.round()),
            ),
          ),
          SizedBox(width: 24, child: Text('$_quantidadeQuestoesTeste')),
        ],
      ),
    );
  }
}

class _VersaoPreviewCard extends StatelessWidget {
  final VersaoProva versao;
  final PdfService pdfService;
  final int forcarQuantidadeParaTeste;

  const _VersaoPreviewCard({
    super.key,
    required this.versao,
    required this.pdfService,
    required this.forcarQuantidadeParaTeste,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              versao.id.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (format) => pdfService.gerarPdfVersao(
                versao,
                forcarQuantidadeParaTeste: forcarQuantidadeParaTeste,
              ),
              maxPageWidth: 320,
              canChangePageFormat: false,
              canChangeOrientation: false,
              allowPrinting: true,
              allowSharing: true,
              pdfFileName: '${versao.id}.pdf',
            ),
          ),
        ],
      ),
    );
  }
}

// lib/screens/provas/preview_layout_screen.dart
//
// Prévia do layout impresso da prova (RF12 + RNF04)
//
// Carrossel horizontal: cada versão é um card, você desliza o dedo pra
// o lado pra passar de versão. Dentro de cada card, se a versão tiver
// mais de uma página, elas empilham pra baixo sozinhas (comportamento
// padrão do PdfPreview) — é exatamente o que o PDF real vai fazer na
// impressão. Cada card tem seu próprio botão de imprimir/exportar,
// então dá pra baixar só a versão que você quiser.

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../services/pdf_service.dart';
import 'gerar_provas_screen.dart'; // VersaoProva

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

  // Controle SÓ PRA TESTE: deixa simular provas com mais ou menos
  // questões pra validar a paginação automática (RNF04) ao vivo, sem
  // precisar editar código. Não é uma opção real do app final.
  int _quantidadeQuestoesTeste = 8;

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
                    // key força recriar o preview quando a quantidade de
                    // teste muda, senão o PdfPreview mantém o PDF antigo
                    // em cache.
                    key: ValueKey('${versao.id}-$_quantidadeQuestoesTeste'),
                    versao: versao,
                    pdfService: _pdfService,
                    quantidadeQuestoes: _quantidadeQuestoesTeste,
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

// Card de uma versão: título + preview menor do PDF real dessa versão,
// com paginação e botões de imprimir/compartilhar já embutidos.
class _VersaoPreviewCard extends StatelessWidget {
  final VersaoProva versao;
  final PdfService pdfService;
  final int quantidadeQuestoes;

  const _VersaoPreviewCard({
    super.key,
    required this.versao,
    required this.pdfService,
    required this.quantidadeQuestoes,
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
                quantidadeQuestoes: quantidadeQuestoes,
              ),
              // Isso é o que deixa o preview menor na tela em vez de
              // ocupar a largura toda.
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
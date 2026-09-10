import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
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

  double _tamanhoFonte = 11;
  double _espacamento = 16;
  double _margem = 28;

  late int _quantidadeQuestoesTeste;

  @override
  void initState() {
    super.initState();
    final primeiraVersao = widget.versoes.isNotEmpty
        ? widget.versoes.first
        : null;
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
        title: Text(
          'Editor de layout — V${_paginaAtual + 1} de ${versoes.length}',
        ),
      ),
      body: AppMaxWidth(
        child: Column(
          children: [
            _buildControlesLayout(),
            _buildControleTeste(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: versoes.length,
                onPageChanged: (i) => setState(() => _paginaAtual = i),
                itemBuilder: (context, index) {
                  final versao = versoes[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: _VersaoPreviewCard(
                      key: ValueKey(
                        '${versao.id}-$_quantidadeQuestoesTeste-$_tamanhoFonte-$_espacamento-$_margem',
                      ),
                      versao: versao,
                      pdfService: _pdfService,
                      forcarQuantidadeParaTeste: _quantidadeQuestoesTeste,
                      tamanhoFonte: _tamanhoFonte,
                      espacamento: _espacamento,
                      margem: _margem,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlesLayout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s2,
        ),
        child: Column(
          children: [
            _sliderLinha(
              label: 'Tamanho da fonte',
              valor: _tamanhoFonte,
              min: 9,
              max: 16,
              divisoes: 7,
              sufixo: 'pt',
              onChanged: (v) => setState(() => _tamanhoFonte = v),
            ),
            _sliderLinha(
              label: 'Espaçamento entre questões',
              valor: _espacamento,
              min: 8,
              max: 32,
              divisoes: 24,
              sufixo: 'pt',
              onChanged: (v) => setState(() => _espacamento = v),
            ),
            _sliderLinha(
              label: 'Margem da página',
              valor: _margem,
              min: 14,
              max: 48,
              divisoes: 34,
              sufixo: 'pt',
              onChanged: (v) => setState(() => _margem = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderLinha({
    required String label,
    required double valor,
    required double min,
    required double max,
    required int divisoes,
    required String sufixo,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Slider(
            value: valor,
            min: min,
            max: max,
            divisions: divisoes,
            label: '${valor.round()}$sufixo',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${valor.round()}$sufixo',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
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
              onChanged: (v) =>
                  setState(() => _quantidadeQuestoesTeste = v.round()),
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
  final double tamanhoFonte;
  final double espacamento;
  final double margem;

  const _VersaoPreviewCard({
    super.key,
    required this.versao,
    required this.pdfService,
    required this.forcarQuantidadeParaTeste,
    required this.tamanhoFonte,
    required this.espacamento,
    required this.margem,
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
                tamanhoFonte: tamanhoFonte,
                espacamento: espacamento,
                margem: margem,
              ),
              maxPageWidth: 500,
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

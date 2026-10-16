import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/aluno.dart';
import '../../models/versao_prova.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../services/alunos_para_pdf.dart';
import '../../services/pdf_service.dart';
import '../../services/prova_repository.dart';
import '../../services/turmas_repository.dart';

/// Dados que a tela de gerar provas entrega ao editor de layout.
class PreviewLayoutArgs {
  final List<VersaoProva> versoes;
  final List<Aluno> alunos;

  const PreviewLayoutArgs({required this.versoes, this.alunos = const []});
}

class PreviewLayoutScreen extends StatefulWidget {
  // `versoes` vem pronta (construtor padrão) ou é lida do repository pelo id
  // (construtor `deProva`).
  final List<VersaoProva>? versoes;
  final List<Aluno> alunos;
  final ProvaRepository? repository;
  final String? provaId;

  const PreviewLayoutScreen({
    super.key,
    required List<VersaoProva> this.versoes,
    this.alunos = const [],
  }) : repository = null,
       provaId = null;

  // Abre o editor só com o id da prova, ex.: página recarregada.
  const PreviewLayoutScreen.deProva({
    super.key,
    required ProvaRepository this.repository,
    required String this.provaId,
  }) : versoes = null,
       alunos = const [];

  @override
  State<PreviewLayoutScreen> createState() => _PreviewLayoutScreenState();
}

class _PreviewLayoutScreenState extends State<PreviewLayoutScreen> {
  final PdfService _pdfService = PdfService();
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _paginaAtual = 0;

  List<VersaoProva> _versoes = const [];
  List<Aluno> _alunos = const [];
  bool _carregando = false;
  bool _naoEncontrada = false;

  double _tamanhoFonte = 11;
  double _espacamento = 16;
  double _margem = 28;

  int _quantidadeQuestoesTeste = 8;

  @override
  void initState() {
    super.initState();
    final dadas = widget.versoes;
    if (dadas != null) {
      _usarDados(dadas, widget.alunos);
    } else {
      _carregando = true;
      _carregarDoRepository();
    }
  }

  void _usarDados(List<VersaoProva> versoes, List<Aluno> alunos) {
    _versoes = versoes;
    _alunos = alunos;
    final quantidadeReal = versoes.isNotEmpty
        ? versoes.first.questoes.length
        : 8;
    _quantidadeQuestoesTeste = quantidadeReal.clamp(1, 30);
  }

  Future<void> _carregarDoRepository() async {
    final prova = await widget.repository!.buscar(widget.provaId!);
    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (prova == null) {
        _naoEncontrada = true;
      } else {
        final turmas = context.read<TurmasRepository>().turmas;
        _usarDados(prova.versoes, alunosDaTurma(prova.turma, turmas));
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final versoes = _versoes;

    if (_carregando || _naoEncontrada) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editor de layout')),
        body: Center(
          child: _carregando
              ? const CircularProgressIndicator()
              : const Text('Prova não encontrada.'),
        ),
      );
    }

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
                      alunos: _alunos,
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
  final List<Aluno> alunos;
  final PdfService pdfService;
  final int forcarQuantidadeParaTeste;
  final double tamanhoFonte;
  final double espacamento;
  final double margem;

  const _VersaoPreviewCard({
    super.key,
    required this.versao,
    required this.alunos,
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
                alunos: alunos,
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

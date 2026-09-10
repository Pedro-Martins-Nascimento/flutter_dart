import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../screens/provas/gerar_provas_screen.dart';

class PdfService {
  Future<Uint8List> gerarPdfVersao(
    VersaoProva versao, {
    int? forcarQuantidadeParaTeste,
    double tamanhoFonte = 11,
    double espacamento = 16,
    double margem = 28,
  }) async {
    final doc = await _criarDocumentoBase();
    doc.addPage(
      _construirPaginaVersao(
        versao,
        forcarQuantidadeParaTeste,
        tamanhoFonte,
        espacamento,
        margem,
      ),
    );
    return doc.save();
  }

  Future<Uint8List> gerarPdfProvas(
    List<VersaoProva> versoes, {
    int? forcarQuantidadeParaTeste,
    double tamanhoFonte = 11,
    double espacamento = 16,
    double margem = 28,
  }) async {
    final doc = await _criarDocumentoBase();
    for (final versao in versoes) {
      doc.addPage(
        _construirPaginaVersao(
          versao,
          forcarQuantidadeParaTeste,
          tamanhoFonte,
          espacamento,
          margem,
        ),
      );
    }
    return doc.save();
  }

  Future<pw.Document> _criarDocumentoBase() async {
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    return pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );
  }

  pw.Page _construirPaginaVersao(
    VersaoProva versao,
    int? forcarQuantidadeParaTeste,
    double tamanhoFonte,
    double espacamento,
    double margem,
  ) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(margem),
      header: (context) => _buildHeader(versao),
      footer: (context) => _buildFooterMarkers(),
      build: (context) => _buildQuestoes(
        versao,
        forcarQuantidadeParaTeste,
        tamanhoFonte,
        espacamento,
      ),
    );
  }

  pw.Widget _buildHeader(VersaoProva versao) {
    return pw.Container(
      width: double.infinity,
      height: 70,
      child: pw.Stack(
        children: [
          pw.Positioned(left: 0, top: 0, child: _cornerMarker()),
          pw.Positioned(right: 0, top: 0, child: _cornerMarker()),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PROVA',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        versao.provaNome,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.Text(
                        versao.id.toUpperCase(),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        versao.alunoId != null
                            ? 'Aluno vinculado'
                            : 'Sem vínculo de aluno',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: versao.qrCode,
                  width: 48,
                  height: 48,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooterMarkers() {
    return pw.Container(
      width: double.infinity,
      height: 24,
      child: pw.Stack(
        children: [
          pw.Positioned(left: 0, bottom: 0, child: _cornerMarker()),
          pw.Positioned(right: 0, bottom: 0, child: _cornerMarker()),
        ],
      ),
    );
  }

  pw.Widget _buildCabecalhoIdentificacao(VersaoProva versao) {
    final aluno = _nomeAluno(versao);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.8, color: PdfColors.grey600),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _campoIdentificacao('Aluno', aluno),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: _campoIdentificacao('Professor', versao.professor),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _campoIdentificacao('Matéria', versao.materia),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: _campoIdentificacao('Turma', versao.turma ?? '—'),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _campoIdentificacao('Data', '____/____/______'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _campoIdentificacao(String label, String valor) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.TextSpan(text: valor, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  String _nomeAluno(VersaoProva versao) {
    if (versao.alunoId == null) return '_______________________________';
    final aluno = alunosMock.firstWhere(
      (a) => a.id == versao.alunoId,
      orElse: () => Aluno(id: '', nome: '—'),
    );
    return aluno.nome;
  }

  pw.Widget _cornerMarker() {
    return pw.Container(width: 16, height: 16, color: PdfColors.black);
  }

  List<pw.Widget> _buildQuestoes(
    VersaoProva versao,
    int? forcarQuantidadeParaTeste,
    double tamanhoFonte,
    double espacamento,
  ) {
    final questoes = versao.questoes;
    final semForcarTeste =
        forcarQuantidadeParaTeste == null || questoes.isEmpty;
    final lista = semForcarTeste
        ? questoes
        : List.generate(
            forcarQuantidadeParaTeste,
            (i) => questoes[i % questoes.length],
          );

    return [
      _buildCabecalhoIdentificacao(versao),
      pw.SizedBox(height: 12),
      if (lista.isEmpty)
        pw.Text(
          'Nenhuma questão selecionada para esta prova.',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        )
      else
        ...lista.asMap().entries.map((entry) {
          final numero = entry.key + 1;
          final questaoVersao = entry.value;
          return pw.Padding(
            padding: pw.EdgeInsets.only(bottom: espacamento),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '$numero. ${questaoVersao.questao.enunciado}',
                  style: pw.TextStyle(fontSize: tamanhoFonte),
                ),
                pw.SizedBox(height: 6),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: List.generate(questaoVersao.alternativas.length, (
                    alt,
                  ) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 10,
                            height: 10,
                            margin: const pw.EdgeInsets.only(top: 2),
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(width: 0.8),
                            ),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Expanded(
                            child: pw.Text(
                              '${String.fromCharCode(65 + alt)}) ${questaoVersao.alternativas[alt]}',
                              style: pw.TextStyle(fontSize: tamanhoFonte - 1),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        }),
    ];
  }
}

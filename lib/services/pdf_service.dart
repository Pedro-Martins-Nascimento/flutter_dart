// lib/services/pdf_service.dart
//
// Geração real do PDF das provas (RF12 + RNF04).
// Usa o pacote `pdf` puro (não widgets do Flutter) porque ele sabe
// paginar sozinho: se uma questão não cabe na página atual, ela inteira
// vai pra próxima página — nada é cortado no meio.

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // PdfGoogleFonts — fonte com suporte a acentuação

import '../screens/provas/gerar_provas_screen.dart'; // VersaoProva
// TODO: quando o modelo VersaoProva virar arquivo próprio em lib/models/,
// atualizar esse import.

class PdfService {
  /// Gera o PDF de UMA versão só (usado no preview em carrossel, onde
  /// cada versão tem seu próprio botão de exportar/imprimir).
  Future<Uint8List> gerarPdfVersao(
    VersaoProva versao, {
    int quantidadeQuestoes = 8,
  }) async {
    final doc = await _criarDocumentoBase();
    doc.addPage(_construirPaginaVersao(versao, quantidadeQuestoes));
    return doc.save();
  }

  /// Gera um PDF único contendo TODAS as versões (uma atrás da outra).
  /// Útil pra um botão de "exportar tudo de uma vez", se o grupo quiser
  /// isso em alguma outra tela.
  Future<Uint8List> gerarPdfProvas(
    List<VersaoProva> versoes, {
    int quantidadeQuestoes = 8,
  }) async {
    final doc = await _criarDocumentoBase();
    for (final versao in versoes) {
      doc.addPage(_construirPaginaVersao(versao, quantidadeQuestoes));
    }
    return doc.save();
  }

  Future<pw.Document> _criarDocumentoBase() async {
    // Helvetica (fonte padrão do pdf) não tem acentuação — troca por uma
    // fonte com Unicode completo, senão "Correção", "questões" etc saem
    // quebrados no PDF final.
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    return pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );
  }

  pw.Page _construirPaginaVersao(VersaoProva versao, int quantidadeQuestoes) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => _buildHeader(versao),
      footer: (context) => _buildFooterMarkers(),
      build: (context) => _buildQuestoes(versao, quantidadeQuestoes),
    );
  }

  // Cabeçalho: título, identificação da versão, vínculo de aluno (se
  // houver), QR code real (codificando o mesmo dado mock de antes) e
  // os marcadores de canto superiores.
  pw.Widget _buildHeader(VersaoProva versao) {
    // Container com altura fixa: é o que dá ao Stack um tamanho de
    // referência. Sem isso, um Stack só com filhos Positioned não sabe
    // se dimensionar e acaba "comendo" a altura da página inteira.
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
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                      ),
                      pw.Text(versao.id.toUpperCase(), style: const pw.TextStyle(fontSize: 11)),
                      pw.Text(
                        versao.alunoId != null ? 'Aluno vinculado' : 'Sem vínculo de aluno',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                // QR code real, codificando o mesmo dado mock que já
                // existia (versao.qrCode). Quando entrar o modelo de dados
                // de verdade (N2), o conteúdo codificado aqui é que muda,
                // a lógica de gerar continua igual.
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

  // Marcadores de canto inferiores, repetidos em toda página (inclusive
  // se uma versão precisar de mais de uma página). Mesmo raciocínio do
  // header: precisa de altura fixa pra não bagunçar o cálculo de espaço.
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

  // Bloco de identificação (Aluno / Professor / Matéria / Data).
  // Fica dentro do `build:` (não do header/footer), então só aparece
  // uma vez, no topo da primeira página — mesmo que a prova estoure
  // pra várias páginas.
  pw.Widget _buildCabecalhoIdentificacao(VersaoProva versao) {
    final data = _formatarData(DateTime.now());
    final aluno = _nomeAluno(versao);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8, color: PdfColors.grey600)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _campoIdentificacao('Aluno', aluno),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _campoIdentificacao('Professor', versao.professor)),
              pw.SizedBox(width: 12),
              pw.Expanded(child: _campoIdentificacao('Matéria', versao.materia)),
            ],
          ),
          pw.SizedBox(height: 4),
          _campoIdentificacao('Data', data),
        ],
      ),
    );
  }

  pw.Widget _campoIdentificacao(String label, String valor) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.TextSpan(text: valor, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // Busca o nome do aluno vinculado (link real que já existe desde a
  // tela Gerar Provas). Se não tiver vínculo, deixa uma linha em
  // branco pra preencher à mão.
  String _nomeAluno(VersaoProva versao) {
    if (versao.alunoId == null) return '_______________________________';
    final aluno = alunosMock.firstWhere(
      (a) => a.id == versao.alunoId,
      orElse: () => Aluno(id: '', nome: '—'),
    );
    return aluno.nome;
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  pw.Widget _cornerMarker() {
    return pw.Container(width: 16, height: 16, color: PdfColors.black);
  }

  // Lista de questões mock — cada uma é um widget independente, então o
  // MultiPage consegue empurrar uma questão inteira pra próxima página
  // se ela não couber, em vez de cortar no meio.
  // `quantidade` agora é parâmetro: é o que permite testar o
  // comportamento de paginação (RNF04) direto pela tela, sem editar código.
  List<pw.Widget> _buildQuestoes(VersaoProva versao, int quantidade) {
    const enunciadoMock =
        'Qual das alternativas abaixo apresenta corretamente a principal '
        'diferença entre uma questão objetiva e uma questão discursiva no '
        'processo de avaliação dos alunos?';

    return [
      _buildCabecalhoIdentificacao(versao),
      pw.SizedBox(height: 12),
      ...List.generate(quantidade, (i) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${i + 1}. $enunciadoMock', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 6),
              pw.Row(
                children: List.generate(4, (alt) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 14),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 10,
                          height: 10,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(width: 0.8),
                          ),
                        ),
                        pw.SizedBox(width: 3),
                        pw.Text(String.fromCharCode(65 + alt), style: const pw.TextStyle(fontSize: 10)),
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
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/aluno.dart';
import '../models/correcao.dart';
import '../models/questao.dart';
import '../models/versao_prova.dart';
import 'layout_folha.dart';

class PdfService {
  /// [criarDocumento] troca o documento-base (as fontes vêm da internet pelo
  /// Google Fonts). Serve para testar sem rede.
  PdfService({this._criarDocumento});

  final Future<pw.Document> Function()? _criarDocumento;

  /// Boletim de um aluno: nota, acertos e o gabarito questão a questão (o que
  /// ele marcou e o que era certo).
  Future<Uint8List> gerarBoletimAluno(Correcao correcao) =>
      gerarBoletinsMultiplos([correcao]);

  /// Boletins de várias correções de uma vez, uma página por correção.
  Future<Uint8List> gerarBoletinsMultiplos(List<Correcao> correcoes) async {
    final doc = await _criarDocumentoBase();
    for (final correcao in correcoes) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => _buildBoletim(correcao),
        ),
      );
    }
    return doc.save();
  }

  List<pw.Widget> _buildBoletim(Correcao correcao) {
    return [
      pw.Text(
        'Boletim: ${correcao.provaNome}',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        '${correcao.alunoNome ?? 'Sem aluno vinculado'} · '
        '${correcao.versaoId.toUpperCase()}'
        '${correcao.turma != null ? ' · ${correcao.turma}' : ''}',
        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 16),
      pw.Row(
        children: [
          _campoResumo('Nota', correcao.nota.toStringAsFixed(1)),
          pw.SizedBox(width: 24),
          _campoResumo('Acertos', '${correcao.acertos}/${correcao.total}'),
        ],
      ),
      pw.SizedBox(height: 16),
      pw.Text(
        'GABARITO POR QUESTÃO',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
        columnWidths: const {
          0: pw.FlexColumnWidth(1),
          1: pw.FlexColumnWidth(6),
          2: pw.FlexColumnWidth(2),
          3: pw.FlexColumnWidth(2),
        },
        children: [
          _linhaTabela('Nº', 'Enunciado', 'Marcada', 'Certa', cabecalho: true),
          for (var i = 0; i < correcao.respostas.length; i++)
            _linhaTabela(
              '${i + 1}',
              correcao.respostas[i].enunciado,
              letraAlternativa(correcao.respostas[i].alternativaMarcada),
              letraAlternativa(correcao.respostas[i].respostaCorreta),
            ),
        ],
      ),
    ];
  }

  pw.Widget _campoResumo(String rotulo, String valor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          rotulo,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.Text(
          valor,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  pw.TableRow _linhaTabela(
    String numero,
    String enunciado,
    String marcada,
    String certa, {
    bool cabecalho = false,
  }) {
    final estilo = pw.TextStyle(
      fontSize: 9,
      fontWeight: cabecalho ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    pw.Widget celula(String texto) => pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(texto, style: estilo),
    );
    return pw.TableRow(
      children: [
        celula(numero),
        celula(enunciado),
        celula(marcada),
        celula(certa),
      ],
    );
  }

  Future<Uint8List> gerarPdfVersao(
    VersaoProva versao, {
    int? forcarQuantidadeParaTeste,
    double tamanhoFonte = 11,
    double espacamento = 16,
    double margem = LayoutFolha.margemPadrao,
    List<Aluno> alunos = const [],
  }) async {
    return gerarPdfProvas(
      [versao],
      forcarQuantidadeParaTeste: forcarQuantidadeParaTeste,
      tamanhoFonte: tamanhoFonte,
      espacamento: espacamento,
      margem: margem,
      alunos: alunos,
    );
  }

  Future<Uint8List> gerarPdfProvas(
    List<VersaoProva> versoes, {
    int? forcarQuantidadeParaTeste,
    double tamanhoFonte = 11,
    double espacamento = 16,
    double margem = LayoutFolha.margemPadrao,
    List<Aluno> alunos = const [],
  }) async {
    // Cada versão sai em duas partes, uma atrás da outra: o caderno de
    // questões ("Prova A") e o gabarito em que o aluno marca as respostas
    // ("Gabarito da Prova A"). Só o gabarito tem QR, marcadores de canto e
    // bolinhas, porque é ele que é fotografado na correção.
    Future<Uint8List> montar(Set<QuestaoNaVersao> questoesAltas) async {
      final doc = await _criarDocumentoBase();
      for (final versao in versoes) {
        doc.addPage(
          _construirPaginaVersao(
            versao,
            forcarQuantidadeParaTeste,
            tamanhoFonte,
            espacamento,
            margem,
            alunos,
            questoesAltas,
          ),
        );
        for (final pagina in _construirGabarito(
          versao,
          forcarQuantidadeParaTeste,
          alunos,
        )) {
          doc.addPage(pagina);
        }
      }
      return doc.save();
    }

    try {
      return await montar(const {});
    } on Exception {
      // Falhou. Só se refaz o PDF se o motivo for uma questão que não cabe
      // inteira nem numa página vazia: essas (e só essas) passam a poder ser
      // divididas, e as demais continuam inteiras. Qualquer outro erro
      // (fonte, dado inválido, layout) segue para quem chamou.
      final altas = await _questoesMaisAltasQuePagina(
        versoes,
        forcarQuantidadeParaTeste,
        tamanhoFonte,
        espacamento,
        margem,
      );
      if (altas.isEmpty) rethrow;
      return montar(altas);
    }
  }

  /// Mede cada questão sozinha numa página vazia, com o mesmo cabeçalho,
  /// rodapé e margem do PDF. Devolve as que não cabem inteiras mas cabem
  /// divididas. Se uma questão não couber nem dividida, o erro dela é
  /// propagado, porque aí o problema não é só a altura.
  Future<Set<QuestaoNaVersao>> _questoesMaisAltasQuePagina(
    List<VersaoProva> versoes,
    int? forcarQuantidadeParaTeste,
    double tamanhoFonte,
    double espacamento,
    double margem,
  ) async {
    final doc = await _criarDocumentoBase();
    final altas = <QuestaoNaVersao>{};
    final medidas = <QuestaoNaVersao>{};

    for (final versao in versoes) {
      final lista = _listaDeQuestoes(versao, forcarQuantidadeParaTeste);
      for (var i = 0; i < lista.length; i++) {
        final questaoVersao = lista[i];
        if (!medidas.add(questaoVersao)) continue;

        pw.Page paginaCom({required bool inteira}) {
          final questao = _buildQuestao(
            i + 1,
            questaoVersao,
            tamanhoFonte,
            espacamento,
          );
          return _paginaDaVersao(
            versao,
            margem,
            () => [inteira ? pw.Inseparable(child: questao) : questao],
          );
        }

        try {
          doc.addPage(paginaCom(inteira: true));
        } on Exception {
          // Não coube inteira. Se dividida também não couber, este addPage
          // lança e o erro sobe.
          doc.addPage(paginaCom(inteira: false));
          altas.add(questaoVersao);
        }
      }
    }
    return altas;
  }

  Future<pw.Document> _criarDocumentoBase() async {
    final injetado = _criarDocumento;
    if (injetado != null) return injetado();
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
    List<Aluno> alunos,
    Set<QuestaoNaVersao> questoesAltas,
  ) {
    return _paginaDaVersao(
      versao,
      margem,
      () => _buildQuestoes(
        versao,
        forcarQuantidadeParaTeste,
        tamanhoFonte,
        espacamento,
        alunos,
        questoesAltas,
      ),
    );
  }

  /// Páginas A4 do caderno de questões da versão. É a mesma usada na medição
  /// das questões, para as duas terem o mesmo espaço útil.
  pw.Page _paginaDaVersao(
    VersaoProva versao,
    double margem,
    List<pw.Widget> Function() corpo,
  ) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(margem),
      header: (context) => _cabecalhoCaderno(versao),
      footer: (context) => _rodapeCaderno(versao),
      build: (context) => corpo(),
    );
  }

  /// Cabeçalho repetido em toda página do caderno, para uma folha solta
  /// ainda dizer de qual prova é. Sem QR: a correção lê só o gabarito.
  pw.Widget _cabecalhoCaderno(VersaoProva versao) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 0.8, color: PdfColors.grey600),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PROVA ${versao.letra}',
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
              ],
            ),
          ),
          pw.Text(
            'Marque as respostas no Gabarito da Prova ${versao.letra}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _rodapeCaderno(VersaoProva versao) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Prova ${versao.letra} · ${versao.id.toUpperCase()}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  /// Gabarito (cartão-resposta) da versão: marcadores de canto, QR de
  /// correção e as bolinhas de cada questão. O QR sai só na primeira página
  /// do gabarito.
  ///
  /// Tudo é posicionado em coordenadas absolutas de [LayoutFolha] (sempre com
  /// a margem padrão), porque o leitor das marcações procura cada bolinha
  /// exatamente nesses pontos. Por isso cada página do gabarito é montada à
  /// parte, sem deixar o conteúdo refluir de uma página para outra.
  List<pw.Page> _construirGabarito(
    VersaoProva versao,
    int? forcarQuantidadeParaTeste,
    List<Aluno> alunos,
  ) {
    const margem = LayoutFolha.margemPadrao;
    const larguraUtil = LayoutFolha.larguraPagina - 2 * margem;
    final lista = _listaDeQuestoes(versao, forcarQuantidadeParaTeste);
    final grade = LayoutFolha.gradeGabarito([
      for (final q in lista) q.alternativas.length,
    ]);
    final paginas = grade.isEmpty ? 1 : grade.last.pagina + 1;

    pw.Widget posicionar(double esquerda, double topo, pw.Widget filho) =>
        pw.Positioned(left: esquerda, top: topo, child: filho);

    return [
      for (var pagina = 0; pagina < paginas; pagina++)
        // MultiPage de uma página só: é montado na hora, como o caderno, e
        // assim as páginas saem no arquivo na mesma ordem em que aparecem.
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) => [
            pw.SizedBox(
              width: LayoutFolha.larguraPagina,
              // Um fio menor que a página, para o MultiPage não abrir outra.
              height: LayoutFolha.alturaPagina - 1,
              child: pw.Stack(
                children: [
                  posicionar(
                    margem,
                    margem,
                    pw.SizedBox(
                      width: larguraUtil,
                      child: _buildHeader(versao, comQr: pagina == 0),
                    ),
                  ),
                  posicionar(
                    margem,
                    LayoutFolha.alturaPagina -
                        margem -
                        LayoutFolha.alturaRodape,
                    pw.SizedBox(
                      width: larguraUtil,
                      child: _buildFooterMarkers(),
                    ),
                  ),
                  if (pagina == 0) ...[
                    posicionar(
                      margem,
                      LayoutFolha.topoIdentificacaoGabarito,
                      pw.SizedBox(
                        width: larguraUtil,
                        height: LayoutFolha.alturaIdentificacaoGabarito,
                        child: _buildCabecalhoIdentificacao(versao, alunos),
                      ),
                    ),
                    posicionar(
                      margem,
                      LayoutFolha.topoAvisoGabarito,
                      pw.SizedBox(
                        width: larguraUtil,
                        height: LayoutFolha.alturaAvisoGabarito,
                        child: _avisoComoMarcar(versao),
                      ),
                    ),
                  ],
                  if (lista.isEmpty && pagina == 0)
                    posicionar(
                      margem,
                      LayoutFolha.topoGradePrimeiraPagina,
                      pw.Text(
                        'Nenhuma questão selecionada para esta prova.',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  for (var q = 0; q < grade.length; q++)
                    if (grade[q].pagina == pagina) ...[
                      posicionar(
                        grade[q].numero.dx,
                        grade[q].numero.dy + 2,
                        pw.Text(
                          '${(q + 1).toString().padLeft(2, '0')}.',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      for (var a = 0; a < grade[q].bolinhas.length; a++)
                        posicionar(
                          grade[q].bolinhas[a].left,
                          grade[q].bolinhas[a].top,
                          _bolinha(a),
                        ),
                    ],
                ],
              ),
            ),
          ],
        ),
    ];
  }

  /// Aviso em destaque no topo do gabarito: marcar com X, com exemplos
  /// desenhados do jeito certo e dos jeitos que atrapalham a leitura.
  pw.Widget _avisoComoMarcar(VersaoProva versao) {
    const corAviso = PdfColor.fromInt(0xFFB45309);
    pw.Widget exemplo(String rotulo, List<_Marca> marcas, {required bool ok}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(right: 16),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              rotulo,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: ok ? PdfColors.green800 : PdfColors.red800,
              ),
            ),
            pw.SizedBox(width: 4),
            for (var alt = 0; alt < marcas.length; alt++)
              pw.Padding(
                padding: const pw.EdgeInsets.only(right: 3),
                child: _bolinha(alt, marca: marcas[alt]),
              ),
          ],
        ),
      );
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF7E6),
        border: pw.Border.all(width: 1, color: corAviso),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ATENÇÃO: MARQUE A RESPOSTA COM UM X',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: corAviso,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Faça um X sobre a bolinha da alternativa escolhida, com caneta '
            'preta ou azul: assim a correção lê melhor. Marque só uma '
            'alternativa por questão e não rasure. Use este gabarito apenas '
            'para a Prova ${versao.letra}.',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            runSpacing: 4,
            children: [
              exemplo('CERTO (X)', const [
                _Marca.nenhuma,
                _Marca.x,
                _Marca.nenhuma,
                _Marca.nenhuma,
              ], ok: true),
              exemplo('ERRADO (visto)', const [
                _Marca.nenhuma,
                _Marca.visto,
                _Marca.nenhuma,
                _Marca.nenhuma,
              ], ok: false),
              exemplo('ERRADO (duas marcas)', const [
                _Marca.x,
                _Marca.nenhuma,
                _Marca.x,
                _Marca.nenhuma,
              ], ok: false),
            ],
          ),
        ],
      ),
    );
  }

  /// Bolinha do gabarito com a letra dentro. [marca] desenha um X ou um
  /// visto por cima, para os exemplos do aviso.
  pw.Widget _bolinha(int alt, {_Marca marca = _Marca.nenhuma}) {
    const lado = LayoutFolha.diametroBolinhaGabarito;
    final circulo = pw.Container(
      width: lado,
      height: lado,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(width: LayoutFolha.bordaBolinha),
      ),
      child: pw.Text(
        letraAlternativa(alt),
        style: const pw.TextStyle(fontSize: 7),
      ),
    );
    if (marca == _Marca.nenhuma) return circulo;

    return pw.Stack(
      children: [
        circulo,
        pw.CustomPaint(
          size: const PdfPoint(lado, lado),
          painter: (canvas, size) {
            // Origem no canto inferior esquerdo, y para cima.
            canvas
              ..setStrokeColor(PdfColors.blue900)
              ..setLineWidth(1.4)
              ..setLineCap(PdfLineCap.round);
            if (marca == _Marca.x) {
              canvas
                ..moveTo(1, 1)
                ..lineTo(size.x - 1, size.y - 1)
                ..moveTo(1, size.y - 1)
                ..lineTo(size.x - 1, 1);
            } else {
              canvas
                ..moveTo(2, size.y * 0.5)
                ..lineTo(size.x * 0.42, 2)
                ..lineTo(size.x + 1, size.y + 1);
            }
            canvas.strokePath();
          },
        ),
      ],
    );
  }

  pw.Widget _buildHeader(VersaoProva versao, {required bool comQr}) {
    return pw.Container(
      width: double.infinity,
      height: LayoutFolha.alturaCabecalho,
      child: pw.Stack(
        children: [
          pw.Positioned(left: 0, top: 0, child: _cornerMarker()),
          pw.Positioned(right: 0, top: 0, child: _cornerMarker()),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: LayoutFolha.paddingHorizontalCabecalho,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GABARITO DA PROVA ${versao.letra}',
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

                if (comQr)
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: versao.qrCode,
                    width: LayoutFolha.ladoQr,
                    height: LayoutFolha.ladoQr,
                  )
                else
                  pw.SizedBox(
                    width: LayoutFolha.ladoQr,
                    height: LayoutFolha.ladoQr,
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
      height: LayoutFolha.alturaRodape,
      child: pw.Stack(
        children: [
          pw.Positioned(left: 0, bottom: 0, child: _cornerMarker()),
          pw.Positioned(right: 0, bottom: 0, child: _cornerMarker()),
        ],
      ),
    );
  }

  pw.Widget _buildCabecalhoIdentificacao(
    VersaoProva versao,
    List<Aluno> alunos,
  ) {
    final aluno = _nomeAluno(versao, alunos);

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
                child: _campoIdentificacao(
                  'Disciplina',
                  disciplinaDaVersao(versao) ?? '—',
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: _campoIdentificacao(
                  'Turma',
                  turmaDaVersao(versao) ?? '—',
                ),
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

  String _nomeAluno(VersaoProva versao, List<Aluno> alunos) {
    if (versao.alunoId == null) return '_______________________________';
    final aluno = alunos.firstWhere(
      (a) => a.id == versao.alunoId,
      orElse: () => Aluno(id: '', nome: '—'),
    );
    return aluno.nome;
  }

  pw.Widget _cornerMarker() {
    return pw.Container(
      width: LayoutFolha.ladoMarcador,
      height: LayoutFolha.ladoMarcador,
      color: PdfColors.black,
    );
  }

  List<pw.Widget> _buildQuestoes(
    VersaoProva versao,
    int? forcarQuantidadeParaTeste,
    double tamanhoFonte,
    double espacamento,
    List<Aluno> alunos,
    Set<QuestaoNaVersao> questoesAltas,
  ) {
    final lista = _listaDeQuestoes(versao, forcarQuantidadeParaTeste);

    return [
      _buildCabecalhoIdentificacao(versao, alunos),
      pw.SizedBox(height: 12),
      if (lista.isEmpty)
        pw.Text(
          'Nenhuma questão selecionada para esta prova.',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        )
      else
        ...lista.asMap().entries.map((entry) {
          final questaoWidget = _buildQuestao(
            entry.key + 1,
            entry.value,
            tamanhoFonte,
            espacamento,
          );
          // Inseparable: a questão inteira (enunciado e alternativas) vai para
          // a página seguinte em vez de ser cortada no meio, o que atrapalharia
          // a leitura das bolinhas. Só as questões que não cabem nem numa
          // página vazia (questoesAltas) podem ser divididas.
          return questoesAltas.contains(entry.value)
              ? questaoWidget
              : pw.Inseparable(child: questaoWidget);
        }),
    ];
  }

  /// Questões da versão, repetidas até [forcarQuantidadeParaTeste] se vier.
  List<QuestaoNaVersao> _listaDeQuestoes(
    VersaoProva versao,
    int? forcarQuantidadeParaTeste,
  ) {
    final questoes = versao.questoes;
    final semForcarTeste =
        forcarQuantidadeParaTeste == null || questoes.isEmpty;
    return semForcarTeste
        ? questoes
        : List.generate(
            forcarQuantidadeParaTeste,
            (i) => questoes[i % questoes.length],
          );
  }

  pw.Widget _buildQuestao(
    int numero,
    QuestaoNaVersao questaoVersao,
    double tamanhoFonte,
    double espacamento,
  ) {
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
          // Alternativas direto na Column da questão (sem Column dentro de
          // Column): assim o PDF consegue dividir uma questão muito alta
          // entre as alternativas, quando ela não cabe numa página.
          // Sem bolinhas: o aluno marca a resposta no gabarito.
          ...List.generate(questaoVersao.alternativas.length, (alt) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4, left: 8),
              child: pw.Text(
                '${letraAlternativa(alt)}) ${questaoVersao.alternativas[alt]}',
                style: pw.TextStyle(fontSize: tamanhoFonte - 1),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Marca desenhada numa bolinha dos exemplos do aviso do gabarito.
enum _Marca { nenhuma, x, visto }

/// Disciplina impressa na prova. Versões antigas, de antes das turmas,
/// guardavam o nome da disciplina no campo turma.
String? disciplinaDaVersao(VersaoProva versao) =>
    versao.disciplina ?? versao.turma;

/// Turma impressa na prova (nenhuma nas versões antigas).
String? turmaDaVersao(VersaoProva versao) =>
    versao.disciplina == null ? null : versao.turma;

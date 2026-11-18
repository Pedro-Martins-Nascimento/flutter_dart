import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/aluno.dart';
import '../models/versao_prova.dart';
import '../models/prova_gerada.dart';

class DocxService {
  Uint8List gerar(ProvaGerada prova, {List<Aluno> alunos = const []}) {
    final documento = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:body>',
    );

    for (var i = 0; i < prova.versoes.length; i++) {
      if (i > 0) {
        _paragrafo(documento, '<w:r><w:br w:type="page"/></w:r>');
      }
      _adicionarVersao(documento, prova, prova.versoes[i], i + 1, alunos);
    }

    documento.write(
      '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
      '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>'
      '</w:sectPr></w:body></w:document>',
    );

    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes))
      ..addFile(ArchiveFile.string('_rels/.rels', _rels))
      ..addFile(ArchiveFile.string('word/document.xml', documento.toString()));

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  void _adicionarVersao(
    StringBuffer xml,
    ProvaGerada prova,
    VersaoProva versao,
    int numero,
    List<Aluno> alunos,
  ) {
    _paragrafo(xml, _texto('Versão $numero', negrito: true, tamanho: 32));
    _paragrafo(xml, _texto(versao.provaNome, negrito: true));
    _paragrafo(xml, _texto('Matéria: ${versao.materia}'));
    _paragrafo(xml, _texto('Turma: ${versao.turma ?? 'Não informada'}'));
    _paragrafo(xml, _texto('Professor: ${versao.professor}'));
    _paragrafo(xml, _texto('Data: ${_data(prova.criadoEm)}'));
    _paragrafo(
      xml,
      _texto('Aluno: ${_nomeAluno(versao, alunos)}'),
    );

    for (var i = 0; i < versao.questoes.length; i++) {
      final questao = versao.questoes[i];
      _paragrafo(
        xml,
        _texto('${i + 1}. ${questao.questao.enunciado}', negrito: true),
      );
      for (var j = 0; j < questao.alternativas.length; j++) {
        _paragrafo(xml, _texto('${String.fromCharCode(65 + j)}) ${questao.alternativas[j]}'));
      }
    }
  }

  String _nomeAluno(VersaoProva versao, List<Aluno> alunos) {
    final alunoId = versao.alunoId;
    if (alunoId == null) return '____________________';
    for (final aluno in alunos) {
      if (aluno.id == alunoId) return aluno.nome;
    }
    return '____________________';
  }

  String _data(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/${data.year}';

  void _paragrafo(StringBuffer xml, String conteudo) {
    xml.write('<w:p>$conteudo</w:p>');
  }

  String _texto(
    String valor, {
    bool negrito = false,
    int? tamanho,
  }) {
    final propriedades = StringBuffer();
    if (negrito) propriedades.write('<w:b/>');
    if (tamanho != null) propriedades.write('<w:sz w:val="$tamanho"/>');
    final rpr = propriedades.isEmpty ? '' : '<w:rPr>$propriedades</w:rPr>';
    return '<w:r>$rpr<w:t xml:space="preserve">${_escapar(valor)}</w:t></w:r>';
  }

  String _escapar(String valor) => const HtmlEscape().convert(valor);

  static const _contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '</Types>';

  static const _rels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>';
}

Uint8List gerarDocx(
  ProvaGerada prova, {
  List<Aluno> alunos = const [],
}) => DocxService().gerar(prova, alunos: alunos);

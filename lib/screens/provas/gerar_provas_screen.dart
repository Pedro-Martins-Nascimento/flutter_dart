import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../models/questao.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../services/provas_repository.dart';
import '../../services/pdf_service.dart';
import 'criar_prova_screen.dart' show DadosProva;
import '../turmas/criar_turma_screen.dart' show Turma, turmasMock;

class Aluno {
  final String id;
  final String nome;

  Aluno({required this.id, required this.nome});
}

class QuestaoNaVersao {
  final Questao questao;
  final List<String> alternativas;
  final int respostaCorreta;

  QuestaoNaVersao({
    required this.questao,
    required this.alternativas,
    required this.respostaCorreta,
  });

  // A questão vai embutida (não só o id) porque uma prova já gerada não
  // pode mudar se a questão for editada/excluída do banco depois.
  Map<String, dynamic> toJson() => {
    'questao': questao.toJson(),
    'alternativas': alternativas,
    'respostaCorreta': respostaCorreta,
  };

  factory QuestaoNaVersao.fromJson(Map<String, dynamic> json) => QuestaoNaVersao(
    questao: Questao.fromJson(json['questao'] as Map<String, dynamic>),
    alternativas: List<String>.from(json['alternativas'] as List),
    respostaCorreta: json['respostaCorreta'] as int,
  );
}

class VersaoProva {
  final String id;
  final String qrCode;
  String? alunoId;
  final List<QuestaoNaVersao> questoes;

  final String materia;
  final String professor;
  final String? turma;
  final String provaNome;

  VersaoProva({
    required this.id,
    required this.qrCode,
    required this.questoes,
    this.alunoId,
    this.materia = 'Matemática',
    this.professor = 'Prof. responsável',
    this.turma,
    this.provaNome = 'Prova sem título',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'qrCode': qrCode,
    'alunoId': alunoId,
    'questoes': questoes.map((q) => q.toJson()).toList(),
    'materia': materia,
    'professor': professor,
    'turma': turma,
    'provaNome': provaNome,
  };

  factory VersaoProva.fromJson(Map<String, dynamic> json) => VersaoProva(
    id: json['id'] as String,
    qrCode: json['qrCode'] as String,
    alunoId: json['alunoId'] as String?,
    questoes: (json['questoes'] as List)
        .map((q) => QuestaoNaVersao.fromJson(q as Map<String, dynamic>))
        .toList(),
    materia: json['materia'] as String,
    professor: json['professor'] as String,
    turma: json['turma'] as String?,
    provaNome: json['provaNome'] as String,
  );
}

// Extraídas da State pra dar pra testar sem precisar montar o widget
// inteiro (ver test/gerar_provas_test.dart) — garantem que, depois do
// embaralhamento, `alternativas[respostaCorreta]` continua sendo o texto
// certo da questão original.
List<Questao> questoesParaVersao(List<Questao> banco, ModoProva modo, Random random) {
  final embaralhado = List<Questao>.from(banco)..shuffle(random);
  if (modo == ModoProva.mesmaEmbaralhada || banco.length <= 2) {
    return embaralhado;
  }
  final tamanho = (banco.length * 0.7).ceil().clamp(1, banco.length);
  return embaralhado.take(tamanho).toList();
}

List<QuestaoNaVersao> materializarQuestoes(List<Questao> banco, ModoProva modo, Random random) {
  return questoesParaVersao(banco, modo, random).map((questao) {
    final ordem = List<int>.generate(questao.alternativas.length, (i) => i)
      ..shuffle(random);
    return QuestaoNaVersao(
      questao: questao,
      alternativas: ordem.map((i) => questao.alternativas[i]).toList(),
      respostaCorreta: ordem.indexOf(questao.respostaCorreta),
    );
  }).toList();
}

final List<Aluno> alunosMock = [
  Aluno(id: 'al1', nome: 'Bruno Oliveira'),
  Aluno(id: 'al2', nome: 'Carla Menezes'),
  Aluno(id: 'al3', nome: 'Diego Farias'),
];

class GerarProvasScreen extends StatefulWidget {
  final DadosProva? dados;

  final ProvaGerada? provaExistente;

  const GerarProvasScreen({super.key, this.dados, this.provaExistente});

  @override
  State<GerarProvasScreen> createState() => _GerarProvasScreenState();
}

class _GerarProvasScreenState extends State<GerarProvasScreen> {
  final TextEditingController quantidadeController = TextEditingController(
    text: '3',
  );
  final PdfService _pdfService = PdfService();
  final Random _random = Random();

  bool _salva = false;

  List<VersaoProva> versoes = [];

  @override
  void initState() {
    super.initState();
    final provaExistente = widget.provaExistente;
    if (provaExistente != null) {
      versoes = List.of(provaExistente.versoes);
      return;
    }

    final pedidas = widget.dados?.versoes;
    if (pedidas != null && pedidas > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _gerarVersoes(pedidas);
      });
    }
  }

  List<Questao> get _bancoSelecionado {
    final questoes = widget.dados?.questoes ?? const [];
    return questoes.isNotEmpty ? questoes : questoesMock.take(8).toList();
  }

  ModoProva get _modo => widget.dados?.modo ?? ModoProva.mesmaEmbaralhada;

  Turma? get _turma {
    final daCriacao = widget.dados?.turma;
    if (daCriacao != null) return daCriacao;

    final nome = widget.provaExistente?.turma;
    if (nome == null) return null;
    for (final turma in turmasMock) {
      if (turma.nome == nome) return turma;
    }
    return null;
  }

  List<Aluno> get _alunosDisponiveis {
    final alunos = _turma?.alunos ?? const [];
    if (alunos.isEmpty) return alunosMock;
    return [for (final aluno in alunos) Aluno(id: aluno.id, nome: aluno.nome)];
  }

  String get _materiaTexto {
    final dados = widget.dados;
    return (dados != null && dados.materias.isNotEmpty)
        ? dados.materiasResumo
        : 'Matemática';
  }

  String get _provaNome => widget.dados?.nomeProva ?? 'Prova sem título';

  String? get _turmaTexto => widget.dados?.turma?.nome;

  void _gerarVersoes([int? quantas]) {
    final quantidade = quantas ?? int.tryParse(quantidadeController.text) ?? 0;
    if (quantidade <= 0) return;

    final banco = _bancoSelecionado;
    final modo = _modo;
    final materiaTexto = _materiaTexto;
    final provaNome = _provaNome;
    final turmaTexto = _turmaTexto;

    // Se a prova está presa a uma turma, já vincula um aluno por versão
    // (round-robin pela lista da turma) — o professor não precisa marcar
    // vínculo por vínculo à mão, só ajustar se alguém faltar/trocar.
    final alunosParaVincular = _turma?.alunos ?? const [];

    setState(() {
      versoes = List.generate(quantidade, (i) {
        final numero = i + 1;
        return VersaoProva(
          id: 'v$numero',

          qrCode: 'PROVA-2026-V$numero-${(1000 + numero * 37)}',
          questoes: materializarQuestoes(banco, modo, _random),
          materia: materiaTexto,
          professor: 'Prof. responsável',
          turma: turmaTexto,
          provaNome: provaNome,
          alunoId: alunosParaVincular.isEmpty
              ? null
              : alunosParaVincular[i % alunosParaVincular.length].id,
        );
      });
    });

    setState(() => _salva = false);
  }

  void _salvarProva() {
    if (versoes.isEmpty || _salva) return;

    ProvasRepository.instance.salvar(
      ProvaGerada(
        id: 'pg_${DateTime.now().millisecondsSinceEpoch}',
        nome: _provaNome,
        materia: _materiaTexto,
        turma: _turmaTexto,
        criadoEm: DateTime.now(),
        versoes: versoes,
      ),
    );

    setState(() => _salva = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Prova salva em Provas geradas.')),
      );
    context.go('/provas-geradas');
  }

  void _vincularAluno(VersaoProva versao, String? alunoId) {
    setState(() {
      versao.alunoId = alunoId;
    });
  }

  void _voltar() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/provas-geradas');
    }
  }

  Future<void> _exportarPdfDireto() async {
    final bytes = await _pdfService.gerarPdfProvas(versoes);
    final nome =
        widget.provaExistente?.nome ?? widget.dados?.nomeProva ?? 'provas';
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: '$nome.pdf',
    );
  }

  void _abrirEditorDeLayout() {
    context.push('/gerar-provas/preview', extra: versoes);
  }

  @override
  void dispose() {
    quantidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editandoExistente = widget.provaExistente != null;
    final quantidadeVeioDaCriacao = (widget.dados?.versoes ?? 0) > 0;
    final mostrarTopo =
        !editandoExistente && !quantidadeVeioDaCriacao || editandoExistente;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          editandoExistente ? widget.provaExistente!.nome : 'Gerar Provas',
        ),

        leading: BackButton(onPressed: _voltar),
      ),

      body: Column(
        children: [
          if (mostrarTopo)
            AppFaixa(
              bordaBase: const BorderSide(color: AppColors.divider),
              child: editandoExistente
                  ? _resumoProvaExistente()
                  : _campoQuantidade(),
            ),
          Expanded(
            child: versoes.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Nenhuma versão gerada ainda.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: AppMaxWidth(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...versoes.map(
                              (versao) => _VersaoCard(
                                versao: versao,
                                alunos: _alunosDisponiveis,
                                onAlunoChanged: (alunoId) =>
                                    _vincularAluno(versao, alunoId),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          if (versoes.isNotEmpty) _acoes(editandoExistente),
        ],
      ),
    );
  }

  Widget _campoQuantidade() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('QUANTAS VERSÕES VOCÊ QUER GERAR?', style: AppTheme.kicker),
        const SizedBox(height: 8),
        AppCard(
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: TextField(
                  controller: quantidadeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _gerarVersoes,
                  child: const Text('Gerar versões'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resumoProvaExistente() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('DESEJA EDITAR O VÍNCULO DA PROVA?', style: AppTheme.kicker),
        const SizedBox(height: 8),
        AppCard(
          child: Text(
            '${widget.provaExistente!.materia}'
            '${widget.provaExistente!.turma != null ? ' • ${widget.provaExistente!.turma}' : ''}'
            ' • ${versoes.length} versão(ões)',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _acoes(bool editandoExistente) {
    return AppFaixa(
      color: AppColors.surface,
      bordaTopo: const BorderSide(color: AppColors.divider),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportarPdfDireto,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportar PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _abrirEditorDeLayout,
                    icon: const Icon(Icons.tune),
                    label: const Text('Editor de layout'),
                  ),
                ),
              ],
            ),
            if (!editandoExistente) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salva ? null : _salvarProva,
                  icon: const Icon(Icons.check),
                  label: Text(_salva ? 'Prova salva' : 'Salvar prova'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VersaoCard extends StatelessWidget {
  final VersaoProva versao;
  final List<Aluno> alunos;
  final ValueChanged<String?> onAlunoChanged;

  const _VersaoCard({
    required this.versao,
    required this.alunos,
    required this.onAlunoChanged,
  });

  @override
  Widget build(BuildContext context) {
    final vinculado = versao.alunoId != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: AppListItem(
        leading: const AppLeadingIcon(icon: Icons.qr_code_2),
        title: versao.id.toUpperCase(),
        subtitle: '${versao.qrCode} · ${versao.questoes.length} questões',
        trailing: Icon(
          vinculado ? Icons.link : Icons.link_off,
          size: 18,
          color: vinculado ? AppColors.accent : AppColors.neutral400,
        ),
        footer: DropdownButtonFormField<String?>(
          initialValue: versao.alunoId,
          decoration: const InputDecoration(
            labelText: 'Vincular aluno (opcional)',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Nenhum vínculo'),
            ),
            ...alunos.map(
              (aluno) => DropdownMenuItem<String?>(
                value: aluno.id,
                child: Text(aluno.nome),
              ),
            ),
          ],
          onChanged: onAlunoChanged,
        ),
      ),
    );
  }
}

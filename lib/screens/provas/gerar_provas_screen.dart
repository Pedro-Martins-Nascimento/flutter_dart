import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../../models/aluno.dart';
import '../../models/questao.dart';
import '../../models/turma.dart';
import '../../models/versao_prova.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../services/prova_repository.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_erro.dart';
import '../../models/prova_gerada.dart';
import '../../services/alunos_para_pdf.dart';
import '../../services/pdf_service.dart';
import '../../services/questoes_repository.dart';
import '../../services/turmas_repository.dart';
import 'criar_prova_screen.dart' show DadosProva;
import 'preview_layout_screen.dart' show PreviewLayoutArgs;

class GerarProvasScreen extends StatefulWidget {
  final DadosProva? dados;

  final ProvaGerada? provaExistente;

  final ProvaRepository repository;

  const GerarProvasScreen({
    super.key,
    required this.repository,
    this.dados,
    this.provaExistente,
  });

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

  /// Caixa "Vincular cada prova a um aluno". Ligada, cada versão recebe um
  /// aluno da turma (dá para trocar); desligada, nenhuma versão tem aluno.
  bool _vincular = false;

  List<VersaoProva> versoes = [];

  @override
  void initState() {
    super.initState();
    final provaExistente = widget.provaExistente;
    if (provaExistente != null) {
      // Prova antiga, salva com "Prof. responsável": imprime com o nome de
      // quem está logado.
      versoes = [
        for (final versao in provaExistente.versoes)
          versao.comProfessorSePadrao(_nomeProfessor),
      ];
      _vincular = versoes.any((v) => v.alunoId != null);
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
    return questoes.isNotEmpty
        ? questoes
        : context.read<QuestoesRepository>().questoes.take(8).toList();
  }

  ModoProva get _modo => widget.dados?.modo ?? ModoProva.mesmaEmbaralhada;

  /// Alunos que podem ser vinculados às versões: os da turma escolhida (ou
  /// de toda a disciplina, se nenhuma turma foi escolhida).
  List<Aluno> get _alunosDisponiveis {
    final dados = widget.dados;
    final List<AlunoTurma> alunos;
    if (dados != null) {
      alunos = dados.turma?.alunos ?? dados.disciplina?.alunos ?? const [];
    } else {
      final prova = widget.provaExistente;
      alunos = prova == null
          ? const []
          : alunosTurmaDaProva(
              disciplina: prova.disciplina,
              turma: prova.turma,
              disciplinas: context.read<TurmasRepository>().disciplinas,
            );
    }
    return [for (final aluno in alunos) Aluno(id: aluno.id, nome: aluno.nome)];
  }

  /// O campo "matéria" da prova guarda o nome da disciplina (não há mais
  /// matérias; ele continua no banco para as provas antigas).
  String get _materiaTexto =>
      widget.dados?.disciplina?.nome ?? 'Sem disciplina';

  /// Nome do professor logado (sem AuthService, como em alguns testes, fica
  /// o texto padrão).
  String get _nomeProfessor =>
      context.read<AuthService?>()?.nomeProfessor ??
      VersaoProva.professorPadrao;

  String get _provaNome => widget.dados?.nomeProva ?? 'Prova sem título';

  String? get _turmaTexto => widget.dados?.turma?.nome;

  String? get _disciplinaTexto => widget.dados?.disciplina?.nome;

  void _gerarVersoes([int? quantas]) {
    final quantidade = quantas ?? int.tryParse(quantidadeController.text) ?? 0;
    if (quantidade <= 0) return;

    final banco = _bancoSelecionado;
    final modo = _modo;
    final materiaTexto = _materiaTexto;
    final provaNome = _provaNome;
    final turmaTexto = _turmaTexto;
    final disciplinaTexto = _disciplinaTexto;

    setState(() {
      versoes = List.generate(quantidade, (i) {
        final numero = i + 1;
        return VersaoProva(
          id: 'v$numero',

          qrCode: 'PROVA-2026-V$numero-${(1000 + numero * 37)}',
          questoes: _materializarQuestoes(banco, modo),
          materia: materiaTexto,
          professor: _nomeProfessor,
          turma: turmaTexto,
          disciplina: disciplinaTexto,
          provaNome: provaNome,
        );
      });
      if (_vincular) _preencherVinculos();
    });

    setState(() => _salva = false);
  }

  Future<void> _salvarProva() async {
    if (versoes.isEmpty || _salva) return;

    setState(() => _salva = true); // evita salvar duas vezes com toque duplo
    final editando = widget.dados?.editando;
    final prova = ProvaGerada(
      id: editando?.id ?? 'pg_${DateTime.now().millisecondsSinceEpoch}',
      nome: _provaNome,
      materia: _materiaTexto,
      turma: _turmaTexto,
      disciplina: _disciplinaTexto,
      criadoEm: editando?.criadoEm ?? DateTime.now(),
      versoes: versoes,
    );
    try {
      if (editando != null) {
        await widget.repository.editar(prova);
      } else {
        await widget.repository.criar(prova);
      }
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salva = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            eErroDeConexao(erro)
                ? 'Sem conexão. A prova não foi salva.'
                : 'Não foi possível salvar a prova.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            editando != null
                ? 'Prova atualizada.'
                : 'Prova salva em Provas geradas.',
          ),
        ),
      );
    context.go('/provas-geradas');
  }

  List<Questao> _questoesParaVersao(List<Questao> banco, ModoProva modo) {
    final embaralhado = List<Questao>.from(banco)..shuffle(_random);
    if (modo == ModoProva.mesmaEmbaralhada || banco.length <= 2) {
      return embaralhado;
    }
    final tamanho = (banco.length * 0.7).ceil().clamp(1, banco.length);
    return embaralhado.take(tamanho).toList();
  }

  List<QuestaoNaVersao> _materializarQuestoes(
    List<Questao> banco,
    ModoProva modo,
  ) {
    return _questoesParaVersao(banco, modo).map((questao) {
      final ordem = List<int>.generate(questao.alternativas.length, (i) => i)
        ..shuffle(_random);
      return QuestaoNaVersao(
        questao: questao,
        alternativas: ordem.map((i) => questao.alternativas[i]).toList(),
        respostaCorreta: ordem.indexOf(questao.respostaCorreta),
      );
    }).toList();
  }

  Future<void> _vincularAluno(VersaoProva versao, String? alunoId) async {
    setState(() {
      versao.alunoId = alunoId;
    });
    await _gravarVinculos([versao]);
  }

  /// Liga ou desliga o vínculo de todas as versões de uma vez.
  Future<void> _alternarVinculo(bool ligar) async {
    final mudadas = <VersaoProva>[];
    setState(() {
      _vincular = ligar;
      if (ligar) {
        mudadas.addAll(_preencherVinculos());
      } else {
        for (final versao in versoes) {
          if (versao.alunoId == null) continue;
          versao.alunoId = null;
          mudadas.add(versao);
        }
      }
    });
    await _gravarVinculos(mudadas);
  }

  /// Dá a cada versão sem aluno o próximo aluno da turma que ainda não tem
  /// prova, na ordem da lista. Devolve as versões que mudaram.
  List<VersaoProva> _preencherVinculos() {
    final usados = {
      for (final versao in versoes)
        if (versao.alunoId != null) versao.alunoId,
    };
    final livres = _alunosDisponiveis
        .where((aluno) => !usados.contains(aluno.id))
        .iterator;
    final mudadas = <VersaoProva>[];
    for (final versao in versoes) {
      if (versao.alunoId != null) continue;
      if (!livres.moveNext()) break;
      versao.alunoId = livres.current.id;
      mudadas.add(versao);
    }
    return mudadas;
  }

  /// Aluno → letra da prova em que ele já está, sem contar [versao]. Esses
  /// alunos ficam desabilitados na lista dela: um aluno só faz uma prova.
  Map<String, String> _alunosEmOutrasProvas(VersaoProva versao) => {
    for (final outra in versoes)
      if (outra != versao && outra.alunoId != null) outra.alunoId!: outra.letra,
  };

  /// Alunos que estão em mais de uma versão (prova salva antes da trava).
  List<Aluno> _alunosRepetidos() {
    final contagem = <String, int>{};
    for (final versao in versoes) {
      final id = versao.alunoId;
      if (id != null) contagem[id] = (contagem[id] ?? 0) + 1;
    }
    return [
      for (final aluno in _alunosDisponiveis)
        if ((contagem[aluno.id] ?? 0) > 1) aluno,
    ];
  }

  /// Alunos da turma que não estão em nenhuma versão.
  List<Aluno> _alunosSemProva() {
    final comProva = {for (final versao in versoes) versao.alunoId};
    return [
      for (final aluno in _alunosDisponiveis)
        if (!comProva.contains(aluno.id)) aluno,
    ];
  }

  /// O repository guarda cópias: numa prova já salva, o vínculo precisa ser
  /// gravado.
  Future<void> _gravarVinculos(List<VersaoProva> mudadas) async {
    final existente = widget.provaExistente;
    if (existente == null || mudadas.isEmpty) return;
    try {
      for (final versao in mudadas) {
        await widget.repository.atualizarVersao(existente.id, versao);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o vínculo.')),
      );
    }
  }

  void _voltar() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/provas-geradas');
    }
  }

  Future<void> _exportarPdfDireto() async {
    final bytes = await _pdfService.gerarPdfProvas(
      versoes,
      alunos: _alunosDisponiveis,
    );
    final nome =
        widget.provaExistente?.nome ?? widget.dados?.nomeProva ?? 'provas';
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: '$nome.pdf',
    );
  }

  void _abrirEditorDeLayout() {
    // O provaId (prova já salva) permite reabrir o editor lendo do repository.
    final id = widget.provaExistente?.id;
    context.push(
      id == null
          ? '/gerar-provas/preview'
          : '/gerar-provas/preview?provaId=$id',
      extra: PreviewLayoutArgs(versoes: versoes, alunos: _alunosDisponiveis),
    );
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
                            _painelVinculo(),
                            const SizedBox(height: AppSpacing.s3),
                            ...versoes.map(
                              (versao) => _VersaoCard(
                                versao: versao,
                                alunos: _alunosDisponiveis,
                                ocupados: _alunosEmOutrasProvas(versao),
                                vincular: _vincular,
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

  Widget _painelVinculo() {
    final alunos = _alunosDisponiveis;
    final semProva = _vincular ? _alunosSemProva() : const <Aluno>[];
    final repetidos = _vincular ? _alunosRepetidos() : const <Aluno>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
          // Material próprio: o cartão tem fundo e esconderia o efeito de
          // toque da caixa.
          child: Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
              value: _vincular,
              onChanged: alunos.isEmpty
                  ? null
                  : (valor) => _alternarVinculo(valor ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.accent,
              title: const Text(
                'Vincular cada prova a um aluno',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                alunos.isEmpty
                    ? 'A turma escolhida não tem alunos para vincular.'
                    : 'Cada prova já vem com um aluno da turma; dá para trocar.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
        if (repetidos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s2),
          _AvisoAlunos(
            alunos: repetidos,
            umAluno: '1 aluno está em mais de uma prova',
            variosAlunos: (n) => '$n alunos estão em mais de uma prova',
            dica: 'Cada aluno deve ficar em uma prova só.',
          ),
        ],
        if (semProva.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s2),
          _AvisoAlunos(
            alunos: semProva,
            umAluno: '1 aluno ficou sem prova',
            variosAlunos: (n) => '$n alunos ficaram sem prova',
            dica: 'Gere mais versões ou troque os vínculos.',
          ),
        ],
      ],
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

/// Aviso amarelo com uma lista de alunos (sem prova, ou repetidos).
class _AvisoAlunos extends StatelessWidget {
  final List<Aluno> alunos;
  final String umAluno;
  final String Function(int quantidade) variosAlunos;
  final String dica;

  const _AvisoAlunos({
    required this.alunos,
    required this.umAluno,
    required this.variosAlunos,
    required this.dica,
  });

  @override
  Widget build(BuildContext context) {
    const mostrar = 5;
    final nomes = alunos.take(mostrar).map((a) => a.nome).toList();
    final resto = alunos.length - nomes.length;
    final lista = resto > 0
        ? '${nomes.join(', ')} e mais $resto'
        : nomes.length == 1
        ? nomes.single
        : '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
    final titulo = alunos.length == 1 ? umAluno : variosAlunos(alunos.length);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.warning100,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$titulo: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '$lista. '),
                  TextSpan(text: dica),
                ],
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersaoCard extends StatelessWidget {
  final VersaoProva versao;
  final List<Aluno> alunos;

  /// Alunos já em outra prova (id → letra da prova): ficam desabilitados.
  final Map<String, String> ocupados;
  final bool vincular;
  final ValueChanged<String?> onAlunoChanged;

  const _VersaoCard({
    required this.versao,
    required this.alunos,
    required this.ocupados,
    required this.vincular,
    required this.onAlunoChanged,
  });

  @override
  Widget build(BuildContext context) {
    final vinculado = versao.alunoId != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: AppListItem(
        leading: const AppLeadingIcon(icon: Icons.qr_code_2),
        title: 'Prova ${versao.letra}',
        subtitle: '${versao.qrCode} · ${versao.questoes.length} questões',
        trailing: Icon(
          vinculado ? Icons.link : Icons.link_off,
          size: 18,
          color: vinculado ? AppColors.accent : AppColors.neutral400,
        ),
        footer: !vincular
            ? null
            : DropdownButtonFormField<String?>(
                // A chave muda com o aluno: quando o vínculo é preenchido de uma
                // vez, o campo mostra o novo valor.
                key: ValueKey('${versao.id}-${versao.alunoId}'),
                initialValue: versao.alunoId,
                decoration: const InputDecoration(
                  labelText: 'Aluno',
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Nenhum vínculo'),
                  ),
                  for (final aluno in alunos)
                    if (ocupados[aluno.id] case final letra?)
                      DropdownMenuItem<String?>(
                        value: aluno.id,
                        enabled: false,
                        child: Text(
                          '${aluno.nome} · já na Prova $letra',
                          style: const TextStyle(color: AppColors.neutral400),
                        ),
                      )
                    else
                      DropdownMenuItem<String?>(
                        value: aluno.id,
                        child: Text(aluno.nome),
                      ),
                ],
                onChanged: onAlunoChanged,
              ),
      ),
    );
  }
}

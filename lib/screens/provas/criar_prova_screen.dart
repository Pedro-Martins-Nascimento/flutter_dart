import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/questao.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../models/turma.dart';
import '../../models/prova_gerada.dart';
import '../../services/questoes_repository.dart';
import '../../services/turmas_repository.dart';

class DadosProva {
  final String nomeProva;
  final Disciplina? disciplina;
  final Turma? turma;
  final List<Questao> questoes;
  final ModoProva modo;
  final int versoes;
  final ProvaGerada? editando;

  DadosProva({
    required this.nomeProva,
    this.disciplina,
    required this.turma,
    required this.questoes,
    required this.modo,
    required this.versoes,
    this.editando,
  });
}

const _minVersoes = 1;
const _maxVersoes = 12;

class CriarProvaScreen extends StatefulWidget {
  final ProvaGerada? editando;

  const CriarProvaScreen({super.key, this.editando});

  @override
  State<CriarProvaScreen> createState() => _CriarProvaScreenState();
}

class _CriarProvaScreenState extends State<CriarProvaScreen> {
  List<Disciplina> get _disciplinasDisponiveis =>
      context.read<TurmasRepository>().disciplinas;
  Disciplina? get _disciplinaSelecionada => disciplinaSelecionadaId == null
      ? null
      : context.read<TurmasRepository>().disciplinaPorId(
          disciplinaSelecionadaId!,
        );
  List<Questao> get _bancoDeQuestoes =>
      context.read<QuestoesRepository>().questoes;

  String? disciplinaSelecionadaId;
  String? turmaSelecionadaId;
  final Set<String> questoesSelecionadas = {};
  ModoProva modoSelecionado = ModoProva.mesmaEmbaralhada;

  final TextEditingController nomeProvaController = TextEditingController();

  int versoesAGerar = 4;

  late final String _assinaturaInicial;

  bool get _editando => widget.editando != null;

  @override
  void initState() {
    super.initState();
    final prova = widget.editando;
    if (prova != null) _preencherCom(prova);
    _assinaturaInicial = _assinatura;
  }

  void _preencherCom(ProvaGerada prova) {
    nomeProvaController.text = prova.nome;

    final noBanco = {for (final q in _bancoDeQuestoes) q.id};
    for (final versao in prova.versoes) {
      for (final q in versao.questoes) {
        if (!noBanco.contains(q.questao.id)) continue;
        questoesSelecionadas.add(q.questao.id);
      }
    }

    // Provas antigas guardavam o nome da disciplina no campo turma.
    final nomeDisciplina = prova.disciplina ?? prova.turma;
    for (final disciplina in _disciplinasDisponiveis) {
      if (disciplina.nome != nomeDisciplina) continue;
      disciplinaSelecionadaId = disciplina.id;
      if (prova.disciplina != null && prova.turma != null) {
        turmaSelecionadaId = disciplina.turmaPorNome(prova.turma!)?.id;
      }
    }

    final conjuntos = {
      for (final versao in prova.versoes)
        (versao.questoes.map((q) => q.questao.id).toList()..sort()).join(','),
    };
    modoSelecionado = conjuntos.length > 1
        ? ModoProva.conjuntosDiferentes
        : ModoProva.mesmaEmbaralhada;
    if (prova.versoes.isNotEmpty) {
      versoesAGerar = prova.versoes.length.clamp(_minVersoes, _maxVersoes);
    }
  }

  String get _assinatura => [
    nomeProvaController.text.trim(),
    disciplinaSelecionadaId ?? '',
    turmaSelecionadaId ?? '',
    (questoesSelecionadas.toList()..sort()).join(','),
    modoSelecionado.name,
    versoesAGerar,
  ].join('|');

  @override
  void dispose() {
    nomeProvaController.dispose();
    super.dispose();
  }

  /// Questões da disciplina escolhida (nenhuma, sem disciplina escolhida).
  List<Questao> get questoesDisponiveis {
    final disciplinaId = disciplinaSelecionadaId;
    if (disciplinaId == null) return const [];
    return context.read<QuestoesRepository>().questoesDaDisciplina(
      disciplinaId,
    );
  }

  void _toggleDisciplina(String? disciplinaId) {
    setState(() {
      disciplinaSelecionadaId = disciplinaId;
      // Questões de outra disciplina saem da seleção.
      final daDisciplina = {for (final q in questoesDisponiveis) q.id};
      questoesSelecionadas.removeWhere((id) => !daDisciplina.contains(id));
      turmaSelecionadaId = null;
    });
  }

  void _toggleTurma(String? turmaId) {
    setState(() => turmaSelecionadaId = turmaId);
  }

  void _toggleQuestao(String questaoId, bool selecionado) {
    setState(() {
      if (selecionado) {
        questoesSelecionadas.add(questaoId);
      } else {
        questoesSelecionadas.remove(questaoId);
      }
    });
  }

  Future<String?> _mostrarDialogoNovoItem({
    required String titulo,
    required String label,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
            onSubmitted: (valor) => Navigator.of(dialogContext).pop(valor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _criarNovaDisciplina() async {
    final nome = await _mostrarDialogoNovoItem(
      titulo: 'Nova disciplina',
      label: 'Nome da disciplina',
    );
    if (nome == null || nome.trim().isEmpty) return;

    if (!mounted) return;
    final nova = context.read<TurmasRepository>().criarDisciplina(nome.trim());
    _toggleDisciplina(nova.id);
  }

  Future<void> _criarNovaTurma() async {
    final disciplinaId = disciplinaSelecionadaId;
    if (disciplinaId == null) return;
    final nome = await _mostrarDialogoNovoItem(
      titulo: 'Nova turma',
      label: 'Nome da turma',
    );
    if (nome == null || nome.trim().isEmpty) return;

    if (!mounted) return;
    final nova = await context.read<TurmasRepository>().criarTurma(
      disciplinaId,
      nome.trim(),
    );
    if (nova != null && mounted) _toggleTurma(nova.id);
  }

  bool get podeAvancar =>
      questoesSelecionadas.isNotEmpty &&
      nomeProvaController.text.trim().isNotEmpty;

  void _avancarParaGeracao() {
    final disciplinaEscolhida = _disciplinaSelecionada;
    final turmaEscolhida = turmaSelecionadaId == null
        ? null
        : disciplinaEscolhida?.turmaPorId(turmaSelecionadaId!);

    final dados = DadosProva(
      nomeProva: nomeProvaController.text.trim(),
      disciplina: disciplinaEscolhida,
      turma: turmaEscolhida,
      questoes: _bancoDeQuestoes
          .where((q) => questoesSelecionadas.contains(q.id))
          .toList(),
      modo: modoSelecionado,
      versoes: versoesAGerar,
      editando: widget.editando,
    );

    context.push('/gerar-provas', extra: dados);
  }

  Widget _listaDeQuestoes() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: ListView(
        key: const ValueKey('lista-questoes'),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [for (final q in questoesDisponiveis) _cardQuestao(q)],
      ),
    );
  }

  Widget _cardQuestao(Questao questao) {
    final selecionada = questoesSelecionadas.contains(questao.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: AppListItem(
        selected: selecionada,
        leading: AppLeadingIcon(
          icon: selecionada ? Icons.check : Icons.quiz_outlined,
          background: selecionada ? AppColors.accent : AppColors.neutral100,
          color: selecionada ? Colors.white : AppColors.textMuted,
        ),
        title: questao.enunciado,
        trailing: Checkbox(
          value: selecionada,
          onChanged: (val) => _toggleQuestao(questao.id, val ?? false),
        ),
        onTap: () => _toggleQuestao(questao.id, !selecionada),
      ),
    );
  }

  bool get _temRascunho => _assinatura != _assinaturaInicial;

  Future<bool> _confirmarSaida() async {
    if (!_temRascunho) return true;

    final sair = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _editando ? 'Descartar as alterações?' : 'Descartar esta prova?',
        ),
        content: Text(
          _editando
              ? 'As mudanças nesta prova serão perdidas.'
              : 'O que você preencheu aqui será perdido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    return sair ?? false;
  }

  Future<void> _sair() async {
    if (!await _confirmarSaida()) return;
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/provas-geradas');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<QuestoesRepository>();
    context.watch<TurmasRepository>();

    return PopScope(
      canPop: !_temRascunho,
      onPopInvokedWithResult: (jaSaiu, _) {
        if (!jaSaiu) _sair();
      },
      child: AppScaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(_editando ? 'Editar prova' : 'Nova prova'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: _sair,
          ),
          centerTitle: false,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.s6),
          children: [
            if (_editando) ...[
              AppCard(
                backgroundColor: AppColors.warning100,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: Text(
                        'Ao salvar, as versões são geradas de novo. '
                        'Folhas desta prova que já foram impressas deixam de valer.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
            ],
            Text('NOME DA PROVA', style: AppTheme.kicker),
            const SizedBox(height: AppSpacing.s2),
            TextField(
              controller: nomeProvaController,
              decoration: const InputDecoration(
                hintText: 'Ex: Avaliação bimestral — 2º bimestre',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.s6),
            Text('DISCIPLINA', style: AppTheme.kicker),
            const SizedBox(height: AppSpacing.s2),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                ..._disciplinasDisponiveis.map((disciplina) {
                  return ChoiceChip(
                    label: Text(disciplina.nome),
                    selected: disciplinaSelecionadaId == disciplina.id,
                    onSelected: (val) =>
                        _toggleDisciplina(val ? disciplina.id : null),
                  );
                }),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Nova disciplina'),
                  onPressed: _criarNovaDisciplina,
                ),
              ],
            ),
            if (_disciplinaSelecionada case final disciplina?) ...[
              const SizedBox(height: AppSpacing.s4),
              Text('TURMA', style: AppTheme.kicker),
              const SizedBox(height: AppSpacing.s2),
              Wrap(
                spacing: AppSpacing.s2,
                runSpacing: AppSpacing.s2,
                children: [
                  ...disciplina.turmas.map((turma) {
                    return ChoiceChip(
                      label: Text(turma.nome),
                      selected: turmaSelecionadaId == turma.id,
                      onSelected: (val) => _toggleTurma(val ? turma.id : null),
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('Nova turma'),
                    onPressed: _criarNovaTurma,
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.s6),
            Row(
              children: [
                Expanded(child: Text('QUESTÕES', style: AppTheme.kicker)),
                Text(
                  '${questoesSelecionadas.length} selecionadas',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            if (_disciplinaSelecionada == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.s4),
                child: Text(
                  'Selecione uma disciplina acima para ver as questões dela.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else ...[
              if (questoesDisponiveis.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                  child: Text(
                    'Ainda não há questões em ${_disciplinaSelecionada!.nome}. '
                    'Crie a primeira sem sair desta tela.',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                _listaDeQuestoes(),
              const SizedBox(height: AppSpacing.s2),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/criar-prova/questao/$disciplinaSelecionadaId',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Nova questão em ${_disciplinaSelecionada!.nome}',
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.s6),
            Text('MODO', style: AppTheme.kicker),
            const SizedBox(height: AppSpacing.s2),
            RadioGroup<ModoProva>(
              groupValue: modoSelecionado,
              onChanged: (val) => setState(() => modoSelecionado = val!),
              child: Column(
                children: [
                  RadioListTile<ModoProva>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mesma prova, embaralhada por versão'),
                    subtitle: const Text(
                      'Todas as versões têm as mesmas questões em ordens diferentes.',
                    ),
                    value: ModoProva.mesmaEmbaralhada,
                  ),
                  RadioListTile<ModoProva>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Conjuntos de questões diferentes'),
                    subtitle: const Text(
                      'Cada versão sorteia o próprio conjunto de questões.',
                    ),
                    value: ModoProva.conjuntosDiferentes,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.s6),
            Text('VERSÕES A GERAR', style: AppTheme.kicker),
            const SizedBox(height: AppSpacing.s2),
            _contadorVersoes(),
            const SizedBox(height: AppSpacing.s2),
            const Text(
              'Cada versão vira Prova A, B… e tem seu gabarito, com o QR.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),

            const SizedBox(height: AppSpacing.s6),
            ElevatedButton(
              onPressed: podeAvancar ? _avancarParaGeracao : null,
              child: Text(
                versoesAGerar == 1
                    ? 'Gerar 1 versão'
                    : 'Gerar $versoesAGerar versões',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contadorVersoes() {
    return Row(
      children: [
        _BotaoContador(
          chave: const ValueKey('versoes-menos'),
          rotulo: 'Menos uma versão',
          icone: Icons.remove,
          onPressed: versoesAGerar > _minVersoes
              ? () => setState(() => versoesAGerar--)
              : null,
        ),
        SizedBox(
          width: 64,
          child: Text(
            '$versoesAGerar',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _BotaoContador(
          chave: const ValueKey('versoes-mais'),
          rotulo: 'Mais uma versão',
          icone: Icons.add,
          onPressed: versoesAGerar < _maxVersoes
              ? () => setState(() => versoesAGerar++)
              : null,
        ),
      ],
    );
  }
}

class _BotaoContador extends StatelessWidget {
  final Key chave;
  final String rotulo;
  final IconData icone;
  final VoidCallback? onPressed;

  const _BotaoContador({
    required this.chave,
    required this.rotulo,
    required this.icone,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ativo = onPressed != null;

    return InkWell(
      key: chave,
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Tooltip(
          message: rotulo,
          child: Icon(
            icone,
            size: 20,
            color: ativo ? AppColors.text : AppColors.neutral400,
          ),
        ),
      ),
    );
  }
}

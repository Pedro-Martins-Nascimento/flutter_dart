import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/questao.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../turmas/criar_turma_screen.dart' show Turma, turmasMock;

class DadosProva {
  final String nomeProva;
  final List<Materia> materias;
  final Turma? turma;
  final List<Questao> questoes;
  final ModoProva modo;
  final int versoes;

  DadosProva({
    required this.nomeProva,
    required this.materias,
    required this.turma,
    required this.questoes,
    required this.modo,
    required this.versoes,
  });

  String get materiasResumo => materias.map((m) => m.nome).join(', ');
}

const _minVersoes = 1;
const _maxVersoes = 12;

class CriarProvaScreen extends StatefulWidget {
  const CriarProvaScreen({super.key});

  @override
  State<CriarProvaScreen> createState() => _CriarProvaScreenState();
}

class _CriarProvaScreenState extends State<CriarProvaScreen> {
  List<Materia> get _materiasDisponiveis => materiasMock;
  List<Turma> get _turmasDisponiveis => turmasMock;

  final Set<String> materiasSelecionadas = {};
  String? turmaSelecionadaId;
  final Set<String> questoesSelecionadas = {};
  ModoProva modoSelecionado = ModoProva.mesmaEmbaralhada;

  final TextEditingController nomeProvaController = TextEditingController();

  int versoesAGerar = 4;

  @override
  void dispose() {
    nomeProvaController.dispose();
    super.dispose();
  }

  List<Questao> get questoesDisponiveis {
    if (materiasSelecionadas.isEmpty) return [];
    return questoesMock
        .where((q) => materiasSelecionadas.contains(q.materiaId))
        .toList();
  }

  void _toggleMateria(String materiaId, bool? selecionado) {
    setState(() {
      if (selecionado == true) {
        materiasSelecionadas.add(materiaId);
      } else {
        materiasSelecionadas.remove(materiaId);
        questoesSelecionadas.removeWhere((qId) {
          final questao = questoesMock.firstWhere((q) => q.id == qId);
          return questao.materiaId == materiaId;
        });
      }
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

  Future<void> _criarNovaMateria() async {
    final nome = await _mostrarDialogoNovoItem(
      titulo: 'Nova matéria',
      label: 'Nome da matéria',
    );
    if (nome == null || nome.trim().isEmpty) return;

    final novaMateria = Materia(
      id: 'mat_${DateTime.now().millisecondsSinceEpoch}',
      nome: nome.trim(),
    );
    setState(() {
      _materiasDisponiveis.add(novaMateria);

      materiasSelecionadas.add(novaMateria.id);
    });
  }

  Future<void> _criarNovaTurma() async {
    final nome = await _mostrarDialogoNovoItem(
      titulo: 'Nova turma',
      label: 'Nome da turma',
    );
    if (nome == null || nome.trim().isEmpty) return;

    final novaTurma = Turma(
      id: 'turma_${DateTime.now().millisecondsSinceEpoch}',
      nome: nome.trim(),
      qtdAlunos: 0,
      qtdProvas: 0,
      alunos: [],
    );
    setState(() {
      turmasMock.insert(0, novaTurma);
      turmaSelecionadaId = novaTurma.id;
    });
  }

  bool get podeAvancar =>
      questoesSelecionadas.isNotEmpty &&
      nomeProvaController.text.trim().isNotEmpty;

  void _avancarParaGeracao() {
    Turma? turmaEscolhida;
    if (turmaSelecionadaId != null) {
      turmaEscolhida = _turmasDisponiveis.firstWhere(
        (t) => t.id == turmaSelecionadaId,
      );
    }

    final dados = DadosProva(
      nomeProva: nomeProvaController.text.trim(),
      materias: _materiasDisponiveis
          .where((m) => materiasSelecionadas.contains(m.id))
          .toList(),
      turma: turmaEscolhida,
      questoes: questoesMock
          .where((q) => questoesSelecionadas.contains(q.id))
          .toList(),
      modo: modoSelecionado,
      versoes: versoesAGerar,
    );

    context.push('/gerar-provas', extra: dados);
  }

  Map<Materia, List<Questao>> get _questoesPorMateria {
    final grupos = <Materia, List<Questao>>{};
    for (final materia in _materiasDisponiveis) {
      if (!materiasSelecionadas.contains(materia.id)) continue;
      final questoes = questoesDisponiveis
          .where((q) => q.materiaId == materia.id)
          .toList();
      if (questoes.isNotEmpty) grupos[materia] = questoes;
    }
    return grupos;
  }

  Widget _listaDeQuestoes() {
    final grupos = _questoesPorMateria;
    final agrupar = grupos.length > 1;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: ListView(
        key: const ValueKey('lista-questoes'),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          for (final (indice, grupo) in grupos.entries.indexed) ...[
            if (agrupar)
              _cabecalhoMateria(
                grupo.key,
                grupo.value.length,
                primeiro: indice == 0,
              ),
            ...grupo.value.map(
              (q) => _cardQuestao(q, mostrarMateria: !agrupar),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cabecalhoMateria(
    Materia materia,
    int total, {
    required bool primeiro,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: primeiro ? 0 : AppSpacing.s5,
        bottom: AppSpacing.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!primeiro) ...[
            const Divider(height: 1, color: AppColors.neutral300),
            const SizedBox(height: AppSpacing.s4),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  materia.nome.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.kicker.copyWith(color: AppColors.accent),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                total == 1 ? '1 questão' : '$total questões',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
        ],
      ),
    );
  }

  Widget _cardQuestao(Questao questao, {required bool mostrarMateria}) {
    final selecionada = questoesSelecionadas.contains(questao.id);
    final materia = _materiasDisponiveis.firstWhere(
      (m) => m.id == questao.materiaId,
      orElse: () => Materia(id: questao.materiaId, nome: '—'),
    );

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
        subtitle: mostrarMateria ? materia.nome : null,
        trailing: Checkbox(
          value: selecionada,
          onChanged: (val) => _toggleQuestao(questao.id, val ?? false),
        ),
        onTap: () => _toggleQuestao(questao.id, !selecionada),
      ),
    );
  }

  bool get _temRascunho =>
      nomeProvaController.text.trim().isNotEmpty ||
      turmaSelecionadaId != null ||
      materiasSelecionadas.isNotEmpty ||
      questoesSelecionadas.isNotEmpty;

  Future<bool> _confirmarSaida() async {
    if (!_temRascunho) return true;

    final sair = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar esta prova?'),
        content: const Text('O que você preencheu aqui será perdido.'),
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
    return PopScope(
      canPop: !_temRascunho,
      onPopInvokedWithResult: (jaSaiu, _) {
        if (!jaSaiu) _sair();
      },
      child: AppScaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Nova prova'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: _sair,
          ),
          centerTitle: false,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.s6),
          children: [
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
            Text('TURMA', style: AppTheme.kicker),
            const SizedBox(height: AppSpacing.s2),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                ..._turmasDisponiveis.map((turma) {
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

            const SizedBox(height: AppSpacing.s6),
            Text('MATÉRIAS', style: AppTheme.kicker),
            const SizedBox(height: AppSpacing.s2),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                ..._materiasDisponiveis.map((materia) {
                  return FilterChip(
                    label: Text(materia.nome),
                    selected: materiasSelecionadas.contains(materia.id),
                    onSelected: (val) => _toggleMateria(materia.id, val),
                  );
                }),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Nova matéria'),
                  onPressed: _criarNovaMateria,
                ),
              ],
            ),

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
            if (questoesDisponiveis.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.s4),
                child: Text(
                  'Selecione uma matéria acima para ver as questões disponíveis.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              _listaDeQuestoes(),

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
              'Cada versão recebe um QR próprio, ligado ao gabarito daquela '
              'ordem de questões.',
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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/correcao.dart';
import '../../models/prova_gerada.dart';
import '../../models/turma.dart';
import '../../models/versao_prova.dart';
import '../../services/correcao_repository.dart';
import '../../services/notas_da_prova.dart';
import '../../services/prova_repository.dart';
import '../../services/relatorio_excel.dart';
import '../../services/salvar_arquivo.dart' show salvarXlsx;
import '../../services/turma_mapper.dart';
import '../../services/firebase_erro.dart';
import '../../services/turmas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

/// Uma turma de uma disciplina: abas Alunos (com importar e adicionar à mão)
/// e Provas da turma.
class VisualizarTurmaScreen extends StatefulWidget {
  final String disciplinaId;
  final String turmaId;
  final ProvaRepository provas;
  final CorrecaoRepository correcoes;

  /// Salva a planilha de notas (trocado nos testes).
  final Future<bool> Function(String nome, Uint8List bytes) salvarPlanilha;

  const VisualizarTurmaScreen({
    super.key,
    required this.disciplinaId,
    required this.turmaId,
    required this.provas,
    required this.correcoes,
    this.salvarPlanilha = salvarXlsx,
  });

  @override
  State<VisualizarTurmaScreen> createState() => _VisualizarTurmaScreenState();
}

class _VisualizarTurmaScreenState extends State<VisualizarTurmaScreen> {
  TurmasRepository get _repositorio => context.read<TurmasRepository>();

  Disciplina? get _disciplina =>
      _repositorio.disciplinaPorId(widget.disciplinaId);

  Turma get turma =>
      _disciplina?.turmaPorId(widget.turmaId) ??
      Turma(id: '0', nome: 'Turma não encontrada');

  Future<void> _deletarTurma() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Excluir turma',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tem certeza que deseja excluir a turma "${turma.nome}"? '
                'Os alunos dela também saem da lista.',
                style: const TextStyle(color: AppColors.text, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Esta ação não pode ser desfeita e todos os dados vinculados serão perdidos.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Excluir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar == true) {
      await _repositorio.excluirTurma(widget.disciplinaId, widget.turmaId);
      if (mounted) context.pop();
    }
  }

  Future<void> _editarAluno(AlunoTurma aluno) async {
    final nomeController = TextEditingController(text: aluno.nome);
    final matriculaController = TextEditingController(text: aluno.matricula);

    final atualizado = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Editar Aluno',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nome do aluno',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Matrícula',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              TextField(
                controller: matriculaController,
                decoration: const InputDecoration(
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (atualizado == true) {
      _repositorio.atualizarAluno(
        widget.disciplinaId,
        widget.turmaId,
        AlunoTurma(
          id: aluno.id,
          nome: nomeController.text.trim(),
          matricula: matriculaController.text.trim(),
        ),
      );
    }
  }

  Future<void> _removerAluno(AlunoTurma aluno) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Remover Aluno',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Deseja remover o aluno ${aluno.nome} desta disciplina?',
                style: const TextStyle(color: AppColors.text, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Remover'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar == true) {
      _repositorio.removerAluno(widget.disciplinaId, widget.turmaId, aluno.id);
    }
  }

  Future<void> _adicionarAluno() async {
    final nomeController = TextEditingController();
    final matriculaController = TextEditingController();

    final criado = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Novo Aluno',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nome do aluno',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              TextField(
                controller: nomeController,
                autofocus: true,
                decoration: const InputDecoration(
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Matrícula',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              TextField(
                controller: matriculaController,
                decoration: const InputDecoration(
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Criar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (criado == true && nomeController.text.trim().isNotEmpty) {
      try {
        await _repositorio.adicionarAlunos(
          widget.disciplinaId,
          widget.turmaId,
          [
            AlunoTurma(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              nome: nomeController.text.trim(),
              matricula: matriculaController.text.trim(),
            ),
          ],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aluno adicionado com sucesso!')),
          );
        }
      } catch (erro) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                eErroDeConexao(erro)
                    ? 'Sem conexão. O aluno não foi salvo.'
                    : 'Não foi possível adicionar o aluno.',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TurmasRepository>();
    final turma = this.turma;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        centerTitle: false,
      ),
      body: AppMaxWidth(
        child: StreamBuilder<List<ProvaResumo>>(
          stream: widget.provas.observar(),
          builder: (context, provasSnapshot) => StreamBuilder<List<Correcao>>(
            stream: widget.correcoes.observar(),
            builder: (context, correcoesSnapshot) {
              // As provas da disciplina são as geradas com o nome dela.
              final provas = [
                for (final prova
                    in provasSnapshot.data ?? const <ProvaResumo>[])
                  if (_ehDaTurma(prova, turma)) prova,
              ];
              final correcoes = correcoesSnapshot.data ?? const <Correcao>[];
              return DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cabecalho(_disciplina, turma),
                    const SizedBox(height: 24),
                    _AbasDePasta(
                      abas: [
                        'Alunos (${turma.alunos.length})',
                        'Provas (${provas.length})',
                      ],
                    ),
                    Expanded(
                      child: Container(
                        color: AppColors.surface,
                        child: TabBarView(
                          children: [
                            _abaAlunos(turma, correcoes),
                            _AbaProvas(
                              provas: provas,
                              correcoes: correcoes,
                              repositorio: widget.provas,
                              alunos: turma.alunos,
                              nomeTurma: turma.nome,
                              salvarPlanilha: widget.salvarPlanilha,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Prova desta turma: gravada com a disciplina e a turma. Provas antigas
  /// (só com o nome da disciplina) aparecem na turma criada com os alunos
  /// antigos, ou na primeira turma se essa não existir.
  bool _ehDaTurma(ProvaResumo prova, Turma turma) {
    final disciplina = _disciplina;
    if (disciplina == null) return false;
    if (prova.disciplina != null) {
      return prova.disciplina == disciplina.nome && prova.turma == turma.nome;
    }
    if (prova.turma != disciplina.nome) return false;
    final migrada = disciplina.turmaPorId(
      TurmaMapper.idTurmaMigrada(disciplina.id),
    );
    final destino =
        migrada ?? (disciplina.turmas.isEmpty ? null : disciplina.turmas.first);
    return destino?.id == turma.id;
  }

  Widget _cabecalho(Disciplina? disciplina, Turma turma) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                disciplina == null ? 'Turma' : 'Turma · ${disciplina.nome}',
                style: AppTheme.kicker,
              ),
              const SizedBox(height: 4),
              Text(
                turma.nome,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(
                    '/turmas/${widget.disciplinaId}/turma/${turma.id}/importar',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s1,
                    ),
                    minimumSize: const Size(0, 44),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Importar alunos'),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: OutlinedButton(
                  onPressed: _adicionarAluno,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s1,
                    ),
                    minimumSize: const Size(0, 44),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Novo Aluno'),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              IconButton(
                tooltip: 'Excluir turma',
                onPressed: _deletarTurma,
                style: IconButton.styleFrom(
                  fixedSize: const Size(44, 44),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.neutral300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _abaAlunos(Turma turma, List<Correcao> correcoes) {
    if (turma.alunos.isEmpty) {
      return const _Vazio(
        'Nenhum aluno ainda. Use "Importar alunos" ou "Novo Aluno".',
      );
    }
    return ListView.separated(
      itemCount: turma.alunos.length,
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final aluno = turma.alunos[index];
        final doAluno = [
          for (final c in correcoes)
            if (c.alunoId == aluno.id) c,
        ]..sort((a, b) => b.corrigidoEm.compareTo(a.corrigidoEm));
        return _AlunoItem(
          aluno: aluno,
          correcoes: doAluno.length,
          onTap: () => _abrirCorrecoesDoAluno(aluno, doAluno),
          onEdit: () => _editarAluno(aluno),
          onDelete: () => _removerAluno(aluno),
        );
      },
    );
  }

  /// Aluno com uma correção abre o resultado direto; com várias, escolhe
  /// qual; sem nenhuma, avisa (a prova dele, se houver, está na aba Provas).
  Future<void> _abrirCorrecoesDoAluno(
    AlunoTurma aluno,
    List<Correcao> correcoes,
  ) async {
    if (correcoes.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${aluno.nome} ainda não tem prova corrigida vinculada.',
            ),
          ),
        );
      return;
    }
    if (correcoes.length == 1) {
      context.push('/corrigir/resultado', extra: correcoes.single);
      return;
    }
    final escolhida = await showModalBottomSheet<Correcao>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s6,
                0,
                AppSpacing.s6,
                AppSpacing.s2,
              ),
              child: Text(
                'CORREÇÕES DE ${aluno.nome.toUpperCase()}',
                style: AppTheme.kicker,
              ),
            ),
            for (final correcao in correcoes)
              _LinhaCorrecao(
                titulo: correcao.provaNome,
                subtitulo:
                    'Prova ${_letraDaVersao(correcao.versaoId)} · '
                    '${_data(correcao.corrigidoEm)}',
                nota: correcao.nota,
                onTap: () => Navigator.of(context).pop(correcao),
              ),
          ],
        ),
      ),
    );
    if (escolhida != null && mounted) {
      context.push('/corrigir/resultado', extra: escolhida);
    }
  }
}

class _AlunoItem extends StatelessWidget {
  final AlunoTurma aluno;
  final int correcoes;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AlunoItem({
    required this.aluno,
    required this.correcoes,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s6,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aluno.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    aluno.matricula,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (correcoes > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent100,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  correcoes == 1 ? '1 correção' : '$correcoes correções',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Editar aluno',
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.neutral400,
                size: 20,
              ),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Remover aluno',
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.neutral400,
                size: 20,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/// Abas no formato de aba de pasta: a selecionada fica branca, emendada no
/// conteúdo branco logo abaixo.
class _AbasDePasta extends StatelessWidget {
  final List<String> abas;

  const _AbasDePasta({required this.abas});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 22),
        tabs: [for (final aba in abas) Tab(height: 44, text: aba)],
      ),
    );
  }
}

/// Provas da disciplina. Cada uma abre a lista das suas versões, com o
/// aluno vinculado (se houver) e a nota de quem já foi corrigido.
class _AbaProvas extends StatelessWidget {
  final List<ProvaResumo> provas;
  final List<Correcao> correcoes;
  final ProvaRepository repositorio;
  final List<AlunoTurma> alunos;
  final String nomeTurma;
  final Future<bool> Function(String nome, Uint8List bytes) salvarPlanilha;

  const _AbaProvas({
    required this.provas,
    required this.correcoes,
    required this.repositorio,
    required this.alunos,
    required this.nomeTurma,
    required this.salvarPlanilha,
  });

  /// Planilha com a nota de cada aluno da turma nesta prova.
  Future<void> _baixarPlanilha(BuildContext context, ProvaResumo prova) async {
    final mensagens = ScaffoldMessenger.of(context);
    void avisar(String texto) => mensagens
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
    try {
      final linhas = linhasDeNotas(
        prova: prova,
        disciplinas: context.read<TurmasRepository>().disciplinas,
        correcoes: correcoes,
      );
      String limpo(String texto) =>
          texto.trim().replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ]+'), '_');
      final salvo = await salvarPlanilha(
        'notas_${limpo(nomeTurma)}_${limpo(prova.nome)}.xlsx',
        gerarXlsxNotas(linhas),
      );
      if (salvo) avisar('Planilha de notas salva.');
    } catch (_) {
      avisar('Não foi possível gerar a planilha.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (provas.isEmpty) {
      return const _Vazio(
        'Nenhuma prova desta turma ainda. Ao criar uma prova, escolha a '
        'disciplina e esta turma.',
      );
    }
    return ListView.separated(
      itemCount: provas.length,
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final prova = provas[index];
        final daProva = {
          for (final c in correcoes)
            if (c.provaId == prova.id) c.versaoId: c,
        };
        return ExpansionTile(
          key: PageStorageKey('prova-${prova.id}'),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s6,
            vertical: AppSpacing.s1,
          ),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_rounded,
              size: 20,
              color: AppColors.accent,
            ),
          ),
          title: Text(
            prova.nome,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          subtitle: Text(
            '${daProva.length} de ${prova.totalVersoes} corrigidas · '
            '${_data(prova.criadoEm)}',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          children: [
            _PlanilhaDaProva(
              corrigidas: daProva.length,
              total: prova.totalVersoes,
              onBaixar: () => _baixarPlanilha(context, prova),
            ),
            _VersoesDaProva(
              provaId: prova.id,
              repositorio: repositorio,
              correcoesPorVersao: daProva,
              alunos: alunos,
            ),
          ],
        );
      },
    );
  }
}

/// Botão da planilha de notas da prova, liberado quando todas as folhas
/// estão corrigidas; antes disso, diz quantas faltam.
class _PlanilhaDaProva extends StatelessWidget {
  final int corrigidas;
  final int total;
  final VoidCallback onBaixar;

  const _PlanilhaDaProva({
    required this.corrigidas,
    required this.total,
    required this.onBaixar,
  });

  @override
  Widget build(BuildContext context) {
    final completa = total > 0 && corrigidas >= total;
    final faltam = total - corrigidas;
    return Container(
      width: double.infinity,
      color: AppColors.neutral100,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s8 + AppSpacing.s6,
        AppSpacing.s3,
        AppSpacing.s6,
        AppSpacing.s1,
      ),
      alignment: Alignment.centerLeft,
      child: completa
          ? ElevatedButton.icon(
              onPressed: onBaixar,
              icon: const Icon(Icons.table_view_rounded, size: 18),
              label: const Text('Baixar planilha de notas'),
            )
          : Text(
              'A planilha de notas fica disponível quando todas as folhas '
              'forem corrigidas (${faltam == 1 ? 'falta 1' : 'faltam $faltam'}).',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
    );
  }
}

class _VersoesDaProva extends StatefulWidget {
  final String provaId;
  final ProvaRepository repositorio;
  final Map<String, Correcao> correcoesPorVersao;
  final List<AlunoTurma> alunos;

  const _VersoesDaProva({
    required this.provaId,
    required this.repositorio,
    required this.correcoesPorVersao,
    required this.alunos,
  });

  @override
  State<_VersoesDaProva> createState() => _VersoesDaProvaState();
}

class _VersoesDaProvaState extends State<_VersoesDaProva> {
  late final Future<ProvaGerada?> _prova = widget.repositorio.buscar(
    widget.provaId,
  );

  String? _nomeDoAluno(String? alunoId) {
    if (alunoId == null) return null;
    for (final aluno in widget.alunos) {
      if (aluno.id == alunoId) return aluno.nome;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProvaGerada?>(
      future: _prova,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.s4),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final prova = snapshot.data;
        if (prova == null) {
          return const _Vazio('Não foi possível carregar esta prova.');
        }
        return Container(
          color: AppColors.neutral100,
          child: Column(
            children: [
              for (final versao in prova.versoes) _linha(context, versao),
            ],
          ),
        );
      },
    );
  }

  Widget _linha(BuildContext context, VersaoProva versao) {
    final correcao = widget.correcoesPorVersao[versao.id];
    final aluno = correcao?.alunoNome ?? _nomeDoAluno(versao.alunoId);
    return _LinhaCorrecao(
      titulo: aluno ?? 'Sem aluno vinculado',
      tituloApagado: aluno == null,
      subtitulo: 'Prova ${versao.letra}',
      nota: correcao?.nota,
      recuo: AppSpacing.s8 + AppSpacing.s6,
      onTap: correcao == null
          ? null
          : () => context.push('/corrigir/resultado', extra: correcao),
    );
  }
}

/// Linha de uma folha: quem é, qual versão e a nota (ou "Pendente").
class _LinhaCorrecao extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final double? nota;
  final VoidCallback? onTap;
  final bool tituloApagado;
  final double recuo;

  const _LinhaCorrecao({
    required this.titulo,
    required this.subtitulo,
    required this.nota,
    required this.onTap,
    this.tituloApagado = false,
    this.recuo = AppSpacing.s6,
  });

  @override
  Widget build(BuildContext context) {
    final nota = this.nota;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          recuo,
          AppSpacing.s3,
          AppSpacing.s6,
          AppSpacing.s3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontStyle: tituloApagado
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: tituloApagado
                          ? AppColors.textMuted
                          : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (nota == null)
              const Text(
                'Pendente',
                style: TextStyle(fontSize: 13, color: AppColors.neutral500),
              )
            else ...[
              Text(
                nota.toStringAsFixed(1).replaceAll('.', ','),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: nota >= 6 ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.s1),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.neutral500,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  final String mensagem;

  const _Vazio(this.mensagem);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Text(
        mensagem,
        style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
      ),
    );
  }
}

String _letraDaVersao(String versaoId) => VersaoProva.letraDe(versaoId);

String _data(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}

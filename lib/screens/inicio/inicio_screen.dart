import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/correcao.dart';
import '../../models/turma.dart';
import '../../services/correcao_repository.dart';
import '../../services/estatistica_service.dart';
import '../../services/nome_da_disciplina.dart';
import '../../services/pendentes.dart';
import '../../services/prova_repository.dart';
import '../../services/questoes_repository.dart';
import '../../services/turmas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_conta.dart';
import '../../widgets/cartoes_quadrados.dart';

class _Numeros {
  final int corrigidas;
  final int pendentes;

  /// Nome da disciplina → percentual de erro.
  final Map<String, int> erroPorDisciplina;

  const _Numeros({
    required this.corrigidas,
    required this.pendentes,
    required this.erroPorDisciplina,
  });

  factory _Numeros.de(
    List<ProvaResumo> provas,
    List<Correcao> correcoes,
    String Function(String materiaId) disciplina,
  ) {
    final acertos = EstatisticaService.percentualAcertoPorGrupo(
      correcoes,
      disciplina,
    );
    return _Numeros(
      corrigidas: correcoes.length,
      pendentes: contarPendentes(provas, correcoes),
      erroPorDisciplina: {
        for (final e in acertos.entries) e.key: (100 - e.value).round(),
      },
    );
  }
}

class _ErroDisciplina {
  final String disciplina;
  final int percentual;

  const _ErroDisciplina(this.disciplina, this.percentual);
}

class InicioScreen extends StatelessWidget {
  final ProvaRepository repository;
  final CorrecaoRepository correcoes;

  const InicioScreen({
    super.key,
    required this.repository,
    required this.correcoes,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<TurmasRepository>();
    context.watch<QuestoesRepository>();
    return StreamBuilder<List<ProvaResumo>>(
      stream: repository.observar(),
      builder: (context, provasSnapshot) => StreamBuilder<List<Correcao>>(
        stream: correcoes.observar(),
        builder: (context, correcoesSnapshot) {
          final provas = provasSnapshot.data ?? const <ProvaResumo>[];
          final feitas = correcoesSnapshot.data ?? const <Correcao>[];
          final disciplina = nomeDaDisciplina(
            context.read<QuestoesRepository>(),
            context.read<TurmasRepository>().disciplinas,
          );
          return _conteudo(
            context,
            provas,
            _Numeros.de(provas, feitas, disciplina),
          );
        },
      ),
    );
  }

  Widget _conteudo(
    BuildContext context,
    List<ProvaResumo> provas,
    _Numeros numeros,
  ) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        final medio = restricoes.maxWidth >= AppLayout.medio;
        final largo = restricoes.maxWidth >= AppLayout.largo;

        final recuo = largo
            ? AppSpacing.s8
            : (medio ? AppSpacing.s6 + AppSpacing.s1 : AppSpacing.s6);

        return Scaffold(
          backgroundColor: largo ? AppColors.bg : AppColors.surface,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.maxContentWidthPainel,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cabecalho(context, medio: medio, recuo: recuo),

                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.only(
                          bottom: largo ? AppSpacing.s8 : AppSpacing.s4,
                        ),
                        children: [
                          _resumoNumeros(numeros, medio: medio, recuo: recuo),
                          if (!medio) _acoesEmBarra(context, recuo),
                          _blocos(
                            context,
                            numeros: numeros,
                            largo: largo,
                            recuo: recuo,
                          ),
                          _disciplinas(context, largo: largo, recuo: recuo),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cabecalho(
    BuildContext context, {
    required bool medio,
    required double recuo,
  }) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _dataPorExtenso(DateTime.now()).toUpperCase(),
          style: AppTheme.kicker,
        ),
        const SizedBox(height: 6),
        Text(
          'Correção de provas',
          style: TextStyle(
            fontSize: medio ? 30 : 24,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.5,
            color: AppColors.text,
          ),
        ),
      ],
    );

    final comAvatar = MediaQuery.sizeOf(context).width < AppLayout.largo;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        recuo,
        medio ? AppSpacing.s6 : 18,
        recuo,
        AppSpacing.s4,
      ),
      child: medio
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: titulo),
                const SizedBox(width: AppSpacing.s4),
                _AcaoCorrigir(),
                const SizedBox(width: AppSpacing.s3),
                _AcaoNovaProva(),
                if (comAvatar) ...[
                  const SizedBox(width: AppSpacing.s3),
                  const AppMenuConta(),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titulo),
                const AppMenuConta(),
              ],
            ),
    );
  }

  Widget _resumoNumeros(
    _Numeros numeros, {
    required bool medio,
    required double recuo,
  }) {
    final espaco = medio ? 56.0 : AppSpacing.s8;

    return Padding(
      padding: EdgeInsets.fromLTRB(recuo, 0, recuo, AppSpacing.s5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: _Numero(
              rotulo: 'Corrigidas',
              valor: '${numeros.corrigidas}',
            ),
          ),
          SizedBox(width: espaco),
          Flexible(
            child: _Numero(rotulo: 'Pendentes', valor: '${numeros.pendentes}'),
          ),
        ],
      ),
    );
  }

  Widget _acoesEmBarra(BuildContext context, double recuo) {
    return Padding(
      padding: EdgeInsets.fromLTRB(recuo, 0, recuo, 22),
      child: Row(
        children: [
          Expanded(child: _AcaoCorrigir()),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: _AcaoNovaProva()),
        ],
      ),
    );
  }

  Widget _blocos(
    BuildContext context, {
    required _Numeros numeros,
    required bool largo,
    required double recuo,
  }) {
    final lateral = largo ? recuo : AppSpacing.s4;
    return Padding(
      padding: EdgeInsets.fromLTRB(lateral, AppSpacing.s2, lateral, 0),
      child: _Bloco(
        titulo: 'Erro por disciplina',
        emCard: true,
        recuo: AppSpacing.s5,
        child: _conteudoEstatistica(context, numeros),
      ),
    );
  }

  /// Quadradinhos: o primeiro cria uma disciplina e, ao lado, vem um por
  /// disciplina, com o botão de criar turma. Tocar abre as turmas dela.
  Widget _disciplinas(
    BuildContext context, {
    required bool largo,
    required double recuo,
  }) {
    final disciplinas = context.read<TurmasRepository>().disciplinas;
    final lateral = largo ? recuo : AppSpacing.s4;
    return Padding(
      padding: EdgeInsets.fromLTRB(lateral, AppSpacing.s6, lateral, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DISCIPLINAS', style: AppTheme.kicker),
          const SizedBox(height: AppSpacing.s3),
          GradeDeCartoes(
            children: [
              CartaoAdicionar(
                rotulo: 'Nova disciplina',
                onTap: () => _novaDisciplina(context),
              ),
              for (final disciplina in disciplinas)
                CartaoItem(
                  titulo: disciplina.nome,
                  subtitulo: _resumoDisciplina(disciplina),
                  onTap: () => context.push('/turmas/${disciplina.id}'),
                  rotuloBotao: 'Nova turma',
                  onBotao: () => _novaTurma(context, disciplina),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _novaDisciplina(BuildContext context) async {
    final nome = await pedirNome(
      context,
      titulo: 'Nova disciplina',
      rotulo: 'Nome da disciplina',
      dica: 'Matemática',
    );
    if (nome == null || !context.mounted) return;
    context.read<TurmasRepository>().criarDisciplina(nome);
  }

  /// Cria a turma e abre a disciplina, onde ela aparece entre as turmas.
  Future<void> _novaTurma(BuildContext context, Disciplina disciplina) async {
    final nome = await pedirNome(
      context,
      titulo: 'Nova turma em ${disciplina.nome}',
      rotulo: 'Nome da turma',
      dica: '3º ano B',
    );
    if (nome == null || !context.mounted) return;
    final repositorio = context.read<TurmasRepository>();
    await repositorio.criarTurma(disciplina.id, nome);
    if (!context.mounted) return;
    context.push('/turmas/${disciplina.id}');
  }

  Widget _conteudoEstatistica(BuildContext context, _Numeros numeros) {
    final linhas = _erroPorDisciplina(context, numeros);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (linhas.isEmpty)
          const Text(
            'Ainda não há correções para calcular o erro por disciplina.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          )
        else
          for (final linha in linhas) _LinhaErro(linha: linha),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.push('/inicio/estatistica'),
            child: const Text('Ver estatística completa'),
          ),
        ),
      ],
    );
  }

  List<_ErroDisciplina> _erroPorDisciplina(BuildContext context, _Numeros numeros) {
    return [
      for (final e in numeros.erroPorDisciplina.entries)
        _ErroDisciplina(e.key, e.value),
    ]..sort((a, b) => b.percentual.compareTo(a.percentual));
  }
}

class _AcaoCorrigir extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.text),
        onPressed: () => context.go('/corrigir'),
        child: const Text('Corrigir agora'),
      ),
    );
  }
}

class _AcaoNovaProva extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: () => context.go('/criar-prova'),
        child: const Text('Nova prova'),
      ),
    );
  }
}

class _Bloco extends StatelessWidget {
  final String titulo;
  final Widget child;
  final double recuo;
  final bool emCard;

  const _Bloco({
    required this.titulo,
    required this.child,
    required this.recuo,
    this.emCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final corpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: recuo),
          child: Text(titulo.toUpperCase(), style: AppTheme.kicker),
        ),
        const SizedBox(height: AppSpacing.s3),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: recuo),
          child: child,
        ),
      ],
    );

    if (emCard) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
        child: corpo,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
      child: corpo,
    );
  }
}

class _Numero extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _Numero({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: -0.5,
            color: AppColors.text,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _LinhaErro extends StatelessWidget {
  final _ErroDisciplina linha;

  const _LinhaErro({required this.linha});

  @override
  Widget build(BuildContext context) {
    final cor = linha.percentual >= 50 ? AppColors.accent : AppColors.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              linha.disciplina,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Container(
              height: 4,
              color: AppColors.neutral200,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: linha.percentual / 100,
                child: Container(color: cor),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          SizedBox(
            width: 38,
            child: Text(
              '${linha.percentual}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _diasDaSemana = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

const List<String> _mesesDoAno = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

String _dataPorExtenso(DateTime data) {
  final dia = _diasDaSemana[data.weekday - 1];
  final mes = _mesesDoAno[data.month - 1];
  return '$dia, ${data.day} de $mes';
}

String _resumoDisciplina(Disciplina disciplina) {
  final turmas = disciplina.turmas.length;
  if (turmas == 0) return 'Sem turmas';
  final alunos = disciplina.qtdAlunos;
  return '$turmas ${turmas == 1 ? 'turma' : 'turmas'} · '
      '$alunos ${alunos == 1 ? 'aluno' : 'alunos'}';
}

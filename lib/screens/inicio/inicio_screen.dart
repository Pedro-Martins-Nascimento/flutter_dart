import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/correcao.dart';
import '../../services/auth_service.dart';
import '../../services/correcao_repository.dart';
import '../../services/estatistica_service.dart';
import '../../services/prova_repository.dart';
import '../../services/questoes_repository.dart';
import '../../services/turmas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

const List<_ResumoProva> _provasMock = [
  _ResumoProva(
    titulo: 'P1 — Matemática',
    meta: '3º ano B — Matutino · 8 versões · 10 questões · 14/08',
  ),
  _ResumoProva(
    titulo: 'Sub — Redes',
    meta: 'Redes de Computadores — Noturno · 6 versões · 12 questões · 02/08',
  ),
  _ResumoProva(
    titulo: 'P1 — Física',
    meta: '2º ano A — Matutino · 4 versões · 8 questões · 28/07',
  ),
];

class _ResumoProva {
  final String titulo;
  final String meta;
  final String? provaId;

  const _ResumoProva({required this.titulo, required this.meta, this.provaId});
}

class _Numeros {
  final int corrigidas;
  final int pendentes;
  final String media;
  final Map<String, int> erroPorMateria;

  const _Numeros({
    required this.corrigidas,
    required this.pendentes,
    required this.media,
    required this.erroPorMateria,
  });

  factory _Numeros.de(List<ProvaResumo> provas, List<Correcao> correcoes) {
    final geradas = provas.fold<int>(0, (soma, p) => soma + p.totalVersoes);
    final acertos = EstatisticaService.percentualAcertoPorMateria(correcoes);
    return _Numeros(
      corrigidas: correcoes.length,
      pendentes: (geradas - correcoes.length).clamp(0, geradas),
      media: correcoes.isEmpty
          ? '-'
          : EstatisticaService.mediaGeral(correcoes)
                .toStringAsFixed(1)
                .replaceAll('.', ','),
      erroPorMateria: {
        for (final e in acertos.entries) e.key: (100 - e.value).round(),
      },
    );
  }
}

class _ErroMateria {
  final String materia;
  final int percentual;

  const _ErroMateria(this.materia, this.percentual);
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
          return _conteudo(context, provas, _Numeros.de(provas, feitas));
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
                            provas: provas,
                            numeros: numeros,
                            largo: largo,
                            recuo: recuo,
                          ),
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
          _dataPorExtenso(DateTime.now()),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 5),
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
                const SizedBox(width: AppSpacing.s2),
                _BotaoSair(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titulo),
                _BotaoSair(),
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
          SizedBox(width: espaco),
          Flexible(
            child: _Numero(rotulo: 'Média', valor: numeros.media),
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
    required List<ProvaResumo> provas,
    required _Numeros numeros,
    required bool largo,
    required double recuo,
  }) {
    const tituloErros = 'Erro por matéria';

    if (!largo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Bloco(
            titulo: tituloErros,
            recuo: recuo,
            child: _conteudoEstatistica(context, numeros),
          ),
          _Bloco(
            titulo: 'Últimas provas',
            recuo: recuo,
            conteudoSemRecuo: true,
            child: _conteudoProvas(context, provas: provas, recuo: recuo),
          ),
        ],
      );
    }

    const recuoCard = AppSpacing.s5;
    return Padding(
      padding: EdgeInsets.fromLTRB(recuo, AppSpacing.s2, recuo, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: _Bloco(
              titulo: tituloErros,
              emCard: true,
              recuo: recuoCard,
              child: _conteudoEstatistica(context, numeros),
            ),
          ),
          const SizedBox(width: AppSpacing.s5),
          Expanded(
            flex: 4,
            child: _Bloco(
              titulo: 'Últimas provas',
              emCard: true,
              recuo: recuoCard,
              conteudoSemRecuo: true,
              child: _conteudoProvas(context, provas: provas, recuo: recuoCard),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudoEstatistica(BuildContext context, _Numeros numeros) {
    final linhas = _erroPorMateria(context, numeros);
    if (linhas.isEmpty) {
      return const Text(
        'Ainda não há correções para calcular o erro por matéria.',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final linha in linhas) _LinhaErro(linha: linha)],
    );
  }

  List<_ErroMateria> _erroPorMateria(BuildContext context, _Numeros numeros) {
    return [
      for (final materia in context.read<QuestoesRepository>().materias)
        if (numeros.erroPorMateria[materia.id] case final erro?)
          _ErroMateria(materia.nome, erro),
    ]..sort((a, b) => b.percentual.compareTo(a.percentual));
  }

  Widget _conteudoProvas(
    BuildContext context, {
    required List<ProvaResumo> provas,
    required double recuo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final prova in _ultimasProvas(provas))
          _LinhaProva(
            resumo: prova,
            recuo: recuo,
            onTap: () {
              if (prova.provaId != null) {
                _abrirProva(context, prova.provaId!);
              } else {
                context.push('/provas-geradas');
              }
            },
          ),
      ],
    );
  }

  Future<void> _abrirProva(BuildContext context, String id) async {
    final prova = await repository.buscar(id);
    if (prova == null || !context.mounted) return;
    context.push('/gerar-provas', extra: prova);
  }

  List<_ResumoProva> _ultimasProvas(List<ProvaResumo> geradas) {
    if (geradas.isEmpty) return _provasMock;

    return [
      for (final prova in geradas.take(3))
        _ResumoProva(
          titulo: prova.nome,
          meta: _metaProva(prova),
          provaId: prova.id,
        ),
    ];
  }

  String _metaProva(ProvaResumo prova) {
    final partes = <String>[prova.materia];
    if (prova.turma != null) partes.add(prova.turma!);
    partes.add('${prova.totalVersoes} versões');
    partes.add(_dataCurta(prova.criadoEm));
    return partes.join(' · ');
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

  final bool conteudoSemRecuo;

  const _Bloco({
    required this.titulo,
    required this.child,
    required this.recuo,
    this.emCard = false,
    this.conteudoSemRecuo = false,
  });

  @override
  Widget build(BuildContext context) {
    final corpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: recuo),
          child: Text(
            titulo.toUpperCase(),
            style: AppTheme.kicker.copyWith(fontSize: 11, letterSpacing: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        if (conteudoSemRecuo)
          child
        else
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
  final _ErroMateria linha;

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
              linha.materia,
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

class _LinhaProva extends StatelessWidget {
  final _ResumoProva resumo;
  final double recuo;
  final VoidCallback onTap;

  const _LinhaProva({
    required this.resumo,
    required this.recuo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: recuo,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resumo.titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    resumo.meta,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.neutral500,
            ),
          ],
        ),
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

String _dataCurta(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes';
}

class _BotaoSair extends StatelessWidget {
  Future<void> _confirmar(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmado == true && context.mounted) {
      await context.read<AuthService>().sair();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sair',
      icon: const Icon(Icons.logout, color: AppColors.textMuted),
      onPressed: () => _confirmar(context),
    );
  }
}

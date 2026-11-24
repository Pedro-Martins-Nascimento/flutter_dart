// Depois que o QR é lido e a versão é achada, o leitor de marcações (OMR) lê
// a foto do gabarito. Questão em branco, com duas marcações ou rasurada fica
// "não identificada" e o professor escolhe na mão; ele também pode corrigir
// qualquer leitura antes de confirmar e calcular a nota.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/aluno.dart';
import '../../models/correcao.dart';
import '../../models/questao.dart';
import '../../models/versao_prova.dart';
import '../../services/alunos_para_pdf.dart';
import '../../services/correcao_repository.dart';
import '../../services/firebase_erro.dart';
import '../../services/leitor_omr.dart';
import '../../models/prova_gerada.dart';
import '../../services/turmas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

/// Lê a foto do gabarito. [alternativasPorQuestao] é o número de bolinhas de
/// cada questão, na ordem impressa.
typedef LerGabarito = Future<LeituraCartao> Function(
  Uint8List foto,
  List<int> alternativasPorQuestao,
);

/// Leitura padrão, fora da thread da tela (a foto tem até 2000 px).
Future<LeituraCartao> lerGabaritoEmSegundoPlano(
  Uint8List foto,
  List<int> alternativasPorQuestao,
) => compute(_lerGabarito, (foto, alternativasPorQuestao));

LeituraCartao _lerGabarito((Uint8List, List<int>) entrada) =>
    LeitorOmr.lerCodificada(entrada.$1, entrada.$2);

class CorrigirVersaoScreen extends StatefulWidget {
  final ProvaGerada prova;
  final VersaoProva versao;
  final CorrecaoRepository correcoes;

  /// Foto da primeira página do gabarito (a do QR). Sem foto (web, desktop),
  /// o professor marca todas as respostas na mão.
  final Uint8List? foto;
  final LerGabarito lerGabarito;

  const CorrigirVersaoScreen({
    super.key,
    required this.prova,
    required this.versao,
    required this.correcoes,
    this.foto,
    this.lerGabarito = lerGabaritoEmSegundoPlano,
  });

  @override
  State<CorrigirVersaoScreen> createState() => _CorrigirVersaoScreenState();
}

class _CorrigirVersaoScreenState extends State<CorrigirVersaoScreen> {
  late final List<int?> _respostas;

  /// Por que cada questão precisa de conferência (nulo se o leitor leu uma
  /// alternativa). Fica mesmo depois que o professor escolhe, para ele ver
  /// quais respostas foram dele.
  late final List<String?> _motivos;

  /// Aviso geral da leitura (sem foto, foto ilegível...).
  String? _aviso;
  bool _lendo = false;
  bool _salvando = false;

  static const _semLeitura =
      'Não foi possível identificar. Selecione manualmente.';
  static const _outraPagina =
      'Está em outra página do gabarito. Selecione manualmente.';

  @override
  void initState() {
    super.initState();
    final total = widget.versao.questoes.length;
    _respostas = List<int?>.filled(total, null);
    _motivos = List<String?>.filled(total, _semLeitura);
    final foto = widget.foto;
    if (foto == null) {
      _aviso =
          'Neste dispositivo a foto não é lida automaticamente. '
          'Selecione a alternativa marcada em cada questão.';
      return;
    }
    _lendo = true;
    _ler(foto);
  }

  Future<void> _ler(Uint8List foto) async {
    String? aviso;
    LeituraCartao? leitura;
    try {
      leitura = await widget.lerGabarito(foto, [
        for (final q in widget.versao.questoes) q.alternativas.length,
      ]);
    } on LeituraOmrException catch (e) {
      aviso = '${e.problema.mensagem} Ou selecione as respostas abaixo.';
    } catch (_) {
      aviso =
          'Não foi possível ler as marcações da foto. '
          'Selecione as respostas abaixo.';
    }
    if (!mounted) return;
    setState(() {
      _lendo = false;
      _aviso = aviso;
      if (leitura == null) return;
      // Questões que não estão na primeira página ficam para o professor.
      for (var i = 0; i < _motivos.length; i++) {
        _motivos[i] = _outraPagina;
      }
      for (final l in leitura.leituras) {
        if (l.indice >= _respostas.length) continue;
        _respostas[l.indice] = l.alternativa;
        _motivos[l.indice] = l.situacao.precisaRevisao
            ? l.situacao.mensagem
            : null;
      }
    });
  }

  bool get _podeConfirmar =>
      !_salvando && !_lendo && _respostas.every((r) => r != null);

  Aluno? _aluno(BuildContext context) {
    final alunoId = widget.versao.alunoId;
    if (alunoId == null) return null;
    for (final aluno in alunosDaProva(
      disciplina: widget.prova.disciplina,
      turma: widget.prova.turma,
      disciplinas: context.read<TurmasRepository>().disciplinas,
    )) {
      if (aluno.id == alunoId) return aluno;
    }
    return null;
  }

  Future<void> _confirmar() async {
    final aluno = _aluno(context);
    final versao = widget.versao;
    final correcao = Correcao(
      id: 'cor_${DateTime.now().millisecondsSinceEpoch}',
      provaId: widget.prova.id,
      versaoId: versao.id,
      provaNome: widget.prova.nome,
      materia: widget.prova.materia,
      turma: widget.prova.turma,
      alunoId: versao.alunoId,
      alunoNome: aluno?.nome,
      corrigidoEm: DateTime.now(),
      respostas: [
        for (var i = 0; i < versao.questoes.length; i++)
          RespostaQuestao(
            questaoId: versao.questoes[i].questao.id,
            materiaId: versao.questoes[i].questao.materiaId,
            enunciado: versao.questoes[i].questao.enunciado,
            alternativaMarcada: _respostas[i]!,
            respostaCorreta: versao.questoes[i].respostaCorreta,
          ),
      ],
    );

    setState(() => _salvando = true);
    try {
      await widget.correcoes.salvar(correcao);
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            eErroDeConexao(erro)
                ? 'Sem conexão. A correção não foi salva.'
                : 'Não foi possível salvar a correção.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    context.pushReplacement('/corrigir/resultado', extra: correcao);
  }

  @override
  Widget build(BuildContext context) {
    final versao = widget.versao;
    final aluno = _aluno(context);

    return AppScaffold(
      appBar: AppBar(title: Text('Corrigir ${versao.id.toUpperCase()}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          AppCard(
            child: Row(
              children: [
                const AppLeadingIcon(icon: Icons.qr_code_2),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.prova.nome,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${versao.qrCode} · ${aluno?.nome ?? 'Sem aluno vinculado'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_lendo) ...[
            const SizedBox(height: AppSpacing.s4),
            const Row(
              children: [
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: AppSpacing.s3),
                Text('Lendo as marcações do gabarito…'),
              ],
            ),
          ],
          if (_aviso case final aviso?) ...[
            const SizedBox(height: AppSpacing.s4),
            AppCard(
              border: Border.all(color: AppColors.warning, width: 1.2),
              child: Text(
                aviso,
                key: const ValueKey('aviso_leitura'),
                style: const TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s5),
          Text(
            'ALTERNATIVAS DETECTADAS · REVISE ANTES DE CONFIRMAR',
            style: AppTheme.kicker,
          ),
          const SizedBox(height: AppSpacing.s3),
          for (var i = 0; i < versao.questoes.length; i++)
            _cartaoQuestao(i, versao.questoes[i]),
          const SizedBox(height: AppSpacing.s4),
          ElevatedButton.icon(
            onPressed: _podeConfirmar ? _confirmar : null,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar correção'),
          ),
        ],
      ),
    );
  }

  Widget _cartaoQuestao(int indice, QuestaoNaVersao questao) {
    final marcada = _respostas[indice];
    final naoIdentificada = marcada == null;
    final motivo = _lendo ? null : _motivos[indice];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: AppCard(
        border: naoIdentificada && !_lendo
            ? Border.all(color: AppColors.warning, width: 1.2)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Q${(indice + 1).toString().padLeft(2, '0')} · ${questao.questao.enunciado}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (naoIdentificada && !_lendo)
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
              ],
            ),
            if (motivo != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  naoIdentificada ? motivo : 'Conferida: $motivo',
                  key: ValueKey('motivo_$indice'),
                  style: TextStyle(
                    fontSize: 11,
                    color: naoIdentificada
                        ? AppColors.warning
                        : AppColors.textMuted,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.s2),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var alt = 0; alt < questao.alternativas.length; alt++)
                  ChoiceChip(
                    label: Text(letraAlternativa(alt)),
                    selected: marcada == alt,
                    onSelected: (_) => setState(() => _respostas[indice] = alt),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

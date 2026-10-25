// Depois que o QR é lido e a versão é achada, o professor revisa as
// alternativas de cada questão e confirma. A leitura das marcações (OMR) ainda
// não existe: a detecção é simulada, com chance de "não identificado", e o
// professor confirma ou corrige cada alternativa antes de calcular a nota.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/aluno.dart';
import '../../models/correcao.dart';
import '../../models/questao.dart';
import '../../models/versao_prova.dart';
import '../../services/alunos_para_pdf.dart';
import '../../services/correcao_repository.dart';
import '../../services/provas_repository.dart' show ProvaGerada;
import '../../services/turmas_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class CorrigirVersaoScreen extends StatefulWidget {
  final ProvaGerada prova;
  final VersaoProva versao;
  final CorrecaoRepository correcoes;
  final Random? random;

  const CorrigirVersaoScreen({
    super.key,
    required this.prova,
    required this.versao,
    required this.correcoes,
    this.random,
  });

  @override
  State<CorrigirVersaoScreen> createState() => _CorrigirVersaoScreenState();
}

class _CorrigirVersaoScreenState extends State<CorrigirVersaoScreen> {
  late final List<int?> _respostas;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final random = widget.random ?? Random();
    _respostas = widget.versao.questoes.map((q) {
      final sorteio = random.nextDouble();
      if (sorteio < 0.10) return null;
      if (sorteio < 0.22) {
        final erradas = List.generate(q.alternativas.length, (i) => i)
          ..remove(q.respostaCorreta);
        return erradas[random.nextInt(erradas.length)];
      }
      return q.respostaCorreta;
    }).toList();
  }

  bool get _podeConfirmar => !_salvando && _respostas.every((r) => r != null);

  Aluno? _aluno(BuildContext context) {
    final alunoId = widget.versao.alunoId;
    if (alunoId == null) return null;
    final turmas = context.read<TurmasRepository>().turmas;
    for (final aluno in alunosDaTurma(widget.prova.turma, turmas)) {
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a correção.')),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: AppCard(
        border: naoIdentificada
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
                if (naoIdentificada)
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
              ],
            ),
            if (naoIdentificada)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Não foi possível identificar. Selecione manualmente.',
                  style: TextStyle(fontSize: 11, color: AppColors.warning),
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

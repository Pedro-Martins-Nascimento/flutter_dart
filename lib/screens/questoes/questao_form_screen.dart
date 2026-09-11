import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/questao.dart';
import '../../services/persistencia_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

const _minAlternativas = 2;
const _maxAlternativas = 8;
const _alternativasPadrao = 4;

class QuestaoFormScreen extends StatefulWidget {
  final String materiaId;
  final Questao? questao;

  const QuestaoFormScreen({super.key, required this.materiaId, this.questao});

  @override
  State<QuestaoFormScreen> createState() => _QuestaoFormScreenState();
}

class _QuestaoFormScreenState extends State<QuestaoFormScreen> {
  late final TextEditingController _enunciado;
  late final List<TextEditingController> _alternativas;
  late int _correta;

  bool get _editando => widget.questao != null;

  @override
  void initState() {
    super.initState();
    final questao = widget.questao;

    _enunciado = TextEditingController(text: questao?.enunciado ?? '');
    _alternativas = [
      for (final texto
          in questao?.alternativas ?? List.filled(_alternativasPadrao, ''))
        TextEditingController(text: texto),
    ];
    _correta = questao?.respostaCorreta ?? 0;
  }

  @override
  void dispose() {
    _enunciado.dispose();
    for (final controller in _alternativas) {
      controller.dispose();
    }
    super.dispose();
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  void _adicionarAlternativa() {
    if (_alternativas.length >= _maxAlternativas) return;
    setState(() => _alternativas.add(TextEditingController()));
  }

  void _removerAlternativa(int indice) {
    if (_alternativas.length <= _minAlternativas) return;

    setState(() {
      _alternativas.removeAt(indice).dispose();

      if (_correta == indice) {
        _correta = 0;
      } else if (_correta > indice) {
        _correta--;
      }
    });
  }

  void _salvar() {
    final enunciado = _enunciado.text.trim();
    if (enunciado.isEmpty) {
      _avisar('Escreva o enunciado da questão.');
      return;
    }

    final textos = _alternativas.map((c) => c.text.trim()).toList();
    if (textos.any((t) => t.isEmpty)) {
      _avisar('Preencha todas as alternativas.');
      return;
    }

    final questao = Questao(
      id: widget.questao?.id ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
      materiaId: widget.materiaId,
      enunciado: enunciado,
      alternativas: textos,
      respostaCorreta: _correta,
    );

    final indice = questoesMock.indexWhere((q) => q.id == questao.id);
    if (indice >= 0) {
      questoesMock[indice] = questao;
    } else {
      questoesMock.add(questao);
    }
    PersistenciaService.instance.salvar();

    context.pop();
  }

  Future<void> _excluir() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir questão'),
        content: const Text(
          'A questão sai do banco e não entra em novas provas. Provas já '
          'geradas não mudam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    questoesMock.removeWhere((q) => q.id == widget.questao!.id);
    PersistenciaService.instance.salvar();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_editando ? 'Editar questão' : 'Nova questão'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        children: [
          Text('ENUNCIADO', style: AppTheme.kicker),
          const SizedBox(height: AppSpacing.s2),
          TextField(
            controller: _enunciado,
            maxLines: 4,
            minLines: 3,
            decoration: const InputDecoration(
              hintText: 'Escreva o enunciado da questão',
            ),
          ),

          const SizedBox(height: AppSpacing.s6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ALTERNATIVAS', style: AppTheme.kicker),
              const SizedBox(width: AppSpacing.s3),
              const Expanded(
                child: Text(
                  'marque a correta',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          ...List.generate(_alternativas.length, _linhaAlternativa),
          if (_alternativas.length < _maxAlternativas)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _adicionarAlternativa,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar alternativa'),
              ),
            ),

          const SizedBox(height: AppSpacing.s6),
          ElevatedButton(
            onPressed: _salvar,
            child: const Text('Salvar questão'),
          ),
          if (_editando) ...[
            const SizedBox(height: AppSpacing.s3),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: _excluir,
              child: const Text('Excluir questão'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linhaAlternativa(int indice) {
    final correta = indice == _correta;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Row(
        children: [
          InkWell(
            onTap: () => setState(() => _correta = indice),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: correta ? AppColors.accent : AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                letraAlternativa(indice),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: correta ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: TextField(
              controller: _alternativas[indice],
              decoration: const InputDecoration(
                hintText: 'Texto da alternativa',
              ),
            ),
          ),
          if (_alternativas.length > _minAlternativas)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.neutral500,
              tooltip: 'Remover alternativa ${letraAlternativa(indice)}',
              onPressed: () => _removerAlternativa(indice),
            ),
        ],
      ),
    );
  }
}

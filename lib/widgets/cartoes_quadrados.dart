// Quadradinhos usados para disciplinas (na tela inicial) e para turmas
// (dentro de uma disciplina): um de "+" para criar e um por item.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const double ladoCartaoQuadrado = 176;

/// Grade de quadradinhos: o de "+" primeiro e os itens ao lado.
class GradeDeCartoes extends StatelessWidget {
  final List<Widget> children;

  const GradeDeCartoes({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s4,
      runSpacing: AppSpacing.s4,
      children: children,
    );
  }
}

/// Quadradinho de "+" que cria um item novo.
class CartaoAdicionar extends StatefulWidget {
  final String rotulo;
  final VoidCallback onTap;

  const CartaoAdicionar({super.key, required this.rotulo, required this.onTap});

  @override
  State<CartaoAdicionar> createState() => _CartaoAdicionarState();
}

class _CartaoAdicionarState extends State<CartaoAdicionar> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(20);
    return Semantics(
      button: true,
      label: widget.rotulo,
      child: MouseRegion(
        onEnter: (_) => setState(() => _sobre = true),
        onExit: (_) => setState(() => _sobre = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: ladoCartaoQuadrado,
          height: ladoCartaoQuadrado,
          decoration: BoxDecoration(
            color: _sobre ? AppColors.accent100 : AppColors.surface,
            borderRadius: raio,
            border: Border.all(
              color: _sobre ? AppColors.accentLight : AppColors.neutral300,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: raio,
              onTap: widget.onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _sobre ? 1.08 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    widget.rotulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quadradinho de um item: nome, uma linha de detalhe e, se vier, um botão
/// embaixo. Tocar fora do botão chama [onTap].
class CartaoItem extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final String? rotuloBotao;
  final VoidCallback? onBotao;

  const CartaoItem({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.rotuloBotao,
    this.onBotao,
  });

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(20);
    final rotuloBotao = this.rotuloBotao;
    return SizedBox(
      width: ladoCartaoQuadrado,
      height: ladoCartaoQuadrado,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: raio,
          side: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  titulo,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                if (rotuloBotao != null)
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 36),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: onBotao,
                      child: Text(rotuloBotao),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pede um nome (de disciplina, turma...). Devolve o nome sem espaços nas
/// pontas, ou null se cancelar.
Future<String?> pedirNome(
  BuildContext context, {
  required String titulo,
  required String rotulo,
  String? dica,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DialogoNome(titulo: titulo, rotulo: rotulo, dica: dica),
  );
}

class _DialogoNome extends StatefulWidget {
  final String titulo;
  final String rotulo;
  final String? dica;

  const _DialogoNome({required this.titulo, required this.rotulo, this.dica});

  @override
  State<_DialogoNome> createState() => _DialogoNomeState();
}

class _DialogoNomeState extends State<_DialogoNome> {
  final _nome = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _confirmar() {
    final nome = _nome.text.trim();
    if (nome.isEmpty) return;
    Navigator.of(context).pop(nome);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _nome,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: widget.rotulo,
          hintText: widget.dica,
        ),
        onSubmitted: (_) => _confirmar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nome,
          builder: (context, valor, _) => ElevatedButton(
            onPressed: valor.text.trim().isEmpty ? null : _confirmar,
            child: const Text('Adicionar'),
          ),
        ),
      ],
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/correcao.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../services/notas_da_prova.dart';
import '../../services/prova_repository.dart';
import '../../services/relatorio_excel.dart';
import '../../services/salvar_arquivo.dart';
import '../../services/turmas_repository.dart';

class ListarProvasScreen extends StatelessWidget {
  final ProvaRepository repository;
  final Future<List<Correcao>> Function() carregarCorrecoes;
  final Future<bool> Function(String nome, Uint8List bytes) salvarArquivo;

  const ListarProvasScreen({
    super.key,
    required this.repository,
    required this.carregarCorrecoes,
    this.salvarArquivo = salvarXlsx,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProvaResumo>>(
      stream: repository.observar(),
      builder: (context, snapshot) =>
          _conteudo(context, snapshot.data ?? const []),
    );
  }

  Widget _conteudo(BuildContext context, List<ProvaResumo> provas) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFaixa(
              bordaBase: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s6,
                vertical: AppSpacing.s6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Provas', style: AppTheme.kicker),
                        const SizedBox(height: 4),
                        Text(
                          'Provas geradas',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  InkWell(
                    onTap: () => context.push('/criar-prova'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: provas.isEmpty
                  ? _vazio(context)
                  : ListView.separated(
                      itemCount: provas.length,
                      padding: EdgeInsets.zero,
                      separatorBuilder: (context, indice) =>
                          const Divider(height: 1),
                      itemBuilder: (context, indice) {
                        final prova = provas[indice];
                        return _ProvaItem(
                          titulo: prova.nome,
                          meta: _subtitulo(prova),
                          onTap: () => _abrir(context, prova),
                          onExportar: () => _exportarNotas(context, prova),
                          onExcluir: () => _excluir(context, prova),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s8 + AppSpacing.s6,
        AppSpacing.s6,
        AppSpacing.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nenhuma prova gerada ainda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          const SizedBox(
            width: 280,
            child: Text(
              'Monte uma prova escolhendo turma, matérias e questões — '
              'as versões geradas ficam guardadas aqui.',
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
          ElevatedButton(
            onPressed: () => context.push('/criar-prova'),
            child: const Text('Nova prova'),
          ),
        ],
      ),
    );
  }

  // A lista só tem o resumo: busca a prova completa antes de abrir.
  Future<void> _abrir(BuildContext context, ProvaResumo resumo) async {
    final completa = await repository.buscar(resumo.id);
    if (completa == null || !context.mounted) return;
    context.push('/gerar-provas', extra: completa);
  }

  Future<void> _exportarNotas(BuildContext context, ProvaResumo prova) async {
    final turmas = context.read<TurmasRepository>().turmas;
    final mensagens = ScaffoldMessenger.of(context);
    void avisar(String texto) => mensagens
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));

    try {
      final linhas = linhasDeNotas(
        prova: prova,
        turmas: turmas,
        correcoes: await carregarCorrecoes(),
      );
      if (linhas.isEmpty) {
        avisar('Esta prova ainda não tem alunos nem correções para exportar.');
        return;
      }
      final nome = prova.nome.trim().replaceAll(
        RegExp(r'[^A-Za-z0-9À-ÿ]+'),
        '_',
      );
      final salvo = await salvarArquivo(
        'notas_$nome.xlsx',
        gerarXlsxNotas(linhas),
      );
      if (salvo) avisar('Planilha de notas salva.');
    } catch (_) {
      avisar('Não foi possível exportar as notas.');
    }
  }

  Future<void> _excluir(BuildContext context, ProvaResumo prova) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir prova?'),
        content: Text(
          '"${prova.nome}" sai do histórico com as '
          '${prova.totalVersoes} versões geradas. As folhas já impressas '
          'continuam válidas, mas não dá pra reabrir a prova aqui.',
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

    if (confirmado == true) await repository.excluir(prova.id);
  }

  String _subtitulo(ProvaResumo prova) {
    final partes = <String>[prova.materia];
    if (prova.turma != null) partes.add(prova.turma!);
    partes.add('${prova.totalVersoes} versão(ões)');
    partes.add(_formatarData(prova.criadoEm));
    return partes.join(' • ');
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final min = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year} $hora:$min';
  }
}

class _ProvaItem extends StatelessWidget {
  final String titulo;
  final String meta;
  final VoidCallback onTap;
  final VoidCallback onExportar;
  final VoidCallback onExcluir;

  const _ProvaItem({
    required this.titulo,
    required this.meta,
    required this.onTap,
    required this.onExportar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s6,
          vertical: AppSpacing.s5,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            _MenuProva(onExportar: onExportar, onExcluir: onExcluir),
            const Icon(
              Icons.chevron_right,
              color: AppColors.neutral400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuProva extends StatelessWidget {
  final VoidCallback onExportar;
  final VoidCallback onExcluir;

  const _MenuProva({required this.onExportar, required this.onExcluir});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: 'Opções da prova',
      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.neutral500),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          onTap: onExportar,
          child: const Text('Exportar notas (.xlsx)'),
        ),
        PopupMenuItem<void>(
          onTap: onExcluir,
          child: const Text(
            'Excluir prova',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

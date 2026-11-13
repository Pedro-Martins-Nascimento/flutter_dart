import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/correcao.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page.dart';
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
            AppPageHeader(
              kicker: 'Provas',
              titulo: 'Provas geradas',
              acao: AppNovoButton(
                rotulo: 'Nova prova',
                onPressed: () => context.push('/criar-prova'),
              ),
            ),
            Expanded(
              child: AppMaxWidth(
                child: provas.isEmpty
                    ? AppEstadoVazio(
                        icone: Icons.description_outlined,
                        titulo: 'Nenhuma prova gerada ainda',
                        mensagem:
                            'Monte uma prova escolhendo turma, matérias e questões — '
                            'as versões geradas ficam guardadas aqui.',
                        acao: AppNovoButton(
                          rotulo: 'Nova prova',
                          onPressed: () => context.push('/criar-prova'),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s4,
                          AppSpacing.s2,
                          AppSpacing.s4,
                          AppSpacing.s8,
                        ),
                        children: [
                          AppListGroup(
                            children: [
                              for (final prova in provas)
                                AppListRow(
                                  titulo: prova.nome,
                                  subtitulo: _subtitulo(prova),
                                  onTap: () => _abrir(context, prova),
                                  menu: _MenuProva(
                                    onExportar: () =>
                                        _exportarNotas(context, prova),
                                    onExcluir: () => _excluir(context, prova),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
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
    partes.add(
      '${prova.totalVersoes} ${prova.totalVersoes == 1 ? 'versão' : 'versões'}',
    );
    partes.add(_formatarData(prova.criadoEm));
    return partes.join(' · ');
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final min = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year} $hora:$min';
  }
}

class _MenuProva extends StatelessWidget {
  final VoidCallback onExportar;
  final VoidCallback onExcluir;

  const _MenuProva({
    required this.onExportar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return AppMenuMais(
      tooltip: 'Opções da prova',
      itens: (context) => [
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

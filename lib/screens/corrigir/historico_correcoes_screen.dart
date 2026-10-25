// Lista as folhas já corrigidas, com acesso rápido ao resultado de cada uma e
// aos boletins em PDF.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../models/correcao.dart';
import '../../services/correcao_repository.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class HistoricoCorrecoesScreen extends StatelessWidget {
  final CorrecaoRepository correcoes;

  const HistoricoCorrecoesScreen({super.key, required this.correcoes});

  Future<void> _exportarTodos(List<Correcao> corrigidas) async {
    final bytes = await PdfService().gerarBoletinsMultiplos(corrigidas);
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'boletins.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Correcao>>(
      stream: correcoes.observar(),
      builder: (context, snapshot) {
        final corrigidas = snapshot.data ?? const <Correcao>[];
        return AppScaffold(
          appBar: AppBar(
            title: const Text('Corrigidas'),
            actions: [
              if (corrigidas.isNotEmpty)
                IconButton(
                  tooltip: 'Exportar boletins de todos (PDF)',
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () => _exportarTodos(corrigidas),
                ),
            ],
          ),
          body: corrigidas.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Nenhuma folha com nota calculada ainda.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              : _lista(context, corrigidas),
        );
      },
    );
  }

  Widget _lista(BuildContext context, List<Correcao> corrigidas) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        for (final correcao in corrigidas)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s3),
            child: AppListItem(
              leading: const AppLeadingIcon(icon: Icons.fact_check),
              title:
                  '${correcao.provaNome} · ${correcao.alunoNome ?? correcao.versaoId.toUpperCase()}',
              subtitle:
                  'Nota ${correcao.nota.toStringAsFixed(1)} · ${correcao.acertos}/${correcao.total} acertos',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.neutral500,
              ),
              onTap: () => context.push('/corrigir/resultado', extra: correcao),
            ),
          ),
      ],
    );
  }
}

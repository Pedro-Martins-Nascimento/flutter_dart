// lib/screens/corrigir/historico_correcoes_screen.dart
//
// Lista as folhas já corrigidas (nota calculada) durante a sessão de
// leitura de QR em CorrigirScreen — acesso rápido pra reabrir o
// resultado de qualquer uma delas.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../services/correcoes_repository.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class HistoricoCorrecoesScreen extends StatelessWidget {
  const HistoricoCorrecoesScreen({super.key});

  Future<void> _exportarTodos(List<Correcao> corrigidas) async {
    final bytes = await PdfService().gerarBoletinsMultiplos(corrigidas);
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'boletins.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CorrecoesRepository.instance,
      builder: (context, _) => _conteudo(context),
    );
  }

  Widget _conteudo(BuildContext context) {
    final corrigidas = CorrecoesRepository.instance.correcoes;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Corrigidas'),
        actions: [
          if (corrigidas.isNotEmpty)
            IconButton(
              tooltip: 'Exportar boletins de todo mundo (PDF)',
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
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.s4),
              children: [
                for (final correcao in corrigidas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                    child: AppListItem(
                      leading: const AppLeadingIcon(icon: Icons.fact_check),
                      title:
                          '${correcao.provaNome} · ${correcao.alunoNome ?? correcao.versao.id.toUpperCase()}',
                      subtitle:
                          'Nota ${correcao.nota.toStringAsFixed(1)} · ${correcao.acertos}/${correcao.total} acertos',
                      trailing: const Icon(Icons.chevron_right, color: AppColors.neutral500),
                      onTap: () => context.push('/corrigir/resultado', extra: correcao),
                    ),
                  ),
              ],
            ),
    );
  }
}

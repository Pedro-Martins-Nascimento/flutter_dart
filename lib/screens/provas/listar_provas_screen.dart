// lib/screens/provas/listar_provas_screen.dart
//
// Tela "Provas geradas" — lista o histórico de rodadas de geração
// (cada rodada = um clique em "Gerar versões" na tela Gerar Provas).
//
// N1: lê direto do ProvasRepository, que é em memória (sem Firebase
// ainda). Tocar num item reabre o preview daquela rodada, com as
// mesmas versões já geradas antes — sem precisar gerar tudo de novo.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../services/provas_repository.dart';

class ListarProvasScreen extends StatelessWidget {
  const ListarProvasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provas = ProvasRepository.instance.provas; // mais recente primeiro

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Provas geradas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Criar prova',
            onPressed: () => context.go('/criar-prova'),
          ),
        ],
      ),
      body: provas.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma prova gerada ainda.\n'
                  'Crie uma prova e gere as versões para ela aparecer aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provas.length,
              itemBuilder: (context, index) {
                final prova = provas[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                  child: AppListItem(
                    leading: const AppLeadingIcon(icon: Icons.description_outlined),
                    title: prova.nome,
                    subtitle: _subtitulo(prova),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.neutral400),
                    onTap: () => context.push('/gerar-provas', extra: prova),
                  ),
                );
              },
            ),
    );
  }

  String _subtitulo(ProvaGerada prova) {
    final partes = <String>[prova.materia];
    if (prova.turma != null) partes.add(prova.turma!);
    partes.add('${prova.versoes.length} versão(ões)');
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

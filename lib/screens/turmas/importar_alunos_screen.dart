// lib/screens/turmas/importar_alunos_screen.dart
//
// Tela "Importar Lista de Alunos" (Seguindo o protótipo da imagem)
// Permite selecionar arquivos CSV/XLSX para importação em lote.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import 'criar_turma_screen.dart'; // Importa o modelo e turmasMock

class ImportarAlunosScreen extends StatefulWidget {
  final String turmaId;

  const ImportarAlunosScreen({super.key, required this.turmaId});

  @override
  State<ImportarAlunosScreen> createState() => _ImportarAlunosScreenState();
}

class _ImportarAlunosScreenState extends State<ImportarAlunosScreen> {
  bool _importando = false;

  Future<void> _escolherArquivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _importando = true);

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes != null) {
        final excel = Excel.decodeBytes(bytes);
        final List<AlunoTurma> novosAlunos = [];

        for (var table in excel.tables.keys) {
          final sheet = excel.tables[table];
          if (sheet == null) continue;

          // Pula a primeira linha (cabeçalho)
          for (var i = 1; i < sheet.maxRows; i++) {
            final row = sheet.rows[i];
            
            // Assume coluna 0 como Nome e coluna 1 como Matrícula
            final nome = row[0]?.value?.toString() ?? '';
            final matricula = row.length > 1 ? row[1]?.value?.toString() ?? '' : '';

            if (nome.isNotEmpty) {
              novosAlunos.add(
                AlunoTurma(
                  id: 'imp_${DateTime.now().millisecondsSinceEpoch}_$i',
                  nome: nome,
                  matricula: matricula,
                ),
              );
            }
          }
        }

        if (novosAlunos.isNotEmpty) {
          final turma = turmasMock.firstWhere((t) => t.id == widget.turmaId);
          setState(() {
            turma.alunos.addAll(novosAlunos);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${novosAlunos.length} alunos importados com sucesso!')),
            );
            context.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar arquivo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Importar lista de alunos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de área de seleção
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.s6),
              border: Border.all(color: AppColors.neutral300, width: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '.csv  .xlsx',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecione a planilha',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Uma coluna com o nome e, se houver, uma com a matrícula.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Botão Escolher Arquivo
            SizedBox(
              width: double.infinity,
              child: _importando 
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : ElevatedButton.icon(
                    onPressed: _escolherArquivo,
                    icon: const Icon(Icons.upload_file, size: 20),
                    label: const Text('Escolher arquivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

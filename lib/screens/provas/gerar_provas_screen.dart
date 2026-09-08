// lib/screens/provas/gerar_provas_screen.dart
//
// Tela "Gerar Provas" (N1 - dados mock, sem Firebase/QR real ainda)
// RF10 — Gerar QR code único por versão, vinculado ao gabarito daquela versão
// RF11 — Vincular (opcionalmente) uma versão a um aluno importado
// RF12 — Exportar a prova em PDF pronta para impressão
//

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../services/provas_repository.dart';
import '../../services/pdf_service.dart';
import 'criar_prova_screen.dart' show DadosProva;

// ---------------------------------------------------------------------
// MODELOS MOCK
// ---------------------------------------------------------------------

class Aluno {
  final String id;
  final String nome;

  Aluno({required this.id, required this.nome});
}

class VersaoProva {
  final String id;
  final String qrCode; 
  String? alunoId; // RF11 — vínculo é opcional

  // Campos usados no cabeçalho de identificação do PDF
  final String materia;
  final String professor;
  final String? turma;
  final String provaNome;

  VersaoProva({
    required this.id,
    required this.qrCode,
    this.alunoId,
    this.materia = 'Matemática',
    this.professor = 'Prof. responsável',
    this.turma,
    this.provaNome = 'Prova sem título',
  });
}

// ---------------------------------------------------------------------
// DADOS MOCK
// ---------------------------------------------------------------------

final List<Aluno> alunosMock = [
  Aluno(id: 'al1', nome: 'Bruno Oliveira'),
  Aluno(id: 'al2', nome: 'Carla Menezes'),
  Aluno(id: 'al3', nome: 'Diego Farias'),
];

// ---------------------------------------------------------------------
// TELA
// ---------------------------------------------------------------------

class GerarProvasScreen extends StatefulWidget {
  // Dados vindos da tela Criar Prova. Fica nullable de propósito —
  // se alguém cair aqui direto (ex: link antigo, hot-reload no meio da
  // rota), a tela ainda funciona com os valores mock de fallback.
  final DadosProva? dados;

  final ProvaGerada? provaExistente;

  const GerarProvasScreen({super.key, this.dados, this.provaExistente});

  @override
  State<GerarProvasScreen> createState() => _GerarProvasScreenState();
}

class _GerarProvasScreenState extends State<GerarProvasScreen> {
  final TextEditingController quantidadeController =
      TextEditingController(text: '3');
  final PdfService _pdfService = PdfService();

  List<VersaoProva> versoes = [];

  @override
  void initState() {
    super.initState();
    final provaExistente = widget.provaExistente;
    if (provaExistente != null) {
      versoes = List.of(provaExistente.versoes);
    }
  }

  void _gerarVersoes() {
    final quantidade = int.tryParse(quantidadeController.text) ?? 0;
    if (quantidade <= 0) return;

    final dados = widget.dados;
    final materiaTexto =
        (dados != null && dados.materias.isNotEmpty) ? dados.materiasResumo : 'Matemática';
    final provaNome = dados?.nomeProva ?? 'Prova sem título';
    final turmaTexto = dados?.turma?.nome;

    setState(() {
      versoes = List.generate(quantidade, (i) {
        final numero = i + 1;
        return VersaoProva(
          id: 'v$numero',
          // string fake só pra representar o conteúdo do QR por enquanto
          qrCode: 'PROVA-2026-V$numero-${(1000 + numero * 37)}',
          materia: materiaTexto,
          professor: 'Prof. responsável',
          turma: turmaTexto,
          provaNome: provaNome,
        );
      });
    });

    // Salva essa rodada no histórico de provas geradas.
    ProvasRepository.instance.salvar(
      ProvaGerada(
        id: 'pg_${DateTime.now().millisecondsSinceEpoch}',
        nome: provaNome,
        materia: materiaTexto,
        turma: turmaTexto,
        criadoEm: DateTime.now(),
        versoes: versoes,
      ),
    );
  }

  void _vincularAluno(VersaoProva versao, String? alunoId) {
    setState(() {
      versao.alunoId = alunoId;
    });
  }

  Future<void> _exportarPdfDireto() async {
    final bytes = await _pdfService.gerarPdfProvas(versoes);
    final nome = widget.provaExistente?.nome ?? widget.dados?.nomeProva ?? 'provas';
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: '$nome.pdf',
    );
  }

  void _abrirEditorDeLayout() {
    context.push('/gerar-provas/preview', extra: versoes);
  }

  @override
  void dispose() {
    quantidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editandoExistente = widget.provaExistente != null;

    return AppScaffold(
      maxWidth: AppLayout.maxContentWidthWide,
      appBar: AppBar(
        title: Text(editandoExistente ? widget.provaExistente!.nome : 'Gerar Provas'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/criar-prova');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!editandoExistente) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Provas geradas'),
              onPressed: () => context.push('/provas-geradas'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s4),
              ),
            ),

            const SizedBox(height: 24),
            Text('QUANTAS VERSÕES VOCÊ QUER GERAR?', style: AppTheme.kicker),
            const SizedBox(height: 8),
            AppCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: quantidadeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _gerarVersoes,
                    child: const Text('Gerar versões'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Text('DESEJA EDITAR O VÍNCULO DA PROVA?', style: AppTheme.kicker),
            const SizedBox(height: 8),
            AppCard(
              child: Text(
                '${widget.provaExistente!.materia}'
                '${widget.provaExistente!.turma != null ? ' • ${widget.provaExistente!.turma}' : ''}'
                ' • ${versoes.length} versão(ões)',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (versoes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Nenhuma versão gerada ainda.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...versoes.map((versao) => _VersaoCard(
                  versao: versao,
                  onAlunoChanged: (alunoId) => _vincularAluno(versao, alunoId),
                )),

          const SizedBox(height: 24),
          if (versoes.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportarPdfDireto,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportar PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _abrirEditorDeLayout,
                    icon: const Icon(Icons.tune),
                    label: const Text('Editor de layout'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// CARD DE CADA VERSÃO
// ---------------------------------------------------------------------

class _VersaoCard extends StatelessWidget {
  final VersaoProva versao;
  final ValueChanged<String?> onAlunoChanged;

  const _VersaoCard({required this.versao, required this.onAlunoChanged});

  @override
  Widget build(BuildContext context) {
    final vinculado = versao.alunoId != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: AppListItem(
        leading: const AppLeadingIcon(icon: Icons.qr_code_2),
        title: versao.id.toUpperCase(),
        subtitle: versao.qrCode,
        trailing: Icon(
          vinculado ? Icons.link : Icons.link_off,
          size: 18,
          color: vinculado ? AppColors.accent : AppColors.neutral400,
        ),
        footer: DropdownButtonFormField<String?>(
          initialValue: versao.alunoId,
          decoration: const InputDecoration(
            labelText: 'Vincular aluno (opcional)',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Nenhum vínculo'),
            ),
            ...alunosMock.map(
              (aluno) => DropdownMenuItem<String?>(
                value: aluno.id,
                child: Text(aluno.nome),
              ),
            ),
          ],
          onChanged: onAlunoChanged,
        ),
      ),
    );
  }
}

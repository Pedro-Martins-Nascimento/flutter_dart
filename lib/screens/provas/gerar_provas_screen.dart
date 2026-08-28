// lib/screens/provas/gerar_provas_screen.dart
//
// Tela "Gerar Provas" (N1 - dados mock, sem Firebase/QR real ainda)
// RF10 — Gerar QR code único por versão, vinculado ao gabarito daquela versão
// RF11 — Vincular (opcionalmente) uma versão a um aluno importado
// RF12 — Exportar a prova em PDF pronta para impressão
//
// O QR code aqui é só um placeholder visual (ícone dentro do
// AppLeadingIcon). Quando o grupo integrar o pacote qr_flutter, troca
// só o `icon:` do AppLeadingIcon por um QrImageView de verdade — a
// lógica de gerar/vincular versão continua igual.
//
// ALTERADO (revisão de UI): o card de cada versão agora usa
// AppListItem/AppCard (lib/widgets/app_card.dart) em vez de um
// Card + Row montado na mão, pra seguir o novo visual soft/iOS-like
// do tema.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

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
  final String qrCode; // depois vira o dado real codificado no QR
  String? alunoId; // RF11 — vínculo é opcional

  // ALTERADO: campos novos, usados no cabeçalho de identificação do PDF
  // (Aluno / Professor / Matéria / Data). São MOCK por enquanto — quando
  // a Criar Prova passar a matéria escolhida pra cá, e o login trouxer
  // o professor logado, esses dois viram valores reais.
  final String materia;
  final String professor;

  VersaoProva({
    required this.id,
    required this.qrCode,
    this.alunoId,
    this.materia = 'Matemática',
    this.professor = 'Prof. responsável',
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
  const GerarProvasScreen({super.key});

  @override
  State<GerarProvasScreen> createState() => _GerarProvasScreenState();
}

class _GerarProvasScreenState extends State<GerarProvasScreen> {
  final TextEditingController quantidadeController =
      TextEditingController(text: '3');

  List<VersaoProva> versoes = [];

  void _gerarVersoes() {
    final quantidade = int.tryParse(quantidadeController.text) ?? 0;
    if (quantidade <= 0) return;

    setState(() {
      versoes = List.generate(quantidade, (i) {
        final numero = i + 1;
        return VersaoProva(
          id: 'v$numero',
          // string fake só pra representar o conteúdo do QR por enquanto
          qrCode: 'PROVA-2026-V$numero-${(1000 + numero * 37)}',
        );
      });
    });
  }

  void _vincularAluno(VersaoProva versao, String? alunoId) {
    setState(() {
      versao.alunoId = alunoId;
    });
  }

  void _exportarPdf() {
    context.push('/gerar-provas/preview', extra: versoes);
  }

  @override
  void dispose() {
    quantidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerar Provas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('QUANTAS VERSÕES VOCÊ QUER GERAR?', style: AppTheme.kicker),
          const SizedBox(height: 8),
          // ALTERADO (revisão de UI): o controle de quantidade também
          // ganhou o "casco" do AppCard, pra cada seção da tela virar um
          // bloco branco com sombra suave, igual as demais telas.
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
            ElevatedButton.icon(
              onPressed: _exportarPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exportar PDF pronto para impressão'),
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
        // Pequeno indicador de vínculo, no mesmo espírito dos ícones da
        // tela de referência (ex: ícone de "olho"/reorder à direita do
        // item) — aqui indica se a versão já tem aluno vinculado.
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
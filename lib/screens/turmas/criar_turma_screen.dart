// lib/screens/turmas/criar_turma_screen.dart
//
// Tela "Minhas Turmas" (Seguindo o protótipo da imagem)
// Exibe a lista de turmas cadastradas com atalho para criar novas.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

// ---------------------------------------------------------------------
// MODELO MOCK
// ---------------------------------------------------------------------

class AlunoTurma {
  final String id;
  final String nome;
  final String matricula;

  AlunoTurma({
    required this.id,
    required this.nome,
    required this.matricula,
  });
}

class Turma {
  final String id;
  final String nome;
  final int qtdAlunos;
  final int qtdProvas;
  final List<AlunoTurma> alunos;

  Turma({
    required this.id,
    required this.nome,
    required this.qtdAlunos,
    required this.qtdProvas,
    List<AlunoTurma>? alunos,
  }) : this.alunos = alunos ?? [];
}

// ---------------------------------------------------------------------
// DADOS MOCK (Transformado em lista mutável para teste N1)
// ---------------------------------------------------------------------

final List<AlunoTurma> alunosMockTurmaB = [
  AlunoTurma(id: '1', nome: 'Ana Beatriz Lima', matricula: '20261137'),
  AlunoTurma(id: '2', nome: 'Bruno Carvalho', matricula: '20261144'),
  AlunoTurma(id: '3', nome: 'Camila Duarte', matricula: '20261151'),
  AlunoTurma(id: '4', nome: 'Diego Fontes', matricula: '20261158'),
  AlunoTurma(id: '5', nome: 'Eduarda Ramos', matricula: '20261165'),
  AlunoTurma(id: '6', nome: 'Felipe Nogueira', matricula: '20261172'),
  AlunoTurma(id: '7', nome: 'Gabriela Torres', matricula: '20261179'),
  AlunoTurma(id: '8', nome: 'Henrique Salles', matricula: '20261186'),
  AlunoTurma(id: 'b9', nome: 'Isabela Rocha', matricula: '20261187'),
  AlunoTurma(id: 'b10', nome: 'João Pedro Silva', matricula: '20261188'),
  AlunoTurma(id: 'b11', nome: 'Karina Lopes', matricula: '20261189'),
  AlunoTurma(id: 'b12', nome: 'Lucas Mendes', matricula: '20261190'),
  AlunoTurma(id: 'b13', nome: 'Mariana Costa', matricula: '20261191'),
  AlunoTurma(id: 'b14', nome: 'Nicolas Freitas', matricula: '20261192'),
  AlunoTurma(id: 'b15', nome: 'Olivia Barbosa', matricula: '20261193'),
  AlunoTurma(id: 'b16', nome: 'Paulo Victor', matricula: '20261194'),
  AlunoTurma(id: 'b17', nome: 'Raquel Nunes', matricula: '20261195'),
  AlunoTurma(id: 'b18', nome: 'Samuel Oliveira', matricula: '20261196'),
  AlunoTurma(id: 'b19', nome: 'Tatiana Guedes', matricula: '20261197'),
  AlunoTurma(id: 'b20', nome: 'Vitor Hugo Lima', matricula: '20261198'),
  AlunoTurma(id: 'b21', nome: 'Yasmin Araujo', matricula: '20261199'),
  AlunoTurma(id: 'b22', nome: 'Arthur Meireles', matricula: '20261200'),
  AlunoTurma(id: 'b23', nome: 'Beatriz Martins', matricula: '20261201'),
  AlunoTurma(id: 'b24', nome: 'Caio Junqueira', matricula: '20261202'),
  AlunoTurma(id: 'b25', nome: 'Davi Luiz', matricula: '20261203'),
  AlunoTurma(id: 'b26', nome: 'Emanuelly Rosa', matricula: '20261204'),
  AlunoTurma(id: 'b27', nome: 'Fernando Augusto', matricula: '20261205'),
  AlunoTurma(id: 'b28', nome: 'Giovanna Lancellotti', matricula: '20261206'),
  AlunoTurma(id: 'b29', nome: 'Heitor Garcia', matricula: '20261207'),
  AlunoTurma(id: 'b30', nome: 'Igor Cavalera', matricula: '20261208'),
  AlunoTurma(id: 'b31', nome: 'Julia Roberts', matricula: '20261209'),
  AlunoTurma(id: 'b32', nome: 'Kadu Moliterno', matricula: '20261210'),
];

final List<AlunoTurma> alunosMock2AnoA = [
  AlunoTurma(id: '9', nome: 'Alice Ferreira', matricula: '20262201'),
  AlunoTurma(id: '10', nome: 'Bernardo Souza', matricula: '20262202'),
  AlunoTurma(id: '11', nome: 'Caio Martins', matricula: '20262203'),
  AlunoTurma(id: '12', nome: 'Daniela Rocha', matricula: '20262204'),
  AlunoTurma(id: 'a5', nome: 'Elisa Volpato', matricula: '20262205'),
  AlunoTurma(id: 'a6', nome: 'Fabio Assunção', matricula: '20262206'),
  AlunoTurma(id: 'a7', nome: 'Gisele Bündchen', matricula: '20262207'),
  AlunoTurma(id: 'a8', nome: 'Humberto Carrão', matricula: '20262208'),
  AlunoTurma(id: 'a9', nome: 'Isis Valverde', matricula: '20262209'),
  AlunoTurma(id: 'a10', nome: 'Juliano Cazarré', matricula: '20262210'),
  AlunoTurma(id: 'a11', nome: 'Klara Castanho', matricula: '20262211'),
  AlunoTurma(id: 'a12', nome: 'Lázaro Ramos', matricula: '20262212'),
  AlunoTurma(id: 'a13', nome: 'Mateus Solano', matricula: '20262213'),
  AlunoTurma(id: 'a14', nome: 'Nanda Costa', matricula: '20262214'),
  AlunoTurma(id: 'a15', nome: 'Otávio Müller', matricula: '20262215'),
  AlunoTurma(id: 'a16', nome: 'Paolla Oliveira', matricula: '20262216'),
  AlunoTurma(id: 'a17', nome: 'Quitéria Chagas', matricula: '20262217'),
  AlunoTurma(id: 'a18', nome: 'Rodrigo Santoro', matricula: '20262218'),
  AlunoTurma(id: 'a19', nome: 'Sophie Charlotte', matricula: '20262219'),
  AlunoTurma(id: 'a20', nome: 'Thiago Lacerda', matricula: '20262220'),
  AlunoTurma(id: 'a21', nome: 'Ursula Corona', matricula: '20262221'),
  AlunoTurma(id: 'a22', nome: 'Vladimir Brichta', matricula: '20262222'),
  AlunoTurma(id: 'a23', nome: 'Wagner Moura', matricula: '20262223'),
  AlunoTurma(id: 'a24', nome: 'Xuxa Meneghel', matricula: '20262224'),
  AlunoTurma(id: 'a25', nome: 'Yanna Lavigne', matricula: '20262225'),
  AlunoTurma(id: 'a26', nome: 'Zezé Polessa', matricula: '20262226'),
];

final List<AlunoTurma> alunosMockRedes = [
  AlunoTurma(id: '13', nome: 'Eduardo Silva', matricula: '20263301'),
  AlunoTurma(id: '14', nome: 'Fernanda Lima', matricula: '20263302'),
  AlunoTurma(id: '15', nome: 'Gabriel Santos', matricula: '20263303'),
  AlunoTurma(id: 'r4', nome: 'Hugo Gloss', matricula: '20263304'),
  AlunoTurma(id: 'r5', nome: 'Ivete Sangalo', matricula: '20263305'),
  AlunoTurma(id: 'r6', nome: 'Jorge Ben', matricula: '20263306'),
  AlunoTurma(id: 'r7', nome: 'Kelly Key', matricula: '20263307'),
  AlunoTurma(id: 'r8', nome: 'Luan Santana', matricula: '20263308'),
  AlunoTurma(id: 'r9', nome: 'Michel Teló', matricula: '20263309'),
  AlunoTurma(id: 'r10', nome: 'Neymar Jr', matricula: '20263310'),
  AlunoTurma(id: 'r11', nome: 'Oscar Schmidt', matricula: '20263311'),
  AlunoTurma(id: 'r12', nome: 'Pabllo Vittar', matricula: '20263312'),
  AlunoTurma(id: 'r13', nome: 'Quevinho', matricula: '20263313'),
  AlunoTurma(id: 'r14', nome: 'Ronaldinho Gaucho', matricula: '20263314'),
  AlunoTurma(id: 'r15', nome: 'Sandy Leah', matricula: '20263315'),
  AlunoTurma(id: 'r16', nome: 'Tiago Leifert', matricula: '20263316'),
  AlunoTurma(id: 'r17', nome: 'Uriel Bueno', matricula: '20263317'),
  AlunoTurma(id: 'r18', nome: 'Valesca Popozuda', matricula: '20263318'),
  AlunoTurma(id: 'r19', nome: 'Wanessa Camargo', matricula: '20263319'),
  AlunoTurma(id: 'r20', nome: 'Zeca Pagodinho', matricula: '20263320'),
];

final List<AlunoTurma> alunosMockPiloto = [
  AlunoTurma(id: '16', nome: 'Helena Costa', matricula: '20264401'),
  AlunoTurma(id: '17', nome: 'Igor Almeida', matricula: '20264402'),
  AlunoTurma(id: 'p3', nome: 'Joana Prado', matricula: '20264403'),
  AlunoTurma(id: 'p4', nome: 'Kleber Bambam', matricula: '20264404'),
  AlunoTurma(id: 'p5', nome: 'Luana Piovani', matricula: '20264405'),
  AlunoTurma(id: 'p6', nome: 'Murilo Benício', matricula: '20264406'),
  AlunoTurma(id: 'p7', nome: 'Nivea Stelmann', matricula: '20264407'),
  AlunoTurma(id: 'p8', nome: 'Olavo Bilac', matricula: '20264408'),
  AlunoTurma(id: 'p9', nome: 'Patrícia Pillar', matricula: '20264409'),
  AlunoTurma(id: 'p10', nome: 'Reynaldo Gianecchini', matricula: '20264410'),
  AlunoTurma(id: 'p11', nome: 'Sabrina Sato', matricula: '20264411'),
  AlunoTurma(id: 'p12', nome: 'Taís Araújo', matricula: '20264412'),
  AlunoTurma(id: 'p13', nome: 'Ulysses Guimarães', matricula: '20264413'),
  AlunoTurma(id: 'p14', nome: 'Vera Fischer', matricula: '20264414'),
  AlunoTurma(id: 'p15', nome: 'William Bonner', matricula: '20264415'),
  AlunoTurma(id: 'p16', nome: 'Xuxa Lopes', matricula: '20264416'),
  AlunoTurma(id: 'p17', nome: 'Yuri Gagarin', matricula: '20264417'),
  AlunoTurma(id: 'p18', nome: 'Zico', matricula: '20264418'),
  AlunoTurma(id: 'p19', nome: 'Aline Moraes', matricula: '20264419'),
  AlunoTurma(id: 'p20', nome: 'Babu Santana', matricula: '20264420'),
  AlunoTurma(id: 'p21', nome: 'Caco Ciocler', matricula: '20264421'),
];

List<Turma> turmasMock = [
  Turma(
    id: '1',
    nome: '3º ano B — Matutino',
    qtdAlunos: alunosMockTurmaB.length,
    qtdProvas: 3,
    alunos: alunosMockTurmaB,
  ),
  Turma(
    id: '2',
    nome: '2º ano A — Matutino',
    qtdAlunos: alunosMock2AnoA.length,
    qtdProvas: 1,
    alunos: alunosMock2AnoA,
  ),
  Turma(
    id: '3',
    nome: 'Redes de Computadores — Noturno',
    qtdAlunos: alunosMockRedes.length,
    qtdProvas: 5,
    alunos: alunosMockRedes,
  ),
  Turma(
    id: '4',
    nome: 'Turma piloto (OMR)',
    qtdAlunos: alunosMockPiloto.length,
    qtdProvas: 2,
    alunos: alunosMockPiloto,
  ),
];

// ---------------------------------------------------------------------
// TELA PRINCIPAL (LISTA)
// ---------------------------------------------------------------------

class CriarTurmaScreen extends StatefulWidget {
  const CriarTurmaScreen({super.key});

  @override
  State<CriarTurmaScreen> createState() => _CriarTurmaScreenState();
}

class _CriarTurmaScreenState extends State<CriarTurmaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho conforme protótipo
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s6,
                vertical: AppSpacing.s6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Turmas', style: AppTheme.kicker),
                      const SizedBox(height: 4),
                      Text(
                        'Minhas turmas',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  // Botão "+" em caixa
                  InkWell(
                    onTap: () async {
                      // RF: Espera o retorno da tela de criação para atualizar a lista
                      await context.push('/turmas/nova');
                      setState(() {});
                    },
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

            const Divider(height: 1),

            // Lista de turmas
            Expanded(
              child: ListView.separated(
                itemCount: turmasMock.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 0),
                itemBuilder: (context, index) {
                  final turma = turmasMock[index];
                  return _TurmaItem(
                    turma: turma,
                    onTap: () async {
                      await context.push('/turmas/${turma.id}');
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TurmaItem extends StatelessWidget {
  final Turma turma;
  final VoidCallback onTap;

  const _TurmaItem({
    required this.turma,
    required this.onTap,
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
                    turma.nome,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${turma.alunos.length} alunos',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
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

// ---------------------------------------------------------------------
// TELA NOVA TURMA (Formulário)
// ---------------------------------------------------------------------

class NovaTurmaScreen extends StatefulWidget {
  const NovaTurmaScreen({super.key});

  @override
  State<NovaTurmaScreen> createState() => _NovaTurmaScreenState();
}

class _NovaTurmaScreenState extends State<NovaTurmaScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _periodoController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _periodoController.dispose();
    super.dispose();
  }

  void _salvar() {
    final nome = _nomeController.text.trim();
    final periodo = _periodoController.text.trim();

    if (nome.isEmpty) return;

    // Adiciona na lista mock global (como primeira da lista)
    setState(() {
      turmasMock.insert(
        0,
        Turma(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          nome: periodo.isNotEmpty ? '$nome — $periodo' : nome,
          qtdAlunos: 0, // Inicia com zero
          qtdProvas: 0, // Inicia com zero
          alunos: [], // Inicia com lista vazia expansível
        ),
      );
    });

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Nova turma'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nome da turma',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                hintText: '3º ano B — Matutino',
                hintStyle: TextStyle(color: AppColors.neutral400),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Período',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _periodoController,
              decoration: const InputDecoration(
                hintText: '2026.2',
                hintStyle: TextStyle(color: AppColors.neutral400),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _salvar,
              child: const Text('Salvar turma'),
            ),
          ],
        ),
      ),
    );
  }
}

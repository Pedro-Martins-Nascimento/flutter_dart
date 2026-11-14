import 'package:flutter_dart/models/prova_gerada.dart';
import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/models/turma.dart';
import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/services/prova_repository_memoria.dart';

final List<Materia> materiasMock = [
  Materia(id: 'mat1', nome: 'Matemática'),
  Materia(id: 'mat2', nome: 'História'),
  Materia(id: 'mat3', nome: 'Biologia'),
  Materia(id: 'mat4', nome: 'Português'),
  Materia(id: 'mat5', nome: 'Geografia'),
  Materia(id: 'mat6', nome: 'Física'),
  Materia(id: 'mat7', nome: 'Química'),
  Materia(id: 'mat8', nome: 'Inglês'),
];

final List<Questao> questoesMock = [
  Questao(
    id: 'q1',
    materiaId: 'mat1',
    enunciado: 'Quanto é 7 x 8?',
    alternativas: ['54', '56', '58', '64'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q2',
    materiaId: 'mat1',
    enunciado: 'Qual a raiz quadrada de 144?',
    alternativas: ['11', '12', '13', '14'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q3',
    materiaId: 'mat1',
    enunciado: 'Resolva a equação: 2x + 6 = 14. Qual o valor de x?',
    alternativas: ['2', '3', '4', '5'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q4',
    materiaId: 'mat1',
    enunciado: 'Se um triângulo tem lados medindo 3 cm, 4 cm e 5 cm, ele é:',
    alternativas: ['Equilátero', 'Isósceles', 'Retângulo', 'Obtusângulo'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q5',
    materiaId: 'mat1',
    enunciado: 'Quanto é 15% de 200?',
    alternativas: ['20', '25', '30', '35'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q6',
    materiaId: 'mat2',
    enunciado: 'Em que ano ocorreu a Proclamação da República no Brasil?',
    alternativas: ['1822', '1888', '1889', '1930'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q7',
    materiaId: 'mat2',
    enunciado: 'Quem foi o primeiro presidente do Brasil?',
    alternativas: [
      'Deodoro da Fonseca',
      'Floriano Peixoto',
      'Prudente de Morais',
      'Getúlio Vargas',
    ],
    respostaCorreta: 0,
  ),
  Questao(
    id: 'q8',
    materiaId: 'mat2',
    enunciado: 'Qual evento marcou o início da Primeira Guerra Mundial?',
    alternativas: [
      'A invasão da Polônia',
      'A queda da Bastilha',
      'O assassinato do Arquiduque Francisco Ferdinando',
      'O Tratado de Versalhes',
    ],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q9',
    materiaId: 'mat3',
    enunciado: 'Qual organela celular é responsável pela produção de energia (ATP)?',
    alternativas: [
      'Complexo de Golgi',
      'Ribossomo',
      'Mitocôndria',
      'Retículo Endoplasmático',
    ],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q10',
    materiaId: 'mat3',
    enunciado: 'O processo pelo qual as plantas produzem seu próprio alimento utilizando luz solar é chamado de:',
    alternativas: ['Respiração', 'Fermentação', 'Fotossíntese', 'Transpiração'],
    respostaCorreta: 2,
  ),
];

final List<Turma> turmasMock = [
  Turma(
    id: '1',
    nome: '3º ano B — Matutino',
    qtdProvas: 3,
    alunos: [
      AlunoTurma(id: '1', nome: 'Ana Beatriz Lima', matricula: '20261137'),
      AlunoTurma(id: '2', nome: 'Bruno Carvalho', matricula: '20261144'),
      AlunoTurma(id: '3', nome: 'Camila Duarte', matricula: '20261151'),
      AlunoTurma(id: '4', nome: 'Diego Fontes', matricula: '20261158'),
      AlunoTurma(id: '5', nome: 'Eduarda Ramos', matricula: '20261165'),
      AlunoTurma(id: '6', nome: 'Felipe Nogueira', matricula: '20261172'),
      AlunoTurma(id: '7', nome: 'Gabriela Torres', matricula: '20261179'),
      AlunoTurma(id: '8', nome: 'Henrique Salles', matricula: '20261186'),
    ],
  ),
  Turma(
    id: '2',
    nome: '2º ano A — Matutino',
    qtdProvas: 1,
    alunos: [
      AlunoTurma(id: 'a1', nome: 'Alice Monteiro', matricula: '20262201'),
      AlunoTurma(id: 'a2', nome: 'Bernardo Silva', matricula: '20262202'),
    ],
  ),
  Turma(
    id: '3',
    nome: 'Redes de Computadores — Noturno',
    qtdProvas: 5,
    alunos: [
      AlunoTurma(id: 'r1', nome: 'Alexandre Pires', matricula: '20263301'),
      AlunoTurma(id: 'r2', nome: 'Bárbara Paz', matricula: '20263302'),
    ],
  ),
  Turma(
    id: '4',
    nome: 'Turma piloto (OMR)',
    qtdProvas: 2,
    alunos: [
      AlunoTurma(id: 'p1', nome: 'Ayrton Senna', matricula: '20264401'),
      AlunoTurma(id: 'p2', nome: 'Barrichello', matricula: '20264402'),
    ],
  ),
];

List<ProvaGerada> provasDeExemplo() {
  final agora = DateTime.now();

  ProvaGerada montar({
    required String id,
    required String nome,
    required String materiaId,
    required int indiceTurma,
    required int quantasVersoes,
    required int diasAtras,
  }) {
    final materia = materiasMock.firstWhere((m) => m.id == materiaId);
    final turma = indiceTurma < turmasMock.length
        ? turmasMock[indiceTurma].nome
        : null;
    final questoes = questoesMock
        .where((q) => q.materiaId == materiaId)
        .toList();

    return ProvaGerada(
      id: id,
      nome: nome,
      materia: materia.nome,
      turma: turma,
      criadoEm: agora.subtract(Duration(days: diasAtras)),
      versoes: List.generate(quantasVersoes, (i) {
        final numero = i + 1;
        return VersaoProva(
          id: 'v$numero',
          qrCode: '${id.toUpperCase()}-V$numero',
          questoes: [
            for (final questao in questoes)
              QuestaoNaVersao(
                questao: questao,
                alternativas: questao.alternativas,
                respostaCorreta: questao.respostaCorreta,
              ),
          ],
          materia: materia.nome,
          turma: turma,
          provaNome: nome,
        );
      }),
    );
  }

  return [
    montar(
      id: 'pg_mock3',
      nome: 'Recuperação — Biologia',
      materiaId: 'mat3',
      indiceTurma: 2,
      quantasVersoes: 2,
      diasAtras: 21,
    ),
    montar(
      id: 'pg_mock2',
      nome: 'Avaliação de História',
      materiaId: 'mat2',
      indiceTurma: 1,
      quantasVersoes: 3,
      diasAtras: 9,
    ),
    montar(
      id: 'pg_mock1',
      nome: 'P1 — Matemática',
      materiaId: 'mat1',
      indiceTurma: 0,
      quantasVersoes: 4,
      diasAtras: 2,
    ),
  ];
}

Future<ProvaRepositoryMemoria> criarProvaRepositoryMemoriaComMocks() async {
  final repo = ProvaRepositoryMemoria();
  for (final prova in provasDeExemplo().reversed) {
    await repo.criar(prova);
  }
  return repo;
}


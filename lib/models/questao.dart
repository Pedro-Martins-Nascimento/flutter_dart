// lib/models/questao.dart
//
// Modelos e banco mock de questões (RF08). Separado das telas pra ser
// fácil de editar/adicionar questão sem mexer em código de UI.

class Materia {
  final String id;
  final String nome;

  Materia({required this.id, required this.nome});
}

class Questao {
  final String id;
  final String materiaId;
  final String enunciado;
  final List<String> alternativas; // sempre 4
  final int respostaCorreta; // índice da alternativa certa em `alternativas`

  Questao({
    required this.id,
    required this.materiaId,
    required this.enunciado,
    required this.alternativas,
    required this.respostaCorreta,
  })  : assert(alternativas.length == 4, 'Toda questão tem exatamente 4 alternativas'),
        assert(
          respostaCorreta >= 0 && respostaCorreta < alternativas.length,
          'respostaCorreta precisa apontar pra uma alternativa que existe',
        );
}

// RF09 — modo de geração da prova.
enum ModoProva {
  mesmaEmbaralhada,
  conjuntosDiferentes,
}

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
  // ---- Matemática ----
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
    enunciado: 'Qual o valor de x na equação 2x + 4 = 10?',
    alternativas: ['2', '3', '4', '6'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q4',
    materiaId: 'mat1',
    enunciado: 'Quanto é 15% de 200?',
    alternativas: ['20', '25', '30', '35'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q5',
    materiaId: 'mat1',
    enunciado:
        'Em uma progressão aritmética de razão 3, começando em 2, qual é o 5º termo?',
    alternativas: ['11', '12', '14', '17'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q6',
    materiaId: 'mat1',
    enunciado: 'Qual é a área de um retângulo de base 8 cm e altura 5 cm?',
    alternativas: ['13 cm²', '40 cm²', '45 cm²', '80 cm²'],
    respostaCorreta: 1,
  ),

  // ---- História ----
  Questao(
    id: 'q7',
    materiaId: 'mat2',
    enunciado: 'Em que ano começou a 2ª Guerra Mundial?',
    alternativas: ['1935', '1939', '1941', '1945'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q8',
    materiaId: 'mat2',
    enunciado: 'Quem proclamou a independência do Brasil?',
    alternativas: ['D. João VI', 'D. Pedro I', 'D. Pedro II', 'Tiradentes'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q9',
    materiaId: 'mat2',
    enunciado: 'Qual evento marcou o fim do regime monárquico no Brasil?',
    alternativas: [
      'Independência (1822)',
      'Abolição da Escravatura (1888)',
      'Proclamação da República (1889)',
      'Revolução de 1930',
    ],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q10',
    materiaId: 'mat2',
    enunciado: 'A Revolução Francesa teve início em que ano?',
    alternativas: ['1776', '1789', '1804', '1815'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q11',
    materiaId: 'mat2',
    enunciado: 'Qual foi o estopim da Primeira Guerra Mundial?',
    alternativas: [
      'A crise econômica de 1929',
      'O assassinato do Arquiduque Francisco Ferdinando',
      'A Guerra Fria',
      'A Revolução Russa',
    ],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q12',
    materiaId: 'mat2',
    enunciado: 'O que foi a Lei Áurea, de 1888?',
    alternativas: [
      'Concedeu direito de voto às mulheres',
      'Aboliu a escravidão no Brasil',
      'Proclamou a República',
      'Criou a primeira Constituição republicana',
    ],
    respostaCorreta: 1,
  ),

  // ---- Biologia ----
  Questao(
    id: 'q13',
    materiaId: 'mat3',
    enunciado: 'O que é fotossíntese?',
    alternativas: [
      'A respiração celular das plantas',
      'O processo em que plantas convertem luz solar em energia química',
      'A digestão de nutrientes pelos vegetais',
      'A reprodução sexuada das plantas',
    ],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q14',
    materiaId: 'mat3',
    enunciado: 'Qual a função das mitocôndrias na célula?',
    alternativas: [
      'Síntese de proteínas',
      'Armazenamento de água',
      'Produção de energia (respiração celular)',
      'Divisão celular',
    ],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q15',
    materiaId: 'mat3',
    enunciado: 'Qual é a unidade básica da vida?',
    alternativas: ['Átomo', 'Célula', 'Tecido', 'Órgão'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q16',
    materiaId: 'mat3',
    enunciado:
        'Qual grupo de organismos é responsável por decompor a matéria orgânica morta?',
    alternativas: ['Produtores', 'Consumidores', 'Decompositores', 'Herbívoros'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q17',
    materiaId: 'mat3',
    enunciado: 'O DNA é composto por quantos tipos de bases nitrogenadas?',
    alternativas: ['2', '3', '4', '5'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q18',
    materiaId: 'mat3',
    enunciado:
        'Qual sistema do corpo humano é responsável pelo transporte de oxigênio e nutrientes?',
    alternativas: [
      'Sistema digestório',
      'Sistema circulatório',
      'Sistema respiratório',
      'Sistema nervoso',
    ],
    respostaCorreta: 1,
  ),

  // ---- Português ----
  Questao(
    id: 'q19',
    materiaId: 'mat4',
    enunciado: 'Qual das alternativas apresenta um substantivo próprio?',
    alternativas: ['cidade', 'São Paulo', 'rapidamente', 'bonito'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q20',
    materiaId: 'mat4',
    enunciado: 'Assinale a frase escrita na voz passiva.',
    alternativas: [
      'O menino comeu a maçã.',
      'A maçã foi comida pelo menino.',
      'O menino vai comer a maçã.',
      'O menino come a maçã.',
    ],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q21',
    materiaId: 'mat4',
    enunciado: 'Que figura de linguagem aparece em "Seus olhos são duas estrelas"?',
    alternativas: ['Metonímia', 'Metáfora', 'Hipérbole', 'Ironia'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q22',
    materiaId: 'mat4',
    enunciado: 'Qual é o plural correto de "cidadão"?',
    alternativas: ['cidadãos', 'cidadães', 'cidadons', 'cidadaos'],
    respostaCorreta: 0,
  ),
  Questao(
    id: 'q23',
    materiaId: 'mat4',
    enunciado:
        'Assinale a alternativa com um verbo no pretérito perfeito do indicativo.',
    alternativas: ['eu como', 'eu comia', 'eu comi', 'eu comerei'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q24',
    materiaId: 'mat4',
    enunciado:
        'Qual a classe gramatical da palavra destacada em "Ele correu RAPIDAMENTE até a escola"?',
    alternativas: ['Substantivo', 'Adjetivo', 'Advérbio', 'Pronome'],
    respostaCorreta: 2,
  ),

  // ---- Geografia ----
  Questao(
    id: 'q25',
    materiaId: 'mat5',
    enunciado: 'Qual é o maior país do mundo em extensão territorial?',
    alternativas: ['Canadá', 'China', 'Rússia', 'Estados Unidos'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q26',
    materiaId: 'mat5',
    enunciado: 'Qual é o maior bioma brasileiro em extensão territorial?',
    alternativas: ['Cerrado', 'Mata Atlântica', 'Amazônia', 'Caatinga'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q27',
    materiaId: 'mat5',
    enunciado:
        'Qual linha imaginária divide a Terra nos hemisférios norte e sul?',
    alternativas: [
      'Meridiano de Greenwich',
      'Linha do Equador',
      'Trópico de Câncer',
      'Círculo Polar Ártico',
    ],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q28',
    materiaId: 'mat5',
    enunciado: 'Qual é a capital da Austrália?',
    alternativas: ['Sydney', 'Melbourne', 'Camberra', 'Perth'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q29',
    materiaId: 'mat5',
    enunciado:
        'O fenômeno El Niño está relacionado ao aquecimento das águas de qual oceano?',
    alternativas: ['Atlântico', 'Índico', 'Pacífico', 'Ártico'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q30',
    materiaId: 'mat5',
    enunciado: 'Qual é o continente mais populoso do mundo?',
    alternativas: ['África', 'Ásia', 'Europa', 'América'],
    respostaCorreta: 1,
  ),

  // ---- Física ----
  Questao(
    id: 'q31',
    materiaId: 'mat6',
    enunciado: 'Qual é a unidade de medida de força no Sistema Internacional?',
    alternativas: ['Joule', 'Newton', 'Watt', 'Pascal'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q32',
    materiaId: 'mat6',
    enunciado: 'A velocidade da luz no vácuo é aproximadamente:',
    alternativas: ['300 mil km/s', '300 mil m/s', '3 mil km/s', '30 mil km/s'],
    respostaCorreta: 0,
  ),
  Questao(
    id: 'q33',
    materiaId: 'mat6',
    enunciado: 'Pela 1ª Lei de Newton (inércia), um corpo em repouso:',
    alternativas: [
      'Tende a se mover sozinho',
      'Permanece em repouso, a menos que uma força atue sobre ele',
      'Acelera infinitamente',
      'Perde massa com o tempo',
    ],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q34',
    materiaId: 'mat6',
    enunciado: 'Qual grandeza física mede a quantidade de matéria de um corpo?',
    alternativas: ['Peso', 'Massa', 'Densidade', 'Volume'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q35',
    materiaId: 'mat6',
    enunciado: 'O que é energia cinética?',
    alternativas: [
      'Energia armazenada por um corpo em repouso',
      'Energia associada ao movimento de um corpo',
      'Energia gerada por reações químicas',
      'Energia armazenada em campos elétricos',
    ],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q36',
    materiaId: 'mat6',
    enunciado: 'Qual é a fórmula da densidade?',
    alternativas: ['d = m/v', 'd = v/m', 'd = m × v', 'd = m + v'],
    respostaCorreta: 0,
  ),

  // ---- Química ----
  Questao(
    id: 'q37',
    materiaId: 'mat7',
    enunciado: 'Qual é o símbolo químico do ouro?',
    alternativas: ['Au', 'Ag', 'O', 'Fe'],
    respostaCorreta: 0,
  ),
  Questao(
    id: 'q38',
    materiaId: 'mat7',
    enunciado: 'O que é um átomo?',
    alternativas: [
      'A menor partícula que mantém as propriedades de um elemento',
      'Uma molécula formada por dois átomos',
      'Uma mistura de substâncias',
      'Um tipo de ligação química',
    ],
    respostaCorreta: 0,
  ),
  Questao(
    id: 'q39',
    materiaId: 'mat7',
    enunciado: 'Qual é o pH aproximado de uma solução neutra?',
    alternativas: ['0', '7', '14', '10'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q40',
    materiaId: 'mat7',
    enunciado: 'Qual gás é essencial para a respiração humana?',
    alternativas: ['Gás carbônico', 'Nitrogênio', 'Oxigênio', 'Hidrogênio'],
    respostaCorreta: 2,
  ),
  Questao(
    id: 'q41',
    materiaId: 'mat7',
    enunciado: 'O que caracteriza uma reação exotérmica?',
    alternativas: [
      'Absorve calor do ambiente',
      'Libera calor para o ambiente',
      'Não envolve troca de energia',
      'Ocorre apenas em solução aquosa',
    ],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q42',
    materiaId: 'mat7',
    enunciado: 'Qual é a fórmula química da água?',
    alternativas: ['H2O', 'CO2', 'O2', 'NaCl'],
    respostaCorreta: 0,
  ),

  // ---- Inglês ----
  Questao(
    id: 'q43',
    materiaId: 'mat8',
    enunciado: 'Choose the correct translation for "livro":',
    alternativas: ['Book', 'Pen', 'Table', 'Chair'],
    respostaCorreta: 0,
  ),
  Questao(
    id: 'q44',
    materiaId: 'mat8',
    enunciado: 'Complete: "She ___ to school every day."',
    alternativas: ['go', 'goes', 'going', 'gone'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q45',
    materiaId: 'mat8',
    enunciado: 'What is the past tense of "go"?',
    alternativas: ['goed', 'went', 'gone', 'going'],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q46',
    materiaId: 'mat8',
    enunciado: 'Choose the correctly formed question:',
    alternativas: [
      'Where you are from?',
      'Where are you from?',
      'From where you are?',
      'You are from where?',
    ],
    respostaCorreta: 1,
  ),
  Questao(
    id: 'q47',
    materiaId: 'mat8',
    enunciado: 'What does "friendly" mean?',
    alternativas: ['Amigável', 'Rápido', 'Distante', 'Triste'],
    respostaCorreta: 0,
  ),
  Questao(
    id: 'q48',
    materiaId: 'mat8',
    enunciado: 'Choose the correct plural of "child":',
    alternativas: ['childs', 'children', 'childes', 'child'],
    respostaCorreta: 1,
  ),
];

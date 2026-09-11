// Round-trip da persistência local (RF-suporte, sem número no Notion):
// salva um snapshot do estado e confere que recarregar restaura tudo
// (matérias, questões, turmas com alunos, provas geradas e correções).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dart/models/questao.dart';
import 'package:flutter_dart/screens/provas/gerar_provas_screen.dart';
import 'package:flutter_dart/screens/turmas/criar_turma_screen.dart';
import 'package:flutter_dart/services/correcoes_repository.dart';
import 'package:flutter_dart/services/persistencia_service.dart';
import 'package:flutter_dart/services/provas_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('salvar() e carregar() fazem ida e volta sem perder dado', () async {
    // Acessa os singletons ANTES de mexer nas listas mock — a primeira
    // vez que `ProvasRepository.instance` é criada, ela monta 3 provas
    // de exemplo a partir de `materiasMock`/`turmasMock` originais; se a
    // gente já tivesse limpo essas listas, essa montagem quebraria.
    // ignore: unnecessary_statements
    ProvasRepository.instance;
    // ignore: unnecessary_statements
    CorrecoesRepository.instance;

    materiasMock.add(Materia(id: 'matX', nome: 'Matéria Teste'));

    final questaoTeste = Questao(
      id: 'qX',
      materiaId: 'matX',
      enunciado: 'Pergunta de teste?',
      alternativas: ['A', 'B', 'C'],
      respostaCorreta: 1,
    );
    questoesMock.add(questaoTeste);

    turmasMock.add(
      Turma(
        id: 'turmaX',
        nome: 'Turma Teste',
        qtdAlunos: 1,
        qtdProvas: 0,
        alunos: [AlunoTurma(id: 'alX', nome: 'Aluno Teste', matricula: '123')],
      ),
    );

    final versao = VersaoProva(
      id: 'v1',
      qrCode: 'QR-TESTE',
      questoes: [
        QuestaoNaVersao(
          questao: questaoTeste,
          alternativas: questaoTeste.alternativas,
          respostaCorreta: 1,
        ),
      ],
      materia: 'Matéria Teste',
      turma: 'Turma Teste',
      provaNome: 'Prova Teste',
    );
    ProvasRepository.instance.importarDePersistencia([
      ProvaGerada(
        id: 'provaX',
        nome: 'Prova Teste',
        materia: 'Matéria Teste',
        turma: 'Turma Teste',
        criadoEm: DateTime(2026, 1, 1),
        versoes: [versao],
      ),
    ]);

    CorrecoesRepository.instance.importarDePersistencia([
      Correcao(
        id: 'corX',
        versao: versao,
        provaNome: 'Prova Teste',
        materia: 'Matéria Teste',
        turma: 'Turma Teste',
        alunoNome: 'Aluno Teste',
        corrigidoEm: DateTime(2026, 1, 2),
        respostas: [RespostaQuestao(alternativaMarcada: 1, correta: true)],
      ),
    ]);

    // Inicializa o serviço (pega a instância mockada do SharedPreferences)
    // e tira o snapshot de tudo o que foi montado acima.
    await PersistenciaService.instance.carregar();
    PersistenciaService.instance.salvar();

    // Simula reabrir o app do zero: limpa tudo em memória.
    materiasMock.clear();
    questoesMock.clear();
    turmasMock.clear();
    ProvasRepository.instance.importarDePersistencia([]);
    CorrecoesRepository.instance.importarDePersistencia([]);

    await PersistenciaService.instance.carregar();

    expect(materiasMock.where((m) => m.nome == 'Matéria Teste'), hasLength(1));

    expect(
      questoesMock.where((q) => q.enunciado == 'Pergunta de teste?'),
      hasLength(1),
    );

    final turmaRestaurada = turmasMock.firstWhere((t) => t.nome == 'Turma Teste');
    expect(turmaRestaurada.alunos.single.nome, 'Aluno Teste');

    final provaRestaurada = ProvasRepository.instance.provas.firstWhere(
      (p) => p.nome == 'Prova Teste',
    );
    expect(provaRestaurada.versoes.single.qrCode, 'QR-TESTE');

    expect(CorrecoesRepository.instance.correcoes, hasLength(1));
    expect(CorrecoesRepository.instance.correcoes.single.nota, 10.0);
    expect(CorrecoesRepository.instance.correcoes.single.alunoNome, 'Aluno Teste');
  });
}

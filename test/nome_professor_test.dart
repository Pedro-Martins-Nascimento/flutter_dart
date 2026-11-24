import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nome do professor na prova', () {
    test('usa o nome do cadastro ou da conta Google', () {
      expect(AuthService.nomeDoProfessor(['Ana Souza']), 'Ana Souza');
    });

    test('sem nome no usuário, usa o nome do provedor (Google)', () {
      expect(
        AuthService.nomeDoProfessor([null, '  ', 'Ana Souza']),
        'Ana Souza',
      );
    });

    test('nunca usa um e-mail como nome', () {
      expect(
        AuthService.nomeDoProfessor(['ana@gmail.com']),
        VersaoProva.professorPadrao,
      );
    });

    test('sem nome fica o texto padrão', () {
      expect(AuthService.nomeDoProfessor([]), VersaoProva.professorPadrao);
    });
  });

  group('versão salva com o texto padrão', () {
    VersaoProva versao(String professor) => VersaoProva(
      id: 'v1',
      qrCode: 'qr',
      questoes: const [],
      professor: professor,
      turma: '9A',
      provaNome: 'P1',
    );

    test('troca "Prof. responsável" pelo nome de quem está logado', () {
      final nova = versao(VersaoProva.professorPadrao)
          .comProfessorSePadrao('Ana Souza');
      expect(nova.professor, 'Ana Souza');
      expect(nova.qrCode, 'qr');
      expect(nova.turma, '9A');
      expect(nova.provaNome, 'P1');
    });

    test('troca um e-mail gravado antes pelo nome', () {
      expect(
        versao('ana@gmail.com').comProfessorSePadrao('Ana Souza').professor,
        'Ana Souza',
      );
    });

    test('não troca um nome que já estava gravado', () {
      final original = versao('Carlos Lima');
      expect(
        original.comProfessorSePadrao('Ana Souza').professor,
        'Carlos Lima',
      );
    });
  });
}

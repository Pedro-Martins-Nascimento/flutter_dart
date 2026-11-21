import 'package:flutter_dart/models/versao_prova.dart';
import 'package:flutter_dart/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nome do professor na prova', () {
    test('cadastro com e-mail e senha usa o nome do cadastro', () {
      expect(
        AuthService.nomeDoProfessor(
          nome: 'Ana Souza',
          email: 'ana@escola.edu.br',
          google: false,
        ),
        'Ana Souza',
      );
    });

    test('cadastro sem nome cai para o e-mail', () {
      expect(
        AuthService.nomeDoProfessor(
          nome: '  ',
          email: 'ana@escola.edu.br',
          google: false,
        ),
        'ana@escola.edu.br',
      );
    });

    test('login pelo Google usa o e-mail da conta', () {
      expect(
        AuthService.nomeDoProfessor(
          nome: 'Ana Souza',
          email: 'ana@gmail.com',
          google: true,
        ),
        'ana@gmail.com',
      );
    });

    test('sem nome nem e-mail fica o texto padrão', () {
      expect(
        AuthService.nomeDoProfessor(nome: null, email: null, google: false),
        VersaoProva.professorPadrao,
      );
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

    test('não troca um nome que já estava gravado', () {
      final original = versao('Carlos Lima');
      expect(
        original.comProfessorSePadrao('Ana Souza').professor,
        'Carlos Lima',
      );
    });
  });
}

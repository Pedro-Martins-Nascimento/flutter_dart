import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Client OAuth "web" do projeto (client_type 3 no google-services.json).
// O login nativo do Android precisa dele pra gerar o idToken do Firebase.
const _googleServerClientId =
    '184286969361-hjuetttnb9ntdpiqmjiamevhr97eoob9.apps.googleusercontent.com';

class AuthErro implements Exception {
  final String mensagem;

  const AuthErro(this.mensagem);

  @override
  String toString() => mensagem;
}

class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? auth, Future<String?> Function()? tokenGoogle})
    : _auth = auth ?? FirebaseAuth.instance,
      _tokenGoogle = tokenGoogle ?? _tokenGoogleNativo {
    _usuario = _auth.currentUser;
    _inscricao = _auth.authStateChanges().listen((usuario) {
      _usuario = usuario;
      notifyListeners();
    });
  }

  final FirebaseAuth _auth;
  final Future<String?> Function() _tokenGoogle;
  late final StreamSubscription<User?> _inscricao;
  User? _usuario;

  User? get usuario => _usuario;
  bool get logado => _usuario != null;

  Future<void> entrarComEmail(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
    } on FirebaseAuthException catch (e) {
      throw AuthErro(_mensagem(e.code));
    }
  }

  Future<void> entrarComGoogle() async {
    try {
      if (kIsWeb) {
        final provedor = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        await _auth.signInWithPopup(provedor);
        return;
      }

      // No celular, o signInWithProvider passa pelo navegador e perde a
      // sessão quando ele não é o Chrome ("falta do estado inicial").
      // O login nativo do Google evita o navegador.
      final idToken = await _tokenGoogle();
      if (idToken == null) throw const AuthErro('Login com Google cancelado.');
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthErro(_mensagem(e.code));
    } on GoogleSignInException catch (e) {
      throw AuthErro(
        e.code == GoogleSignInExceptionCode.canceled
            ? 'Login com Google cancelado.'
            : 'Não foi possível entrar com o Google. Tente novamente.',
      );
    }
  }

  static bool _googleIniciado = false;

  static Future<String?> _tokenGoogleNativo() async {
    final google = GoogleSignIn.instance;
    if (!_googleIniciado) {
      await google.initialize(serverClientId: _googleServerClientId);
      _googleIniciado = true;
    }
    final conta = await google.authenticate();
    return conta.authentication.idToken;
  }

  Future<void> sair() async {
    // Sem isso, o próximo login reaproveita a mesma conta do Google.
    if (_googleIniciado) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  String _mensagem(String codigo) {
    switch (codigo) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'E-mail ou senha incorretos.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente em alguns minutos.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-canceled':
      case 'canceled':
        return 'Login com Google cancelado.';
      case 'operation-not-allowed':
        return 'Este método de login não está habilitado no Firebase.';
      default:
        return 'Não foi possível entrar. Tente novamente.';
    }
  }

  @override
  void dispose() {
    _inscricao.cancel();
    super.dispose();
  }
}

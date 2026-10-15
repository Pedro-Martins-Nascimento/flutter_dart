import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthErro implements Exception {
  final String mensagem;

  const AuthErro(this.mensagem);

  @override
  String toString() => mensagem;
}

class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _usuario = _auth.currentUser;
    _inscricao = _auth.authStateChanges().listen((usuario) {
      _usuario = usuario;
      notifyListeners();
    });
  }

  final FirebaseAuth _auth;
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
    final provedor = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(provedor);
      } else {
        await _auth.signInWithProvider(provedor);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthErro(_mensagem(e.code));
    }
  }

  Future<void> sair() => _auth.signOut();

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

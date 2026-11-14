import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConexaoService extends ChangeNotifier {
  ConexaoService({this.connectivity, bool? onlineInicial}) {
    if (onlineInicial != null) {
      _online = onlineInicial;
    } else {
      _iniciar();
    }
  }

  final Connectivity? connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;

  bool get online => _online;
  bool get offline => !_online;

  Connectivity get _instancia => connectivity ?? Connectivity();

  Future<void> _iniciar() async {
    try {
      final status = await _instancia.checkConnectivity();
      _atualizarStatus(status);
      _subscription = _instancia.onConnectivityChanged.listen(_atualizarStatus);
    } catch (_) {
      // Se falhar ao checar conectividade, assume online como padrão defensivo.
      _online = true;
    }
  }

  void _atualizarStatus(List<ConnectivityResult> resultados) {
    final conectado = resultados.any(
      (r) => r != ConnectivityResult.none,
    );
    if (_online != conectado) {
      _online = conectado;
      notifyListeners();
    }
  }

  @visibleForTesting
  void definirOnline(bool valor) {
    if (_online != valor) {
      _online = valor;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

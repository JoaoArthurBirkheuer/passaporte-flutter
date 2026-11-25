import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConectividadeService {
  ConectividadeService._();

  static final ConectividadeService instance = ConectividadeService._();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _iniciado = false;

  Future<void> iniciar() async {
    if (_iniciado) return;
    _iniciado = true;

    try {
      final resultados = await _connectivity.checkConnectivity();
      offline.value = _semConexao(resultados);
      _sub = _connectivity.onConnectivityChanged.listen((resultados) {
        offline.value = _semConexao(resultados);
      });
    } catch (_) {
      // Se o plugin não estiver disponível, mantém o estado online.
    }
  }

  bool _semConexao(List<ConnectivityResult> resultados) {
    return resultados.isEmpty || resultados.contains(ConnectivityResult.none);
  }

  void dispose() {
    _sub?.cancel();
    offline.dispose();
  }
}

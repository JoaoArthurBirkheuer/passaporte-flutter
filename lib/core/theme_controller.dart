import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();
  static const String _chave = 'tema';

  ThemeMode _modo = ThemeMode.system;

  ThemeMode get modo => _modo;

  String get rotulo {
    switch (_modo) {
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
    }
  }

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString(_chave);
    _modo = switch (valor) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> definir(ThemeMode modo) async {
    if (_modo == modo) return;
    _modo = modo;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, modo.name);
  }
}

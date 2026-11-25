class AiConfig {
  AiConfig._();

  static const List<String> modelos = [
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-3.5-flash',
  ];

  static const int tentativasPorModelo = 2;

  static const Duration esperaEntreTentativas = Duration(milliseconds: 600);
}

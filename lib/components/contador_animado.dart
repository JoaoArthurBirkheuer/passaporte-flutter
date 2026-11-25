import 'package:flutter/material.dart';

class ContadorAnimado extends StatelessWidget {
  const ContadorAnimado({
    super.key,
    required this.valor,
    this.decimais = 0,
    this.duracao = const Duration(milliseconds: 600),
    this.style,
  });

  final double valor;
  final int decimais;
  final Duration duracao;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final animar = !MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: valor),
      duration: animar ? duracao : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, atual, _) {
        return Text(
          atual.toStringAsFixed(decimais),
          style: style,
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

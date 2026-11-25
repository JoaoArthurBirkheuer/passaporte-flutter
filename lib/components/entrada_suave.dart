import 'package:flutter/material.dart';

class EntradaSuave extends StatelessWidget {
  const EntradaSuave({
    super.key,
    required this.child,
    this.deslocamento = 12,
    this.duracao = const Duration(milliseconds: 260),
  });

  final Widget child;
  final double deslocamento;
  final Duration duracao;

  @override
  Widget build(BuildContext context) {
    final animar = !MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: animar ? duracao : Duration.zero,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, valor, filho) {
        return Opacity(
          opacity: valor.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - valor) * deslocamento),
            child: filho,
          ),
        );
      },
    );
  }
}

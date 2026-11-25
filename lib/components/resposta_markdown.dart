import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class RespostaMarkdown extends StatelessWidget {
  const RespostaMarkdown({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme;
    final scheme = theme.colorScheme;

    return MarkdownBody(
      data: texto,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: base.bodyLarge,
        strong: base.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        em: base.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
        listBullet: base.bodyLarge,
        h1: base.headlineSmall,
        h2: base.titleLarge,
        h3: base.titleMedium,
        blockSpacing: 8,
        code: base.bodyMedium?.copyWith(
          backgroundColor: scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

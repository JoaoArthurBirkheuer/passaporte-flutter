import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/estado_vazio.dart';
import '../components/resposta_markdown.dart';
import '../core/formatadores.dart';
import '../models/historico_ia.dart';
import '../services/historico_ia_service.dart';

class HistoricoIaScreen extends StatefulWidget {
  const HistoricoIaScreen({super.key});

  @override
  State<HistoricoIaScreen> createState() => _HistoricoIaScreenState();
}

class _HistoricoIaScreenState extends State<HistoricoIaScreen> {
  final HistoricoIaService _historicoService = HistoricoIaService();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _excluir(HistoricoIa historico) async {
    final uid = _uid;
    if (uid == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir do histórico?'),
          content: const Text(
            'Essa solicitação e a resposta da IA serão removidas permanentemente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Excluir',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmado != true || !mounted) return;

    try {
      await _historicoService.excluir(uid, historico.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Histórico atualizado.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o item.')),
      );
    }
  }

  IconData _iconeTipo(String tipo) {
    switch (tipo) {
      case 'roteiro':
        return Icons.route_outlined;
      case 'resumo':
        return Icons.auto_stories_outlined;
      default:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Entre para ver o histórico.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico da IA')),
      body: StreamBuilder<List<HistoricoIa>>(
        stream: _historicoService.streamHistorico(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const EstadoVazio(
              icone: Icons.cloud_off_outlined,
              titulo: 'Não foi possível carregar o histórico',
              subtitulo: 'Verifique sua conexão e tente novamente.',
            );
          }

          final itens = snapshot.data ?? const <HistoricoIa>[];
          if (itens.isEmpty) {
            return const EstadoVazio(
              icone: Icons.history,
              titulo: 'Nenhuma solicitação ainda',
              subtitulo:
                  'Quando você gerar dicas, roteiros ou resumos, eles aparecerão aqui.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: itens.length,
            itemBuilder: (context, index) {
              final item = itens[index];
              final scheme = Theme.of(context).colorScheme;

              return Card(
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: CircleAvatar(
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      _iconeTipo(item.tipo),
                      color: scheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.rotuloTipo,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${formatarDataHora(item.criadoEm)} • ${item.prompt}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  children: [
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Solicitação',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      item.prompt,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Resposta',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RespostaMarkdown(texto: item.resposta),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _excluir(item),
                        icon: Icon(Icons.delete_outline, color: scheme.error),
                        label: Text(
                          'Excluir',
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

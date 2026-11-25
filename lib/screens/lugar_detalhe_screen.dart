import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../components/seletor_local_mapa.dart';
import '../core/categorias.dart';
import '../core/formatadores.dart';
import '../models/lugar.dart';
import '../services/lugar_service.dart';
import 'ia_screen.dart';
import 'lugar_form_screen.dart';

class LugarDetalheScreen extends StatefulWidget {
  const LugarDetalheScreen({super.key, required this.lugar});

  final Lugar lugar;

  @override
  State<LugarDetalheScreen> createState() => _LugarDetalheScreenState();
}

class _LugarDetalheScreenState extends State<LugarDetalheScreen> {
  final LugarService _lugarService = LugarService();
  late Lugar _lugar;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _lugar = widget.lugar;
  }

  Future<void> _editar() async {
    final atualizou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LugarFormScreen(lugar: _lugar)),
    );
    if (atualizou != true) return;

    final uid = _uid;
    if (uid == null) return;
    final novo = await _lugarService.buscar(uid, _lugar.id);
    if (novo != null && mounted) {
      setState(() => _lugar = novo);
    }
  }

  Future<void> _excluir() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir lugar?'),
          content: Text(
            'Tem certeza que deseja excluir "${_lugar.nome}"? Essa ação não pode ser desfeita.',
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
    final uid = _uid;
    if (uid == null) return;

    try {
      await _lugarService.excluir(uid, _lugar.id);
      HapticFeedback.lightImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lugar excluído.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o lugar.')),
      );
    }
  }

  void _pedirDicasIa() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => IaScreen(lugarInicial: _lugar)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coordenada = LatLng(_lugar.latitude, _lugar.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(_lugar.nome, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: _editar,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir',
            onPressed: _excluir,
            icon: Icon(Icons.delete_outline, color: scheme.error),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Hero(
                            tag: 'lugar-${_lugar.id}',
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                iconeCategoria(_lugar.categoria),
                                color: scheme.primary,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lugar.categoria,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: scheme.primary),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _StatusChip(planejado: _lugar.planejado),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _lugar.planejado
                                            ? 'Previsto para ${formatarData(_lugar.dataVisita)}'
                                            : formatarData(_lugar.dataVisita),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  for (var i = 1; i <= 5; i++)
                                    Icon(
                                      i <= _lugar.avaliacao
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 18,
                                      color: const Color(0xFFF59E0B),
                                    ),
                                ],
                              ),
                              Text(
                                '${_lugar.avaliacao}/5',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_lugar.endereco.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _lugar.endereco,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SeletorLocalMapa(
                valor: coordenada,
                onChanged: (_) {},
                interativo: false,
                altura: 230,
              ),
              const SizedBox(height: 8),
              Text(
                'Lat ${formatarCoordenada(_lugar.latitude)} • '
                'Lng ${formatarCoordenada(_lugar.longitude)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notes_outlined,
                            color: scheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Minhas anotações',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _lugar.descricao.trim().isEmpty
                            ? 'Você ainda não escreveu anotações sobre este lugar.'
                            : _lugar.descricao,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pedirDicasIa,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Pedir dicas à IA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.planejado});

  final bool planejado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cor = planejado
        ? scheme.onTertiaryContainer
        : scheme.onPrimaryContainer;
    final fundo = planejado
        ? scheme.tertiaryContainer
        : scheme.primaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        planejado ? 'Planejado' : 'Visitado',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

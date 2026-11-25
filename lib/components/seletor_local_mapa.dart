import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/formatadores.dart';

class SeletorLocalMapa extends StatefulWidget {
  const SeletorLocalMapa({
    super.key,
    required this.valor,
    required this.onChanged,
    this.altura = 250,
    this.centroInicial = const LatLng(-23.550520, -46.633308),
    this.interativo = true,
  });

  final LatLng? valor;
  final ValueChanged<LatLng> onChanged;
  final double altura;
  final LatLng centroInicial;
  final bool interativo;

  @override
  State<SeletorLocalMapa> createState() => _SeletorLocalMapaState();
}

class _SeletorLocalMapaState extends State<SeletorLocalMapa> {
  final MapController _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoom(double delta) {
    final camera = _controller.camera;
    _controller.move(camera.center, (camera.zoom + delta).clamp(2.0, 18.0));
  }

  @override
  void didUpdateWidget(covariant SeletorLocalMapa oldWidget) {
    super.didUpdateWidget(oldWidget);
    final valor = widget.valor;
    if (valor != null && oldWidget.valor != valor) {
      _controller.move(valor, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valor = widget.valor;
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: widget.altura,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: valor ?? widget.centroInicial,
                initialZoom: 15,
                onTap: widget.interativo
                    ? (_, point) => widget.onChanged(point)
                    : null,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.joaobirkheuer.diarioviagens',
                ),
                if (valor != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: valor,
                        width: 52,
                        height: 52,
                        child: Icon(
                          Icons.location_pin,
                          size: 48,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                const SimpleAttributionWidget(
                  source: Text('OpenStreetMap contributors'),
                ),
              ],
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        valor == null
                            ? 'Toque no mapa para escolher o local'
                            : 'Lat ${formatarCoordenada(valor.latitude)} • '
                                  'Lng ${formatarCoordenada(valor.longitude)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (!widget.interativo)
                      Icon(Icons.lock_outline, size: 16, color: scheme.outline),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 36,
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Aproximar',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _zoom(1),
                      icon: const Icon(Icons.add, size: 20),
                    ),
                    const Divider(height: 1),
                    IconButton(
                      tooltip: 'Afastar',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _zoom(-1),
                      icon: const Icon(Icons.remove, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

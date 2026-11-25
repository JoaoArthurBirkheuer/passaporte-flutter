import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/categorias.dart';
import '../core/formatadores.dart';
import '../core/mapa_memoria.dart';
import '../models/lugar.dart';
import '../services/conectividade_service.dart';
import '../services/geocoding_service.dart';
import '../services/localizacao_service.dart';
import '../services/lugar_service.dart';
import 'lugar_detalhe_screen.dart';
import 'lugar_form_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  static const LatLng _centroPadrao = LatLng(-23.550520, -46.633308);

  final MapController _mapController = MapController();
  final LugarService _lugarService = LugarService();
  final LocalizacaoService _localizacaoService = LocalizacaoService();
  final GeocodingService _geocodingService = GeocodingService();

  LatLng? _posicaoAtual;
  bool _carregandoLocalizacao = false;
  bool _ajustouMapa = false;
  String? _erroLocalizacao;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _geocodingService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _zoom(double delta) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + delta).clamp(2.0, 18.0));
  }

  void _verTodosLugares(List<Lugar> lugares) {
    if (lugares.isEmpty) return;
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: lugares
            .map((lugar) => LatLng(lugar.latitude, lugar.longitude))
            .toList(),
        padding: const EdgeInsets.all(60),
        maxZoom: 14,
      ),
    );
  }

  Future<void> _obterLocalizacao({bool moverMapa = false}) async {
    if (_carregandoLocalizacao) return;
    setState(() {
      _carregandoLocalizacao = true;
      _erroLocalizacao = null;
    });

    try {
      final posicao = await _localizacaoService.obterPosicaoAtual();
      final destino = LatLng(posicao.latitude, posicao.longitude);
      if (!mounted) return;
      setState(() => _posicaoAtual = destino);
      if (moverMapa) _mapController.move(destino, 15);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erroLocalizacao = e.toString());
    } finally {
      if (mounted) setState(() => _carregandoLocalizacao = false);
    }
  }

  Future<void> _mostrarAjudaLocalizacao() async {
    final tentarNovamente = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Como ativar a localização'),
          content: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No emulador Android:'),
              SizedBox(height: 4),
              Text('1. Clique nos três pontos (...) ao lado do emulador.'),
              Text('2. Abra a aba Location.'),
              Text('3. Informe latitude e longitude e clique em Set Location.'),
              SizedBox(height: 8),
              Text('Exemplo: -23.550520, -46.633308 (São Paulo).'),
              SizedBox(height: 12),
              Text(
                'No celular: ative o GPS e permita a localização para o app.',
              ),
              SizedBox(height: 8),
              Text('Via terminal: adb emu geo fix -46.633308 -23.550520'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Geolocator.openAppSettings();
              },
              child: const Text('Configurações do app'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Geolocator.openLocationSettings();
              },
              child: const Text('GPS'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Tentar novamente'),
            ),
          ],
        );
      },
    );

    if (tentarNovamente == true) {
      _obterLocalizacao(moverMapa: true);
    }
  }

  void _abrirDetalhe(Lugar lugar) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LugarDetalheScreen(lugar: lugar)));
  }

  Future<void> _adicionarNoPonto(LatLng ponto) async {
    final uid = _uid;
    if (uid == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LugarFormScreen(coordenadaInicial: ponto),
      ),
    );
  }

  Future<void> _novoLugar() async {
    final uid = _uid;
    if (uid == null) return;

    final centro = _mapController.camera.center;
    MapaMemoria.ultimoCentro = centro;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LugarFormScreen(centroInicial: centro)),
    );
  }

  Future<void> _abrirAcoesPonto(LatLng ponto) async {
    final uid = _uid;
    if (uid == null) return;

    MapaMemoria.ultimoCentro = ponto;

    final adicionar = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PontoSelecionadoSheet(
        ponto: ponto,
        geocodingService: _geocodingService,
      ),
    );

    if (adicionar == true && mounted) {
      await _adicionarNoPonto(ponto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<LugaresSnapshot>(
      stream: uid == null ? null : _lugarService.streamLugares(uid),
      builder: (context, snapshot) {
        final lugares = snapshot.data?.lugares ?? const <Lugar>[];

        if (!_ajustouMapa && lugares.isNotEmpty) {
          _ajustouMapa = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _mapController.fitCamera(
              CameraFit.coordinates(
                coordinates: lugares
                    .map((lugar) => LatLng(lugar.latitude, lugar.longitude))
                    .toList(),
                padding: const EdgeInsets.all(60),
                maxZoom: 14,
              ),
            );
          });
        }

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _posicaoAtual ?? _centroPadrao,
                initialZoom: 12.5,
                onTap: (_, ponto) => _abrirAcoesPonto(ponto),
                onLongPress: (_, ponto) => _adicionarNoPonto(ponto),
                onPositionChanged: (camera, _) {
                  MapaMemoria.ultimoCentro = camera.center;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.joaobirkheuer.diarioviagens',
                ),
                MarkerLayer(
                  markers: [
                    if (_posicaoAtual != null)
                      Marker(
                        point: _posicaoAtual!,
                        width: 28,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6),
                            ],
                          ),
                        ),
                      ),
                    ...lugares.map(
                      (lugar) => Marker(
                        point: LatLng(lugar.latitude, lugar.longitude),
                        width: 46,
                        height: 46,
                        child: GestureDetector(
                          onTap: () => _abrirDetalhe(lugar),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.primary,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6),
                              ],
                            ),
                            child: Icon(
                              iconeCategoria(lugar.categoria),
                              color: scheme.primary,
                              size: 23,
                            ),
                          ),
                        ),
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
              top: 12,
              left: 12,
              right: 12,
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildStatusCard(scheme, lugares.length),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Aproximar',
                          onPressed: () => _zoom(1),
                          icon: const Icon(Icons.add),
                        ),
                        const Divider(height: 1),
                        IconButton(
                          tooltip: 'Ver todos os lugares',
                          onPressed: lugares.isEmpty
                              ? null
                              : () => _verTodosLugares(lugares),
                          icon: const Icon(Icons.zoom_out_map),
                        ),
                        const Divider(height: 1),
                        IconButton(
                          tooltip: 'Afastar',
                          onPressed: () => _zoom(-1),
                          icon: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.small(
                    heroTag: 'minha-localizacao',
                    tooltip: 'Centralizar em mim',
                    backgroundColor: Colors.white,
                    foregroundColor: scheme.primary,
                    onPressed: _carregandoLocalizacao
                        ? null
                        : () => _obterLocalizacao(moverMapa: true),
                    child: _carregandoLocalizacao
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'novo-lugar-mapa',
                    onPressed: _novoLugar,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Novo lugar'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(ColorScheme scheme, int total) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.public, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          total == 1
                              ? '1 lugar no seu mapa'
                              : '$total lugares no seu mapa',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: ConectividadeService.instance.offline,
                        builder: (context, offline, _) {
                          if (!offline) return const SizedBox.shrink();
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  'Offline',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: scheme.onTertiaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _erroLocalizacao ??
                        (_posicaoAtual == null
                            ? 'Toque em "Centralizar em mim" para ativar sua localização.'
                            : 'Toque ou segure no mapa para adicionar um lugar'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (_erroLocalizacao != null)
              TextButton(
                onPressed: _mostrarAjudaLocalizacao,
                child: const Text('Resolver'),
              )
            else if (_posicaoAtual == null && !_carregandoLocalizacao)
              TextButton(
                onPressed: () => _obterLocalizacao(moverMapa: true),
                child: const Text('Ativar'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PontoSelecionadoSheet extends StatefulWidget {
  const _PontoSelecionadoSheet({
    required this.ponto,
    required this.geocodingService,
  });

  final LatLng ponto;
  final GeocodingService geocodingService;

  @override
  State<_PontoSelecionadoSheet> createState() => _PontoSelecionadoSheetState();
}

class _PontoSelecionadoSheetState extends State<_PontoSelecionadoSheet> {
  late final Future<EnderecoGeocodificado?> _endereco;

  @override
  void initState() {
    super.initState();
    _endereco = widget.geocodingService.reverse(
      latitude: widget.ponto.latitude,
      longitude: widget.ponto.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.add_location_alt_outlined,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adicionar lugar aqui?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lat ${formatarCoordenada(widget.ponto.latitude)} • '
                        'Lng ${formatarCoordenada(widget.ponto.longitude)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FutureBuilder<EnderecoGeocodificado?>(
              future: _endereco,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Buscando endereço...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                }

                final endereco = snapshot.data;
                if (endereco == null) {
                  return Text(
                    'Endereço não encontrado. Você pode adicionar mesmo assim.',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }

                return Row(
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
                        endereco.enderecoCompleto,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Adicionar lugar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

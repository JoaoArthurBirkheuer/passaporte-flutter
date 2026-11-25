import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../components/campo_formulario.dart';
import '../components/seletor_local_mapa.dart';
import '../core/categorias.dart';
import '../core/formatadores.dart';
import '../core/mapa_memoria.dart';
import '../models/lugar.dart';
import '../services/geocoding_service.dart';
import '../services/localizacao_service.dart';
import '../services/lugar_service.dart';

class LugarFormScreen extends StatefulWidget {
  const LugarFormScreen({
    super.key,
    this.lugar,
    this.coordenadaInicial,
    this.centroInicial,
  });

  final Lugar? lugar;
  final LatLng? coordenadaInicial;
  final LatLng? centroInicial;

  @override
  State<LugarFormScreen> createState() => _LugarFormScreenState();
}

class _LugarFormScreenState extends State<LugarFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final LugarService _lugarService = LugarService();
  final LocalizacaoService _localizacaoService = LocalizacaoService();
  final GeocodingService _geocodingService = GeocodingService();

  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _dataController = TextEditingController();
  final _categoriaPersonalizadaController = TextEditingController();

  String _categoria = 'Cidade';
  String _status = Lugar.statusVisitado;
  int _avaliacao = 4;
  DateTime _dataVisita = DateTime.now();
  LatLng? _coordenada;
  late final LatLng _centroMapa;
  String? _erroCoordenada;
  bool _salvando = false;
  bool _buscandoLocalizacao = false;
  bool _buscandoEndereco = false;
  bool _enderecoManual = false;
  Timer? _debounceEndereco;

  late final String _nomeInicial;
  late final String _descricaoInicial;
  late String _enderecoInicial;
  late final String _categoriaInicial;
  late final String _categoriaPersonalizadaInicial;
  late final String _statusInicial;
  late final int _avaliacaoInicial;
  late final DateTime _dataInicial;
  late final LatLng? _coordenadaInicial;

  bool get _editando => widget.lugar != null;

  @override
  void initState() {
    super.initState();
    _centroMapa = widget.centroInicial ?? MapaMemoria.ultimoCentro;
    final lugar = widget.lugar;
    if (lugar != null) {
      _nomeController.text = lugar.nome;
      _descricaoController.text = lugar.descricao;
      _enderecoController.text = lugar.endereco;
      _enderecoManual = lugar.endereco.trim().isNotEmpty;

      if (categoriasLugar.contains(lugar.categoria)) {
        _categoria = lugar.categoria;
      } else {
        _categoria = 'Outro';
        _categoriaPersonalizadaController.text = lugar.categoria;
      }

      _avaliacao = lugar.avaliacao;
      _status = lugar.status;
      _dataVisita = lugar.dataVisita;
      _coordenada = LatLng(lugar.latitude, lugar.longitude);

      if (lugar.endereco.trim().isEmpty) {
        _agendarBuscaEndereco(_coordenada!);
      }
    } else if (widget.coordenadaInicial != null) {
      _coordenada = widget.coordenadaInicial;
      _agendarBuscaEndereco(_coordenada!);
    }
    _dataController.text = formatarData(_dataVisita);

    _nomeInicial = _nomeController.text;
    _descricaoInicial = _descricaoController.text;
    _enderecoInicial = _enderecoController.text;
    _categoriaInicial = _categoria;
    _categoriaPersonalizadaInicial = _categoriaPersonalizadaController.text;
    _statusInicial = _status;
    _avaliacaoInicial = _avaliacao;
    _dataInicial = DateTime(
      _dataVisita.year,
      _dataVisita.month,
      _dataVisita.day,
    );
    _coordenadaInicial = _coordenada;

    for (final controller in [
      _nomeController,
      _descricaoController,
      _enderecoController,
      _categoriaPersonalizadaController,
    ]) {
      controller.addListener(_aoAlterarCampo);
    }
  }

  @override
  void dispose() {
    _debounceEndereco?.cancel();
    for (final controller in [
      _nomeController,
      _descricaoController,
      _enderecoController,
      _categoriaPersonalizadaController,
    ]) {
      controller.removeListener(_aoAlterarCampo);
    }
    _nomeController.dispose();
    _descricaoController.dispose();
    _enderecoController.dispose();
    _dataController.dispose();
    _categoriaPersonalizadaController.dispose();
    _geocodingService.dispose();
    super.dispose();
  }

  void _aoAlterarCampo() {
    if (mounted) setState(() {});
  }

  bool get _alterou {
    if (_nomeController.text.trim() != _nomeInicial.trim()) return true;
    if (_descricaoController.text.trim() != _descricaoInicial.trim()) {
      return true;
    }
    if (_enderecoController.text.trim() != _enderecoInicial.trim()) return true;
    if (_categoria != _categoriaInicial) return true;
    if (_categoriaPersonalizadaController.text.trim() !=
        _categoriaPersonalizadaInicial.trim()) {
      return true;
    }
    if (_status != _statusInicial) return true;
    if (_avaliacao != _avaliacaoInicial) return true;
    if (!_mesmaData(_dataVisita, _dataInicial)) return true;
    if (!_mesmaCoordenada(_coordenada, _coordenadaInicial)) return true;
    return false;
  }

  bool _mesmaData(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _mesmaCoordenada(LatLng? a, LatLng? b) {
    if (a == null || b == null) return a == b;
    return (a.latitude - b.latitude).abs() < 0.0000001 &&
        (a.longitude - b.longitude).abs() < 0.0000001;
  }

  Future<bool> _confirmarDescarte() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Descartar alterações?'),
          content: const Text(
            'Você tem alterações que ainda não foram salvas. Deseja sair mesmo assim?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Continuar editando'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Descartar',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
    return descartar == true;
  }

  Future<void> _selecionarData() async {
    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataVisita,
      firstDate: DateTime(1950),
      lastDate: DateTime(agora.year + 5, 12, 31),
      helpText: _status == Lugar.statusPlanejado
          ? 'Data prevista'
          : 'Data da visita',
    );
    if (escolhida == null) return;
    setState(() {
      _dataVisita = escolhida;
      _dataController.text = formatarData(escolhida);
    });
  }

  void _selecionarCoordenada(LatLng ponto) {
    setState(() {
      _coordenada = ponto;
      _erroCoordenada = null;
    });
    _agendarBuscaEndereco(ponto);
  }

  void _agendarBuscaEndereco(LatLng ponto) {
    _debounceEndereco?.cancel();
    _debounceEndereco = Timer(
      const Duration(milliseconds: 700),
      () => _buscarEndereco(ponto),
    );
  }

  Future<void> _buscarEndereco(LatLng ponto) async {
    if (!mounted) return;
    setState(() => _buscandoEndereco = true);

    final endereco = await _geocodingService.reverse(
      latitude: ponto.latitude,
      longitude: ponto.longitude,
    );

    if (!mounted) return;
    setState(() {
      _buscandoEndereco = false;
      if (endereco != null &&
          (!_enderecoManual || _enderecoController.text.trim().isEmpty)) {
        _enderecoController.text = endereco.enderecoCompleto;
        _enderecoManual = false;
        _enderecoInicial = endereco.enderecoCompleto;
      }
    });
  }

  Future<void> _usarMinhaLocalizacao() async {
    if (_buscandoLocalizacao) return;
    setState(() => _buscandoLocalizacao = true);
    try {
      final posicao = await _localizacaoService.obterPosicaoAtual();
      if (!mounted) return;
      _selecionarCoordenada(LatLng(posicao.latitude, posicao.longitude));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _buscandoLocalizacao = false);
    }
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    final formValido = _formKey.currentState?.validate() ?? false;

    if (_coordenada == null) {
      setState(() => _erroCoordenada = 'Escolha um ponto no mapa');
    }

    if (!formValido || _coordenada == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final categoriaFinal = _categoria == 'Outro'
        ? (_categoriaPersonalizadaController.text.trim().isEmpty
              ? 'Outro'
              : _categoriaPersonalizadaController.text.trim())
        : _categoria;

    setState(() => _salvando = true);
    try {
      final lugar = Lugar(
        id: widget.lugar?.id ?? '',
        nome: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim(),
        categoria: categoriaFinal,
        avaliacao: _avaliacao,
        dataVisita: _dataVisita,
        latitude: _coordenada!.latitude,
        longitude: _coordenada!.longitude,
        endereco: _enderecoController.text.trim(),
        status: _status,
        criadoEm: widget.lugar?.criadoEm,
      );

      if (_editando) {
        await _lugarService.atualizar(uid, lugar);
      } else {
        await _lugarService.criar(uid, lugar);
      }

      HapticFeedback.lightImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editando ? 'Lugar atualizado.' : 'Lugar adicionado ao diário.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o lugar.')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _secaoTitulo(BuildContext context, IconData icone, String titulo) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Row(
        children: [
          Icon(icone, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duracao = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return PopScope(
      canPop: !_alterou && !_salvando,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _salvando) return;
        final descartar = await _confirmarDescarte();
        if (descartar && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_editando ? 'Editar lugar' : 'Novo lugar')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _secaoTitulo(context, Icons.label_outline, 'Identificação'),
                    CampoFormulario(
                      controller: _nomeController,
                      rotulo: 'Nome do lugar',
                      dica: 'Ex.: Mirante do Pão de Açúcar',
                      icone: Icons.place_outlined,
                      obrigatorio: true,
                      validador: (value) {
                        if ((value?.trim().length ?? 0) > 120) {
                          return 'Use até 120 caracteres';
                        }
                        return null;
                      },
                    ),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      expandedInsets: EdgeInsets.zero,
                      segments: const [
                        ButtonSegment(
                          value: Lugar.statusVisitado,
                          label: Text('Já visitei'),
                          icon: Icon(Icons.check_circle_outline, size: 18),
                        ),
                        ButtonSegment(
                          value: Lugar.statusPlanejado,
                          label: Text('Quero visitar'),
                          icon: Icon(Icons.bookmark_border, size: 18),
                        ),
                      ],
                      selected: {_status},
                      onSelectionChanged: (selecao) {
                        setState(() => _status = selecao.first);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _categoria,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de lugar',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categoriasLugar
                          .map(
                            (categoria) => DropdownMenuItem(
                              value: categoria,
                              child: Row(
                                children: [
                                  Icon(iconeCategoria(categoria), size: 18),
                                  const SizedBox(width: 10),
                                  Text(categoria),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) {
                        if (valor != null) setState(() => _categoria = valor);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                      child: Text(
                        'Escolha o tipo que mais combina com o lugar. Se não tiver certeza, use "Outro" e descreva.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    AnimatedSize(
                      duration: duracao,
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: _categoria == 'Outro'
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: CampoFormulario(
                                controller: _categoriaPersonalizadaController,
                                rotulo: 'Descreva o tipo',
                                dica: 'Ex.: Mirante, Feira, Igreja, Estádio',
                                icone: Icons.edit_outlined,
                                validador: (value) {
                                  if ((value?.trim().length ?? 0) > 40) {
                                    return 'Use até 40 caracteres';
                                  }
                                  return null;
                                },
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    const SizedBox(height: 18),
                    _secaoTitulo(context, Icons.pin_drop_outlined, 'Local'),
                    CampoFormulario(
                      controller: _dataController,
                      rotulo: _status == Lugar.statusPlanejado
                          ? 'Data prevista'
                          : 'Data da visita',
                      icone: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: _selecionarData,
                      sufixo: IconButton(
                        onPressed: _selecionarData,
                        icon: const Icon(Icons.event_outlined),
                      ),
                    ),
                    CampoFormulario(
                      controller: _enderecoController,
                      rotulo: 'Endereço ou referência',
                      dica: 'Preenchido automaticamente ao escolher o ponto',
                      icone: Icons.location_on_outlined,
                      maxLines: 2,
                      onChanged: (_) => _enderecoManual = true,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ponto no mapa',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _buscandoLocalizacao
                              ? null
                              : _usarMinhaLocalizacao,
                          icon: _buscandoLocalizacao
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location, size: 18),
                          label: const Text('Usar minha localização'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SeletorLocalMapa(
                      valor: _coordenada,
                      centroInicial: _centroMapa,
                      onChanged: _selecionarCoordenada,
                    ),
                    if (_erroCoordenada != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _erroCoordenada!,
                        style: TextStyle(color: scheme.error, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _coordenada == null
                                ? 'Nenhum ponto escolhido ainda.'
                                : 'Lat ${formatarCoordenada(_coordenada!.latitude)} • '
                                      'Lng ${formatarCoordenada(_coordenada!.longitude)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        if (_buscandoEndereco)
                          Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Buscando endereço...',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _secaoTitulo(context, Icons.notes_outlined, 'Detalhes'),
                    CampoFormulario(
                      controller: _descricaoController,
                      rotulo: 'Anotações',
                      dica: 'O que você achou deste lugar?',
                      icone: Icons.notes_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _status == Lugar.statusPlanejado
                          ? 'Expectativa geral'
                          : 'Avaliação geral',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nota geral do lugar; não é uma nota de comida ou serviço.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (var nota = 1; nota <= 5; nota++)
                          IconButton(
                            tooltip: '$nota estrela(s)',
                            onPressed: () => setState(() => _avaliacao = nota),
                            icon: Icon(
                              nota <= _avaliacao
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 30,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text('$_avaliacao/5'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _salvando ? null : _salvar,
                      icon: _salvando
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_salvando ? 'Salvando...' : 'Salvar lugar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

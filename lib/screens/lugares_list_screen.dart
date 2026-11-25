import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/entrada_suave.dart';
import '../components/estado_vazio.dart';
import '../components/lugar_card.dart';
import '../core/categorias.dart';
import '../models/lugar.dart';
import '../services/conectividade_service.dart';
import '../services/lugar_service.dart';
import 'lugar_detalhe_screen.dart';
import 'lugar_form_screen.dart';

class LugaresListScreen extends StatefulWidget {
  const LugaresListScreen({super.key});

  @override
  State<LugaresListScreen> createState() => _LugaresListScreenState();
}

class _LugaresListScreenState extends State<LugaresListScreen> {
  static const Map<String, String> _ordenacoes = {
    'recentes': 'Mais recentes',
    'antigos': 'Mais antigos',
    'avaliacao': 'Melhor nota',
    'nome': 'Nome (A–Z)',
  };

  final LugarService _lugarService = LugarService();
  final TextEditingController _buscaController = TextEditingController();

  String _busca = '';
  String? _categoria;
  String? _status;
  String _ordenacao = 'recentes';
  final Set<String> _excluindo = <String>{};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool get _temFiltroAvancado => _categoria != null || _ordenacao != 'recentes';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _abrirFormulario() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LugarFormScreen()));
  }

  Future<void> _abrirDetalhe(Lugar lugar) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LugarDetalheScreen(lugar: lugar)));
  }

  Future<bool> _confirmarExclusao(Lugar lugar) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir lugar?'),
          content: Text('Tem certeza que deseja excluir "${lugar.nome}"?'),
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
    return confirmado == true && mounted;
  }

  Future<void> _excluir(Lugar lugar) async {
    if (_excluindo.contains(lugar.id)) return;
    if (!await _confirmarExclusao(lugar)) return;
    await _excluirComDesfazer(lugar);
  }

  Future<void> _excluirComDesfazer(Lugar lugar) async {
    final uid = _uid;
    if (uid == null || _excluindo.contains(lugar.id)) return;

    setState(() => _excluindo.add(lugar.id));

    try {
      await _lugarService.excluir(uid, lugar.id);
      HapticFeedback.lightImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('"${lugar.nome}" foi excluído.'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () => _desfazerExclusao(uid, lugar),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() => _excluindo.remove(lugar.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o lugar.')),
      );
    }
  }

  Future<void> _desfazerExclusao(String uid, Lugar lugar) async {
    try {
      await _lugarService.criar(uid, lugar);
      HapticFeedback.selectionClick();
      if (!mounted) return;
      setState(() => _excluindo.remove(lugar.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lugar restaurado.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _excluindo.remove(lugar.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível desfazer a exclusão.')),
      );
    }
  }

  Future<void> _abrirFiltros() async {
    final resultado = await showModalBottomSheet<_FiltrosResultado>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FiltrosSheet(
        categoriaInicial: _categoria,
        ordenacaoInicial: _ordenacao,
        ordenacoes: _ordenacoes,
      ),
    );

    if (resultado == null || !mounted) return;
    setState(() {
      _categoria = resultado.categoria;
      _ordenacao = resultado.ordenacao;
    });
  }

  void _limparTudo() {
    _buscaController.clear();
    setState(() {
      _busca = '';
      _categoria = null;
      _status = null;
      _ordenacao = 'recentes';
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<LugaresSnapshot>(
      stream: _lugarService.streamLugares(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return EstadoVazio(
            icone: Icons.cloud_off_outlined,
            titulo: 'Não foi possível carregar o diário',
            subtitulo: 'Verifique sua conexão e tente novamente.',
            acao: OutlinedButton(
              onPressed: () => setState(() {}),
              child: const Text('Tentar novamente'),
            ),
          );
        }

        final todos = snapshot.data?.lugares ?? const <Lugar>[];
        final filtrados = _ordenar(todos.where(_filtrar).toList());
        final visiveis = filtrados
            .where((lugar) => !_excluindo.contains(lugar.id))
            .toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Stack(
              children: [
                Column(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: ConectividadeService.instance.offline,
                      builder: (context, offline, _) {
                        if (!offline) return const SizedBox.shrink();
                        return _buildOfflineBanner();
                      },
                    ),
                    _buildFiltros(),
                    Expanded(
                      child: todos.isEmpty
                          ? EstadoVazio(
                              icone: Icons.menu_book_outlined,
                              titulo: 'Seu diário está vazio',
                              subtitulo:
                                  'Adicione o primeiro lugar que você visitou ou quer visitar.',
                              acao: ElevatedButton.icon(
                                onPressed: _abrirFormulario,
                                icon: const Icon(Icons.add),
                                label: const Text('Adicionar lugar'),
                              ),
                            )
                          : filtrados.isEmpty
                          ? EstadoVazio(
                              icone: Icons.search_off_outlined,
                              titulo: 'Nenhum lugar encontrado',
                              subtitulo:
                                  'Tente outra busca ou remova os filtros.',
                              acao: OutlinedButton(
                                onPressed: _limparTudo,
                                child: const Text('Limpar filtros'),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 4,
                                bottom: 100,
                              ),
                              itemCount: visiveis.length,
                              itemBuilder: (context, index) {
                                final lugar = visiveis[index];
                                return EntradaSuave(
                                  key: ValueKey<String>(lugar.id),
                                  child: Dismissible(
                                    key: ValueKey<String>(
                                      'dismiss-${lugar.id}',
                                    ),
                                    direction: DismissDirection.endToStart,
                                    background: _buildSwipeBackground(),
                                    confirmDismiss: (_) =>
                                        _confirmarExclusao(lugar),
                                    onDismissed: (_) =>
                                        _excluirComDesfazer(lugar),
                                    child: LugarCard(
                                      lugar: lugar,
                                      onTap: () => _abrirDetalhe(lugar),
                                      onDelete: () => _excluir(lugar),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                if (todos.isNotEmpty)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.extended(
                      heroTag: 'novo-lugar-diario',
                      onPressed: _abrirFormulario,
                      icon: const Icon(Icons.add),
                      label: const Text('Novo lugar'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfflineBanner() {
    final cor = Theme.of(context).colorScheme.onTertiaryContainer;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modo offline — exibindo os dados salvos no dispositivo.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeBackground() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: scheme.onError),
          const SizedBox(width: 8),
          Text(
            'Excluir',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onError),
          ),
        ],
      ),
    );
  }

  List<Lugar> _ordenar(List<Lugar> lugares) {
    final lista = [...lugares];
    switch (_ordenacao) {
      case 'antigos':
        lista.sort((a, b) => a.dataVisita.compareTo(b.dataVisita));
        break;
      case 'avaliacao':
        lista.sort((a, b) {
          final porNota = b.avaliacao.compareTo(a.avaliacao);
          if (porNota != 0) return porNota;
          return b.dataVisita.compareTo(a.dataVisita);
        });
        break;
      case 'nome':
        lista.sort(
          (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
        );
        break;
      case 'recentes':
      default:
        lista.sort((a, b) => b.dataVisita.compareTo(a.dataVisita));
        break;
    }
    return lista;
  }

  bool _filtrar(Lugar lugar) {
    final busca = _busca.trim().toLowerCase();
    final combinaBusca =
        busca.isEmpty ||
        lugar.nome.toLowerCase().contains(busca) ||
        lugar.categoria.toLowerCase().contains(busca) ||
        lugar.endereco.toLowerCase().contains(busca) ||
        lugar.descricao.toLowerCase().contains(busca);
    final combinaCategoria =
        _categoria == null || lugar.categoria == _categoria;
    final combinaStatus = _status == null || lugar.status == _status;
    return combinaBusca && combinaCategoria && combinaStatus;
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _buscaController,
            onChanged: (valor) => setState(() => _busca = valor),
            decoration: InputDecoration(
              hintText: 'Buscar por nome, categoria, endereço ou nota',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busca.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: () {
                        _buscaController.clear();
                        setState(() => _busca = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _statusChip(
                        rotulo: 'Todos',
                        valor: null,
                        icone: Icons.apps_outlined,
                      ),
                      const SizedBox(width: 8),
                      _statusChip(
                        rotulo: 'Já visitei',
                        valor: Lugar.statusVisitado,
                        icone: Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 8),
                      _statusChip(
                        rotulo: 'Quero visitar',
                        valor: Lugar.statusPlanejado,
                        icone: Icons.bookmark_border,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: _temFiltroAvancado,
                child: IconButton.filledTonal(
                  tooltip: 'Filtros e ordenação',
                  onPressed: _abrirFiltros,
                  icon: const Icon(Icons.tune),
                ),
              ),
            ],
          ),
          if (_temFiltroAvancado) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (_categoria != null)
                  Chip(
                    label: Text(_categoria!),
                    onDeleted: () => setState(() => _categoria = null),
                  ),
                if (_categoria != null) const SizedBox(width: 8),
                Text(
                  'Ordenar: ${_ordenacoes[_ordenacao]}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                TextButton(onPressed: _limparTudo, child: const Text('Limpar')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip({
    required String rotulo,
    required String? valor,
    required IconData icone,
  }) {
    final selecionado = _status == valor;
    return ChoiceChip(
      avatar: Icon(icone, size: 16),
      label: Text(rotulo),
      selected: selecionado,
      onSelected: (_) => setState(() => _status = valor),
    );
  }
}

class _FiltrosResultado {
  const _FiltrosResultado({required this.categoria, required this.ordenacao});

  final String? categoria;
  final String ordenacao;
}

class _FiltrosSheet extends StatefulWidget {
  const _FiltrosSheet({
    required this.categoriaInicial,
    required this.ordenacaoInicial,
    required this.ordenacoes,
  });

  final String? categoriaInicial;
  final String ordenacaoInicial;
  final Map<String, String> ordenacoes;

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  String? _categoria;
  late String _ordenacao;

  @override
  void initState() {
    super.initState();
    _categoria = widget.categoriaInicial;
    _ordenacao = widget.ordenacaoInicial;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            Text('Categoria', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _categoria == null,
                  onSelected: (_) => setState(() => _categoria = null),
                ),
                ...categoriasLugar.map(
                  (categoria) => ChoiceChip(
                    label: Text(categoria),
                    selected: _categoria == categoria,
                    onSelected: (_) => setState(() => _categoria = categoria),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Ordenar por', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.ordenacoes.entries
                  .map(
                    (opcao) => ChoiceChip(
                      label: Text(opcao.value),
                      selected: _ordenacao == opcao.key,
                      onSelected: (_) => setState(() => _ordenacao = opcao.key),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        const _FiltrosResultado(
                          categoria: null,
                          ordenacao: 'recentes',
                        ),
                      );
                    },
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        _FiltrosResultado(
                          categoria: _categoria,
                          ordenacao: _ordenacao,
                        ),
                      );
                    },
                    child: const Text('Aplicar'),
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

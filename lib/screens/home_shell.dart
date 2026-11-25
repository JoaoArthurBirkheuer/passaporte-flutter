import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'ia_screen.dart';
import 'lugares_list_screen.dart';
import 'mapa_screen.dart';
import 'perfil_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const List<String> _titulos = [
    'Mapa',
    'Meu diário',
    'Assistente de viagem',
    'Perfil',
  ];

  int _pagina = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<PerfilScreenState> _perfilKey =
      GlobalKey<PerfilScreenState>();
  final AuthService _authService = AuthService();

  void _selecionarPagina(int indice) {
    if (indice == _pagina) return;
    HapticFeedback.selectionClick();
    setState(() => _pagina = indice);
    if (indice == 3) {
      _perfilKey.currentState?.recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final largura = MediaQuery.sizeOf(context).width;
    final telaLarga = largura >= 900;
    final railEstendido = largura >= 1200;
    final animacaoTitulo = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);

    final conteudo = IndexedStack(
      index: _pagina,
      children: [
        const MapaScreen(),
        HeroMode(enabled: _pagina == 1, child: const LugaresListScreen()),
        const IaScreen(),
        PerfilScreen(key: _perfilKey),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.explore_outlined,
                color: scheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: AnimatedSwitcher(
                duration: animacaoTitulo,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final deslocamento = Tween<Offset>(
                    begin: const Offset(0, 0.28),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: deslocamento,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _titulos[_pagina],
                  key: ValueKey<int>(_pagina),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
      body: telaLarga
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _pagina,
                  onDestinationSelected: _selecionarPagina,
                  extended: railEstendido,
                  labelType: railEstendido
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: Text('Mapa'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book),
                      label: Text('Diário'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.auto_awesome_outlined),
                      selectedIcon: Icon(Icons.auto_awesome),
                      label: Text('IA'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Perfil'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: conteudo),
              ],
            )
          : conteudo,
      bottomNavigationBar: telaLarga
          ? null
          : NavigationBar(
              selectedIndex: _pagina,
              onDestinationSelected: _selecionarPagina,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Mapa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Diário',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'IA',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final nome = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Viajante';
    final email = user?.email ?? '';

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.explore_outlined,
                      color: scheme.onPrimary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Passaporte',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(nome, style: Theme.of(context).textTheme.bodyMedium),
                  if (email.isNotEmpty)
                    Text(email, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Divider(),
            _drawerItem(context, 0, Icons.map_outlined, 'Mapa'),
            _drawerItem(context, 1, Icons.menu_book_outlined, 'Diário'),
            _drawerItem(context, 2, Icons.auto_awesome_outlined, 'IA'),
            _drawerItem(context, 3, Icons.person_outline, 'Perfil'),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Como usar'),
              onTap: () => _abrirComoUsar(context),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Sair', style: TextStyle(color: scheme.error)),
              onTap: () async {
                Navigator.of(context).pop();
                await _authService.sair();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirComoUsar(BuildContext context) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!context.mounted) return;
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _ComoUsarSheet(),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    int indice,
    IconData icone,
    String rotulo,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selecionado = _pagina == indice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icone,
          color: selecionado ? scheme.primary : scheme.onSurfaceVariant,
        ),
        title: Text(
          rotulo,
          style: TextStyle(
            color: selecionado ? scheme.primary : scheme.onSurface,
            fontWeight: selecionado ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: selecionado,
        selectedTileColor: scheme.primary.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () {
          Navigator.of(context).pop();
          _selecionarPagina(indice);
        },
      ),
    );
  }
}

class _ComoUsarSheet extends StatelessWidget {
  const _ComoUsarSheet();

  static const List<(IconData, String, String)> _dicas = [
    (
      Icons.map_outlined,
      'Mapa',
      'Toque no mapa para criar um lugar no ponto. Segure para abrir o formulário '
          'direto. Use o botão de enquadrar para ver todos os lugares.',
    ),
    (
      Icons.bookmark_border,
      'Status',
      'Escolha "Já visitei" ou "Quero visitar". A data e a avaliação se adaptam '
          'ao status escolhido.',
    ),
    (
      Icons.tune,
      'Filtros',
      'Busque por nome, tipo ou endereço. Use os chips de status e o menu de '
          'filtros para ordenar por data, nota ou nome.',
    ),
    (
      Icons.auto_awesome,
      'IA',
      'Peça Dicas, Roteiro ou Resumo. Ao trocar a ação ou o lugar, a resposta '
          'atual é limpa e a anterior fica salva no histórico.',
    ),
    (
      Icons.palette_outlined,
      'Tema',
      'No Perfil, alterne entre claro, escuro e sistema. A preferência fica '
          'salva neste dispositivo.',
    ),
    (
      Icons.swipe_left_outlined,
      'Excluir',
      'Deslize um cartão para a esquerda para excluir. A lixeira também funciona, '
          'e o aviso permite desfazer a exclusão.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Como usar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Dicas rápidas para aproveitar o Passaporte.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            for (final (icone, titulo, texto) in _dicas)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icone, color: scheme.primary, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            texto,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

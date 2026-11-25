import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/contador_animado.dart';
import '../core/theme_controller.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/historico_ia_service.dart';
import '../services/lugar_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => PerfilScreenState();
}

class PerfilScreenState extends State<PerfilScreen> {
  final AuthService _authService = AuthService();
  final LugarService _lugarService = LugarService();
  final HistoricoIaService _historicoService = HistoricoIaService();

  Future<_ResumoPerfil>? _resumo;
  bool _saindo = false;

  @override
  void initState() {
    super.initState();
    _recarregar();
  }

  void recarregar() => _recarregar();

  void _recarregar() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _resumo = _carregarResumo(uid);
    });
  }

  Future<_ResumoPerfil> _carregarResumo(String uid) async {
    final perfil = await _authService.perfil();
    final lugares = await _lugarService.listar(uid);
    final totalHistorico = await _historicoService.contar(uid);

    final total = lugares.length;
    final visitados = lugares.where((lugar) => lugar.visitado).length;
    final planejados = lugares.where((lugar) => lugar.planejado).length;
    final media = total == 0
        ? 0.0
        : lugares.map((lugar) => lugar.avaliacao).reduce((a, b) => a + b) /
              total;

    return _ResumoPerfil(
      perfil: perfil,
      totalLugares: total,
      visitados: visitados,
      planejados: planejados,
      mediaAvaliacao: media,
      totalIa: totalHistorico,
    );
  }

  Future<void> _editarNome(UserModel? perfil) async {
    final controller = TextEditingController(text: perfil?.displayName ?? '');

    final novoNome = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar nome'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (novoNome == null || novoNome.trim().isEmpty) return;
    await _authService.atualizarNome(novoNome);
    _recarregar();
  }

  Future<void> _sair() async {
    if (_saindo) return;
    setState(() => _saindo = true);
    try {
      await _authService.sair();
    } finally {
      if (mounted) setState(() => _saindo = false);
    }
  }

  String _iniciais(String nome, String email) {
    final base = nome.trim().isEmpty ? email.trim() : nome.trim();
    if (base.isEmpty) return 'P';
    final partes = base.split(RegExp(r'\s+'));
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<_ResumoPerfil>(
      future: _resumo,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Não foi possível carregar o perfil.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _recarregar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final resumo = snapshot.data;
        final user = FirebaseAuth.instance.currentUser;
        final perfil = resumo?.perfil;
        final nome = perfil?.displayName.trim().isNotEmpty == true
            ? perfil!.displayName.trim()
            : (user?.displayName?.trim().isNotEmpty == true
                  ? user!.displayName!.trim()
                  : 'Viajante');
        final email = perfil?.email.isNotEmpty == true
            ? perfil!.email
            : (user?.email ?? '');
        final foto = perfil?.photoUrl.trim().isNotEmpty == true
            ? perfil!.photoUrl
            : (user?.photoURL ?? '');
        final visitados = resumo?.visitados ?? 0;
        final planejados = resumo?.planejados ?? 0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: scheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          backgroundImage: foto.isEmpty
                              ? null
                              : NetworkImage(foto),
                          child: foto.isEmpty
                              ? Text(
                                  _iniciais(nome, email),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          nome,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _Indicador(
                                valor: (resumo?.totalLugares ?? 0).toDouble(),
                                rotulo: 'Lugares',
                                icone: Icons.place_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Indicador(
                                valor: resumo?.mediaAvaliacao ?? 0,
                                decimais: 1,
                                rotulo: 'Média',
                                icone: Icons.star_outline_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Indicador(
                                valor: (resumo?.totalIa ?? 0).toDouble(),
                                rotulo: 'Pedidos IA',
                                icone: Icons.auto_awesome_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$visitados '
                          '${visitados == 1 ? 'visitado' : 'visitados'} • '
                          '$planejados '
                          '${planejados == 1 ? 'planejado' : 'planejados'}',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => _editarNome(perfil),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar nome'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _saindo ? null : _sair,
                  icon: _saindo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.logout, color: scheme.error),
                  label: Text(
                    _saindo ? 'Saindo...' : 'Sair da conta',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
                const SizedBox(height: 24),
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
                              Icons.palette_outlined,
                              color: scheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Aparência',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListenableBuilder(
                          listenable: ThemeController.instance,
                          builder: (context, _) {
                            return SegmentedButton<ThemeMode>(
                              showSelectedIcon: false,
                              expandedInsets: EdgeInsets.zero,
                              segments: const [
                                ButtonSegment(
                                  value: ThemeMode.system,
                                  label: Text('Sistema'),
                                ),
                                ButtonSegment(
                                  value: ThemeMode.light,
                                  label: Text('Claro'),
                                ),
                                ButtonSegment(
                                  value: ThemeMode.dark,
                                  label: Text('Escuro'),
                                ),
                              ],
                              selected: {ThemeController.instance.modo},
                              onSelectionChanged: (selecao) {
                                HapticFeedback.selectionClick();
                                ThemeController.instance.definir(selecao.first);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Por padrão, o app segue o tema do sistema. Sua escolha fica salva neste dispositivo.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                              Icons.info_outline,
                              color: scheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sobre o Passaporte',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Um diário de viagens com autenticação Firebase, CRUD no '
                          'Cloud Firestore, mapa OpenStreetMap e sugestões geradas '
                          'pelo Gemini.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _Etiqueta(texto: 'Flutter'),
                            _Etiqueta(texto: 'Firebase Auth'),
                            _Etiqueta(texto: 'Firestore'),
                            _Etiqueta(texto: 'OpenStreetMap'),
                            _Etiqueta(texto: 'Gemini'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResumoPerfil {
  const _ResumoPerfil({
    required this.perfil,
    required this.totalLugares,
    required this.visitados,
    required this.planejados,
    required this.mediaAvaliacao,
    required this.totalIa,
  });

  final UserModel? perfil;
  final int totalLugares;
  final int visitados;
  final int planejados;
  final double mediaAvaliacao;
  final int totalIa;
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.valor,
    required this.rotulo,
    required this.icone,
    this.decimais = 0,
  });

  final double valor;
  final String rotulo;
  final IconData icone;
  final int decimais;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icone, size: 18, color: scheme.primary),
          const SizedBox(height: 6),
          ContadorAnimado(
            valor: valor,
            decimais: decimais,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            rotulo,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(texto, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

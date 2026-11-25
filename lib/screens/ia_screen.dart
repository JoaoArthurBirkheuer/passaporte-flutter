import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/estado_vazio.dart';
import '../components/resposta_markdown.dart';
import '../core/formatadores.dart';
import '../core/tipo_lugar.dart';
import '../models/historico_ia.dart';
import '../models/lugar.dart';
import '../services/historico_ia_service.dart';
import '../services/ia_service.dart';
import '../services/localizacao_service.dart';
import '../services/lugar_service.dart';
import 'historico_ia_screen.dart';

enum AcaoIa { dicas, roteiro, resumo }

extension AcaoIaRotulo on AcaoIa {
  String get rotulo {
    switch (this) {
      case AcaoIa.dicas:
        return 'Dicas';
      case AcaoIa.roteiro:
        return 'Roteiro';
      case AcaoIa.resumo:
        return 'Resumo';
    }
  }

  String get descricao {
    switch (this) {
      case AcaoIa.dicas:
        return 'Dicas e curiosidades sobre um lugar específico.';
      case AcaoIa.roteiro:
        return 'Um roteiro de um dia com todos os lugares do diário.';
      case AcaoIa.resumo:
        return 'Um resumo afetivo da sua viagem e sugestões de próximos destinos.';
    }
  }
}

class IaScreen extends StatefulWidget {
  const IaScreen({super.key, this.lugarInicial});

  final Lugar? lugarInicial;

  @override
  State<IaScreen> createState() => _IaScreenState();
}

class _IaScreenState extends State<IaScreen> {
  final IaService _iaService = IaService();
  final LugarService _lugarService = LugarService();
  final HistoricoIaService _historicoService = HistoricoIaService();
  final LocalizacaoService _localizacaoService = LocalizacaoService();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<String>? _sub;
  AcaoIa _acao = AcaoIa.dicas;
  String? _lugarSelecionadoId;
  String _resposta = '';
  String? _erro;
  bool _gerando = false;
  bool _autoSelecionou = false;
  String _ultimoPrompt = '';
  Lugar? _ultimoLugar;
  AcaoIa _ultimaAcao = AcaoIa.dicas;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _lugarSelecionadoId = widget.lugarInicial?.id;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Lugar? _lugarSelecionado(List<Lugar> lugares) {
    for (final lugar in lugares) {
      if (lugar.id == _lugarSelecionadoId) return lugar;
    }
    if (lugares.isEmpty &&
        widget.lugarInicial != null &&
        widget.lugarInicial!.id == _lugarSelecionadoId) {
      return widget.lugarInicial;
    }
    return null;
  }

  Future<void> _gerar(List<Lugar> lugares) async {
    final uid = _uid;
    if (uid == null || _gerando) return;

    final selecionado = _lugarSelecionado(lugares);

    if (_acao == AcaoIa.dicas && selecionado == null) {
      _aviso('Escolha um lugar para receber as dicas.');
      return;
    }

    if (_acao != AcaoIa.dicas && lugares.isEmpty) {
      _aviso('Cadastre pelo menos um lugar no diário primeiro.');
      return;
    }

    final acao = _acao;
    final prompt = _montarPrompt(acao, selecionado, lugares);
    FocusScope.of(context).unfocus();
    await _sub?.cancel();

    setState(() {
      _gerando = true;
      _erro = null;
      _resposta = '';
      _ultimoPrompt = prompt;
      _ultimoLugar = acao == AcaoIa.dicas ? selecionado : null;
      _ultimaAcao = acao;
    });

    _sub = _iaService
        .gerarEmStream(prompt)
        .listen(
          (pedaco) {
            if (!mounted) return;
            setState(() => _resposta += pedaco);
            _rolarParaFim();
          },
          onError: (Object e) {
            if (!mounted) return;
            setState(() {
              _erro = _mensagemErro(e);
              _gerando = false;
            });
          },
          onDone: () {
            if (!mounted) return;
            setState(() => _gerando = false);
            _salvarHistorico(
              uid,
              prompt,
              acao == AcaoIa.dicas ? selecionado : null,
              acao,
            );
          },
          cancelOnError: true,
        );
  }

  Future<void> _parar() async {
    await _sub?.cancel();
    _sub = null;
    if (!mounted) return;
    setState(() => _gerando = false);

    final uid = _uid;
    if (uid != null && _resposta.trim().isNotEmpty) {
      await _salvarHistorico(uid, _ultimoPrompt, _ultimoLugar, _ultimaAcao);
    }
  }

  void _mudarAcao(AcaoIa acao) {
    if (_gerando || _acao == acao) return;

    final tinhaResposta = _resposta.trim().isNotEmpty;
    _sub?.cancel();
    _sub = null;

    setState(() {
      _acao = acao;
      _resposta = '';
      _erro = null;
    });

    if (tinhaResposta) {
      _aviso('A resposta anterior ficou salva no histórico.');
    }
  }

  void _mudarLugar(String? id) {
    if (_gerando || id == _lugarSelecionadoId) return;

    final tinhaResposta = _resposta.trim().isNotEmpty;
    _sub?.cancel();
    _sub = null;

    setState(() {
      _lugarSelecionadoId = id;
      _resposta = '';
      _erro = null;
    });

    if (tinhaResposta) {
      _aviso('A resposta anterior ficou salva no histórico.');
    }
  }

  Future<void> _salvarHistorico(
    String uid,
    String prompt,
    Lugar? lugar,
    AcaoIa acao,
  ) async {
    final resposta = _resposta.trim();
    if (resposta.isEmpty) return;

    try {
      await _historicoService.salvar(
        uid,
        HistoricoIa(
          id: '',
          tipo: acao.name,
          lugarId: lugar?.id,
          prompt: prompt,
          resposta: resposta,
          criadoEm: DateTime.now(),
        ),
      );
      if (!mounted) return;
      _aviso('Resposta salva no histórico.');
    } catch (_) {
      if (!mounted) return;
      _aviso('Não foi possível salvar a resposta no histórico.');
    }
  }

  String _montarPrompt(AcaoIa acao, Lugar? lugar, List<Lugar> lugares) {
    switch (acao) {
      case AcaoIa.dicas:
        return _promptDicas(lugar!, lugares);
      case AcaoIa.roteiro:
        return _promptRoteiro(lugares);
      case AcaoIa.resumo:
        return _promptResumo(lugares);
    }
  }

  String _enderecoOuCoordenadas(Lugar lugar) {
    final endereco = lugar.endereco.trim();
    if (endereco.isNotEmpty) return endereco;
    return 'coordenadas '
        '${formatarCoordenada(lugar.latitude)}, '
        '${formatarCoordenada(lugar.longitude)}';
  }

  String _contextoLugar(Lugar lugar, {bool incluirNotas = true}) {
    final tipo = tipoEfetivo(lugar);
    final categoriaOriginal = lugar.categoria == 'Outro'
        ? ' (categoria original: Outro)'
        : '';
    final linhas = <String>[
      'Nome: ${lugar.nome}',
      'Status: ${lugar.planejado ? 'Quero visitar' : 'Já visitei'}',
      'Tipo: $tipo$categoriaOriginal',
      'Endereço: ${_enderecoOuCoordenadas(lugar)}',
      'Coordenadas: ${formatarCoordenada(lugar.latitude)}, '
          '${formatarCoordenada(lugar.longitude)}',
      'Avaliação geral (não é nota de comida/serviço): ${lugar.avaliacao}/5',
      'Data da visita: ${formatarData(lugar.dataVisita)}',
      if (incluirNotas && lugar.descricao.trim().isNotEmpty)
        'Anotações do usuário: ${lugar.descricao.trim()}',
    ];
    return linhas.join('\n');
  }

  String _promptDicas(Lugar lugar, List<Lugar> lugares) {
    final tipo = tipoEfetivo(lugar);
    final foco = focoParaTipo(tipo);
    final outros = lugares
        .where((l) => l.id != lugar.id && tipoEfetivo(l) != 'Residência')
        .take(6)
        .toList();
    final outrosTexto = outros.isEmpty
        ? 'O usuário não cadastrou outros lugares.'
        : outros
              .map(
                (l) =>
                    '- ${l.nome} (${tipoEfetivo(l)}) — ${_enderecoOuCoordenadas(l)}',
              )
              .join('\n');

    return 'Você é um guia de viagens brasileiro, específico e prático. '
        'Não invente fatos. Use o contexto abaixo.\n\n'
        'CONTEXTO DO LUGAR\n'
        '${_contextoLugar(lugar)}\n\n'
        'TIPO EFETIVO\n$tipo\n\n'
        'FOCO PARA ESTE TIPO DE LUGAR\n$foco\n\n'
        'OUTROS LUGARES DO USUÁRIO (para sugerir algo próximo, se fizer sentido)\n'
        '$outrosTexto\n\n'
        'REGRAS DE FIDELIDADE E FOCO\n'
        '- A nota no contexto é uma avaliação geral do lugar. Não a use para '
        'inferir qualidade de comida, preço ou atendimento.\n'
        '- Só mencione alimentação se o tipo efetivo for Restaurante/Café ou '
        'se as anotações do usuário mencionarem comida. No máximo uma vez.\n'
        '- Não repita a mesma informação em tópicos diferentes. Cada tópico '
        'deve trazer algo novo.\n'
        '- Não invente preços, cardápios, horários de voo, serviços ou '
        'características específicas que não estejam nas anotações ou no '
        'endereço. Se não houver dados, diga que não sabe.\n'
        '- Se o status for "Já visitei" e o lugar for local (transporte, '
        'residência, rotina), priorize dicas práticas de uso e arredores, '
        'não dicas de turismo.\n'
        '- Se "melhor horário/dia" não fizer sentido para o tipo, diga isso '
        'em vez de forçar uma recomendação.\n'
        '- Não sugira residências como atividade turística. Se o único lugar '
        'próximo for uma residência, sugira o bairro ou a cidade.\n\n'
        'TAREFA\n'
        '1. Dê 3 dicas realmente específicas para ${lugar.nome}, considerando '
        'o tipo "$tipo" e o endereço informado.\n'
        '2. Diga o melhor horário ou dia para visitar e o motivo, se fizer '
        'sentido para o tipo.\n'
        '3. Aponte um cuidado, risco ou alerta útil.\n'
        '4. Sugira uma atividade ou lugar próximo. Se houver um lugar do '
        'diário do usuário que combine, cite-o pelo nome; caso contrário, '
        'cite o bairro ou a cidade.\n'
        '5. Evite frases genéricas. Cada dica deve ter informação concreta.\n'
        '6. Considere o status: se for "Quero visitar", priorize planejamento; '
        'se for "Já visitei", priorize dicas práticas de uso ou lembranças, '
        'sem assumir que é uma atração turística.\n\n'
        'Responda em português do Brasil, em tópicos curtos. Se não souber '
        'algo, diga que não sabe em vez de inventar.';
  }

  String _promptRoteiro(List<Lugar> lugares) {
    final selecionados = lugares.take(10).toList();
    final contexto = selecionados
        .map(
          (l) =>
              '- ${l.nome}\n'
              '  ${_contextoLugar(l).replaceAll('\n', '\n  ')}',
        )
        .join('\n');
    final distancias = _matrizDistancias(selecionados);

    return 'Você é um planejador de viagens brasileiro. Monte um roteiro de '
        '1 dia usando SOMENTE os lugares abaixo ou, no máximo, uma sugestão '
        'extra claramente marcada como sugestão.\n\n'
        'LUGARES\n$contexto\n\n'
        'DISTÂNCIAS APROXIMADAS\n$distancias\n\n'
        'TAREFA\n'
        '- Agrupe os lugares por proximidade usando as distâncias.\n'
        '- Divida em manhã, tarde e noite.\n'
        '- Estime o tempo de deslocamento entre os grupos.\n'
        '- Inclua uma parada para almoço coerente com a região.\n'
        '- Explique em uma frase por que a ordem faz sentido.\n'
        '- Não invente lugares que não estão na lista; se sugerir algo extra, '
        'marque como "sugestão extra".\n\n'
        'Responda em português do Brasil, em formato de lista por período.';
  }

  String _promptResumo(List<Lugar> lugares) {
    final selecionados = lugares.take(12).toList();
    final contexto = selecionados
        .map(
          (l) =>
              '- ${l.nome} (${tipoEfetivo(l)}) — '
              '${l.planejado ? 'planejado' : 'visitado'} — '
              '${_enderecoOuCoordenadas(l)} — nota geral ${l.avaliacao}/5'
              '${l.descricao.trim().isEmpty ? '' : ' — ${l.descricao.trim()}'}',
        )
        .join('\n');

    return 'Você é um cronista de viagens brasileiro. Escreva um resumo '
        'afetivo, mas específico, do diário abaixo.\n\n'
        'LUGARES\n$contexto\n\n'
        'TAREFA\n'
        '- Mencione pelo menos dois lugares pelo nome.\n'
        '- Destaque o lugar favorito com base na nota e nas anotações.\n'
        '- Identifique um padrão no perfil do viajante (tipos de lugar, '
        'cidades, notas).\n'
        '- Sugira um próximo destino coerente com esse perfil e explique o '
        'motivo em uma frase.\n'
        '- Não invente lugares, notas ou experiências que não estejam no '
        'diário.\n\n'
        'Responda em português do Brasil, em 3 a 5 parágrafos curtos.';
  }

  String _matrizDistancias(List<Lugar> lugares) {
    if (lugares.length < 2) return 'Só há um lugar cadastrado.';

    final linhas = <String>[];
    for (var i = 0; i < lugares.length; i++) {
      for (var j = i + 1; j < lugares.length; j++) {
        final a = lugares[i];
        final b = lugares[j];
        final metros = _localizacaoService.distanciaEmMetros(
          origemLat: a.latitude,
          origemLng: a.longitude,
          destinoLat: b.latitude,
          destinoLng: b.longitude,
        );
        final km = (metros / 1000).toStringAsFixed(1);
        linhas.add('- ${a.nome} ↔ ${b.nome}: $km km');
      }
    }
    return linhas.join('\n');
  }

  String _mensagemErro(Object e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('high demand') || msg.contains('overloaded')) {
      return 'Os servidores da IA estão sobrecarregados. Tente novamente em alguns segundos.';
    }
    if (msg.contains('quota') || msg.contains('429')) {
      return 'Limite de requisições atingido. Tente novamente em instantes.';
    }
    if (msg.contains('app check') || msg.contains('appcheck')) {
      return 'A verificação de segurança do app falhou. Confira o App Check.';
    }
    if (msg.contains('network') || msg.contains('socketexception')) {
      return 'Sem conexão com a internet. Verifique sua rede.';
    }
    if (msg.contains('permission') || msg.contains('403')) {
      return 'A IA não está habilitada para este projeto. Confira o AI Logic.';
    }
    return 'Não foi possível obter a resposta. Tente novamente.';
  }

  void _aviso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  void _copiar() {
    Clipboard.setData(ClipboardData(text: _resposta));
    _aviso('Resposta copiada.');
  }

  void _rolarParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) return const SizedBox.shrink();

    final emRotaSeparada = ModalRoute.of(context)?.canPop ?? false;

    final conteudo = StreamBuilder<LugaresSnapshot>(
      stream: _lugarService.streamLugares(uid),
      builder: (context, snapshot) {
        final lugares = snapshot.data?.lugares ?? const <Lugar>[];

        if (!_autoSelecionou &&
            _lugarSelecionadoId == null &&
            lugares.isNotEmpty) {
          _autoSelecionou = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _lugarSelecionadoId = lugares.first.id);
          });
        }

        final selecionado = _lugarSelecionado(lugares);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _buildCabecalho(lugares),
                const SizedBox(height: 16),
                SegmentedButton<AcaoIa>(
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  segments: const [
                    ButtonSegment(
                      value: AcaoIa.dicas,
                      label: Text('Dicas'),
                      icon: Icon(Icons.lightbulb_outline, size: 18),
                    ),
                    ButtonSegment(
                      value: AcaoIa.roteiro,
                      label: Text('Roteiro'),
                      icon: Icon(Icons.route_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: AcaoIa.resumo,
                      label: Text('Resumo'),
                      icon: Icon(Icons.auto_stories_outlined, size: 18),
                    ),
                  ],
                  selected: {_acao},
                  onSelectionChanged: _gerando
                      ? null
                      : (selecao) => _mudarAcao(selecao.first),
                ),
                const SizedBox(height: 10),
                Text(
                  _acao.descricao,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (_acao == AcaoIa.dicas)
                  _buildSeletorLugar(lugares, selecionado),
                _buildBotaoGerar(lugares, selecionado),
                if (_gerando) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                const SizedBox(height: 20),
                _buildResultado(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HistoricoIaScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Ver histórico da IA'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (emRotaSeparada) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assistente de viagem')),
        body: conteudo,
      );
    }

    return conteudo;
  }

  Widget _buildCabecalho(List<Lugar> lugares) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assistente de viagem',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lugares.isEmpty
                        ? 'Cadastre lugares no diário para começar.'
                        : '${lugares.length} lugar(es) disponíveis para a IA.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.auto_awesome_outlined, color: scheme.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSeletorLugar(List<Lugar> lugares, Lugar? selecionado) {
    if (lugares.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Adicione um lugar no Diário para pedir dicas específicas.',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final idValido =
        selecionado != null &&
            lugares.any((lugar) => lugar.id == selecionado.id)
        ? selecionado.id
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey(idValido ?? 'sem-lugar'),
        initialValue: idValido,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Lugar',
          prefixIcon: Icon(Icons.place_outlined),
        ),
        items: lugares
            .map(
              (lugar) => DropdownMenuItem(
                value: lugar.id,
                child: Text(lugar.nome, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: _gerando ? null : _mudarLugar,
      ),
    );
  }

  Widget _buildBotaoGerar(List<Lugar> lugares, Lugar? selecionado) {
    final podeGerar =
        !_gerando &&
        ((_acao == AcaoIa.dicas && selecionado != null) ||
            (_acao != AcaoIa.dicas && lugares.isNotEmpty));

    return ElevatedButton.icon(
      onPressed: _gerando ? _parar : (podeGerar ? () => _gerar(lugares) : null),
      icon: Icon(_gerando ? Icons.stop : Icons.auto_awesome),
      label: Text(_gerando ? 'Parar' : 'Gerar com Gemini'),
    );
  }

  Widget _buildResultado() {
    final duracao = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);

    return AnimatedSwitcher(
      duration: duracao,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _buildResultadoConteudo(),
    );
  }

  Widget _buildResultadoConteudo() {
    final scheme = Theme.of(context).colorScheme;

    if (_resposta.isEmpty && _erro == null) {
      return EstadoVazio(
        key: const ValueKey<String>('ia-vazio'),
        icone: Icons.auto_awesome_outlined,
        titulo: 'Sua próxima ideia de viagem aparece aqui',
        subtitulo:
            'Escolha uma ação e toque em "Gerar com Gemini" para receber uma sugestão personalizada.',
      );
    }

    if (_erro != null) {
      return Card(
        key: const ValueKey<String>('ia-erro'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: scheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_erro!, style: TextStyle(color: scheme.error)),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      key: const ValueKey<String>('ia-resultado'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Resposta do Gemini',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copiar',
                  onPressed: _copiar,
                  icon: const Icon(Icons.copy_outlined),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_ultimaAcao.rotulo} • '
              '${_ultimoLugar?.nome ?? 'seu diário'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            RespostaMarkdown(texto: _resposta),
            const SizedBox(height: 12),
            Text(
              'Conteúdo gerado por IA. Confirme informações importantes.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../core/ai_config.dart';

class IaService {
  FirebaseAI? _ai;
  String? _modeloPreferido;

  FirebaseAI get _firebaseAi => _ai ??= FirebaseAI.googleAI();

  GenerativeModel _modelo(String modelo) {
    return _firebaseAi.generativeModel(
      model: modelo,
      generationConfig: GenerationConfig(maxOutputTokens: 1400),
      systemInstruction: Content.system(
        'Você é um guia de viagens brasileiro, objetivo e específico. '
        'Use apenas as informações fornecidas e conhecimento verificável sobre o local. '
        'Nunca invente nomes, endereços, preços ou fatos. '
        'Não trate conhecimento genérico como fato específico do local. '
        'Não presuma que todo lugar é uma atração turística. '
        'Se não souber algo, diga claramente que não sabe. '
        'Responda em português do Brasil, em tópicos curtos e práticos.',
      ),
    );
  }

  List<String> get _modelosEmOrdem {
    final preferido = _modeloPreferido;
    if (preferido == null) return AiConfig.modelos;
    return [
      preferido,
      ...AiConfig.modelos.where((modelo) => modelo != preferido),
    ];
  }

  Stream<String> gerarEmStream(String prompt) async* {
    Object? ultimoErro;

    for (final modelo in _modelosEmOrdem) {
      for (
        var tentativa = 1;
        tentativa <= AiConfig.tentativasPorModelo;
        tentativa++
      ) {
        var recebeuAlgo = false;

        try {
          final model = _modelo(modelo);
          final stream = model.generateContentStream([Content.text(prompt)]);

          await for (final chunk in stream) {
            final texto = chunk.text;
            if (texto != null && texto.isNotEmpty) {
              recebeuAlgo = true;
              yield texto;
            }
          }

          if (recebeuAlgo) {
            _modeloPreferido = modelo;
            return;
          }

          ultimoErro = StateError('O modelo $modelo não retornou conteúdo.');
        } catch (e) {
          ultimoErro = e;
          debugPrint('IaService.gerarEmStream [$modelo] falhou: $e');

          if (recebeuAlgo || !_ehTemporario(e)) {
            rethrow;
          }
        }

        if (tentativa < AiConfig.tentativasPorModelo) {
          await Future<void>.delayed(AiConfig.esperaEntreTentativas);
        }
      }
    }

    throw ultimoErro ??
        Exception('Nenhum modelo conseguiu responder. Tente novamente.');
  }

  Future<String> gerar(String prompt) async {
    Object? ultimoErro;

    for (final modelo in _modelosEmOrdem) {
      for (
        var tentativa = 1;
        tentativa <= AiConfig.tentativasPorModelo;
        tentativa++
      ) {
        try {
          final model = _modelo(modelo);
          final response = await model.generateContent([Content.text(prompt)]);
          final texto = response.text;

          if (texto != null && texto.trim().isNotEmpty) {
            _modeloPreferido = modelo;
            return texto;
          }

          ultimoErro = StateError('O modelo $modelo não retornou conteúdo.');
        } catch (e) {
          ultimoErro = e;
          debugPrint('IaService.gerar [$modelo] falhou: $e');
          if (!_ehTemporario(e)) {
            rethrow;
          }
        }

        if (tentativa < AiConfig.tentativasPorModelo) {
          await Future<void>.delayed(AiConfig.esperaEntreTentativas);
        }
      }
    }

    throw ultimoErro ??
        Exception('Nenhum modelo conseguiu responder. Tente novamente.');
  }

  bool _ehTemporario(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('high demand') ||
        msg.contains('overloaded') ||
        msg.contains('unavailable') ||
        msg.contains('resource_exhausted') ||
        msg.contains('rate limit') ||
        msg.contains('quota') ||
        msg.contains('timeout') ||
        msg.contains('deadline') ||
        msg.contains('socketexception') ||
        msg.contains('network') ||
        msg.contains('503') ||
        msg.contains('502') ||
        msg.contains('504') ||
        msg.contains('500') ||
        msg.contains('429');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_utils.dart';

class HistoricoIa {
  final String id;
  final String tipo;
  final String? lugarId;
  final String prompt;
  final String resposta;
  final DateTime criadoEm;

  const HistoricoIa({
    required this.id,
    required this.tipo,
    this.lugarId,
    required this.prompt,
    required this.resposta,
    required this.criadoEm,
  });

  Map<String, dynamic> toMap() => {
    'tipo': tipo,
    if (lugarId != null) 'lugarId': lugarId,
    'prompt': prompt,
    'resposta': resposta,
    'criadoEm': Timestamp.fromDate(criadoEm),
  };

  factory HistoricoIa.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return HistoricoIa(
      id: doc.id,
      tipo: data['tipo'] as String? ?? 'dicas',
      lugarId: data['lugarId'] as String?,
      prompt: data['prompt'] as String? ?? '',
      resposta: data['resposta'] as String? ?? '',
      criadoEm: timestampParaData(data['criadoEm']) ?? DateTime.now(),
    );
  }

  String get rotuloTipo {
    switch (tipo) {
      case 'roteiro':
        return 'Roteiro';
      case 'resumo':
        return 'Resumo do diário';
      default:
        return 'Dicas do lugar';
    }
  }
}

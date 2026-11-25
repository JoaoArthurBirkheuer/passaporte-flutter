import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_utils.dart';

class Lugar {
  static const String statusVisitado = 'visitado';
  static const String statusPlanejado = 'planejado';

  final String id;
  final String nome;
  final String descricao;
  final String categoria;
  final int avaliacao;
  final DateTime dataVisita;
  final double latitude;
  final double longitude;
  final String endereco;
  final String status;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  const Lugar({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.avaliacao,
    required this.dataVisita,
    required this.latitude,
    required this.longitude,
    required this.endereco,
    this.status = statusVisitado,
    this.criadoEm,
    this.atualizadoEm,
  });

  bool get visitado => status == statusVisitado;

  bool get planejado => status == statusPlanejado;

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'descricao': descricao,
    'categoria': categoria,
    'avaliacao': avaliacao,
    'dataVisita': Timestamp.fromDate(dataVisita),
    'latitude': latitude,
    'longitude': longitude,
    'endereco': endereco,
    'status': status,
    if (criadoEm != null) 'criadoEm': Timestamp.fromDate(criadoEm!),
    'atualizadoEm': Timestamp.now(),
  };

  factory Lugar.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Lugar(
      id: doc.id,
      nome: data['nome'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      categoria: data['categoria'] as String? ?? 'Outro',
      avaliacao: (data['avaliacao'] as num?)?.toInt() ?? 3,
      dataVisita: timestampParaData(data['dataVisita']) ?? DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      endereco: data['endereco'] as String? ?? '',
      status: data['status'] == statusPlanejado
          ? statusPlanejado
          : statusVisitado,
      criadoEm: timestampParaData(data['criadoEm']),
      atualizadoEm: timestampParaData(data['atualizadoEm']),
    );
  }

  Lugar copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? categoria,
    int? avaliacao,
    DateTime? dataVisita,
    double? latitude,
    double? longitude,
    String? endereco,
    String? status,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Lugar(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      avaliacao: avaliacao ?? this.avaliacao,
      dataVisita: dataVisita ?? this.dataVisita,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      endereco: endereco ?? this.endereco,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}

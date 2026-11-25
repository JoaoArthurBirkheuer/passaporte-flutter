import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/historico_ia.dart';

class HistoricoIaService {
  HistoricoIaService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _historico(String uid) {
    return _firestore.collection('users').doc(uid).collection('ia_historico');
  }

  Stream<List<HistoricoIa>> streamHistorico(String uid) {
    return _historico(uid)
        .orderBy('criadoEm', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(HistoricoIa.fromDoc).toList());
  }

  Future<void> salvar(String uid, HistoricoIa historico) async {
    await _historico(uid).add(historico.toMap());
  }

  Future<int> contar(String uid) async {
    final snapshot = await _historico(uid).count().get();
    return snapshot.count ?? 0;
  }

  Future<void> excluir(String uid, String id) async {
    await _historico(uid).doc(id).delete();
  }
}

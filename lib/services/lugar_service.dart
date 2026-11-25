import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lugar.dart';

class LugaresSnapshot {
  const LugaresSnapshot({
    required this.lugares,
    required this.fromCache,
    required this.hasPendingWrites,
  });

  final List<Lugar> lugares;
  final bool fromCache;
  final bool hasPendingWrites;
}

class LugarService {
  LugarService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _lugares(String uid) {
    return _firestore.collection('users').doc(uid).collection('lugares');
  }

  Stream<LugaresSnapshot> streamLugares(String uid) {
    return _lugares(uid)
        .orderBy('dataVisita', descending: true)
        .snapshots()
        .map(
          (snapshot) => LugaresSnapshot(
            lugares: snapshot.docs.map(Lugar.fromDoc).toList(),
            fromCache: snapshot.metadata.isFromCache,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          ),
        );
  }

  Future<List<Lugar>> listar(String uid) async {
    final snapshot = await _lugares(
      uid,
    ).orderBy('dataVisita', descending: true).get();
    return snapshot.docs.map(Lugar.fromDoc).toList();
  }

  Future<Lugar?> buscar(String uid, String lugarId) async {
    final doc = await _lugares(uid).doc(lugarId).get();
    if (!doc.exists) return null;
    return Lugar.fromDoc(doc);
  }

  Future<String> criar(String uid, Lugar lugar) async {
    final dados = lugar.toMap()
      ..['criadoEm'] = Timestamp.now()
      ..['atualizadoEm'] = Timestamp.now();
    final doc = await _lugares(uid).add(dados);
    return doc.id;
  }

  Future<void> atualizar(String uid, Lugar lugar) async {
    await _lugares(uid).doc(lugar.id).update(lugar.toMap());
  }

  Future<void> excluir(String uid, String lugarId) async {
    await _lugares(uid).doc(lugarId).delete();
  }
}

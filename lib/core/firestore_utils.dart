import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? timestampParaData(dynamic valor) {
  if (valor is Timestamp) return valor.toDate();
  if (valor is DateTime) return valor;
  return null;
}

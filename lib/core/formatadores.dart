import 'package:intl/intl.dart';

final DateFormat _formatoData = DateFormat('dd/MM/yyyy');
final DateFormat _formatoDataHora = DateFormat('dd/MM/yyyy • HH:mm');

String formatarData(DateTime data) => _formatoData.format(data);

String formatarDataHora(DateTime data) => _formatoDataHora.format(data);

String formatarCoordenada(double valor) => valor.toStringAsFixed(5);

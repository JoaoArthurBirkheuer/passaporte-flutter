import 'dart:convert';

import 'package:http/http.dart' as http;

class EnderecoGeocodificado {
  const EnderecoGeocodificado({
    required this.enderecoCompleto,
    this.cidade,
    this.estado,
    this.pais,
  });

  final String enderecoCompleto;
  final String? cidade;
  final String? estado;
  final String? pais;

  String get cidadeEstado {
    final partes = [
      if (cidade != null && cidade!.isNotEmpty) cidade!,
      if (estado != null && estado!.isNotEmpty) estado!,
    ];
    return partes.join(' - ');
  }
}

class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, EnderecoGeocodificado?> _cache = {};

  Future<EnderecoGeocodificado?> reverse({
    required double latitude,
    required double longitude,
  }) async {
    final chave =
        '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
    if (_cache.containsKey(chave)) return _cache[chave];

    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'accept-language': 'pt-BR',
      'zoom': '18',
      'addressdetails': '1',
    });

    try {
      final resposta = await _client
          .get(
            uri,
            headers: const {
              'User-Agent': 'PassaporteTDM/1.0 (projeto academico)',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (resposta.statusCode != 200) {
        _cache[chave] = null;
        return null;
      }

      final json = jsonDecode(resposta.body);
      if (json is! Map<String, dynamic>) {
        _cache[chave] = null;
        return null;
      }

      final endereco =
          (json['address'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};

      String? escolher(List<String> chaves) {
        for (final chave in chaves) {
          final valor = endereco[chave];
          if (valor is String && valor.trim().isNotEmpty) {
            return valor.trim();
          }
        }
        return null;
      }

      final resultado = EnderecoGeocodificado(
        enderecoCompleto: (json['display_name'] as String?)?.trim() ?? '',
        cidade: escolher([
          'city',
          'town',
          'village',
          'municipality',
          'county',
          'suburb',
        ]),
        estado: escolher(['state', 'region']),
        pais: escolher(['country']),
      );

      if (resultado.enderecoCompleto.isEmpty) {
        _cache[chave] = null;
        return null;
      }

      _cache[chave] = resultado;
      return resultado;
    } catch (_) {
      _cache[chave] = null;
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

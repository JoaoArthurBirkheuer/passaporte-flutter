import 'package:geolocator/geolocator.dart';

class LocalizacaoException implements Exception {
  const LocalizacaoException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class LocalizacaoService {
  Future<Position> obterPosicaoAtual() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      throw const LocalizacaoException(
        'A localização do dispositivo está desativada. Ative o GPS e tente novamente.',
      );
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.denied) {
      throw const LocalizacaoException('Permissão de localização negada.');
    }

    if (permissao == LocationPermission.deniedForever) {
      throw const LocalizacaoException(
        'Permissão de localização negada permanentemente. Habilite nas configurações do app.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  double distanciaEmMetros({
    required double origemLat,
    required double origemLng,
    required double destinoLat,
    required double destinoLng,
  }) {
    return Geolocator.distanceBetween(
      origemLat,
      origemLng,
      destinoLat,
      destinoLng,
    );
  }
}

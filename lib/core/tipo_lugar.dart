import '../models/lugar.dart';

String tipoEfetivo(Lugar lugar) {
  final categoria = lugar.categoria.trim();

  if (categoria == 'Hotel') return 'Hospedagem';
  if (categoria == 'Restaurante' || categoria == 'Café') {
    return 'Restaurante/Café';
  }
  if (categoria.isNotEmpty && categoria != 'Outro') return categoria;

  final nome = lugar.nome.toLowerCase();

  if (_contemAlgum(nome, [
    'aeroporto',
    'rodoviária',
    'rodoviaria',
    'terminal',
    'estação',
    'estacao',
  ])) {
    return 'Transporte';
  }
  if (_contemAlgum(nome, ['casa', 'apartamento', 'residência', 'residencia'])) {
    return 'Residência';
  }
  if (_contemAlgum(nome, ['hotel', 'pousada', 'hostel'])) {
    return 'Hospedagem';
  }
  if (_contemAlgum(nome, [
    'restaurante',
    'lanchonete',
    'café',
    'cafe',
    'cafeteria',
  ])) {
    return 'Restaurante/Café';
  }
  if (nome.contains('praia')) return 'Praia';
  if (nome.contains('parque')) return 'Parque';
  if (nome.contains('museu')) return 'Museu';
  if (nome.contains('trilha')) return 'Trilha';
  if (_contemAlgum(nome, ['igreja', 'santuário', 'santuario'])) {
    return 'Igreja';
  }

  return 'Outro';
}

bool _contemAlgum(String texto, List<String> termos) {
  for (final termo in termos) {
    if (texto.contains(termo)) return true;
  }
  return false;
}

String focoParaTipo(String tipo) {
  switch (tipo) {
    case 'Transporte':
      return 'Este é um ponto de transporte. Foque em acesso, transporte público, '
          'estacionamento, check-in, segurança e tempo de espera. Não fale de '
          'alimentação a menos que as anotações mencionem comida.';
    case 'Restaurante/Café':
      return 'Este é um lugar de alimentação. Foque em pratos, horários, reserva '
          'e preço.';
    case 'Praia':
    case 'Parque':
    case 'Trilha':
      return 'Foque em clima, calçado, segurança e melhor horário para a '
          'atividade.';
    case 'Museu':
    case 'Centro histórico':
      return 'Foque em ingressos, horários, filas, guias e respeito ao espaço.';
    case 'Hospedagem':
      return 'Foque em check-in, localização, estacionamento e comodidades.';
    case 'Residência':
      return 'Este é um lugar residencial, não uma atração turística. Foque em '
          'informações práticas, segurança, acesso e arredores.';
    case 'Igreja':
      return 'Foque em horários de missa, dress code, respeito e arredores.';
    default:
      return 'Foque em informações práticas e específicas para este tipo de '
          'lugar.';
  }
}

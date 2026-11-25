import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_final_tdm_joao_arthur/core/tipo_lugar.dart';
import 'package:projeto_final_tdm_joao_arthur/models/historico_ia.dart';
import 'package:projeto_final_tdm_joao_arthur/models/lugar.dart';

void main() {
  test('Lugar.toMap contém os campos usados pelo Firestore', () {
    final lugar = Lugar(
      id: 'lugar-1',
      nome: 'Mirante',
      descricao: 'Vista incrível',
      categoria: 'Montanha',
      avaliacao: 5,
      dataVisita: DateTime(2026, 1, 15),
      latitude: -22.9519,
      longitude: -43.2105,
      endereco: 'Rio de Janeiro',
    );

    final map = lugar.toMap();

    expect(map['nome'], 'Mirante');
    expect(map['categoria'], 'Montanha');
    expect(map['avaliacao'], 5);
    expect(map['latitude'], -22.9519);
    expect(map['longitude'], -43.2105);
    expect(map.containsKey('atualizadoEm'), isTrue);
    expect(map.containsKey('dataVisita'), isTrue);
    expect(lugar.visitado, isTrue);
    expect(map['status'], Lugar.statusVisitado);
  });

  test('Lugar planejado mantém o status no mapa do Firestore', () {
    final lugar = Lugar(
      id: 'lugar-2',
      nome: 'Chapada',
      descricao: 'Próxima viagem',
      categoria: 'Trilha',
      avaliacao: 5,
      dataVisita: DateTime(2027, 7, 10),
      latitude: -12.5,
      longitude: -41.5,
      endereco: 'Chapada Diamantina',
      status: Lugar.statusPlanejado,
    );

    expect(lugar.planejado, isTrue);
    expect(lugar.visitado, isFalse);
    expect(lugar.toMap()['status'], Lugar.statusPlanejado);
  });

  test('tipoEfetivo reconhece aeroporto, casa e restaurante', () {
    Lugar criar(String nome, String categoria) => Lugar(
      id: nome,
      nome: nome,
      descricao: '',
      categoria: categoria,
      avaliacao: 4,
      dataVisita: DateTime(2026, 1, 1),
      latitude: -28.2,
      longitude: -52.4,
      endereco: 'Passo Fundo',
    );

    expect(
      tipoEfetivo(criar('Aeroporto de Passo Fundo', 'Outro')),
      'Transporte',
    );
    expect(tipoEfetivo(criar('Minha casa', 'Outro')), 'Residência');
    expect(
      tipoEfetivo(criar('Restaurante Central', 'Restaurante')),
      'Restaurante/Café',
    );
    expect(tipoEfetivo(criar('Praia do Forte', 'Praia')), 'Praia');
  });

  test('HistoricoIa.toMap mantém prompt, resposta e tipo', () {
    final historico = HistoricoIa(
      id: 'historico-1',
      tipo: 'roteiro',
      lugarId: 'lugar-1',
      prompt: 'Monte um roteiro',
      resposta: 'Manhã: mirante...',
      criadoEm: DateTime(2026, 2, 1),
    );

    final map = historico.toMap();

    expect(map['tipo'], 'roteiro');
    expect(map['lugarId'], 'lugar-1');
    expect(map['prompt'], 'Monte um roteiro');
    expect(map['resposta'], 'Manhã: mirante...');
    expect(map.containsKey('criadoEm'), isTrue);
  });
}

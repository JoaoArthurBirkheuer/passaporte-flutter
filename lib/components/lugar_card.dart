import 'package:flutter/material.dart';

import '../core/categorias.dart';
import '../core/formatadores.dart';
import '../models/lugar.dart';

class LugarCard extends StatelessWidget {
  const LugarCard({super.key, required this.lugar, this.onTap, this.onDelete});

  final Lugar lugar;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'lugar-${lugar.id}',
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    iconeCategoria(lugar.categoria),
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lugar.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (lugar.planejado) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Planejado',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: scheme.onTertiaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lugar.planejado
                          ? '${lugar.categoria} • previsto para ${formatarData(lugar.dataVisita)}'
                          : '${lugar.categoria} • ${formatarData(lugar.dataVisita)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (lugar.endereco.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        lugar.endereco,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(
                            i <= lugar.avaliacao
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 17,
                            color: const Color(0xFFF59E0B),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Excluir',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

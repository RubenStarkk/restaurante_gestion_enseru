import 'package:flutter/material.dart';
import '../models/order_model.dart';

/// Una fila de la comanda — un plato con su qty, total y estado de
/// cocina. Permite editar la cantidad o eliminar la línea desde la UI.
class OrderItemRow extends StatelessWidget {
  final OrderItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const OrderItemRow({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final (kitchenLabel, kitchenColor) = switch (item.kitchenStatus) {
      KitchenStatus.pending => ('Pendiente', Colors.grey),
      KitchenStatus.preparing => ('Preparando', Colors.orange),
      KitchenStatus.ready => ('Listo', Colors.blue),
      KitchenStatus.served => ('Servido', Colors.green),
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${item.qty} × ${item.unitPrice.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    decoration: BoxDecoration(
                      color: kitchenColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    child: Text(
                      kitchenLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: kitchenColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Botones de cantidad (deshabilitados si ya está siendo
            // preparado o servido para no liar a cocina).
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: item.kitchenStatus == KitchenStatus.pending
                  ? (item.qty > 1 ? onDecrement : onRemove)
                  : null,
            ),
            SizedBox(
              width: 22,
              child: Text(
                '${item.qty}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: item.kitchenStatus == KitchenStatus.pending
                  ? onIncrement
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              '${item.lineTotal.toStringAsFixed(2)} €',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
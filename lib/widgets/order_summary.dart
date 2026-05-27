import 'package:flutter/material.dart';
import '../models/order_model.dart';

/// Resumen de la comanda al pie de la pantalla. Muestra nº de items
/// y total. Solo lectura, no se interactúa con él.
class OrderSummary extends StatelessWidget {
  final List<OrderItem> items;
  const OrderSummary({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, it) => sum + it.lineTotal);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.receipt_long,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '${items.length} ${items.length == 1 ? "línea" : "líneas"}',
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Text(
            'Total: ${total.toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../models/menu_item_model.dart';
import '../../models/order_model.dart';
import '../../models/table_model.dart';
import '../../services/menu_service.dart';
import '../../services/orders_service.dart';
import '../../widgets/order_item_row.dart';
import '../../widgets/order_summary.dart';

/// Pantalla de toma de comandas. Dos paneles:
///   - Izquierda: carta digital agrupada por categorías, con botón
///     "Añadir" en cada plato.
///   - Derecha: lista de items de la comanda actual + resumen + cerrar.
///
/// En móvil, los dos paneles se apilan verticalmente; en tablet/PC
/// quedan lado a lado.
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _ordersService = OrdersService();
  final _menuService = MenuService();

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final order = args?['order'] as OrderModel?;
    final table = args?['table'] as TableModel?;

    if (order == null || table == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comanda')),
        body: const Center(
            child: Text('Comanda no especificada. Vuelve al detalle de mesa.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Comanda · Mesa ${table.name}'),
        actions: [
          StreamBuilder<OrderModel?>(
            stream: _ordersService.watchOpenOrderForTable(table.id),
            builder: (context, snap) {
              final isOpen = snap.data?.status == OrderStatus.open;
              return TextButton.icon(
                icon: Icon(
                  isOpen ? Icons.lock : Icons.lock_open,
                  color: Colors.white,
                ),
                label: Text(
                  isOpen ? 'Cerrar cuenta' : 'Reabrir',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () => isOpen
                    ? _confirmAndClose(order.id)
                    : _ordersService.reopenOrder(order.id),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          if (wide) {
            return Row(
              children: [
                Expanded(flex: 5, child: _MenuPanel(
                  menuService: _menuService,
                  onPick: (item) => _pickAndAdd(item, order.id),
                )),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 4,
                  child: _OrderPanel(
                    order: order,
                    ordersService: _ordersService,
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(child: _MenuPanel(
                  menuService: _menuService,
                  onPick: (item) => _pickAndAdd(item, order.id),
                )),
                const Divider(height: 1),
                Expanded(
                  child: _OrderPanel(
                    order: order,
                    ordersService: _ordersService,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmAndClose(String orderId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar cuenta'),
        content: const Text(
            '¿Cerrar la comanda? Podrás reabrirla si necesitas añadir más consumiciones.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _ordersService.closeOrder(orderId);
    }
  }

  /// Si es un plato per_person, pregunta cuántas personas. Si es per_unit,
  /// añade directamente con qty=1.
  Future<void> _pickAndAdd(MenuItemModel item, String orderId) async {
    int qty = 1;
    if (item.pricingType == PricingType.perPerson) {
      final picked = await showDialog<int>(
        context: context,
        builder: (_) => _PerPersonDialog(item: item),
      );
      if (picked == null) return; // canceló
      qty = picked;
    }
    await _ordersService.addItem(orderId: orderId, item: item, qty: qty);
  }
}

// ============================================================
//  Panel izquierdo — carta
// ============================================================

class _MenuPanel extends StatelessWidget {
  final MenuService menuService;
  final ValueChanged<MenuItemModel> onPick;
  const _MenuPanel({required this.menuService, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MenuItemModel>>(
      stream: menuService.watchAll(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        // Agrupar por categoría (helper que ya existe en MenuService).
        final byCategory = <String, List<MenuItemModel>>{};
        for (final it in items) {
          byCategory.putIfAbsent(it.category, () => []).add(it);
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final entry in byCategory.entries) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final it in entry.value)
                Card(
                  child: ListTile(
                    title: Text(it.name),
                    subtitle: Text(
                      '${it.price.toStringAsFixed(2)} €'
                          '${it.pricingType == PricingType.perPerson ? " / pers." : ""}',
                    ),
                    trailing: const Icon(Icons.add_circle),
                    onTap: () => onPick(it),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

// ============================================================
//  Panel derecho — la comanda
// ============================================================

class _OrderPanel extends StatelessWidget {
  final OrderModel order;
  final OrdersService ordersService;
  const _OrderPanel({required this.order, required this.ordersService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderItem>>(
      stream: ordersService.watchItems(order.id),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        return Column(
          children: [
            Expanded(
              child: items.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aún no hay items.\nToca un plato de la carta para añadirlo.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  for (final it in items)
                    OrderItemRow(
                      item: it,
                      onIncrement: () => ordersService.updateItemQty(
                        orderId: order.id,
                        itemId: it.id,
                        newQty: it.qty + 1,
                      ),
                      onDecrement: () => ordersService.updateItemQty(
                        orderId: order.id,
                        itemId: it.id,
                        newQty: it.qty - 1,
                      ),
                      onRemove: () => ordersService.removeItem(
                        orderId: order.id,
                        itemId: it.id,
                      ),
                    ),
                ],
              ),
            ),
            OrderSummary(items: items),
          ],
        );
      },
    );
  }
}

// ============================================================
//  Diálogo "cuántas personas" para platos per_person
// ============================================================

class _PerPersonDialog extends StatefulWidget {
  final MenuItemModel item;
  const _PerPersonDialog({required this.item});

  @override
  State<_PerPersonDialog> createState() => _PerPersonDialogState();
}

class _PerPersonDialogState extends State<_PerPersonDialog> {
  int _qty = 2;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.item.price.toStringAsFixed(2)} € por persona',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const Text('¿Para cuántas personas?'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$_qty',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _qty++),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Subtotal: ${(widget.item.price * _qty).toStringAsFixed(2)} €',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_qty),
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}
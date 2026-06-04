import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../services/orders_service.dart';

/// Vista de cocina en tiempo real — Sprint 2 Kike.
///
/// Muestra todas las líneas de comandas abiertas con estado
/// pending o preparing, agrupadas por mesa.
///
/// Usa exclusivamente tipos ya definidos en el proyecto:
///   - KitchenStatus (order_model.dart): pending, preparing, ready, served
///   - OrderItem     (order_model.dart): id, name, qty, kitchenStatus…
///   - OrdersService (orders_service.dart): watchKitchenItems(),
///                                          updateKitchenStatus()
class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final _service = OrdersService();
  KitchenStatus? _filter; // null = ver pending + preparing

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'COCINA',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 6,
            fontWeight: FontWeight.w300,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [const _LiveClock(), const SizedBox(width: 16)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FilterBar(
            selected: _filter,
            onSelect: (s) => setState(() => _filter = s),
          ),
        ),
      ),
      body: StreamBuilder<List<KitchenItem>>(
        stream: _service.watchKitchenItems(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A843)),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: Color(0xFF555555), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Error al conectar\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF888888)),
                  ),
                ],
              ),
            );
          }

          var items = snap.data ?? [];
          if (_filter != null) {
            items = items
                .where((ki) => ki.item.kitchenStatus == _filter)
                .toList();
          }

          if (items.isEmpty) {
            return _EmptyState(filter: _filter);
          }

          return _KitchenGrid(items: items, service: _service);
        },
      ),
    );
  }
}

// ─── Barra de filtros ─────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelect});

  final KitchenStatus? selected;
  final ValueChanged<KitchenStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      height: 48,
      child: Row(
        children: [
          _FilterChip(
            label: 'Todos',
            color: Colors.white,
            active: selected == null,
            onTap: () => onSelect(null),
          ),
          _FilterChip(
            label: 'Pendiente',
            color: _colorOf(KitchenStatus.pending),
            active: selected == KitchenStatus.pending,
            onTap: () => onSelect(
                selected == KitchenStatus.pending ? null : KitchenStatus.pending),
          ),
          _FilterChip(
            label: 'Preparando',
            color: _colorOf(KitchenStatus.preparing),
            active: selected == KitchenStatus.preparing,
            onTap: () => onSelect(selected == KitchenStatus.preparing
                ? null
                : KitchenStatus.preparing),
          ),
          _FilterChip(
            label: 'Listo',
            color: _colorOf(KitchenStatus.ready),
            active: selected == KitchenStatus.ready,
            onTap: () => onSelect(
                selected == KitchenStatus.ready ? null : KitchenStatus.ready),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: active ? color : Colors.transparent, width: 2),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? color : const Color(0xFF555555),
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Grid responsive de mesas ─────────────────────────────────────────────────

class _KitchenGrid extends StatelessWidget {
  const _KitchenGrid({required this.items, required this.service});

  final List<KitchenItem> items;
  final OrdersService service;

  @override
  Widget build(BuildContext context) {
    // agrupar por mesa
    final byTable = <String, List<KitchenItem>>{};
    for (final ki in items) {
      byTable.putIfAbsent(ki.tableId, () => []).add(ki);
    }
    final tableIds = byTable.keys.toList()..sort();

    return LayoutBuilder(builder: (context, constraints) {
      // 1 col < 600 px, 2 < 900 px, 3 en adelante
      final cols = constraints.maxWidth >= 900
          ? 3
          : constraints.maxWidth >= 600
          ? 2
          : 1;

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemCount: tableIds.length,
        itemBuilder: (context, i) {
          final id = tableIds[i];
          return _TableCard(
            tableId: id,
            items: byTable[id]!,
            service: service,
          );
        },
      );
    });
  }
}

// ─── Tarjeta de mesa ──────────────────────────────────────────────────────────

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.tableId,
    required this.items,
    required this.service,
  });

  final String tableId;
  final List<KitchenItem> items;
  final OrdersService service;

  @override
  Widget build(BuildContext context) {
    final hasPending =
    items.any((ki) => ki.item.kitchenStatus == KitchenStatus.pending);
    final hasPreparing =
    items.any((ki) => ki.item.kitchenStatus == KitchenStatus.preparing);

    // color del borde según urgencia: pending > preparing > ninguno
    final borderColor = hasPending
        ? _colorOf(KitchenStatus.pending)
        : hasPreparing
        ? _colorOf(KitchenStatus.preparing)
        : const Color(0xFF333333);

    // número legible de mesa (quita prefijos como "table_", "mesa_")
    final tableLabel = tableId
        .replaceAll('table_', '')
        .replaceAll('mesa_', '')
        .replaceAll('_', ' ');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // cabecera
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF252525),
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Icon(Icons.table_restaurant_rounded,
                    color: borderColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Mesa $tableLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length} plato${items.length != 1 ? "s" : ""}',
                  style: const TextStyle(
                      color: Color(0xFF777777), fontSize: 11),
                ),
              ],
            ),
          ),
          // items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
              const Divider(color: Color(0xFF2E2E2E), height: 1),
              itemBuilder: (_, i) => _ItemRow(
                ki: items[i],
                service: service,
              ),
            ),
          ),
          // botón "Todo listo" — solo visible si hay algo pendiente o preparando
          if (hasPending || hasPreparing)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: _MarkAllReadyButton(items: items, service: service),
            ),
        ],
      ),
    );
  }
}

// ─── Botón "Todo listo" ───────────────────────────────────────────────────────

class _MarkAllReadyButton extends StatefulWidget {
  const _MarkAllReadyButton({required this.items, required this.service});

  final List<KitchenItem> items;
  final OrdersService service;

  @override
  State<_MarkAllReadyButton> createState() => _MarkAllReadyButtonState();
}

class _MarkAllReadyButtonState extends State<_MarkAllReadyButton> {
  bool _loading = false;

  Future<void> _markAll() async {
    setState(() => _loading = true);
    try {
      for (final ki in widget.items) {
        if (ki.item.kitchenStatus != KitchenStatus.ready &&
            ki.item.kitchenStatus != KitchenStatus.served) {
          await widget.service.updateKitchenStatus(
            orderId: ki.orderId,
            itemId: ki.item.id,
            status: KitchenStatus.ready,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readyColor = _colorOf(KitchenStatus.ready);
    return GestureDetector(
      onTap: _loading ? null : _markAll,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: readyColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: readyColor.withOpacity(0.4)),
        ),
        child: _loading
            ? const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: readyColor, size: 14),
            const SizedBox(width: 6),
            Text(
              'Todo listo',
              style: TextStyle(
                color: readyColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fila de item ─────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.ki, required this.service});

  final KitchenItem ki;
  final OrdersService service;

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(ki.item.kitchenStatus);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // punto de estado
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          // nombre + cantidad
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ki.item.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  // qty viene de OrderItem.qty (el modelo real)
                  'x${ki.item.qty}',
                  style: const TextStyle(
                      color: Color(0xFF777777), fontSize: 11),
                ),
              ],
            ),
          ),
          // botón de avance de estado
          _AdvanceButton(ki: ki, service: service),
        ],
      ),
    );
  }
}

// ─── Botón avanzar estado ─────────────────────────────────────────────────────

class _AdvanceButton extends StatefulWidget {
  const _AdvanceButton({required this.ki, required this.service});

  final KitchenItem ki;
  final OrdersService service;

  @override
  State<_AdvanceButton> createState() => _AdvanceButtonState();
}

class _AdvanceButtonState extends State<_AdvanceButton> {
  bool _loading = false;

  // pending → preparing → ready → served (ya no avanza)
  KitchenStatus? _next(KitchenStatus current) => switch (current) {
    KitchenStatus.pending   => KitchenStatus.preparing,
    KitchenStatus.preparing => KitchenStatus.ready,
    KitchenStatus.ready     => KitchenStatus.served,
    KitchenStatus.served    => null,
  };

  String _nextLabel(KitchenStatus current) => switch (current) {
    KitchenStatus.pending   => 'Preparando',
    KitchenStatus.preparing => 'Listo',
    KitchenStatus.ready     => 'Servido',
    KitchenStatus.served    => '',
  };

  Future<void> _advance() async {
    final next = _next(widget.ki.item.kitchenStatus);
    if (next == null) return;
    setState(() => _loading = true);
    try {
      await widget.service.updateKitchenStatus(
        orderId: widget.ki.orderId,
        itemId: widget.ki.item.id,
        status: next,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.ki.item.kitchenStatus;

    if (current == KitchenStatus.served) {
      return const Icon(Icons.check_circle_rounded,
          color: Color(0xFF555555), size: 20);
    }

    if (_loading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: Color(0xFFD4A843)),
      );
    }

    final next = _next(current)!;
    final color = _colorOf(next);
    return GestureDetector(
      onTap: _advance,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Text(
          _nextLabel(current),
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final KitchenStatus? filter;

  @override
  Widget build(BuildContext context) {
    final msg = filter == null
        ? 'No hay comandas activas'
        : 'No hay platos en estado "${_labelOf(filter!)}"';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.restaurant_menu_rounded,
              color: Color(0xFF333333), size: 64),
          const SizedBox(height: 20),
          Text(msg,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            'Las nuevas comandas aparecerán aquí en tiempo real',
            style: TextStyle(color: Color(0xFF444444), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Reloj en vivo ────────────────────────────────────────────────────────────

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _now = DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _now;
    final s =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    return Text(s,
        style: const TextStyle(
            color: Color(0xFF777777),
            fontSize: 13,
            fontFamily: 'monospace',
            letterSpacing: 1));
  }
}

// ─── Helpers de color y etiqueta ─────────────────────────────────────────────

Color _colorOf(KitchenStatus s) => switch (s) {
  KitchenStatus.pending   => const Color(0xFFE74C3C),
  KitchenStatus.preparing => const Color(0xFFE8A020),
  KitchenStatus.ready     => const Color(0xFF27AE60),
  KitchenStatus.served    => const Color(0xFF555555),
};

String _labelOf(KitchenStatus s) => switch (s) {
  KitchenStatus.pending   => 'Pendiente',
  KitchenStatus.preparing => 'Preparando',
  KitchenStatus.ready     => 'Listo',
  KitchenStatus.served    => 'Servido',
};
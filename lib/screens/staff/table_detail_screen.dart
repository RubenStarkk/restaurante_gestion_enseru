import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/order_model.dart';
import '../../models/reservation_model.dart';
import '../../models/table_model.dart';
import '../../services/auth_service.dart';
import '../../services/orders_service.dart';
import '../../services/reservations_service.dart';
import '../../services/tables_service.dart';

/// Detalle de una mesa para el staff.
///
/// Muestra:
///   - Datos de la mesa (nombre, capacidad, estado actual)
///   - Reserva activa para hoy si existe (con teléfono ofuscado si
///     el usuario es waiter — cumple RNF3)
///   - Acciones del staff: ocupar manualmente, liberar, bloquear/
///     desbloquear, cancelar reserva (solo admin)
///   - Botón "Abrir / ver comanda" que lleva a OrderScreen
class TableDetailScreen extends StatefulWidget {
  const TableDetailScreen({super.key});

  @override
  State<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends State<TableDetailScreen> {
  final _tablesService = TablesService();
  final _ordersService = OrdersService();
  final _authService = AuthService();

  StaffRole? _role;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await _authService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        _role = role;
        _loadingRole = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialTable =
    ModalRoute.of(context)!.settings.arguments as TableModel?;

    if (initialTable == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de mesa')),
        body: const Center(child: Text('Mesa no especificada.')),
      );
    }

    // StreamBuilder para que si el estado de la mesa cambia en otro
    // dispositivo (otro camarero, el admin), aquí se vea al momento.
    return StreamBuilder<List<TableModel>>(
      stream: _tablesService.watchAll(),
      builder: (context, snap) {
        // Mientras carga, usamos la mesa que llegó por argumento.
        final table = snap.hasData
            ? snap.data!.firstWhere(
              (t) => t.id == initialTable.id,
          orElse: () => initialTable,
        )
            : initialTable;

        return Scaffold(
          appBar: AppBar(
            title: Text('Mesa ${table.name}'),
          ),
          body: _loadingRole
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TableInfoCard(table: table),
                const SizedBox(height: 16),
                _ReservationSection(table: table, role: _role),
                const SizedBox(height: 16),
                _OrderSection(
                  table: table,
                  ordersService: _ordersService,
                ),
                const SizedBox(height: 24),
                _AdminActions(
                  table: table,
                  role: _role,
                  tablesService: _tablesService,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
//  Tarjeta de info básica de la mesa
// ============================================================

class _TableInfoCard extends StatelessWidget {
  final TableModel table;
  const _TableInfoCard({required this.table});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (table.status) {
      TableStatus.free => ('Libre', Colors.green),
      TableStatus.occupied => ('Ocupada', Colors.red),
      TableStatus.reserved => ('Reservada', Colors.amber),
      TableStatus.blocked => ('Bloqueada', Colors.grey),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(Icons.event_seat, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mesa ${table.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Capacidad: ${table.capacity} personas'),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Sección "Reserva de hoy"
// ============================================================

class _ReservationSection extends StatelessWidget {
  final TableModel table;
  final StaffRole? role;
  const _ReservationSection({required this.table, required this.role});

  @override
  Widget build(BuildContext context) {
    // Buscamos reservas activas de HOY para esta mesa.
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final query = FirebaseFirestore.instance
        .collection('reservations')
        .where('tableIds', arrayContains: table.id)
        .where('date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('date', isLessThan: Timestamp.fromDate(dayEnd))
        .where('status', isEqualTo: 'active');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error al leer reservas: ${snap.error}'),
            ),
          );
        }
        if (!snap.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snap.data!.docs.isEmpty) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.event_busy),
              title: Text('Sin reservas para hoy'),
              subtitle:
              Text('La mesa no tiene reservas activas hoy.'),
            ),
          );
        }
        final reservations =
        snap.data!.docs.map(ReservationModel.fromDoc).toList();
        return Column(
          children: [
            for (final r in reservations)
              _ReservationCard(reservation: r, role: role),
          ],
        );
      },
    );
  }
}

class _ReservationCard extends StatefulWidget {
  final ReservationModel reservation;
  final StaffRole? role;
  const _ReservationCard({required this.reservation, required this.role});

  @override
  State<_ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<_ReservationCard> {
  final _reservationsService = ReservationsService();
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;
    final role = widget.role;
    final isAdmin = role == StaffRole.admin;
    final phoneDisplay = isAdmin
        ? reservation.customerPhone
        : maskPhone(reservation.customerPhone);
    final shiftLabel = reservation.shift == Shift.lunch
        ? 'Comida (13:00)'
        : 'Cena (20:00)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Reserva activa',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            _Row(icon: Icons.person, label: reservation.customerName),
            _Row(
              icon: Icons.phone,
              label: phoneDisplay,
              trailing: isAdmin
                  ? null
                  : const Tooltip(
                message: 'Visible solo para admin',
                child: Icon(Icons.lock_outline,
                    size: 16, color: Colors.grey),
              ),
            ),
            if (isAdmin &&
                (reservation.customerEmail?.isNotEmpty ?? false))
              _Row(
                icon: Icons.email_outlined,
                label: reservation.customerEmail!,
              ),
            _Row(icon: Icons.access_time, label: shiftLabel),
            _Row(
              icon: Icons.people,
              label:
              '${reservation.guests} ${reservation.guests == 1 ? "persona" : "personas"}',
            ),
            if (reservation.preorderedItems.isNotEmpty) ...[
              const Divider(),
              Text(
                'Platos pre-encargados',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              for (final p in reservation.preorderedItems)
                Text('· ${p.qty}× ${p.name}'),
            ],
            // Botón de cancelación — solo admin.
            if (isAdmin) ...[
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: _cancelling
                      ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.cancel_outlined),
                  label: Text(_cancelling
                      ? 'Cancelando…'
                      : 'Cancelar reserva'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                  onPressed: _cancelling ? null : _confirmAndCancel,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Text(
          '¿Cancelar la reserva de ${widget.reservation.customerName}? '
              'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _cancelling = true);
    try {
      await _reservationsService.cancelReservation(widget.reservation.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva cancelada.')),
      );
      // No hace falta tocar _cancelling: el StreamBuilder de la sección
      // padre detectará el cambio de status y dejará de pintar esta card.
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cancelar: $e')),
      );
    }
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  const _Row({required this.icon, required this.label, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ============================================================
//  Sección "Comanda" — abre o lleva a la pantalla de comanda
// ============================================================

class _OrderSection extends StatelessWidget {
  final TableModel table;
  final OrdersService ordersService;
  const _OrderSection({required this.table, required this.ordersService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderModel?>(
      stream: ordersService.watchOpenOrderForTable(table.id),
      builder: (context, snap) {
        final hasOpen = snap.data != null;
        return Card(
          child: ListTile(
            leading: Icon(
              hasOpen ? Icons.receipt_long : Icons.add_circle_outline,
              color: hasOpen
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(hasOpen ? 'Ver comanda activa' : 'Abrir comanda'),
            subtitle: Text(
              hasOpen
                  ? 'Continúa añadiendo platos o cierra la cuenta'
                  : 'Inicia una nueva comanda para esta mesa',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Si no hay comanda abierta, la creamos antes de navegar.
              OrderModel order;
              if (snap.data != null) {
                order = snap.data!;
              } else {
                order = await ordersService.openForTable(table.id);
              }
              if (!context.mounted) return;
              Navigator.of(context).pushNamed(
                AppRoutes.staffOrder,
                arguments: {'order': order, 'table': table},
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================
//  Acciones del staff (solo admin)
// ============================================================

class _AdminActions extends StatelessWidget {
  final TableModel table;
  final StaffRole? role;
  final TablesService tablesService;

  const _AdminActions({
    required this.table,
    required this.role,
    required this.tablesService,
  });

  @override
  Widget build(BuildContext context) {
    if (role != StaffRole.admin) {
      // Los camareros no ven estos botones.
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Acciones de administrador',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (table.status == TableStatus.blocked)
          OutlinedButton.icon(
            icon: const Icon(Icons.lock_open),
            label: const Text('Desbloquear mesa'),
            onPressed: () => _changeStatus(context, TableStatus.free),
          )
        else
          OutlinedButton.icon(
            icon: const Icon(Icons.block),
            label: const Text('Bloquear mesa (reserva telefónica)'),
            onPressed: () => _changeStatus(context, TableStatus.blocked),
          ),
        const SizedBox(height: 8),
        if (table.status == TableStatus.occupied)
          OutlinedButton.icon(
            icon: const Icon(Icons.event_seat),
            label: const Text('Marcar como libre'),
            onPressed: () => _changeStatus(context, TableStatus.free),
          )
        else if (table.status == TableStatus.free)
          OutlinedButton.icon(
            icon: const Icon(Icons.restaurant),
            label: const Text('Marcar como ocupada'),
            onPressed: () => _changeStatus(context, TableStatus.occupied),
          ),
      ],
    );
  }

  Future<void> _changeStatus(
      BuildContext context, TableStatus newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('tables')
          .doc(table.id)
          .update({'status': tableStatusToString(newStatus)});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesa ${table.name} actualizada.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
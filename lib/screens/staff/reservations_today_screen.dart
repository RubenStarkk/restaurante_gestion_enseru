import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../../models/reservation_model.dart';
import '../../models/table_model.dart';
import '../../services/auth_service.dart';
import '../../services/reservations_service.dart';
import '../../services/tables_service.dart';

/// Pantalla "Reservas del día" para el staff.
///
/// Lista todas las reservas del día actual (activas, canceladas, etc.)
/// agrupadas por turno, con totales arriba. Al pulsar una reserva,
/// navega al TableDetailScreen de su mesa.
///
/// Aplica RNF3: si el usuario es waiter, los teléfonos aparecen
/// parcialmente ocultos mediante maskPhone().
class ReservationsTodayScreen extends StatefulWidget {
  const ReservationsTodayScreen({super.key});

  @override
  State<ReservationsTodayScreen> createState() =>
      _ReservationsTodayScreenState();
}

class _ReservationsTodayScreenState extends State<ReservationsTodayScreen> {
  final _reservationsService = ReservationsService();
  final _tablesService = TablesService();
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
    final today = DateTime.now();
    final dateLabel = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(today);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Reservas del día'),
            Text(
              dateLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: _loadingRole
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ReservationModel>>(
        stream: _reservationsService.watchToday(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _ErrorBox(error: snap.error!);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          if (all.isEmpty) {
            return const _EmptyBox();
          }
          return _ReservationsContent(
            reservations: all,
            role: _role,
            tablesService: _tablesService,
          );
        },
      ),
    );
  }
}

// ============================================================
//  Contenido cuando hay reservas
// ============================================================

class _ReservationsContent extends StatelessWidget {
  final List<ReservationModel> reservations;
  final StaffRole? role;
  final TablesService tablesService;

  const _ReservationsContent({
    required this.reservations,
    required this.role,
    required this.tablesService,
  });

  @override
  Widget build(BuildContext context) {
    // Separamos por turno.
    final lunch = reservations.where((r) => r.shift == Shift.lunch).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final dinner = reservations.where((r) => r.shift == Shift.dinner).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Contadores para el resumen.
    final active = reservations
        .where((r) => r.status == ReservationStatus.active)
        .toList();
    final cancelled = reservations
        .where((r) => r.status == ReservationStatus.cancelled)
        .length;
    final totalGuests = active.fold<int>(0, (sum, r) => sum + r.guests);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryBox(
          activeCount: active.length,
          cancelledCount: cancelled,
          totalGuests: totalGuests,
        ),
        const SizedBox(height: 16),
        if (lunch.isNotEmpty) ...[
          _ShiftSection(
            title: 'Comida (13:00 – 15:30)',
            icon: Icons.wb_sunny_outlined,
            reservations: lunch,
            role: role,
            tablesService: tablesService,
          ),
          const SizedBox(height: 24),
        ],
        if (dinner.isNotEmpty)
          _ShiftSection(
            title: 'Cena (20:00 – 23:00)',
            icon: Icons.nights_stay_outlined,
            reservations: dinner,
            role: role,
            tablesService: tablesService,
          ),
      ],
    );
  }
}

// ============================================================
//  Resumen / contadores
// ============================================================

class _SummaryBox extends StatelessWidget {
  final int activeCount;
  final int cancelledCount;
  final int totalGuests;

  const _SummaryBox({
    required this.activeCount,
    required this.cancelledCount,
    required this.totalGuests,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _Stat(
              value: '$activeCount',
              label: activeCount == 1 ? 'reserva activa' : 'reservas activas',
              color: primary,
            ),
            const VerticalDivider(width: 32),
            _Stat(
              value: '$totalGuests',
              label: totalGuests == 1 ? 'persona' : 'personas',
              color: primary,
            ),
            if (cancelledCount > 0) ...[
              const VerticalDivider(width: 32),
              _Stat(
                value: '$cancelledCount',
                label: cancelledCount == 1
                    ? 'cancelada'
                    : 'canceladas',
                color: Colors.grey.shade600,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ============================================================
//  Sección de un turno
// ============================================================

class _ShiftSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ReservationModel> reservations;
  final StaffRole? role;
  final TablesService tablesService;

  const _ShiftSection({
    required this.title,
    required this.icon,
    required this.reservations,
    required this.role,
    required this.tablesService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        for (final r in reservations)
          _ReservationCard(
            reservation: r,
            role: role,
            tablesService: tablesService,
          ),
      ],
    );
  }
}

// ============================================================
//  Tarjeta de una reserva
// ============================================================

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final StaffRole? role;
  final TablesService tablesService;

  const _ReservationCard({
    required this.reservation,
    required this.role,
    required this.tablesService,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == StaffRole.admin;
    final isCancelled = reservation.status == ReservationStatus.cancelled;
    final tableIdLabel = reservation.tableIds.isEmpty
        ? '—'
        : reservation.tableIds.join(', ');
    final phoneDisplay =
    isAdmin ? reservation.customerPhone : maskPhone(reservation.customerPhone);

    return Opacity(
      opacity: isCancelled ? 0.5 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: () async {
            // Cargar el TableModel de la primera mesa y navegar al detalle.
            if (reservation.tableIds.isEmpty) return;
            final table = await tablesService
                .fetchById(reservation.tableIds.first);
            if (table == null || !context.mounted) return;
            Navigator.of(context).pushNamed(
              AppRoutes.staffTableDetail,
              arguments: table,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar con mesa
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    tableIdLabel.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Datos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reservation.customerName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (isCancelled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Cancelada',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.people, size: 14),
                          const SizedBox(width: 4),
                          Text('${reservation.guests}'),
                          const SizedBox(width: 12),
                          const Icon(Icons.phone, size: 14),
                          const SizedBox(width: 4),
                          Text(phoneDisplay),
                          if (!isAdmin) ...[
                            const SizedBox(width: 4),
                            const Tooltip(
                              message: 'Visible solo para admin',
                              child: Icon(Icons.lock_outline,
                                  size: 12, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                      if (reservation.preorderedItems.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.restaurant_menu, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${reservation.preorderedItems.length} pre-encargo'
                                  '${reservation.preorderedItems.length > 1 ? "s" : ""}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  Estado vacío y error
// ============================================================

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.event_busy, size: 56),
            SizedBox(height: 16),
            Text(
              'No hay reservas para hoy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('Cuando se creen, aparecerán aquí.'),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final Object error;
  const _ErrorBox({required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar las reservas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('$error', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
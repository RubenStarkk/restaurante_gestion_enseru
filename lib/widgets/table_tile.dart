import 'package:flutter/material.dart';
import '../models/table_model.dart';

/// Tarjeta visual de una mesa. Muestra nombre, capacidad e icono según
/// estado. Cambia de color para que un golpe de vista identifique la
/// situación de la sala.
///
/// Usado en:
/// - Dashboard del staff (Sergio): plano vivo en tiempo real.
/// - Selección de mesas del cliente (Rubén): paso 2 de la reserva.
class TableTile extends StatelessWidget {
  final TableModel table;

  /// Si está marcada (el cliente la ha seleccionado).
  final bool selected;

  /// Si está deshabilitada (no se puede pulsar).
  /// Para el cliente: estado != free.
  /// Para el staff: nunca (siempre puede entrar al detalle).
  final bool disabled;

  /// (Sprint 2 Rubén) Indica si esta mesa tiene una reserva activa
  /// para el turno actual. Cuando es `true` y el estado real es `free`,
  /// el tile se pinta como "Reservada (próximamente)" — color ámbar y
  /// pequeño candado — sin tocar el campo `status` de Firestore.
  /// Se usa en el Dashboard del staff para que el camarero vea de un
  /// vistazo qué mesas tienen reserva sin entrar al detalle.
  final bool hasActiveReservation;

  final VoidCallback? onTap;

  const TableTile({
    super.key,
    required this.table,
    this.selected = false,
    this.disabled = false,
    this.hasActiveReservation = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Si hay reserva activa pero el estado real sigue siendo libre,
    // pintamos como si fuera "reserved" (mismo ámbar). El status real
    // no se toca, sólo la representación visual.
    final effectiveStatus =
    (hasActiveReservation && table.status == TableStatus.free)
        ? TableStatus.reserved
        : table.status;

    final (bg, fg, icon, label) = _styleFor(effectiveStatus, scheme);

    // Etiqueta más explícita cuando el ámbar viene de una reserva,
    // para distinguirlo del ámbar de "status manual = reserved".
    final shownLabel =
    (hasActiveReservation && table.status == TableStatus.free)
        ? 'Reservada hoy'
        : label;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? scheme.primary : Colors.transparent,
                width: selected ? 3 : 0,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 28),
                const SizedBox(height: 4),
                Text(
                  table.name,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${table.capacity} pax',
                  style: TextStyle(color: fg, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  shownLabel,
                  style: TextStyle(color: fg, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Devuelve (color de fondo, color del texto, icono, etiqueta).
  (Color, Color, IconData, String) _styleFor(
      TableStatus status,
      ColorScheme scheme,
      ) {
    switch (status) {
      case TableStatus.free:
        return (
        Colors.green.shade100,
        Colors.green.shade900,
        Icons.event_seat,
        'Libre',
        );
      case TableStatus.occupied:
        return (
        Colors.red.shade100,
        Colors.red.shade900,
        Icons.restaurant,
        'Ocupada',
        );
      case TableStatus.reserved:
        return (
        Colors.amber.shade100,
        Colors.amber.shade900,
        Icons.bookmark,
        'Reservada',
        );
      case TableStatus.blocked:
        return (
        Colors.grey.shade300,
        Colors.grey.shade800,
        Icons.block,
        'Bloqueada',
        );
    }
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../../models/reservation_model.dart';

/// Datos que la pantalla 1 envía a la pantalla 2 mediante arguments.
class ReservationStep1Result {
  final DateTime date;
  final Shift shift;
  final int guests;

  const ReservationStep1Result({
    required this.date,
    required this.shift,
    required this.guests,
  });
}

/// Paso 1 del flujo de reserva: fecha, turno y número de comensales.
///
/// Reglas de negocio:
/// - Fecha mínima: hoy.
/// - Fecha máxima: hoy + 60 días.
/// - Comensales aceptados: 1 a 4. Si elige 5+, popup informativo y bloqueo.
class ReservationStep1Screen extends StatefulWidget {
  const ReservationStep1Screen({super.key});

  @override
  State<ReservationStep1Screen> createState() => _ReservationStep1ScreenState();
}

class _ReservationStep1ScreenState extends State<ReservationStep1Screen> {
  // Contacto de prueba para grupos grandes. Cambiar antes de la entrega.
  static const _phonePlaceholder = '+34 600 000 000';
  static const _emailPlaceholder = 'reservas@enseru.local';
  static const _maxOnlineGuests = 4;

  DateTime? _date;
  Shift? _shift;
  int _guests = 2;

  bool get _canContinue =>
      _date != null && _shift != null && _guests >= 1 && _guests <= _maxOnlineGuests;

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 60)),
      helpText: 'Selecciona la fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _showLargeGroupDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.groups, size: 40),
        title: const Text('Reserva de grupo grande'),
        content: const Text(
          'Para grupos de 5 personas o más, gestionamos la reserva por '
              'teléfono o correo para asegurar la mejor mesa para tu grupo:\n\n'
              '📞  $_phonePlaceholder\n'
              '✉️  $_emailPlaceholder\n\n'
              '¡Te esperamos!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _onContinue() {
    if (!_canContinue) return;
    Navigator.of(context).pushNamed(
      AppRoutes.reservationStep2,
      arguments: ReservationStep1Result(
        date: _date!,
        shift: _shift!,
        guests: _guests,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date == null
        ? 'Selecciona fecha'
        : DateFormat("EEEE d 'de' MMMM 'de' y", 'es_ES').format(_date!);

    return Scaffold(
      appBar: AppBar(title: const Text('Reservar mesa')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Paso 1 de 3',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¿Cuándo nos visitas?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                // --- Fecha ---
                _SectionLabel(label: 'Fecha'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(dateLabel),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(height: 16),

                // --- Turno ---
                _SectionLabel(label: 'Turno'),
                Row(
                  children: [
                    Expanded(
                      child: _ShiftCard(
                        title: 'Comida',
                        subtitle: '13:00 — 15:30',
                        icon: Icons.wb_sunny,
                        selected: _shift == Shift.lunch,
                        onTap: () => setState(() => _shift = Shift.lunch),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ShiftCard(
                        title: 'Cena',
                        subtitle: '20:00 — 23:00',
                        icon: Icons.nights_stay,
                        selected: _shift == Shift.dinner,
                        onTap: () => setState(() => _shift = Shift.dinner),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Comensales ---
                _SectionLabel(label: 'Comensales'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$_guests ${_guests == 1 ? "persona" : "personas"}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _guests > 1
                              ? () => setState(() => _guests--)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            if (_guests < _maxOnlineGuests) {
                              setState(() => _guests++);
                            } else {
                              _showLargeGroupDialog();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Para grupos de 5 personas o más, contacta con el '
                      'restaurante.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 32),

                // --- Continuar ---
                FilledButton.icon(
                  onPressed: _canContinue ? _onContinue : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Continuar', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ShiftCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
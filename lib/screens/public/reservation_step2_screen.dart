import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../../models/reservation_model.dart';
import '../../models/table_model.dart';
import '../../services/tables_service.dart';
import '../../widgets/table_tile.dart';
import 'reservation_step1_screen.dart';

/// Datos que la pantalla 2 envía a la pantalla 3.
class ReservationStep2Result {
  final ReservationStep1Result step1;
  final TableModel table;
  const ReservationStep2Result({required this.step1, required this.table});
}

/// Paso 2: el cliente ve las mesas disponibles para su grupo y elige una.
class ReservationStep2Screen extends StatefulWidget {
  const ReservationStep2Screen({super.key});

  @override
  State<ReservationStep2Screen> createState() => _ReservationStep2ScreenState();
}

class _ReservationStep2ScreenState extends State<ReservationStep2Screen> {
  final _service = TablesService();
  TableModel? _selected;

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)!.settings.arguments as ReservationStep1Result?;

    if (args == null) {
      // Si alguien entra a esta ruta sin pasar por el paso 1, lo devolvemos.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.reservationStep1);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reservar mesa')),
      body: Column(
        children: [
          _Header(args: args),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<TableModel>>(
              stream: _service.watchAvailableFor(args.guests),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _ErrorBox(error: snap.error!);
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tables = snap.data!;
                if (tables.isEmpty) {
                  return const _EmptyBox();
                }
                return _TableGrid(
                  tables: tables,
                  selected: _selected,
                  onTap: (t) => setState(() => _selected = t),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Atrás'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _selected == null
                          ? null
                          : () => Navigator.of(context).pushNamed(
                        AppRoutes.reservationStep3,
                        arguments: ReservationStep2Result(
                          step1: args,
                          table: _selected!,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Continuar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ReservationStep1Result args;
  const _Header({required this.args});

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(args.date);
    final shiftText =
    args.shift == Shift.lunch ? 'Comida · 13:00' : 'Cena · 20:00';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paso 2 de 3',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Elige tu mesa',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _Chip(icon: Icons.calendar_today, label: dateText),
              _Chip(icon: Icons.access_time, label: shiftText),
              _Chip(
                icon: Icons.person,
                label:
                '${args.guests} ${args.guests == 1 ? "persona" : "personas"}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TableGrid extends StatelessWidget {
  final List<TableModel> tables;
  final TableModel? selected;
  final ValueChanged<TableModel> onTap;

  const _TableGrid({
    required this.tables,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 2 columnas en móvil estrecho, 3 en tablet, 4 en escritorio.
        final cols = constraints.maxWidth < 480
            ? 2
            : constraints.maxWidth < 800
            ? 3
            : 4;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: tables.length,
          itemBuilder: (_, i) {
            final t = tables[i];
            final isFree = t.status == TableStatus.free;
            return TableTile(
              table: t,
              selected: selected?.id == t.id,
              disabled: !isFree,
              onTap: () => onTap(t),
            );
          },
        );
      },
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy, size: 48),
            const SizedBox(height: 12),
            Text(
              'No hay mesas con capacidad suficiente.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Prueba con un grupo más pequeño o contacta con el restaurante.',
              textAlign: TextAlign.center,
            ),
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
              'No se pudieron cargar las mesas',
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
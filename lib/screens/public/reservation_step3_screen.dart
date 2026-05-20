import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/menu_item_model.dart';
import '../../models/reservation_model.dart';
import '../../services/menu_service.dart';
import '../../services/reservations_service.dart';
import 'reservation_step2_screen.dart';

/// Paso 3 del flujo: pre-encargo (si aplica) + datos de contacto + confirmar.
class ReservationStep3Screen extends StatefulWidget {
  const ReservationStep3Screen({super.key});

  @override
  State<ReservationStep3Screen> createState() => _ReservationStep3ScreenState();
}

class _ReservationStep3ScreenState extends State<ReservationStep3Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _reservationsService = ReservationsService();
  final _menuService = MenuService();

  // <menuItemId, qty>
  final Map<String, int> _preorderQty = {};
  // Caché para construir los PreorderedItem en el momento de confirmar.
  List<MenuItemModel> _availableByOrderItems = [];

  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isMoreThan24hAhead(DateTime reservationDate, Shift shift) {
    // La hora del turno: 13:00 comida, 20:00 cena.
    final hour = shift == Shift.lunch ? 13 : 20;
    final reservationDateTime = DateTime(
      reservationDate.year,
      reservationDate.month,
      reservationDate.day,
      hour,
    );
    return reservationDateTime.difference(DateTime.now()).inHours >= 24;
  }

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)!.settings.arguments as ReservationStep2Result?;
    if (args == null) {
      // Si llegan aquí sin pasar el paso 2, los devolvemos al inicio.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final allowsPreorder = _isMoreThan24hAhead(args.step1.date, args.step1.shift);

    return Scaffold(
      appBar: AppBar(title: const Text('Reservar mesa')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Paso 3 de 3',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confirma tu reserva',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                _SummaryCard(args: args),
                const SizedBox(height: 24),

                // --- Pre-encargo ---
                if (allowsPreorder) ...[
                  _SectionTitle(
                    icon: Icons.restaurant_menu,
                    title: 'Platos "Por Encargo" (opcional)',
                    subtitle:
                    'Estos platos requieren preparación previa. Reserva '
                        'con más de 24h de antelación, así que ya puedes '
                        'añadirlos.',
                  ),
                  const SizedBox(height: 8),
                  _PreorderList(
                    service: _menuService,
                    qty: _preorderQty,
                    onChanged: (items) {
                      // Cacheamos para luego construir los PreorderedItem.
                      _availableByOrderItems = items;
                    },
                    onIncrement: (id) => setState(() {
                      _preorderQty[id] = (_preorderQty[id] ?? 0) + 1;
                    }),
                    onDecrement: (id) => setState(() {
                      final v = (_preorderQty[id] ?? 0) - 1;
                      if (v <= 0) {
                        _preorderQty.remove(id);
                      } else {
                        _preorderQty[id] = v;
                      }
                    }),
                  ),
                  const SizedBox(height: 24),
                ] else
                  _PreorderUnavailableBanner(),

                if (!allowsPreorder) const SizedBox(height: 16),

                // --- Datos de contacto ---
                _SectionTitle(
                  icon: Icons.contact_mail,
                  title: 'Datos de contacto',
                  subtitle: 'Necesitamos un teléfono por si surge cualquier '
                      'imprevisto.',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.length < 2) return 'Introduce tu nombre';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.length < 6) return 'Introduce un teléfono válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (opcional)',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null; // opcional
                    if (!t.contains('@') || !t.contains('.')) {
                      return 'Email no válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Política de cortesía: la mesa se mantiene hasta 10 minutos '
                      'después de la hora del turno.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),

                // --- Botones ---
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
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
                        onPressed: _submitting ? null : () => _confirm(args),
                        icon: _submitting
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.check_circle_outline),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            _submitting ? 'Confirmando...' : 'Confirmar reserva',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(ReservationStep2Result args) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    // Construir los preorderedItems a partir de _preorderQty + caché.
    final preordered = <PreorderedItem>[];
    for (final entry in _preorderQty.entries) {
      final item = _availableByOrderItems
          .where((m) => m.id == entry.key)
          .cast<MenuItemModel?>()
          .firstWhere((_) => true, orElse: () => null);
      if (item == null) continue;
      preordered.add(PreorderedItem(
        menuItemId: item.id,
        name: item.name,
        qty: entry.value,
        unitPrice: item.price,
      ));
    }

    try {
      final result = await _reservationsService.createReservation(
        date: args.step1.date,
        shift: args.step1.shift,
        guests: args.step1.guests,
        tableId: args.table.id,
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        customerEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text,
        preorderedItems: preordered,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _ConfirmationScreen(
            code: result.code,
            args: args,
            customerName: _nameController.text.trim(),
            preordered: preordered,
          ),
        ),
      );
    } on TableAlreadyReservedException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.error_outline, size: 40, color: Colors.red),
          title: const Text('Mesa no disponible'),
          content: Text(
            '${e.message}\n\nVolveremos al paso anterior para elegir otra mesa.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // cierra el diálogo
                Navigator.of(context).pop(); // vuelve al step 2
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear la reserva. Inténtalo de nuevo.'),
        ),
      );
    }
  }
}

// ============================================================
//  Componentes internos de la pantalla
// ============================================================

class _SummaryCard extends StatelessWidget {
  final ReservationStep2Result args;
  const _SummaryCard({required this.args});

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat("EEEE d 'de' MMMM 'de' y", 'es_ES')
        .format(args.step1.date);
    final shiftText =
    args.step1.shift == Shift.lunch ? 'Comida · 13:00' : 'Cena · 20:00';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            _Row(icon: Icons.calendar_today, label: dateText),
            _Row(icon: Icons.access_time, label: shiftText),
            _Row(
              icon: Icons.table_restaurant,
              label: 'Mesa ${args.table.name} '
                  '(capacidad ${args.table.capacity})',
            ),
            _Row(
              icon: Icons.person,
              label:
              '${args.step1.guests} ${args.step1.guests == 1 ? "persona" : "personas"}',
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Row({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.icon, required this.title, this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _PreorderUnavailableBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.amber.shade900),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Los platos "Por Encargo" (paellas, asados, etc.) requieren '
                    'reservar con más de 24h de antelación. Para esta reserva no '
                    'están disponibles online — el camarero te informará de la '
                    'carta del día.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreorderList extends StatelessWidget {
  final MenuService service;
  final Map<String, int> qty;
  final ValueChanged<List<MenuItemModel>> onChanged;
  final ValueChanged<String> onIncrement;
  final ValueChanged<String> onDecrement;

  const _PreorderList({
    required this.service,
    required this.qty,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MenuItemModel>>(
      stream: service.watchByOrderItems(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text('Error cargando platos: ${snap.error}');
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final items = snap.data!;
        WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(items));
        if (items.isEmpty) {
          return const Text('No hay platos por encargo disponibles.');
        }
        return Card(
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _PreorderRow(
                  item: items[i],
                  qty: qty[items[i].id] ?? 0,
                  onIncrement: () => onIncrement(items[i].id),
                  onDecrement: () => onDecrement(items[i].id),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PreorderRow extends StatelessWidget {
  final MenuItemModel item;
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _PreorderRow({
    required this.item,
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final priceUnit =
    item.pricingType == PricingType.perPerson ? '€ / persona' : '€';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (item.description != null && item.description!.isNotEmpty)
                  Text(
                    item.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text('${item.price.toStringAsFixed(2)} $priceUnit'),
              ],
            ),
          ),
          IconButton(
            onPressed: qty > 0 ? onDecrement : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 24,
            child: Text('$qty', textAlign: TextAlign.center),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Pantalla de confirmación final
// ============================================================

class _ConfirmationScreen extends StatelessWidget {
  final String code;
  final ReservationStep2Result args;
  final String customerName;
  final List<PreorderedItem> preordered;

  const _ConfirmationScreen({
    required this.code,
    required this.args,
    required this.customerName,
    required this.preordered,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat("EEEE d 'de' MMMM 'de' y", 'es_ES')
        .format(args.step1.date);
    final shiftText =
    args.step1.shift == Shift.lunch ? 'Comida · 13:00' : 'Cena · 20:00';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserva confirmada'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              shrinkWrap: true,
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.check_circle,
                  size: 72,
                  color: Colors.green.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Reserva confirmada!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Te esperamos, $customerName.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código de reserva',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          code,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Divider(height: 24),
                        _Row(icon: Icons.calendar_today, label: dateText),
                        _Row(icon: Icons.access_time, label: shiftText),
                        _Row(
                          icon: Icons.table_restaurant,
                          label: 'Mesa ${args.table.name}',
                        ),
                        _Row(
                          icon: Icons.person,
                          label:
                          '${args.step1.guests} ${args.step1.guests == 1 ? "persona" : "personas"}',
                        ),
                        if (preordered.isNotEmpty) ...[
                          const Divider(),
                          Text(
                            'Platos pre-encargados',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          for (final p in preordered)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('· ${p.qty}× ${p.name}'),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Recuerda: la mesa se mantiene hasta 10 minutos después de '
                      'la hora del turno. Si no puedes venir, avísanos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  icon: const Icon(Icons.home),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Volver al inicio'),
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
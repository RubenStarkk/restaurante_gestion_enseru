import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app.dart';
import '../../models/table_model.dart';
import '../../services/auth_service.dart';
import '../../services/tables_service.dart';
import '../../widgets/table_tile.dart';

/// Dashboard del staff — el "Mapa en Vivo" del local.
///
/// Muestra todas las mesas con su estado actual usando StreamBuilder:
/// si un camarero ocupa una mesa o el admin la bloquea, se ve aquí en
/// tiempo real sin recargar.
///
/// Reutiliza:
///   - `TablesService.watchAll()` (Rubén)
///   - `TableTile` (Rubén)
///
/// Al pulsar una mesa, navega al TableDetailScreen (placeholder por
/// ahora, Sprint 2 lo implementa).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tablesService = TablesService();
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa en vivo'),
        actions: [
          // Email del usuario logueado, para que se sepa quién está.
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  user.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmAndSignOut(context, authService),
          ),
        ],
      ),
      body: Column(
        children: [
          // Leyenda de colores para que cualquiera entienda el mapa
          // de un vistazo.
          const _Legend(),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<TableModel>>(
              stream: tablesService.watchAll(),
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
                  onTap: (table) {
                    Navigator.of(context).pushNamed(
                      AppRoutes.staffTableDetail,
                      arguments: table,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSignOut(
      BuildContext context, AuthService authService) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await authService.signOut();
    // Tras signOut, el AuthGate detecta el cambio y nos manda al login
    // automáticamente. Pero como esta pantalla está YA pintada, hacemos
    // un push explícito por si acaso.
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.staffLogin);
  }
}

// ============================================================
//  Sub-widgets internos
// ============================================================

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: const [
          _LegendDot(color: Colors.green, label: 'Libre'),
          _LegendDot(color: Colors.amber, label: 'Reservada'),
          _LegendDot(color: Colors.red, label: 'Ocupada'),
          _LegendDot(color: Colors.grey, label: 'Bloqueada'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TableGrid extends StatelessWidget {
  final List<TableModel> tables;
  final ValueChanged<TableModel> onTap;

  const _TableGrid({required this.tables, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 2 columnas en móvil, 4 en tablet, 6 en escritorio.
        final cols = constraints.maxWidth < 480
            ? 2
            : constraints.maxWidth < 900
            ? 4
            : 6;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: tables.length,
          itemBuilder: (_, i) => TableTile(
            table: tables[i],
            onTap: () => onTap(tables[i]),
          ),
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
          children: const [
            Icon(Icons.table_restaurant, size: 48),
            SizedBox(height: 12),
            Text('No hay mesas dadas de alta.'),
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
              'No se pudo cargar el mapa de mesas',
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
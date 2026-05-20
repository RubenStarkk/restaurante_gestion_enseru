import 'package:flutter/material.dart';

/// Raíz de la app. Define tema y rutas con nombres.
/// Cada pantalla real se irá enchufando a su ruta correspondiente a medida
/// que Sergio / Kike / Rubén las vayan creando. Mientras tanto, cada ruta
/// muestra un placeholder con el nombre del responsable.
class EnseruApp extends StatelessWidget {
  const EnseruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurante Enseru',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: AppRoutes.home,
      routes: {
        // Parte pública
        AppRoutes.home: (_) => const _Placeholder(
              who: 'Kike',
              title: 'Home / Landing',
              file: 'lib/screens/public/home_screen.dart',
            ),
        AppRoutes.menu: (_) => const _Placeholder(
              who: 'Kike',
              title: 'Carta Digital',
              file: 'lib/screens/public/menu_screen.dart',
            ),
        AppRoutes.reservationStep1: (_) => const _Placeholder(
              who: 'Rubén',
              title: 'Reserva — Paso 1 (Fecha/Turno/Personas)',
              file: 'lib/screens/public/reservation_step1_screen.dart',
            ),
        AppRoutes.reservationStep2: (_) => const _Placeholder(
              who: 'Rubén',
              title: 'Reserva — Paso 2 (Plano Interactivo)',
              file: 'lib/screens/public/reservation_step2_screen.dart',
            ),
        AppRoutes.reservationStep3: (_) => const _Placeholder(
              who: 'Rubén',
              title: 'Reserva — Paso 3 (Datos de Contacto)',
              file: 'lib/screens/public/reservation_step3_screen.dart',
            ),

        // Parte staff
        AppRoutes.staffLogin: (_) => const _Placeholder(
              who: 'Sergio',
              title: 'Login Staff',
              file: 'lib/screens/staff/login_screen.dart',
            ),
        AppRoutes.staffDashboard: (_) => const _Placeholder(
              who: 'Sergio',
              title: 'Dashboard (Mapa en Vivo)',
              file: 'lib/screens/staff/dashboard_screen.dart',
            ),
        AppRoutes.staffTableDetail: (_) => const _Placeholder(
              who: 'Sergio',
              title: 'Detalle de Mesa',
              file: 'lib/screens/staff/table_detail_screen.dart',
            ),
        AppRoutes.staffOrder: (_) => const _Placeholder(
              who: 'Sergio',
              title: 'Comanda',
              file: 'lib/screens/staff/order_screen.dart',
            ),
        AppRoutes.staffKitchen: (_) => const _Placeholder(
              who: 'Kike',
              title: 'Vista de Cocina',
              file: 'lib/screens/staff/kitchen_screen.dart',
            ),
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB23A1F), // tono terracota
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}

/// Rutas centralizadas para evitar strings sueltos por todo el código.
class AppRoutes {
  // Público
  static const home = '/';
  static const menu = '/menu';
  static const reservationStep1 = '/reservar';
  static const reservationStep2 = '/reservar/mesas';
  static const reservationStep3 = '/reservar/datos';

  // Staff
  static const staffLogin = '/staff/login';
  static const staffDashboard = '/staff';
  static const staffTableDetail = '/staff/mesa';
  static const staffOrder = '/staff/comanda';
  static const staffKitchen = '/staff/cocina';
}

/// Placeholder temporal. Cada uno borra el suyo cuando crea la pantalla real
/// y la engancha en `routes` arriba.
class _Placeholder extends StatelessWidget {
  final String who;
  final String title;
  final String file;
  const _Placeholder({
    required this.who,
    required this.title,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Pendiente · responsable: $who'),
              const SizedBox(height: 8),
              Text(file, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

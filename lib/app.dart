import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/public/reservation_step1_screen.dart';
import 'screens/public/reservation_step2_screen.dart';
import 'screens/public/reservation_step3_screen.dart';
import 'screens/staff/login_screen.dart';
import 'screens/staff/dashboard_screen.dart';
import 'widgets/auth_gate.dart';

/// Raíz de la app. Define tema y rutas con nombres.
/// Las rutas /staff/* están envueltas en AuthGate, así si no hay sesión
/// el usuario va a /staff/login automáticamente.
class EnseruApp extends StatelessWidget {
  const EnseruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurante Enseru',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      theme: _buildTheme(),
      initialRoute: AppRoutes.home,
      routes: {
        // ── Parte pública ───────────────────────────────────────
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
        AppRoutes.reservationStep1: (_) => const ReservationStep1Screen(),
        AppRoutes.reservationStep2: (_) => const ReservationStep2Screen(),
        AppRoutes.reservationStep3: (_) => const ReservationStep3Screen(),

        // ── Parte staff (protegida con AuthGate) ────────────────
        AppRoutes.staffLogin: (_) => const LoginScreen(),
        AppRoutes.staffDashboard: (_) =>
        const AuthGate(child: DashboardScreen()),

        // Las siguientes son del Sprint 2 (Sergio + Kike).
        AppRoutes.staffTableDetail: (_) => const AuthGate(
          child: _Placeholder(
            who: 'Sergio',
            title: 'Detalle de Mesa',
            file: 'lib/screens/staff/table_detail_screen.dart',
          ),
        ),
        AppRoutes.staffOrder: (_) => const AuthGate(
          child: _Placeholder(
            who: 'Sergio',
            title: 'Comanda',
            file: 'lib/screens/staff/order_screen.dart',
          ),
        ),
        AppRoutes.staffKitchen: (_) => const AuthGate(
          child: _Placeholder(
            who: 'Kike',
            title: 'Vista de Cocina',
            file: 'lib/screens/staff/kitchen_screen.dart',
          ),
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

/// Placeholder temporal para pantallas que aún no existen.
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
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/public/landing_screen.dart';
import 'screens/public/menu_screen.dart';
import 'screens/public/reservation_step1_screen.dart';
import 'screens/public/reservation_step2_screen.dart';
import 'screens/public/reservation_step3_screen.dart';
import 'screens/staff/login_screen.dart';
import 'screens/staff/dashboard_screen.dart';
import 'screens/staff/table_detail_screen.dart';
import 'screens/staff/order_screen.dart';
import 'screens/staff/kitchen_screen.dart';
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
        // ── Parte pública ──────────────────────────────────────────────────
        AppRoutes.home:             (_) => const LandingScreen(),
        AppRoutes.menu:             (_) => const MenuScreen(),
        AppRoutes.reservationStep1: (_) => const ReservationStep1Screen(),
        AppRoutes.reservationStep2: (_) => const ReservationStep2Screen(),
        AppRoutes.reservationStep3: (_) => const ReservationStep3Screen(),

        // ── Parte staff (protegida con AuthGate) ───────────────────────────
        AppRoutes.staffLogin:     (_) => const LoginScreen(),
        AppRoutes.staffDashboard: (_) => const AuthGate(child: DashboardScreen()),
        AppRoutes.staffTableDetail:(_) => const AuthGate(child: TableDetailScreen()),
        AppRoutes.staffOrder:     (_) => const AuthGate(child: OrderScreen()),
        AppRoutes.staffKitchen:   (_) => const AuthGate(child: KitchenScreen()),
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
  static const home             = '/';
  static const menu             = '/menu';
  static const reservationStep1 = '/reservar';
  static const reservationStep2 = '/reservar/mesas';
  static const reservationStep3 = '/reservar/datos';

  // Staff
  static const staffLogin       = '/staff/login';
  static const staffDashboard   = '/staff';
  static const staffTableDetail = '/staff/mesa';
  static const staffOrder       = '/staff/comanda';
  static const staffKitchen     = '/staff/cocina';
}
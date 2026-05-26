import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app.dart';
import '../services/auth_service.dart';

/// Envuelve un widget exigiendo que el usuario esté autenticado y
/// tenga un rol staff válido. Si no, redirige a la pantalla de login.
///
/// Se usa en `app.dart` envolviendo todas las rutas /staff/*:
///   AppRoutes.staffDashboard: (_) =>
///       const AuthGate(child: DashboardScreen()),
///
/// Reactivo: si la sesión expira mientras el usuario está dentro,
/// el StreamBuilder lo detecta y lo manda al login automáticamente.
class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras Firebase resuelve el estado inicial (chequea token
        // guardado en IndexedDB, etc.) mostramos un loader.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // No hay sesión. Redirigimos al login.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context)
                .pushReplacementNamed(AppRoutes.staffLogin);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Hay sesión. Comprobamos también que tenga rol staff válido.
        // Esto cubre el caso raro: un usuario autenticado en Firebase
        // pero sin doc en /users/{uid} (puede pasar si un admin lo
        // creó y se olvidó de asignarle rol).
        return FutureBuilder<StaffRole?>(
          future: authService.getCurrentUserRole(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (roleSnap.data == null) {
              // Usuario sin rol. Cerramos sesión y mandamos al login.
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await authService.signOut();
                if (!context.mounted) return;
                Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.staffLogin);
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // Todo OK: usuario logueado y con rol. Mostramos el child.
            return child;
          },
        );
      },
    );
  }
}
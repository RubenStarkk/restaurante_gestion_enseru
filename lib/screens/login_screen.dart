import 'package:flutter/material.dart';
// Importamos nuestro motor de seguridad
import '../services/auth_service.dart';

/// Usamos un 'StatefulWidget' porque esta pantalla tiene que "recordar"
/// lo que el usuario escribe en los cuadros de texto.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. CONTROLADORES: Son como "sensores" que nos permiten leer
  // lo que hay escrito dentro de cada campo de texto.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 2. SERVICIOS: Instanciamos nuestro AuthService para poder usarlo.
  final AuthService _authService = AuthService();

  // 3. ESTADO DE CARGA: Para saber si estamos esperando a Firebase.
  bool _cargando = false;

  /// FUNCIÓN PARA INTENTAR EL ACCESO
  void _intentarLogin() async {
    setState(() => _cargando = true); // Mostramos el círculo de carga

    // Llamamos a la función que creamos en AuthService
    var usuario = await _authService.iniciarSesion(
      _emailController.text.trim(), // .trim() quita espacios accidentales
      _passwordController.text,
    );

    setState(() => _cargando = false); // Quitamos el círculo de carga

    if (usuario != null) {
      // SI EL LOGIN ES ÉXITO: Por ahora mostraremos un mensaje.
      // En la Fase 2, aquí navegaremos al plano de mesas.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Bienvenido al sistema!')),
      );
    } else {
      // SI HAY ERROR: Avisamos al usuario.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario o clave incorrectos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          // CORRECCIÓN: En Flutter, para limitar el ancho o alto usamos 'constraints'.
          // 'BoxConstraints' es como darle una regla al contenedor para que no crezca más de la cuenta.
          constraints: const BoxConstraints(
            maxWidth: 400, // Aquí le decimos: "No midas más de 400 píxeles de ancho".
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ... el resto de tus widgets (Icono, Text, TextField, etc.) siguen igual ...
              // Icono visual del restaurante
              const Icon(Icons.restaurant_menu, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                'Gestión de Personal',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // CAMPO DE EMAIL
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              // CAMPO DE CONTRASEÑA
              TextField(
                controller: _passwordController,
                obscureText: true, // Esto hace que se vean puntitos en vez de letras
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),

              // BOTÓN DE ENTRAR
              _cargando
                  ? const CircularProgressIndicator() // Si carga, muestra círculo
                  : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _intentarLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('INICIAR SESIÓN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
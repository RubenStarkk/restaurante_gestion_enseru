// IMPORTACIONES: Traemos las herramientas externas que necesitamos
import 'package:flutter/material.dart'; // Librería principal de Google para crear interfaces visuales
import 'package:firebase_core/firebase_core.dart'; // El motor central para que Firebase funcione en Flutter
import 'firebase_options.dart'; // El archivo que contiene las "llaves" del proyecto en la nube
import 'screens/login_screen.dart';

/// FUNCIÓN MAIN: Es el punto de entrada de cualquier programa Dart.
/// Usamos 'async' porque conectar con internet (Firebase) lleva tiempo y no queremos que la app se congele.
void main() async {

  // 1. WidgetsFlutterBinding: Asegura que el motor de Flutter esté totalmente listo 
  // antes de intentar hacer nada con la base de datos o la red.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase.initializeApp: Este es el "apretón de manos". 
  // Tu código le dice a Google: "Hola, soy esta app específica y quiero conectarme".
  // Usamos 'await' para que el programa espere a que la conexión sea exitosa antes de seguir.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Usa las credenciales que creaste para Web
  );

  // 3. runApp: Una vez que Firebase está listo, lanzamos la interfaz visual de la app.
  runApp(const MyApp());
}

/// CLASE MYAPP: Es la raíz de toda nuestra aplicación.
/// Es un 'StatelessWidget', lo que significa que esta parte de la interfaz no cambia por sí sola.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp: Configuración general (título, colores globales, idioma, etc.)
    return MaterialApp(
      title: 'App Gestión Restaurante', // Nombre que aparece en la pestaña del navegador
      debugShowCheckedModeBanner: false, // Quita la etiqueta roja de "Debug" de la esquina
      theme: ThemeData(
        // Definimos los colores principales según vuestro diseño
        primarySwatch: Colors.blue,
        useMaterial3: true, // Usa el diseño más moderno de Google
      ),
      // Definimos la primera pantalla que verá el usuario
      home: const LoginScreen(),
    );
  }
}

/// PANTALLA INICIAL: Un pequeño boceto para confirmar que todo funciona.
class PantallaInicial extends StatelessWidget {
  const PantallaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold es el "lienzo" en blanco donde dibujamos la pantalla
      appBar: AppBar(
        title: const Text('Restaurante Gestión - Fase 1'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_done, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              '¡Conexión con Firebase Exitosa!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Infraestructura base lista para el equipo.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
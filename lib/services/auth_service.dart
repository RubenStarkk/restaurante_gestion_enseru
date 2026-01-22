// IMPORTACIONES: Necesitamos la librería de autenticación de Firebase
import 'package:firebase_auth/firebase_auth.dart';

/// ESTA CLASE SE ENCARGA DE LA SEGURIDAD.
/// Centralizamos aquí todo lo que tenga que ver con iniciar o cerrar sesión.
class AuthService {
  // 1. INSTANCIA DE FIREBASE AUTH: Es nuestro enlace directo con el servicio de Google.
  // La marcamos como 'final' porque no cambiará durante la ejecución.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 2. STREAM DE ESTADO: Esta es una de las funciones más potentes de Flutter.
  // Es como una "radio" que siempre nos está diciendo si hay alguien logueado o no.
  // Si el usuario entra o sale, la app se enterará automáticamente.
  Stream<User?> get usuarioEstado {
    return _auth.authStateChanges();
  }

  // 3. FUNCIÓN PARA INICIAR SESIÓN:
  // Recibe el email y la clave que el camarero escriba en el formulario.
  // Usamos 'Future' porque la respuesta de internet no es instantánea.
  Future<User?> iniciarSesion(String email, String password) async {
    try {
      // Intentamos validar las credenciales en Firebase
      UserCredential resultado = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Si todo va bien, nos devuelve el usuario
      return resultado.user;

    } on FirebaseAuthException catch (e) {
      // Si hay un error (ej: contraseña mal, usuario no existe), lo capturamos aquí
      print("ERROR EN EL LOGIN: ${e.message}");
      return null;
    } catch (e) {
      // Captura cualquier otro tipo de error inesperado
      print("ERROR INESPERADO: $e");
      return null;
    }
  }

  // 4. FUNCIÓN PARA CERRAR SESIÓN:
  // Fundamental para cuando el camarero termina su turno.
  Future<void> cerrarSesion() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print("ERROR AL CERRAR SESIÓN: $e");
    }
  }
}
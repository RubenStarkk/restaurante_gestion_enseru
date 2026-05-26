import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Roles posibles del personal.
/// - admin: acceso total (gestión de reservas, bloquear mesas, ver
///   datos de contacto completos).
/// - waiter: acceso operativo (toma de comandas, vista de cocina).
///   El teléfono del cliente se ofusca (RNF3 — esto lo aplicaremos
///   en el TableDetailScreen del Sprint 2).
enum StaffRole { admin, waiter }

StaffRole? _parseRole(String? raw) {
  switch (raw) {
    case 'admin':
      return StaffRole.admin;
    case 'waiter':
      return StaffRole.waiter;
    default:
      return null;
  }
}

/// Mensaje de error legible para el usuario a partir del código de
/// FirebaseAuthException. Sin esto, la UI mostraría errores crípticos
/// tipo "[firebase_auth/invalid-credential]".
String authErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'El email no tiene un formato válido.';
    case 'user-disabled':
      return 'Este usuario está deshabilitado. Contacta con el administrador.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email o contraseña incorrectos.';
    case 'too-many-requests':
      return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
    case 'network-request-failed':
      return 'No hay conexión. Comprueba tu red.';
    default:
      return 'No se pudo iniciar sesión. Inténtalo de nuevo.';
  }
}

/// Servicio de autenticación del personal.
///
/// Encapsula Firebase Auth y la consulta del rol del usuario en
/// /users/{uid}. Se usa desde el AuthGate (estado de sesión) y desde
/// la LoginScreen (signIn / signOut).
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  // Caché del rol del usuario actual para no consultar Firestore en
  // cada navegación. Se invalida si cambia el usuario.
  String? _cachedUid;
  StaffRole? _cachedRole;

  /// Usuario actualmente logueado, o null si no hay sesión.
  User? get currentUser => _auth.currentUser;

  /// Stream que emite el usuario cada vez que cambia el estado de
  /// autenticación (login, logout, expiración del token). El AuthGate
  /// se basa en esto para decidir qué mostrar.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Inicia sesión con email y contraseña.
  /// Lanza FirebaseAuthException si las credenciales son inválidas;
  /// la UI usa authErrorMessage() para mostrar un texto legible.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    _cachedUid = null;
    _cachedRole = null;
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Cierra la sesión actual.
  Future<void> signOut() async {
    _cachedUid = null;
    _cachedRole = null;
    await _auth.signOut();
  }

  /// Devuelve el rol del usuario actual leyendo /users/{uid}.
  /// Si el doc no existe o no tiene un rol válido, devuelve null
  /// (significa "usuario logueado pero sin permisos de staff").
  Future<StaffRole?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    if (_cachedUid == user.uid && _cachedRole != null) {
      return _cachedRole;
    }

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final role = _parseRole(doc.data()?['role'] as String?);
    _cachedUid = user.uid;
    _cachedRole = role;
    return role;
  }
}
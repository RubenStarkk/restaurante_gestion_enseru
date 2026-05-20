import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/table_model.dart';

/// Servicio para leer y modificar mesas en Firestore.
///
/// - `watchAll()` devuelve un Stream con todas las mesas en tiempo real:
///   el plano vivo del staff y la selección de mesas del cliente se basan
///   en esto.
/// - `watchAvailableFor()` filtra solo las que sirven para una reserva
///   concreta (capacidad suficiente y no bloqueadas).
class TablesService {
  TablesService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('tables');

  /// Stream con TODAS las mesas, ordenadas por nombre.
  /// Útil para el Dashboard del staff (plano vivo).
  Stream<List<TableModel>> watchAll() {
    return _col.orderBy('name').snapshots().map(
          (snap) => snap.docs.map(TableModel.fromDoc).toList(),
    );
  }

  /// Stream con las mesas que CABEN para el número de comensales dado.
  /// No filtra por reservas — eso se hace en ReservationsService cuando
  /// el cliente intenta confirmar (transacción).
  ///
  /// El staff verá todas las mesas; este filtro es solo para el cliente.
  Stream<List<TableModel>> watchAvailableFor(int guests) {
    return _col
        .where('capacity', isGreaterThanOrEqualTo: guests)
        .orderBy('capacity')
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
          .map(TableModel.fromDoc)
      // Las bloqueadas las descartamos en cliente
          .where((t) => t.status != TableStatus.blocked)
          .toList(),
    );
  }

  /// Lectura puntual de una mesa por su ID.
  Future<TableModel?> fetchById(String tableId) async {
    final doc = await _col.doc(tableId).get();
    if (!doc.exists) return null;
    return TableModel.fromDoc(doc);
  }
}
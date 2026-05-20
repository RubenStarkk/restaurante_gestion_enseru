import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

/// Servicio de lectura del catálogo de platos.
///
/// NOTA: versión mínima creada por Rubén para el flujo de reservas
/// (necesitamos listar platos "Por Encargo" en el paso 3). Kike puede
/// extenderla con más métodos sin tocar los existentes.
class MenuService {
  MenuService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('menu_items');

  /// Stream con todos los platos, ordenados por categoría y nombre.
  Stream<List<MenuItemModel>> watchAll() {
    return _col.orderBy('category').orderBy('name').snapshots().map(
          (snap) => snap.docs.map(MenuItemModel.fromDoc).toList(),
    );
  }

  /// Stream con solo los platos "Por Encargo" (requieren > 24h de
  /// antelación). Para el paso 3 del flujo de reserva.
  Stream<List<MenuItemModel>> watchByOrderItems() {
    return _col
        .where('byOrder', isEqualTo: true)
        .orderBy('category')
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs.map(MenuItemModel.fromDoc).toList(),
    );
  }
}
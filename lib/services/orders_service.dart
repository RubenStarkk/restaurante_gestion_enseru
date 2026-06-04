import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/menu_item_model.dart';
import '../models/order_model.dart';

/// Servicio de comandas — gestiona el ciclo de vida de una comanda
/// (abrir, añadir/modificar items, cerrar, reabrir) y la cola de
/// platos para cocina.
///
/// Reglas de negocio implementadas:
/// - Una sola comanda OPEN por mesa a la vez. Si ya existe abierta, la
///   reutilizamos en vez de crear otra.
/// - Reabrir una comanda cerrada cambia su status a OPEN otra vez
///   (cumple RF7 — Gestión de Cuenta).
/// - Al añadir un item desnormalizamos nombre y precio (cumple lo que
///   dejó pensado Rubén en el modelo: si el admin cambia la carta, los
///   tickets antiguos no se ven afectados).
class OrdersService {
  OrdersService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  CollectionReference<Map<String, dynamic>> _itemsOf(String orderId) =>
      _orders.doc(orderId).collection('items');

  // ──────────────────────────────────────────────────────────
  //  Comanda principal
  // ──────────────────────────────────────────────────────────

  /// Stream de la comanda OPEN de una mesa concreta.
  /// Devuelve null si no hay ninguna abierta.
  Stream<OrderModel?> watchOpenOrderForTable(String tableId) {
    return _orders
        .where('tableId', isEqualTo: tableId)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return OrderModel.fromDoc(snap.docs.first);
    });
  }

  /// Abre una comanda nueva para esa mesa. Si ya hay una OPEN, la
  /// devuelve (idempotente — el camarero no acaba con dos comandas
  /// abiertas accidentalmente).
  Future<OrderModel> openForTable(String tableId) async {
    final existing = await _orders
        .where('tableId', isEqualTo: tableId)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return OrderModel.fromDoc(existing.docs.first);
    }

    final ref = _orders.doc();
    final user = _auth.currentUser;
    final order = OrderModel(
      id: ref.id,
      tableId: tableId,
      waiterUid: user?.uid ?? 'unknown',
      openedAt: DateTime.now(),
      status: OrderStatus.open,
    );
    await ref.set(order.toMap());
    return order;
  }

  /// Cierra una comanda. Cambia status a closed y guarda closedAt.
  Future<void> closeOrder(String orderId) async {
    await _orders.doc(orderId).update({
      'status': 'closed',
      'closedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Reabre una comanda cerrada (RF7 — Gestión de Cuenta).
  Future<void> reopenOrder(String orderId) async {
    await _orders.doc(orderId).update({
      'status': 'open',
      'closedAt': FieldValue.delete(),
    });
  }

  // ──────────────────────────────────────────────────────────
  //  Items de la comanda
  // ──────────────────────────────────────────────────────────

  /// Stream de los items de una comanda, ordenados por fecha de
  /// creación. La UI los pinta como filas.
  Stream<List<OrderItem>> watchItems(String orderId) {
    return _itemsOf(orderId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(OrderItem.fromDoc).toList());
  }

  /// Añade un item a la comanda.
  ///
  /// Desnormaliza `name` y `unitPrice` del plato actual; eso evita que
  /// si mañana el admin cambia el precio en la carta, este ticket
  /// histórico cambie también.
  ///
  /// Para platos `per_person`, el camarero pasa `qty` = nº de personas
  /// y nosotros multiplicamos. Para `per_unit`, `qty` = nº de raciones.
  Future<void> addItem({
    required String orderId,
    required MenuItemModel item,
    required int qty,
  }) async {
    final ref = _itemsOf(orderId).doc();
    final lineTotal = item.price * qty;
    final orderItem = OrderItem(
      id: ref.id,
      menuItemId: item.id,
      name: item.name,
      qty: qty,
      unitPrice: item.price,
      lineTotal: lineTotal,
      kitchenStatus: KitchenStatus.pending,
      createdAt: DateTime.now(),
    );
    await ref.set(orderItem.toMap());
  }

  /// Cambia la cantidad de una línea ya añadida. Recalcula el total.
  Future<void> updateItemQty({
    required String orderId,
    required String itemId,
    required int newQty,
  }) async {
    final snap = await _itemsOf(orderId).doc(itemId).get();
    if (!snap.exists) return;
    final unitPrice = (snap.data()?['unitPrice'] as num).toDouble();
    await snap.reference.update({
      'qty': newQty,
      'lineTotal': unitPrice * newQty,
    });
  }

  /// Borra una línea (item) de la comanda.
  Future<void> removeItem({
    required String orderId,
    required String itemId,
  }) async {
    await _itemsOf(orderId).doc(itemId).delete();
  }

  /// Cambia el estado de cocina de una línea
  /// (pending → preparing → ready → served).
  Future<void> updateKitchenStatus({
    required String orderId,
    required String itemId,
    required KitchenStatus status,
  }) async {
    await _itemsOf(orderId).doc(itemId).update({
      'kitchenStatus': kitchenStatusToString(status),
    });
  }

  // ──────────────────────────────────────────────────────────
  //  Vista de cocina — añadido por Kike (Sprint 2)
  // ──────────────────────────────────────────────────────────

  /// Stream de todos los items con estado pending o preparing de todas
  /// las comandas abiertas. Lo usa exclusivamente KitchenScreen.
  ///
  /// Implementación en dos pasos para evitar queries collectionGroup
  /// (que requeriría un índice global adicional):
  ///   1. Escucha las comandas con status == 'open'.
  ///   2. Por cada comanda, consulta sus items activos.
  Stream<List<KitchenItem>> watchKitchenItems() {
    return _orders
        .where('status', isEqualTo: 'open')
        .snapshots()
        .asyncMap((ordersSnap) async {
      if (ordersSnap.docs.isEmpty) return <KitchenItem>[];

      final result = <KitchenItem>[];
      for (final orderDoc in ordersSnap.docs) {
        final tableId =
            (orderDoc.data())['tableId'] as String? ?? '';

        final itemsSnap = await _itemsOf(orderDoc.id)
            .where('kitchenStatus', whereIn: ['pending', 'preparing'])
            .orderBy('createdAt')
            .get();

        for (final itemDoc in itemsSnap.docs) {
          result.add(KitchenItem(
            orderId: orderDoc.id,
            tableId: tableId,
            item: OrderItem.fromDoc(itemDoc),
          ));
        }
      }
      return result;
    });
  }

  // ──────────────────────────────────────────────────────────
  //  Helpers de cálculo
  // ──────────────────────────────────────────────────────────

  /// Total de una lista de items. Útil para mostrar el subtotal en la
  /// pantalla de comanda sin pedir nada extra a Firestore.
  double totalOf(List<OrderItem> items) {
    return items.fold(0, (sum, it) => sum + it.lineTotal);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  DTO de cocina — añadido por Kike (Sprint 2)
// ──────────────────────────────────────────────────────────────────────────────

/// Agrupa un OrderItem con el contexto de su comanda y mesa.
/// Solo lo usa KitchenScreen — no es un modelo de Firestore.
class KitchenItem {
  const KitchenItem({
    required this.orderId,
    required this.tableId,
    required this.item,
  });

  final String orderId;
  final String tableId;
  final OrderItem item;
}

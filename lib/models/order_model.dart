import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado de la comanda (RF7 — Gestión de Cuenta).
/// Una comanda cerrada puede reabrirse para añadir consumiciones extra.
enum OrderStatus { open, closed }

OrderStatus _parseOrderStatus(String? raw) =>
    raw == 'closed' ? OrderStatus.closed : OrderStatus.open;

String orderStatusToString(OrderStatus s) =>
    s == OrderStatus.closed ? 'closed' : 'open';

/// Estado de cocina por línea de comanda.
enum KitchenStatus { pending, preparing, ready, served }

KitchenStatus _parseKitchen(String? raw) {
  switch (raw) {
    case 'preparing':
      return KitchenStatus.preparing;
    case 'ready':
      return KitchenStatus.ready;
    case 'served':
      return KitchenStatus.served;
    case 'pending':
    default:
      return KitchenStatus.pending;
  }
}

String kitchenStatusToString(KitchenStatus s) {
  switch (s) {
    case KitchenStatus.preparing:
      return 'preparing';
    case KitchenStatus.ready:
      return 'ready';
    case KitchenStatus.served:
      return 'served';
    case KitchenStatus.pending:
      return 'pending';
  }
}

/// Cabecera de la comanda — `orders/{id}`.
class OrderModel {
  final String id;
  final String tableId;
  final String waiterUid;
  final DateTime openedAt;
  final DateTime? closedAt;
  final OrderStatus status;

  const OrderModel({
    required this.id,
    required this.tableId,
    required this.waiterUid,
    required this.openedAt,
    required this.status,
    this.closedAt,
  });

  factory OrderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return OrderModel(
      id: doc.id,
      tableId: d['tableId'] as String? ?? '',
      waiterUid: d['waiterUid'] as String? ?? '',
      openedAt:
          (d['openedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      closedAt: (d['closedAt'] as Timestamp?)?.toDate(),
      status: _parseOrderStatus(d['status'] as String?),
    );
  }

  Map<String, dynamic> toMap() => {
        'tableId': tableId,
        'waiterUid': waiterUid,
        'openedAt': Timestamp.fromDate(openedAt),
        if (closedAt != null) 'closedAt': Timestamp.fromDate(closedAt!),
        'status': orderStatusToString(status),
      };
}

/// Línea de comanda — `orders/{orderId}/items/{itemId}`.
/// Desnormalizamos `name` y `unitPrice` para que el ticket histórico no se
/// vea afectado si la carta cambia más adelante.
class OrderItem {
  final String id;
  final String menuItemId;
  final String name;          // desnormalizado
  final int qty;
  final double unitPrice;     // desnormalizado
  final double lineTotal;     // = qty * unitPrice (o personas * precio si perPerson)
  final KitchenStatus kitchenStatus;
  final DateTime createdAt;

  const OrderItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.kitchenStatus,
    required this.createdAt,
  });

  factory OrderItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return OrderItem(
      id: doc.id,
      menuItemId: d['menuItemId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      qty: (d['qty'] as num?)?.toInt() ?? 1,
      unitPrice: (d['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (d['lineTotal'] as num?)?.toDouble() ?? 0,
      kitchenStatus: _parseKitchen(d['kitchenStatus'] as String?),
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'menuItemId': menuItemId,
        'name': name,
        'qty': qty,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
        'kitchenStatus': kitchenStatusToString(kitchenStatus),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Turno de la reserva.
enum Shift { lunch, dinner }

Shift _parseShift(String? raw) =>
    raw == 'dinner' ? Shift.dinner : Shift.lunch;

String shiftToString(Shift s) => s == Shift.dinner ? 'dinner' : 'lunch';

/// Estado de una reserva.
enum ReservationStatus { active, cancelled, completed, noShow }

ReservationStatus _parseResStatus(String? raw) {
  switch (raw) {
    case 'cancelled':
      return ReservationStatus.cancelled;
    case 'completed':
      return ReservationStatus.completed;
    case 'no_show':
      return ReservationStatus.noShow;
    case 'active':
    default:
      return ReservationStatus.active;
  }
}

String reservationStatusToString(ReservationStatus s) {
  switch (s) {
    case ReservationStatus.cancelled:
      return 'cancelled';
    case ReservationStatus.completed:
      return 'completed';
    case ReservationStatus.noShow:
      return 'no_show';
    case ReservationStatus.active:
      return 'active';
  }
}

/// Plato pre-encargado en la reserva (RF5).
/// Guardamos nombre y precio desnormalizados para que el resumen de la
/// reserva no cambie si más adelante se edita la carta.
class PreorderedItem {
  final String menuItemId;
  final String name;
  final int qty;
  final double unitPrice;

  const PreorderedItem({
    required this.menuItemId,
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  factory PreorderedItem.fromMap(Map<String, dynamic> m) => PreorderedItem(
    menuItemId: m['menuItemId'] as String? ?? '',
    name: m['name'] as String? ?? '',
    qty: (m['qty'] as num?)?.toInt() ?? 1,
    unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'menuItemId': menuItemId,
    'name': name,
    'qty': qty,
    'unitPrice': unitPrice,
  };
}

class ReservationModel {
  final String id;

  /// Fecha del servicio (día). Recomendado guardar a las 00:00 del día.
  final DateTime date;
  final Shift shift;
  final int guests;
  final List<String> tableIds;     // mesas asignadas

  final String customerName;
  final String customerPhone;
  final String? customerEmail;

  final List<PreorderedItem> preorderedItems;

  final ReservationStatus status;
  final DateTime createdAt;

  const ReservationModel({
    required this.id,
    required this.date,
    required this.shift,
    required this.guests,
    required this.tableIds,
    required this.customerName,
    required this.customerPhone,
    required this.preorderedItems,
    required this.status,
    required this.createdAt,
    this.customerEmail,
  });

  factory ReservationModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final preList = (d['preorderedItems'] as List?) ?? const [];
    return ReservationModel(
      id: doc.id,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shift: _parseShift(d['shift'] as String?),
      guests: (d['guests'] as num?)?.toInt() ?? 0,
      tableIds: ((d['tableIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      customerName: d['customerName'] as String? ?? '',
      customerPhone: d['customerPhone'] as String? ?? '',
      customerEmail: d['customerEmail'] as String?,
      preorderedItems: preList
          .whereType<Map>()
          .map((m) => PreorderedItem.fromMap(m.cast<String, dynamic>()))
          .toList(),
      status: _parseResStatus(d['status'] as String?),
      createdAt:
      (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'shift': shiftToString(shift),
    'guests': guests,
    'tableIds': tableIds,
    'customerName': customerName,
    'customerPhone': customerPhone,
    if (customerEmail != null) 'customerEmail': customerEmail,
    'preorderedItems': preorderedItems.map((p) => p.toMap()).toList(),
    'status': reservationStatusToString(status),
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

/// Oculta parcialmente un teléfono para mostrarlo a usuarios con
/// rol "waiter" (RNF3 — Privacidad).
///
/// Muestra los primeros 3 dígitos y los últimos 2; el resto como
/// asteriscos. Ej: "600123456" → "600****56".
/// Si el teléfono es muy corto, oculta todo.
String maskPhone(String phone) {
  final clean = phone.replaceAll(RegExp(r'\s+'), '');
  if (clean.length < 6) return '****';
  final start = clean.substring(0, 3);
  final end = clean.substring(clean.length - 2);
  final masked = '*' * (clean.length - 5);
  return '$start$masked$end';
}
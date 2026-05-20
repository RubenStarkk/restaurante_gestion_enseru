import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado actual de una mesa.
/// - free: libre y disponible.
/// - occupied: hay clientes sentados (comanda abierta).
/// - reserved: hay una reserva activa para el turno actual.
/// - blocked: bloqueada manualmente por el admin (RF3 — reserva telefónica
///   o cualquier motivo operativo).
enum TableStatus { free, occupied, reserved, blocked }

TableStatus _parseStatus(String? raw) {
  switch (raw) {
    case 'occupied':
      return TableStatus.occupied;
    case 'reserved':
      return TableStatus.reserved;
    case 'blocked':
      return TableStatus.blocked;
    case 'free':
    default:
      return TableStatus.free;
  }
}

String tableStatusToString(TableStatus s) => s.name;

class TableModel {
  final String id;
  final String name;          // "M1", "Terraza 3", etc.
  final int capacity;         // nº máximo de comensales
  final double x;             // coordenada X en el plano (0..1 normalizada)
  final double y;             // coordenada Y en el plano (0..1 normalizada)
  final TableStatus status;

  const TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.x,
    required this.y,
    required this.status,
  });

  factory TableModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return TableModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      capacity: (d['capacity'] as num?)?.toInt() ?? 0,
      x: (d['x'] as num?)?.toDouble() ?? 0,
      y: (d['y'] as num?)?.toDouble() ?? 0,
      status: _parseStatus(d['status'] as String?),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'capacity': capacity,
        'x': x,
        'y': y,
        'status': tableStatusToString(status),
      };

  TableModel copyWith({
    String? name,
    int? capacity,
    double? x,
    double? y,
    TableStatus? status,
  }) {
    return TableModel(
      id: id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      x: x ?? this.x,
      y: y ?? this.y,
      status: status ?? this.status,
    );
  }
}

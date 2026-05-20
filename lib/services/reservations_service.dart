import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';
import '../models/table_model.dart';

/// Lanzada cuando la mesa ya está reservada para ese turno (lock ocupado).
class TableAlreadyReservedException implements Exception {
  final String message;
  TableAlreadyReservedException([
    this.message = 'La mesa ya no está disponible para ese turno.',
  ]);
  @override
  String toString() => message;
}

/// Servicio de reservas. Encapsula la creación, la prevención de dobles
/// reservas mediante un lock determinista y las consultas para el staff.
///
/// Estrategia anti-doble-reserva:
///   Como el SDK web de Firestore no permite `where` dentro de
///   `runTransaction`, usamos un "lock document" en
///   /reservation_locks/{mesa_AAAA-MM-DD_turno}. La regla de Firestore
///   permite CREATE pero no UPDATE, por lo que el primero en crear el
///   doc se queda con la mesa para ese turno; el resto recibe error.
class ReservationsService {
  ReservationsService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reservations =>
      _db.collection('reservations');

  CollectionReference<Map<String, dynamic>> get _tables =>
      _db.collection('tables');

  Future<({String reservationId, String code})> createReservation({
    required DateTime date,
    required Shift shift,
    required int guests,
    required String tableId,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    List<PreorderedItem> preorderedItems = const [],
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dateStr = '${dayStart.year.toString().padLeft(4, '0')}-'
        '${dayStart.month.toString().padLeft(2, '0')}-'
        '${dayStart.day.toString().padLeft(2, '0')}';
    final lockId = '${tableId}_${dateStr}_${shiftToString(shift)}';
    final lockRef = _db.collection('reservation_locks').doc(lockId);

    // 1. Intentar adquirir el lock. Si ya existe → mesa reservada.
    try {
      await lockRef.set({
        'tableId': tableId,
        'date': Timestamp.fromDate(dayStart),
        'shift': shiftToString(shift),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (_) {
      throw TableAlreadyReservedException();
    }

    // 2. Verificar la mesa (capacidad y que no esté bloqueada).
    final tableSnap = await _tables.doc(tableId).get();
    if (!tableSnap.exists) {
      throw TableAlreadyReservedException('La mesa ya no existe.');
    }
    final table = TableModel.fromDoc(tableSnap);
    if (table.status == TableStatus.blocked) {
      throw TableAlreadyReservedException(
        'La mesa no está disponible para reservar.',
      );
    }
    if (table.capacity < guests) {
      throw TableAlreadyReservedException(
        'Esta mesa no tiene capacidad suficiente.',
      );
    }

    // 3. Crear la reserva.
    final ref = _reservations.doc();
    final now = DateTime.now();
    final code = _generateCode(now, ref.id);

    final reservation = ReservationModel(
      id: ref.id,
      date: dayStart,
      shift: shift,
      guests: guests,
      tableIds: [tableId],
      customerName: customerName.trim(),
      customerPhone: customerPhone.trim(),
      customerEmail: customerEmail?.trim(),
      preorderedItems: preorderedItems,
      status: ReservationStatus.active,
      createdAt: now,
    );

    final data = reservation.toMap();
    data['code'] = code;
    data['lockId'] = lockId;

    await ref.set(data);

    return (reservationId: ref.id, code: code);
  }

  /// Código de reserva legible para el cliente. R-AAAA-XXXX donde XXXX
  /// son los 4 primeros chars del ID Firestore en mayúsculas.
  String _generateCode(DateTime when, String firestoreId) {
    final shortId = firestoreId.substring(0, 4).toUpperCase();
    return 'R-${when.year}-$shortId';
  }

  /// Reservas activas para una fecha y turno. Lo usará el staff en
  /// futuros sprints para preparar la sala.
  Stream<List<ReservationModel>> watchByDateAndShift({
    required DateTime date,
    required Shift shift,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return _reservations
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('date', isLessThan: Timestamp.fromDate(dayEnd))
        .where('shift', isEqualTo: shiftToString(shift))
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (snap) => snap.docs.map(ReservationModel.fromDoc).toList(),
    );
  }
}
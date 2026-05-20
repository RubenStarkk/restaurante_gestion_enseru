import 'package:cloud_firestore/cloud_firestore.dart';

/// Cómo se cobra el plato.
/// - perUnit: precio fijo por ración/unidad.
/// - perPerson: precio por persona; el camarero indica cuántas (RF8 —
///   Precios Variables).
enum PricingType { perUnit, perPerson }

PricingType _parsePricing(String? raw) {
  switch (raw) {
    case 'per_person':
      return PricingType.perPerson;
    case 'per_unit':
    default:
      return PricingType.perUnit;
  }
}

String pricingTypeToString(PricingType p) =>
    p == PricingType.perPerson ? 'per_person' : 'per_unit';

class MenuItemModel {
  final String id;
  final String name;
  final String? description;
  final String category;       // "Entrantes", "Arroces", "Carnes", "Postres"...
  final double price;
  final PricingType pricingType;

  /// RF5 — plato "Por Encargo": requiere reserva con > 24 h de antelación.
  final bool byOrder;

  /// Etiqueta visual "Nuevo" / "Tapa de la semana" en la landing.
  final bool newArrival;

  final String? imageUrl;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.pricingType,
    required this.byOrder,
    required this.newArrival,
    this.description,
    this.imageUrl,
  });

  factory MenuItemModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return MenuItemModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String?,
      category: d['category'] as String? ?? 'Otros',
      price: (d['price'] as num?)?.toDouble() ?? 0,
      pricingType: _parsePricing(d['pricingType'] as String?),
      byOrder: d['byOrder'] as bool? ?? false,
      newArrival: d['newArrival'] as bool? ?? false,
      imageUrl: d['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (description != null) 'description': description,
        'category': category,
        'price': price,
        'pricingType': pricingTypeToString(pricingType),
        'byOrder': byOrder,
        'newArrival': newArrival,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}

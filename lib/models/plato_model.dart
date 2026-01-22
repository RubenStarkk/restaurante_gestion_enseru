/// ESTA CLASE ES EL "MOLDE" PARA CUALQUIER PLATO DEL RESTAURANTE.
/// La usamos para que el código entienda qué es un plato y qué datos tiene.
class PlatoModel {
  // 1. DEFINICIÓN DE ATRIBUTOS (Las características del plato)
  final String id;          // Un código único que Firebase le da a cada plato
  final String nombre;      // El nombre del plato (ej: Paella)
  final String descripcion; // Una breve descripción de los ingredientes
  final double precio;      // El precio. Usamos 'double' porque lleva decimales [cite: 40]
  final String categoria;   // Para agrupar: "Entrantes", "Arroces", "Postres" [cite: 13]
  final bool isPorEncargo;  // REQUISITO: ¿Es un plato que necesita 24h de antelación? [cite: 36]
  final String imagenUrl;   // El enlace a la foto del plato (para el rendimiento < 2s) [cite: 42]

  // 2. EL CONSTRUCTOR: Es la función que crea el plato en la memoria del ordenador.
  PlatoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.categoria,
    required this.isPorEncargo,
    required this.imagenUrl,
  });

  // 3. FACTORY FROMFIRESTORE: Esta función es como un "Traductor".
  // Firebase nos envía los datos en un formato llamado Map (parecido a un JSON).
  // Esta función coge ese "paquete" de internet y lo convierte en un objeto PlatoModel.
  factory PlatoModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return PlatoModel(
      id: documentId, // Guardamos el ID que viene de la base de datos
      nombre: data['nombre'] ?? 'Sin nombre', // Si no hay nombre, pone uno por defecto
      descripcion: data['descripcion'] ?? '',
      precio: (data['precio'] ?? 0.0).toDouble(), // Aseguramos que sea un número con decimales
      categoria: data['categoria'] ?? 'General',
      isPorEncargo: data['isPorEncargo'] ?? false, // Por defecto, el plato no es por encargo
      imagenUrl: data['imagenUrl'] ?? '',
    );
  }

  // 4. TOFIRESTORE: El traductor inverso.
  // Cuando queráis añadir un plato nuevo desde el panel de Admin,
  // esta función convierte el objeto PlatoModel en un formato que Firebase entiende.
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'categoria': categoria,
      'isPorEncargo': isPorEncargo,
      'imagenUrl': imagenUrl,
    };
  }
}
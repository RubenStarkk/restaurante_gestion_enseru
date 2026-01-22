/// ESTA CLASE DEFINE CÓMO ES UNA MESA EN NUESTRO SISTEMA.
/// Es la pieza clave para el Plano Interactivo y la Gestión de Aforo.
class MesaModel {
  // 1. ATRIBUTOS (Características de la mesa)
  final String id;          // El ID único que Firebase asigna a la mesa
  final String nombre;      // Nombre visual (ej: "Mesa 1" o "Mesa Ventana")
  final int capacidad;      // REQUISITO: Capacidad máxima para la "Selección Inteligente"
  final String estado;      // REQUISITO: "Libre", "Ocupada" o "Reservada" (tiempo real)

  // Estas coordenadas servirán para dibujar la mesa en el mapa interactivo
  final double posX;        // Posición horizontal en el plano
  final double posY;        // Posición vertical en el plano

  // 2. CONSTRUCTOR: Para crear la mesa en el código
  MesaModel({
    required this.id,
    required this.nombre,
    required this.capacidad,
    required this.estado,
    required this.posX,
    required this.posY,
  });

  // 3. FROMFIRESTORE: Convierte los datos que vienen de la nube en una Mesa real
  factory MesaModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return MesaModel(
      id: documentId,
      nombre: data['nombre'] ?? 'Mesa sin nombre',
      capacidad: data['capacidad'] ?? 2, // Si no se indica, suponemos mesa de 2
      estado: data['estado'] ?? 'Libre',
      posX: (data['posX'] ?? 0.0).toDouble(),
      posY: (data['posY'] ?? 0.0).toDouble(),
    );
  }

  // 4. TOFIRESTORE: Prepara la mesa para guardarla en Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'capacidad': capacidad,
      'estado': estado,
      'posX': posX,
      'posY': posY,
    };
  }
}
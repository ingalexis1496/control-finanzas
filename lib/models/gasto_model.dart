import 'package:cloud_firestore/cloud_firestore.dart';

class GastoModel {
  final String? id;
  final String concepto;
  final double monto;
  final String categoria;
  final String pagadoPor;
  final String tipo; // 'gasto' o 'ingreso'
  final String metodoPago; // 'Efectivo', 'Nequi', 'Tarjeta'
  final DateTime fecha;

  GastoModel({
    this.id,
    required this.concepto,
    required this.monto,
    required this.categoria,
    required this.pagadoPor,
    required this.tipo,
    required this.metodoPago,
    required this.fecha,
  });

  // Lógica de 4 semanas exactas por mes
  String get idSemana {
    int semanaDelMes;
    if (fecha.day <= 7) {
      semanaDelMes = 1;
    } else if (fecha.day <= 14) {
      semanaDelMes = 2;
    } else if (fecha.day <= 21) {
      semanaDelMes = 3;
    } else {
      semanaDelMes = 4;
    }

    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    String nombreMes = meses[fecha.month - 1];

    return '$nombreMes - Semana $semanaDelMes'; // Ej: "Septiembre - Semana 1"
  }

  factory GastoModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GastoModel(
      id: doc.id,
      concepto: data['concepto'] ?? '',
      monto: (data['monto'] ?? 0.0).toDouble(),
      categoria: data['categoria'] ?? 'General',
      pagadoPor: data['pagadoPor'] ?? 'Yo',
      tipo: data['tipo'] ?? 'gasto',
      metodoPago: data['metodoPago'] ?? 'Efectivo',
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'concepto': concepto,
      'monto': monto,
      'categoria': categoria,
      'pagadoPor': pagadoPor,
      'tipo': tipo,
      'metodoPago': metodoPago,
      'fecha': Timestamp.fromDate(fecha),
    };
  }
}

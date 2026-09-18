import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/gasto_model.dart';

class GastoProvider with ChangeNotifier {
  final CollectionReference _gastosRef = FirebaseFirestore.instance.collection(
    'gastos',
  );

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Obtener el usuario autenticado actual
  User? get _currentUser => FirebaseAuth.instance.currentUser;
  String? get _userId => _currentUser?.uid;

  /// Obtiene los gastos del usuario actual y realiza la migración automática
  /// de los documentos antiguos que no tengan userId para no perderlos.
  Stream<List<GastoModel>> obtenerGastosStream() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);

    return _gastosRef.orderBy('fecha', descending: true).snapshots().asyncMap((
      snapshot,
    ) async {
      List<GastoModel> listaGastos = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String? docUserId = data['userId'];

        // MIGRACIÓN AUTOMÁTICA: Si el documento antiguo no tiene userId,
        // se lo asignamos automáticamente al usuario actual para que no se pierda.
        if (docUserId == null || docUserId.isEmpty) {
          await _gastosRef.doc(doc.id).update({'userId': userId});
          data['userId'] = userId; // Actualizamos localmente para el filtro
        }

        // Filtramos para mostrar únicamente los registros que pertenecen a este usuario
        if (data['userId'] == userId) {
          listaGastos.add(GastoModel.fromFirestore(doc));
        }
      }

      return listaGastos;
    });
  }

  /// Agrega una nueva transacción asegurándose de inyectar el userId actual
  /// y asignando el nombre de forma automática según el correo electrónico.
  Future<void> agregarTransaccion(GastoModel transaccion) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _currentUser;
      if (user == null || user.uid.isEmpty) {
        throw Exception('No hay usuario autenticado');
      }

      // 🎯 AQUÍ ESTÁ LA MAGIA: Determinamos automáticamente quién paga según el correo
      final String email = user.email ?? '';
      final String pagadoPorDinamico = (email == 'alexgo.1496@gmail.com')
          ? 'Alexis'
          : 'Eimy';

      // Convertimos el modelo a mapa y le inyectamos el userId y el pagadoPor correcto
      final Map<String, dynamic> datosTransaccion = transaccion.toMap();
      datosTransaccion['userId'] = user.uid;
      datosTransaccion['pagadoPor'] =
          pagadoPorDinamico; // Sobrescribimos con el nombre exacto

      await _gastosRef.add(datosTransaccion);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error al agregar transacción: $e');
      rethrow;
    }
  }

  Future<void> eliminarTransaccion(String id) async {
    try {
      await _gastosRef.doc(id).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al eliminar transacción: $e');
      rethrow;
    }
  }
}

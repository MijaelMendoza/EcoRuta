import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gmaps/models/MiTeleferico/LineaTeleferico.dart';

class LineaTelefericoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveLineaTeleferico(LineaTeleferico linea) async {
    try {
      await _firestore.collection('LineasTelefericos').add(linea.toMap());
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateLineaTeleferico(String id, LineaTeleferico linea) async {
    try {
      await _firestore.collection('LineasTelefericos').doc(id).update(linea.toMap());
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteLineaTeleferico(String id) async {
    try {
      await _firestore.collection('LineasTelefericos').doc(id).delete();
    } catch (e) {
      print(e);
    }
  }

  Stream<List<LineaTeleferico>> getLineasTelefericos() {
    return _firestore.collection('LineasTelefericos').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final estaciones = (data['estaciones'] as List)
            .map((e) => Estacion(
                  nombreEstacion: e['nombreEstacion'],
                  nombreUbicacion: e['nombreUbicacion'],
                  nombreUbicacionGoogle: e['nombreUbicacionGoogle'],
                  longitud: e['longitud'],
                  latitud: e['latitud'],
                  orden: e['orden'],
                ))
            .toList();

        return LineaTeleferico(
          nombre: data['nombre'],
          color: data['color'],
          colorValue: data['colorValue'],
          estaciones: estaciones,
        );
      }).toList();
    });
  }
}

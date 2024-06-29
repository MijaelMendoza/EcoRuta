import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gmaps/models/MiLinea/lineas_model.dart';

class LineasMiniApi {
  final CollectionReference _lineasMiniCollection = FirebaseFirestore.instance.collection('lineasMini');

  Future<List<LineasMini>> getAllLineasMini() async {
    try {
      final querySnapshot = await _lineasMiniCollection.get();
      return querySnapshot.docs.map((doc) => LineasMini.fromMap(doc.data() as Map<String, dynamic>, lineaId: doc.id)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<LineasMini?> getLineasMiniById(String id) async {
    try {
      final docSnapshot = await _lineasMiniCollection.doc(id).get();
      if (docSnapshot.exists) {
        return LineasMini.fromMap(docSnapshot.data() as Map<String, dynamic>, lineaId: docSnapshot.id);
      } else {
        return null;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addLineasMini(LineasMini lineasMini) async {
    try {
      await _lineasMiniCollection.add(lineasMini.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLineasMini(LineasMini lineasMini) async {
    try {
      await _lineasMiniCollection.doc(lineasMini.id).update(lineasMini.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLineasMini(String lineasMiniId) async {
    try {
      await _lineasMiniCollection.doc(lineasMiniId).delete();
    } catch (e) {
      rethrow;
    }
  }
}

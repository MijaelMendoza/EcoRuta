import 'package:cloud_firestore/cloud_firestore.dart';

class Zona {
  final String nombreZona;
  final double longitud;
  final double latitud;
  final int order;

  Zona({
    required this.nombreZona,
    required this.longitud,
    required this.latitud,
    required this.order,
  });

  factory Zona.fromMap(Map<String, dynamic> map) {
    return Zona(
      nombreZona: map['nombreZona'] as String? ?? '',
      longitud: (map['longitud'] ?? 0).toDouble(),
      latitud: (map['latitud'] ?? 0).toDouble(),
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombreZona': nombreZona,
      'longitud': longitud,
      'latitud': latitud,
      'order': order,
    };
  }
}

class LineasMini {
  final String id;
  final String tipo;
  final String linea;
  final String sindicato;
  final bool ida;
  final bool vigente;
  final List<Zona> zonas;

  LineasMini({
    required this.id,
    required this.tipo,
    required this.linea,
    required this.sindicato,
    required this.ida,
    required this.vigente,
    required this.zonas,
  });

  factory LineasMini.fromMap(Map<String, dynamic> map, {required String lineaId}) {
    return LineasMini(
      id: lineaId,
      tipo: map['tipo'] as String? ?? '',
      linea: map['linea'] as String? ?? '',
      sindicato: map['sindicato'] as String? ?? '',
      ida: map['ida'] as bool? ?? false,
      vigente: map['vigente'] as bool? ?? true,
      zonas: (map['zonas'] as List<dynamic>? ?? []).map((zonaMap) => Zona.fromMap(zonaMap as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'linea': linea,
      'sindicato': sindicato,
      'ida': ida,
      'vigente': vigente,
      'zonas': zonas.map((zona) => zona.toJson()).toList(),
    };
  }
}

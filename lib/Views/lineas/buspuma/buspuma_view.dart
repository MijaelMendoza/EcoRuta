import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_gmaps/.env.dart';
import 'package:flutter_gmaps/Controllers/MiLinea/lineas_controller.dart';
import 'package:flutter_gmaps/core/directions_repository.dart';
import 'package:flutter_gmaps/models/MiLinea/lineas_model.dart';
import 'package:flutter_gmaps/models/directions/directions_model.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_webservice/places.dart';

class RoutePumakatariScreen extends ConsumerStatefulWidget {
  final LatLng originPosition;
  final LatLng destinationPosition;

  RoutePumakatariScreen({required this.originPosition, required this.destinationPosition});

  @override
  _RoutePumakatariScreenState createState() => _RoutePumakatariScreenState();
}

class _RoutePumakatariScreenState extends ConsumerState<RoutePumakatariScreen> {
  late GoogleMapController _googleMapController;
  Marker? _originMarker;
  Marker? _destinationMarker;
  Directions? _info;
  final TextEditingController _destinationController = TextEditingController();
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  double _price = 0.0;
  double _co2 = 0.0;
  final LatLng _calle1Obrajes = LatLng(-16.5235717, -68.1177334);
  final Set<String> _processedRoutes = {};
final Map<String, Color> transportColors = {
  'Pumakatari': Colors.blue,
  'Minibus': Colors.green,
  'Taxi': Colors.red,
};

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  Future<BitmapDescriptor> _createCustomPumakatariMarkerBitmap() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 160.0; // Make the icon larger for Pumakatari
    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.directions_bus.codePoint),
      style: TextStyle(
        fontSize: 100.0, // Larger font size for Pumakatari
        fontFamily: Icons.directions_bus.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  void _initializeMarkers() {
    setState(() {
      _originMarker = Marker(
        markerId: MarkerId('origin'),
        position: widget.originPosition,
        infoWindow: InfoWindow(title: 'Origen'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
      _destinationMarker = Marker(
        markerId: MarkerId('destination'),
        position: widget.destinationPosition,
        infoWindow: InfoWindow(title: 'Destino'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    });
    _fetchBusRoutes('pumakatari');
  }

  Future<void> _fetchBusRoutes(String tipo, {LatLng? origin}) async {
    try {
      final lineasController = ref.read(lineasMiniControllerProvider.notifier);
      final lineas = await lineasController.getAllLineasMini();
      final nearbyLineas = lineas.where((linea) {
        return linea.tipo == (tipo == "pumakatari" ? "Pumakatari" : tipo) && linea.zonas.any((zona) {
          final distance = Geolocator.distanceBetween(
            (origin ?? widget.originPosition).latitude,
            (origin ?? widget.originPosition).longitude,
            zona.latitud,
            zona.longitud,
          );
          return distance <= 1000; // 1 km
        });
      }).toList();

      if (nearbyLineas.isNotEmpty) {
        final optimalLinea = await _findOptimalLinea(nearbyLineas, widget.destinationPosition);
        final puntos = optimalLinea.zonas.map((zona) => LatLng(zona.latitud, zona.longitud)).toList();
        await _addPolyline(puntos);

        final destinoCercano = _getClosestPoint(puntos, widget.destinationPosition, 1000); // 1 km de tolerancia
        if (destinoCercano != null) {
          final directions = await DirectionsRepository().getDirections(
            origin: origin ?? widget.originPosition,
            destination: destinoCercano,
          );
          setState(() {
            _info = directions;
            _calculatePriceAndCO2ForPumakatari(puntos, directions!);
          });
        } else {
          final directions = await DirectionsRepository().getDirections(
            origin: origin ?? widget.originPosition,
            destination: puntos.last,
          );
          setState(() {
            _info = directions;
            _calculatePriceAndCO2ForPumakatari(puntos, directions!);
            _checkNextBusRoute(puntos.last, widget.destinationPosition, tipo);
          });
        }
      } else {
        setState(() {
          _info = null;
          _price = 0.0;
          _co2 = 0.0;
        });
        print('No hay rutas cercanas');
      }
    } catch (e) {
      print('Error al buscar rutas de bus: $e');
    }
  }

  Future<LineasMini> _findOptimalLinea(List<LineasMini> lineas, LatLng destination) async {
    LineasMini? optimalLinea;
    double minDistance = double.infinity;

    for (var linea in lineas) {
      for (var zona in linea.zonas) {
        final distance = Geolocator.distanceBetween(
          zona.latitud,
          zona.longitud,
          destination.latitude,
          destination.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          optimalLinea = linea;
        }
      }
    }

    return optimalLinea!;
  }

  Future<void> _addPolyline(List<LatLng> puntos) async {
    final busMarkerIcon = await _createCustomPumakatariMarkerBitmap();
    for (int i = 0; i < puntos.length - 1; i++) {
      final directions = await DirectionsRepository().getDirections(
        origin: puntos[i],
        destination: puntos[i + 1],
      );

      if (directions != null) {
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: PolylineId(directions.bounds.toString()),
              color: Colors.blue,
              width: 5,
              points: directions.polylinePoints.map((e) => LatLng(e.latitude, e.longitude)).toList(),
            ),
          );

          // Add bus markers
          _markers.add(Marker(
            markerId: MarkerId('bus_marker_${puntos[i]}'),
            position: puntos[i],
            icon: busMarkerIcon,
            infoWindow: InfoWindow(
              title: 'Parada de Pumakatari',
              snippet: 'Punto ${i + 1}',
            ),
          ));
        });
      }
    }
  }

  Future<void> _calculatePriceAndCO2ForPumakatari(List<LatLng> puntos, Directions directions, {bool isSecondTrip = false}) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('constantes')
          .where('tipo', isEqualTo: 'pumakatari')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>?;
        if (data != null) {
          final price1 = _getDouble(data['precio1']);
          final price2 = _getDouble(data['precio2']);
          final fuelConsumption = _getDouble(data['consumo_medio']);
          final fuelType = data['tipo_combustible'] as String?;
          final capacity = _getDouble(data['capacidad_promedio']).toInt();

          if (fuelType != null) {
            double selectedPrice = price1;
            for (var punto in puntos) {
              if (_isBeyondCalle1Obrajes(punto)) {
                selectedPrice = price2;
                break;
              }
            }

            final distance = _parseDistance(directions.totalDistance);
            final routeKey = directions.bounds.toString();
            if (!_processedRoutes.contains(routeKey)) {
              setState(() {
                _price += isSecondTrip ? _price + selectedPrice : selectedPrice;
                _co2 += _calculateCO2Emission(fuelConsumption, fuelType, distance) / capacity;
                _processedRoutes.add(routeKey);
              });
            }
          } else {
            print('Error: tipo_combustible es nulo');
          }
        } else {
          print('Error: Datos del documento son nulos');
        }
      }
    } catch (e) {
      print('Error al obtener datos de la base de datos: $e');
    }
  }

  Future<void> _checkNextBusRoute(LatLng currentOrigin, LatLng finalDestination, String tipo) async {
    final lineasController = ref.read(lineasMiniControllerProvider.notifier);
    final lineas = await lineasController.getAllLineasMini();

    final nearbyLineas = lineas.where((linea) {
      return linea.tipo == (tipo == "pumakatari" ? "Pumakatari" : tipo) && linea.zonas.any((zona) {
        final distance = Geolocator.distanceBetween(
          currentOrigin.latitude,
          currentOrigin.longitude,
          zona.latitud,
          zona.longitud,
        );
        return distance <= 1000; // 1 km
      });
    }).toList();

    if (nearbyLineas.isNotEmpty) {
      final optimalLinea = await _findOptimalLinea(nearbyLineas, finalDestination);

      final puntos = optimalLinea.zonas.map((zona) => LatLng(zona.latitud, zona.longitud)).toList();
      await _addPolyline(puntos);

      final directions = await DirectionsRepository().getDirections(
        origin: currentOrigin,
        destination: finalDestination,
      );

      if (directions != null) {
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: PolylineId(directions.bounds.toString() + "_next"),
              color: Colors.red,
              width: 5,
              points: directions.polylinePoints.map((e) => LatLng(e.latitude, e.longitude)).toList(),
            ),
          );
          _calculatePriceAndCO2ForPumakatari(puntos, directions, isSecondTrip: true);
          if (directions.polylinePoints.last != finalDestination) {
            _checkNextBusRoute(puntos.last, finalDestination, tipo);
          }
        });
      }
    }
  }

  LatLng? _getClosestPoint(List<LatLng> puntos, LatLng destination, double toleranceInMeters) {
    LatLng? closestPoint;
    double minDistance = toleranceInMeters;

    for (var punto in puntos) {
      final distance = Geolocator.distanceBetween(
        punto.latitude,
        punto.longitude,
        destination.latitude,
        destination.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = punto;
      }
    }

    return closestPoint;
  }

  bool _isBeyondCalle1Obrajes(LatLng punto) {
    return punto.latitude > _calle1Obrajes.latitude;
  }

  double _getDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      throw ArgumentError('El valor no es ni int ni double');
    }
  }

  double _calculateCO2Emission(double fuelConsumption, String fuelType, double distance) {
    const fuelEmissionFactors = {
      'gasolina': 2.31,
      'diesel': 2.68,
      'electricidad': 0.47
    };
    return fuelConsumption * fuelEmissionFactors[fuelType]! * distance;
  }

  double _parseDistance(String distance) {
    final parts = distance.split(' ');
    if (parts.length < 2) return 0.0;

    final value = double.tryParse(parts[0]);
    if (value == null) return 0.0;

    if (parts[1].toLowerCase().contains('km')) {
      return value;
    } else if (parts[1].toLowerCase().contains('m')) {
      return value / 1000.0;
    } else {
      return 0.0;
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Iniciar Ruta en Pumakatari'),
    ),
    body: Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.originPosition,
            zoom: 14.5,
          ),
          onMapCreated: (controller) {
            _googleMapController = controller;
          },
          markers: _markers,
          polylines: _polylines,
        ),
        Positioned(
          bottom: 50,
          left: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 6.0,
              horizontal: 12.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 6.0,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ruta',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_info!.totalDistance}, ${_info!.totalDuration}',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Precio: \$${_price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'CO₂: ${_co2.toStringAsFixed(2)} kg',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600),
                  ),
                
              ],
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 6.0,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: transportColors.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        color: entry.value,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ),
  );
}

}

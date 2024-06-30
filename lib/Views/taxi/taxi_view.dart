import 'package:flutter/material.dart';
import 'package:flutter_gmaps/.env.dart';
import 'package:flutter_gmaps/core/directions_repository.dart';
import 'package:flutter_gmaps/models/directions/directions_model.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:google_maps_webservice/places.dart';

class RouteTaxiScreen extends StatefulWidget {
  final LatLng originPosition;
  final LatLng destinationPosition;

  RouteTaxiScreen({required this.originPosition, required this.destinationPosition});

  @override
  _RouteTaxiScreenState createState() => _RouteTaxiScreenState();
}

class _RouteTaxiScreenState extends State<RouteTaxiScreen> {
  late GoogleMapController _googleMapController;
  Marker? _originMarker;
  Marker? _destinationMarker;
  Directions? _info;
  final TextEditingController _destinationController = TextEditingController();
  LatLng? _currentPosition;
  Set<Polyline> _polylines = {};
  double _price = 0.0;
  double _co2 = 0.0;

  final String _googleApiKey = googleAPIKey;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
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
    _getDirections();
  }

  Future<void> _getDirections() async {
    try {
      final directions = await DirectionsRepository().getDirections(
        origin: widget.originPosition,
        destination: widget.destinationPosition,
      );

      setState(() {
        _info = directions;
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('overview_polyline'),
            color: Colors.blue,
            width: 5,
            points: directions!.polylinePoints.map((e) => LatLng(e.latitude, e.longitude)).toList(),
          ),
        );
        final distanceInKm = _parseDistance(directions.totalDistance);
        _calculatePriceAndCO2ForTaxi(distanceInKm);
      });
    } catch (e) {
      print('Error al obtener direcciones: $e');
    }
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _calculatePriceAndCO2ForTaxi(double distance) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('constantes').doc('wvskphrtYSRHVxBUj6nw').get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final pricePerKm = _getDouble(data['precio']);
        final fuelConsumption = _getDouble(data['consumo_medio']);
        final fuelType = data['tipo_combustible'] as String;
        final capacity = data['capacidad_promedio'] as int;

        setState(() {
          _price = (distance <= 1) ? 10 : (pricePerKm * distance).roundToDouble(); // Precio redondeado y mínimo de 10
          _co2 = _calculateCO2Emission(fuelConsumption, fuelType, distance) / capacity; // Emisiones por pasajero
        });
      }
    } catch (e) {
      print('Error al obtener datos de la base de datos: $e');
    }
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
        title: const Text('Iniciar Ruta en Taxi'),
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
            markers: {
              if (_originMarker != null) _originMarker!,
              if (_destinationMarker != null) _destinationMarker!,
            },
            polylines: _polylines,
          ),
          if (_info != null)
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
                      'Precio: \$${_price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'CO₂: ${_co2.toStringAsFixed(2)} kg',
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

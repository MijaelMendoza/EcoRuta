import 'package:flutter/material.dart';
import 'package:flutter_gmaps/.env.dart';
import 'package:flutter_gmaps/Controllers/MiLinea/lineas_controller.dart';
import 'package:flutter_gmaps/core/directions_repository.dart';
import 'package:flutter_gmaps/models/directions/directions_model.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RouteTaxiScreen extends ConsumerStatefulWidget {
  @override
  _RouteTaxiScreenState createState() => _RouteTaxiScreenState();
}

class _RouteTaxiScreenState extends ConsumerState<RouteTaxiScreen> {
  late GoogleMapController _googleMapController;
  Marker? _destinationMarker;
  Marker? _currentLocationMarker;
  Directions? _info;
  final TextEditingController _destinationController = TextEditingController();
  LatLng? _currentPosition;
  String _selectedTransport = 'taxi';
  Set<Polyline> _polylines = {};

  final String _googleApiKey = googleAPIKey;

  @override
  void dispose() {
    _googleMapController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _currentLocationMarker = Marker(
          markerId: MarkerId('current_location'),
          position: _currentPosition!,
          infoWindow: InfoWindow(title: 'Ubicación Actual'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        );
      });
      _googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 14.5),
        ),
      );
    } catch (e) {
      print('Error al obtener la ubicación actual: $e');
    }
  }

  void _handlePressButton() async {
    try {
      Prediction? p = await PlacesAutocomplete.show(
        context: context,
        apiKey: googleAPIKey,
        mode: Mode.overlay,
        language: "es",
        components: [Component(Component.country, "bo")],
      );

      if (p != null) {
        _displayPrediction(p);
      }
    } catch (e) {
      print('Error al obtener predicciones: $e');
    }
  }

  Future<void> _displayPrediction(Prediction p) async {
    try {
      GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: _googleApiKey);
      PlacesDetailsResponse detail = await places.getDetailsByPlaceId(p.placeId!);
      final lat = detail.result.geometry!.location.lat;
      final lng = detail.result.geometry!.location.lng;
      _addMarker(LatLng(lat, lng));
    } catch (e) {
      print('Error al obtener detalles del lugar: $e');
    }
  }

  Future<void> _fetchBusRoutes(String tipo) async {
    try {
      final lineasController = ref.read(lineasMiniControllerProvider.notifier);
      final lineas = await lineasController.getAllLineasMini();
      final nearbyLineas = lineas.where((linea) {
        return linea.tipo == tipo && linea.zonas.any((zona) {
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            zona.latitud,
            zona.longitud,
          );
          return distance <= 1000; // 1 km
        });
      }).toList();

      if (nearbyLineas.isNotEmpty) {
        // Mostrar la primera línea cercana encontrada
        final linea = nearbyLineas.first;
        final puntos = linea.zonas.map((zona) => LatLng(zona.latitud, zona.longitud)).toList();
        _addPolyline(puntos);

        // Calcular la distancia y tiempo de la ruta de bus
        final directions = await DirectionsRepository().getDirections(
          origin: _currentPosition!,
          destination: puntos.last,
        );
        setState(() => _info = directions);
      } else {
        // No se encontraron rutas cercanas
        setState(() {
          _info = null;
        });
        print('No hay rutas cercanas');
      }
    } catch (e) {
      print('Error al buscar rutas de bus: $e');
    }
  }

  void _addPolyline(List<LatLng> puntos) {
    final polyline = Polyline(
      polylineId: const PolylineId('bus_route'),
      color: Colors.blue,
      width: 5,
      points: puntos,
    );
    setState(() {
      _polylines.add(polyline);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Ruta'),
        actions: [
          IconButton(
            icon: Icon(Icons.directions_car),
            onPressed: () => _selectTransport('taxi'),
          ),
          IconButton(
            icon: Icon(Icons.directions_bus),
            onPressed: () => _selectTransport('pumakatari'),
          ),
          IconButton(
            icon: Icon(Icons.directions_bus_filled),
            onPressed: () => _selectTransport('minibus'),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-16.488997, -68.1248959),
              zoom: 11.5,
            ),
            onMapCreated: (controller) {
              _googleMapController = controller;
              _getCurrentLocation();
            },
            markers: {
              if (_currentLocationMarker != null) _currentLocationMarker!,
              if (_destinationMarker != null) _destinationMarker!,
            },
            polylines: _polylines,
            onTap: _addMarker,
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: GestureDetector(
              onTap: _handlePressButton,
              child: AbsorbPointer(
                child: TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    hintText: 'Buscar destino',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
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
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _addMarker(LatLng pos) async {
    try {
      setState(() {
        _destinationMarker = Marker(
          markerId: const MarkerId('destination'),
          infoWindow: const InfoWindow(title: 'Destino'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          position: pos,
        );
      });

      final directions = await DirectionsRepository().getDirections(
        origin: _currentPosition!,
        destination: pos,
      );

      setState(() {
        _info = directions;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('overview_polyline'),
            color: Colors.blue,
            width: 5,
            points: _info!.polylinePoints.map((e) => LatLng(e.latitude, e.longitude)).toList(),
          ),
        };
      });
    } catch (e) {
      print('Error al agregar marcador o obtener direcciones: $e');
    }
  }

  void _selectTransport(String transport) {
    setState(() {
      _selectedTransport = transport;
      _polylines.clear(); // Limpiar las polilíneas existentes
      _info = null; // Resetear la información de la ruta
    });

    if (transport == 'taxi') {
      if (_destinationMarker != null) {
        // Recalcular la ruta de taxi
        _addMarker(_destinationMarker!.position);
      }
    } else if (transport == 'pumakatari') {
      _fetchBusRoutes('pumakatari');
    } else if (transport == 'minibus') {
      _fetchBusRoutes('minibus');
    }
  }
}

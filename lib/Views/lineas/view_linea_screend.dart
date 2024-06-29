// views/view_linea_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Controllers/MiLinea/lineas_controller.dart';
import 'package:flutter_gmaps/core/directions_repository.dart';
import 'package:flutter_gmaps/models/MiLinea/lineas_model.dart';
import 'package:flutter_gmaps/models/directions/directions_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


enum MarkerType { none, origin, stop, destination, delete }

class ViewLineaScreen extends ConsumerStatefulWidget {
  final LineasMini linea;

  ViewLineaScreen({required this.linea});

  @override
  _ViewLineaScreenState createState() => _ViewLineaScreenState();
}

class _ViewLineaScreenState extends ConsumerState<ViewLineaScreen> {
  late GoogleMapController _googleMapController;
  MarkerType _selectedMarkerType = MarkerType.none;
  Marker? _originMarker;
  Marker? _destinationMarker;
  List<Marker> _stopMarkers = [];
  List<Directions> _directionsList = [];
  List<LatLng> _polylineCoordinates = [];
  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _lineaController = TextEditingController();
  final TextEditingController _sindicatoController = TextEditingController();
  bool _ida = true;
  bool _vigente = true;

  @override
  void initState() {
    super.initState();
    _initMarkersAndPolylines();
    _tipoController.text = widget.linea.tipo;
    _lineaController.text = widget.linea.linea;
    _sindicatoController.text = widget.linea.sindicato;
    _ida = widget.linea.ida;
    _vigente = widget.linea.vigente;
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    _tipoController.dispose();
    _lineaController.dispose();
    _sindicatoController.dispose();
    super.dispose();
  }

  Future<void> _initMarkersAndPolylines() async {
    List<LatLng> positions = widget.linea.zonas
        .map((zona) => LatLng(zona.latitud, zona.longitud))
        .toList();

    for (int i = 0; i < positions.length - 1; i++) {
      final directions = await DirectionsRepository().getDirections(
        origin: positions[i],
        destination: positions[i + 1],
      );

      if (directions != null) {
        setState(() {
          _directionsList.add(directions);
          _polylineCoordinates.addAll(directions.polylinePoints
              .map((e) => LatLng(e.latitude, e.longitude))
              .toList());
        });
      }
    }

    if (positions.isNotEmpty) {
      setState(() {
        _originMarker = Marker(
          markerId: const MarkerId('origin'),
          position: positions.first,
          infoWindow: InfoWindow(title: widget.linea.zonas.first.nombreZona),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        );
        _destinationMarker = Marker(
          markerId: const MarkerId('destination'),
          position: positions.last,
          infoWindow: InfoWindow(title: widget.linea.zonas.last.nombreZona),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
        _stopMarkers = positions
            .sublist(1, positions.length - 1)
            .map((pos) => Marker(
                  markerId: MarkerId(pos.toString()),
                  position: pos,
                  infoWindow: InfoWindow(title: 'Parada'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ver y Editar Línea'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateRoute,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.linea.zonas.first.latitud,
                widget.linea.zonas.first.longitud,
              ),
              zoom: 11.5,
            ),
            onMapCreated: (controller) => _googleMapController = controller,
            markers: {
              if (_originMarker != null) _originMarker!,
              if (_destinationMarker != null) _destinationMarker!,
              ..._stopMarkers,
            },
            polylines: _createPolylines(),
            onTap: _handleTap,
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "btn_origin",
                  backgroundColor: _selectedMarkerType == MarkerType.origin
                      ? Colors.green
                      : Colors.grey,
                  onPressed: () {
                    setState(() {
                      _selectedMarkerType = MarkerType.origin;
                    });
                  },
                  child: const Icon(Icons.place),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "btn_stop",
                  backgroundColor: _selectedMarkerType == MarkerType.stop
                      ? Colors.blue
                      : Colors.grey,
                  onPressed: () {
                    setState(() {
                      _selectedMarkerType = MarkerType.stop;
                    });
                  },
                  child: const Icon(Icons.stop_circle),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "btn_destination",
                  backgroundColor: _selectedMarkerType == MarkerType.destination
                      ? Colors.red
                      : Colors.grey,
                  onPressed: () {
                    setState(() {
                      _selectedMarkerType = MarkerType.destination;
                    });
                  },
                  child: const Icon(Icons.flag),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "btn_delete",
                  backgroundColor: _selectedMarkerType == MarkerType.delete
                      ? Colors.black
                      : Colors.grey,
                  onPressed: () {
                    setState(() {
                      _selectedMarkerType = MarkerType.delete;
                    });
                  },
                  child: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(LatLng position) async {
    if (_selectedMarkerType == MarkerType.none) return;

    if (_selectedMarkerType == MarkerType.delete) {
      _deleteMarker(position);
      return;
    }

    String streetName = await _getStreetName(position);

    if (_selectedMarkerType == MarkerType.origin) {
      setState(() {
        _originMarker = Marker(
          markerId: const MarkerId('origin'),
          position: position,
          infoWindow: InfoWindow(title: 'Origen', snippet: streetName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        );
        _updatePolyline();
      });
    } else if (_selectedMarkerType == MarkerType.stop) {
      if (_destinationMarker != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pueden agregar más paradas después del destino.')));
        return;
      }
      setState(() {
        _stopMarkers.add(
          Marker(
            markerId: MarkerId(position.toString()),
            position: position,
            infoWindow: InfoWindow(title: 'Parada', snippet: streetName),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        _updatePolyline();
      });
    } else if (_selectedMarkerType == MarkerType.destination) {
      setState(() {
        _destinationMarker = Marker(
          markerId: const MarkerId('destination'),
          position: position,
          infoWindow: InfoWindow(title: 'Destino', snippet: streetName),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
        _updatePolyline();
      });
    }
  }

  void _deleteMarker(LatLng position) {
    setState(() {
      if (_originMarker?.position == position) {
        _originMarker = null;
      } else if (_destinationMarker?.position == position) {
        _destinationMarker = null;
      } else {
        _stopMarkers.removeWhere((marker) =>
            marker.position.latitude == position.latitude &&
            marker.position.longitude == position.longitude);
      }
      _updatePolyline();
    });
  }

  void _updatePolyline() async {
    _directionsList.clear();
    _polylineCoordinates.clear();

    final markers = [_originMarker, ..._stopMarkers, _destinationMarker]
        .where((marker) => marker != null)
        .toList();

    for (int i = 0; i < markers.length - 1; i++) {
      final origin = markers[i]!.position;
      final destination = markers[i + 1]!.position;
      final directions = await DirectionsRepository().getDirections(
        origin: origin,
        destination: destination,
      );

      if (directions != null) {
        _directionsList.add(directions);
        _polylineCoordinates.addAll(directions.polylinePoints
            .map((e) => LatLng(e.latitude, e.longitude))
            .toList());
      }
    }

    setState(() {});
  }

  Set<Polyline> _createPolylines() {
    return {
      for (final directions in _directionsList)
        Polyline(
          polylineId: PolylineId(directions.bounds.toString()),
          color: Colors.blue,
          width: 5,
          points: directions.polylinePoints
              .map((e) => LatLng(e.latitude, e.longitude))
              .toList(),
        )
    };
  }

  Future<String> _getStreetName(LatLng position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      return placemarks.first.street ?? '';
    }
    return '';
  }

  void _updateRoute() {
    if (_originMarker == null || _destinationMarker == null || _stopMarkers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Debe haber un origen, destino y al menos una parada.')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final _formKey = GlobalKey<FormState>();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Actualizar Ruta'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _tipoController,
                      decoration: InputDecoration(labelText: 'Tipo de Bus'),
                      validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: _lineaController,
                      decoration: InputDecoration(labelText: 'Línea'),
                      validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: _sindicatoController,
                      decoration: InputDecoration(labelText: 'Sindicato'),
                      validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                    ),
                    Row(
                      children: [
                        Text('Ida'),
                        Switch(
                          value: _ida,
                          onChanged: (value) {
                            setState(() {
                              _ida = value;
                            });
                          },
                        ),
                        Text('Vuelta'),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Vigente'),
                        Switch(
                          value: _vigente,
                          onChanged: (value) {
                            setState(() {
                              _vigente = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final zonas = <Zona>[];
                      if (_originMarker != null) {
                        zonas.add(Zona(
                          nombreZona: _originMarker!.infoWindow.snippet ?? 'Origen',
                          longitud: _originMarker!.position.longitude,
                          latitud: _originMarker!.position.latitude,
                          order: 1,
                        ));
                      }
                      for (int i = 0; i < _stopMarkers.length; i++) {
                        zonas.add(Zona(
                          nombreZona: _stopMarkers[i].infoWindow.snippet ?? 'Parada',
                          longitud: _stopMarkers[i].position.longitude,
                          latitud: _stopMarkers[i].position.latitude,
                          order: i + 2,
                        ));
                      }
                      if (_destinationMarker != null) {
                        zonas.add(Zona(
                          nombreZona: _destinationMarker!.infoWindow.snippet ?? 'Destino',
                          longitud: _destinationMarker!.position.longitude,
                          latitud: _destinationMarker!.position.latitude,
                          order: zonas.length + 1,
                        ));
                      }

                      final updatedLinea = LineasMini(
                        id: widget.linea.id,
                        tipo: _tipoController.text,
                        linea: _lineaController.text,
                        sindicato: _sindicatoController.text,
                        ida: _ida,
                        vigente: _vigente,
                        zonas: zonas,
                      );

                      ref.read(lineasMiniApiProvider).updateLineasMini(updatedLinea).then((_) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ruta actualizada con éxito.')));
                      });
                    }
                  },
                  child: Text('Actualizar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

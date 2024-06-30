import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gmaps/.env.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_gmaps/models/MiTeleferico/LineaTeleferico.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/LineasTelefericoController.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class RouteViewTeleferico extends StatefulWidget {
  final LatLng originPosition;
  final LatLng destinationPosition;

  RouteViewTeleferico({required this.originPosition, required this.destinationPosition});

  @override
  _RouteViewTelefericoState createState() => _RouteViewTelefericoState();
}

class _RouteViewTelefericoState extends State<RouteViewTeleferico> {
  late GoogleMapController _googleMapController;
  final LineaTelefericoController _lineaTelefericoController = LineaTelefericoController();
  List<LineaTeleferico> _lineasTeleferico = [];
  Map<String, Estacion> _estaciones = {};
  Map<String, List<String>> _grafo = {};
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  double _price = 0.0;
  double _co2 = 0.0;
  double _totalDistance = 0.0;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadLineasTeleferico();
  }

  Future<void> _loadLineasTeleferico() async {
    _lineaTelefericoController.getLineasTelefericos().listen((lineas) {
      setState(() {
        _lineasTeleferico = lineas;
        _crearGrafoEstaciones();
        _buscarRutasTeleferico();
      });
    });
  }

  void _crearGrafoEstaciones() {
    _estaciones.clear();
    _grafo.clear();
    for (var linea in _lineasTeleferico) {
      for (var estacion in linea.estaciones) {
        _estaciones[estacion.nombreEstacion] = estacion;
        if (!_grafo.containsKey(estacion.nombreEstacion)) {
          _grafo[estacion.nombreEstacion] = [];
        }
      }
      for (int i = 0; i < linea.estaciones.length - 1; i++) {
        final estacionActual = linea.estaciones[i];
        final estacionSiguiente = linea.estaciones[i + 1];
        _grafo[estacionActual.nombreEstacion]!.add(estacionSiguiente.nombreEstacion);
        _grafo[estacionSiguiente.nombreEstacion]!.add(estacionActual.nombreEstacion);
      }
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(Color color) async {
    final svgString = await rootBundle.loadString('assets/svgs/TelefericoIcon.svg');
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 130.0;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

    final DrawableRoot svgDrawableRoot = await svg.fromSvgString(svgString, svgString);
    svgDrawableRoot.scaleCanvasToViewBox(canvas, Size(size, size));
    svgDrawableRoot.clipCanvasToViewBox(canvas);
    svgDrawableRoot.draw(canvas, Rect.fromLTWH(0, 0, size, size));

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<BitmapDescriptor> _createCustomTransferMarkerBitmap(Color color1, Color color2) async {
    final svgString = await rootBundle.loadString('assets/svgs/TelefericoIcon.svg');
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 130.0;

    final Paint paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;
    final Paint paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawArc(Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2), -pi / 2, pi, true, paint1);
    canvas.drawArc(Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2), pi / 2, pi, true, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

    final DrawableRoot svgDrawableRoot = await svg.fromSvgString(svgString, svgString);
    svgDrawableRoot.scaleCanvasToViewBox(canvas, Size(size, size));
    svgDrawableRoot.clipCanvasToViewBox(canvas);
    svgDrawableRoot.draw(canvas, Rect.fromLTWH(0, 0, size, size));

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<List<LatLng>> _getRouteCoordinates(LatLng origin, LatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleAPIKey';
    final response = await http.get(Uri.parse(url));
    final jsonResponse = json.decode(response.body);

    if (jsonResponse['status'] == 'OK') {
      final points = jsonResponse['routes'][0]['overview_polyline']['points'];
      _totalDuration += Duration(seconds: jsonResponse['routes'][0]['legs'][0]['duration']['value']);
      _totalDistance += jsonResponse['routes'][0]['legs'][0]['distance']['value'] / 1000; // Convert meters to kilometers
      return _decodePolyline(points);
    } else {
      return [];
    }
  }

  List<LatLng> _decodePolyline(String poly) {
    var list = poly.codeUnits;
    var lList = [];
    int index = 0;
    int len = poly.length;
    int c = 0;

    // repeating until all attributes are decoded
    do {
      var shift = 0;
      int result = 0;

      // for decoding value of one attribute
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      /* if value is negative then bitwise not the value */
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    /*adding to previous value as done in encoding */
    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    List<LatLng> points = [];

    for (var i = 0; i < lList.length; i += 2) {
      points.add(LatLng(lList[i], lList[i + 1]));
    }

    return points;
  }

  void _buscarRutasTeleferico() async {
    final estacionOrigen = _estacionMasCercana(widget.originPosition);
    final estacionDestino = _estacionMasCercana(widget.destinationPosition);

    if (estacionOrigen == null || estacionDestino == null) {
      return;
    }

    final ruta = _encontrarRuta(estacionOrigen, estacionDestino);

    if (ruta != null) {
      await _mostrarRutaEnMapa(ruta, estacionOrigen, estacionDestino);
    }
  }

  Estacion? _estacionMasCercana(LatLng posicion) {
    Estacion? estacionCercana;
    double distanciaMinima = double.infinity;

    _estaciones.forEach((nombre, estacion) {
      final distancia = Geolocator.distanceBetween(
        posicion.latitude,
        posicion.longitude,
        estacion.latitud,
        estacion.longitud,
      );
      if (distancia < distanciaMinima) {
        distanciaMinima = distancia;
        estacionCercana = estacion;
      }
    });

    return estacionCercana;
  }

  List<Estacion>? _encontrarRuta(Estacion origen, Estacion destino) {
    final dist = <String, double>{};
    final prev = <String, String?>{};
    final pq = PriorityQueue<String>((a, b) => dist[a]!.compareTo(dist[b]!));

    _estaciones.forEach((nombre, estacion) {
      dist[nombre] = double.infinity;
      prev[nombre] = null;
    });

    dist[origen.nombreEstacion] = 0;
    pq.add(origen.nombreEstacion);

    while (pq.isNotEmpty) {
      final u = pq.removeFirst();

      if (u == destino.nombreEstacion) {
        final ruta = <Estacion>[];
        String? actual = destino.nombreEstacion;
        while (actual != null) {
          ruta.insert(0, _estaciones[actual]!);
          actual = prev[actual];
        }
        return ruta;
      }

      for (var vecino in _grafo[u]!) {
        final alt = dist[u]! + _distanciaEntreEstaciones(u, vecino);
        if (alt < dist[vecino]!) {
          dist[vecino] = alt;
          prev[vecino] = u;
          pq.add(vecino);
        }
      }
    }

    return null;
  }

  double _distanciaEntreEstaciones(String nombreA, String nombreB) {
    final estacionA = _estaciones[nombreA]!;
    final estacionB = _estaciones[nombreB]!;
    return Geolocator.distanceBetween(
      estacionA.latitud,
      estacionA.longitud,
      estacionB.latitud,
      estacionB.longitud,
    );
  }

  Future<void> _mostrarRutaEnMapa(List<Estacion> ruta, Estacion estacionOrigen, Estacion estacionDestino) async {
    _polylines.clear();
    _markers.clear();
    _price = 0.0;
    _co2 = 0.0;
    _totalDistance = 0.0;
    _totalDuration = Duration.zero;

    // Ruta desde el origen hasta la primera estación
    final rutaOrigenEstacion = await _getRouteCoordinates(widget.originPosition, LatLng(estacionOrigen.latitud, estacionOrigen.longitud));
    _polylines.add(Polyline(
      polylineId: PolylineId('origen_a_estacion_inicial'),
      color: Colors.blue,
      width: 5,
      points: rutaOrigenEstacion,
    ));

    for (int i = 0; i < ruta.length - 1; i++) {
      final estacionActual = ruta[i];
      final estacionSiguiente = ruta[i + 1];

      final lineaActual = _lineasTeleferico.firstWhere((linea) => linea.estaciones.contains(estacionActual));
      final lineaSiguiente = _lineasTeleferico.firstWhere((linea) => linea.estaciones.contains(estacionSiguiente));

      Color colorActual = Color(int.parse('0xff${lineaActual.colorValue.substring(1)}'));
      Color colorSiguiente = Color(int.parse('0xff${lineaSiguiente.colorValue.substring(1)}'));

      BitmapDescriptor markerIcon;

      if (lineaActual.id == lineaSiguiente.id) {
        // No es un transbordo
        markerIcon = await _createCustomMarkerBitmap(colorActual);
      } else {
        // Es un transbordo
        markerIcon = await _createCustomTransferMarkerBitmap(colorActual, colorSiguiente);
      }

      final marker = Marker(
        markerId: MarkerId(estacionActual.nombreEstacion),
        position: LatLng(estacionActual.latitud, estacionActual.longitud),
        infoWindow: InfoWindow(
          title: estacionActual.nombreEstacion,
          snippet: estacionActual.nombreUbicacion,
        ),
        icon: markerIcon,
      );

      _markers.add(marker);

      _polylines.add(Polyline(
        polylineId: PolylineId('border_polyline_${lineaActual.nombre}_$i'),
        color: Colors.black,
        width: 9,
        points: [
          LatLng(estacionActual.latitud, estacionActual.longitud),
          LatLng(estacionSiguiente.latitud, estacionSiguiente.longitud),
        ],
      ));

      _polylines.add(Polyline(
        polylineId: PolylineId('polyline_${lineaActual.nombre}_$i'),
        color: colorSiguiente,  // Usamos el color de la siguiente estación para la línea
        width: 5,
        points: [
          LatLng(estacionActual.latitud, estacionActual.longitud),
          LatLng(estacionSiguiente.latitud, estacionSiguiente.longitud),
        ],
      ));

      // Calcular precio y CO2 para cada tramo
      await _calcularPrecioYCO2(lineaActual.id == lineaSiguiente.id, estacionActual, estacionSiguiente);
    }

    // Añadir el último marcador para la estación final
    final estacionFinal = ruta.last;
    final lineaFinal = _lineasTeleferico.firstWhere((linea) => linea.estaciones.contains(estacionFinal));

    final finalColor = Color(int.parse('0xff${lineaFinal.colorValue.substring(1)}'));
    final finalMarkerIcon = await _createCustomMarkerBitmap(finalColor);

    final finalMarker = Marker(
      markerId: MarkerId(estacionFinal.nombreEstacion),
      position: LatLng(estacionFinal.latitud, estacionFinal.longitud),
      infoWindow: InfoWindow(
        title: estacionFinal.nombreEstacion,
        snippet: estacionFinal.nombreUbicacion,
      ),
      icon: finalMarkerIcon,
    );

    _markers.add(finalMarker);

    // Ruta desde la última estación hasta el destino
    final rutaEstacionDestino = await _getRouteCoordinates(LatLng(estacionDestino.latitud, estacionDestino.longitud), widget.destinationPosition);
    _polylines.add(Polyline(
      polylineId: PolylineId('estacion_final_a_destino'),
      color: Colors.blue,
      width: 5,
      points: rutaEstacionDestino,
    ));

    // Añadir marcador de origen
    _markers.add(Marker(
      markerId: MarkerId('origen'),
      position: widget.originPosition,
      infoWindow: InfoWindow(
        title: 'Origen',
        snippet: 'Punto de inicio',
      ),
    ));

    // Añadir marcador de destino
    _markers.add(Marker(
      markerId: MarkerId('destino'),
      position: widget.destinationPosition,
      infoWindow: InfoWindow(
        title: 'Destino',
        snippet: 'Punto de llegada',
      ),
    ));

    setState(() {});
  }

  Future<void> _calcularPrecioYCO2(bool esMismaLinea, Estacion estacionActual, Estacion estacionSiguiente) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('constantes').doc('CuhQJiL6y9MwPt1R70kc').get();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final tarifaGeneral = data['TarifaGeneral'];
        final tarifaPreferencial = data['TarifaPreferencial'];
        final consumoMedio = _getDouble(data['consumo_medio']);
        final tipoCombustible = data['tipo_combustible'] as String;
        final capacidadPromedio = _getDouble(data['capacidad_promedio']).toInt();

        final distancia = _distanciaEntreEstaciones(estacionActual.nombreEstacion, estacionSiguiente.nombreEstacion) / 1000; // Convertir a kilómetros
        final tarifa = esMismaLinea ? tarifaGeneral['PrimeraLinea'] : tarifaGeneral['Transbordo'];
        
        setState(() {
          _price += tarifa;
          _co2 += _calculateCO2Emission(consumoMedio, tipoCombustible, distancia) / capacidadPromedio; // Emisiones por pasajero
        });
      }
    } catch (e) {
      print('Error al calcular precio y CO2: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ruta de Teleférico'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(-16.4897, -68.1193),
              zoom: 14.5,
            ),
            onMapCreated: (controller) {
              _googleMapController = controller;
            },
            markers: _markers,
            polylines: _polylines,
          ),
          if (_totalDistance > 0 && _totalDuration != Duration.zero)
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
                      'Distancia: ${_totalDistance.toStringAsFixed(2)} km, Tiempo: ${_totalDuration.inMinutes} min',
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

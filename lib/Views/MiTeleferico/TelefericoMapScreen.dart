import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/LineasTelefericoController.dart';
import 'package:flutter_gmaps/models/MiTeleferico/LineaTeleferico.dart';

class TelefericosHandler {
  static final LineaTelefericoController _firebaseController = LineaTelefericoController();

  static Future<void> loadLineasTeleferico({
    required Function(List<Marker>) onMarkersLoaded,
    required Function(List<Polyline>) onPolylinesLoaded,
  }) async {
    _firebaseController.getLineasTelefericos().listen((lineas) async {
      List<Marker> markers = [];
      List<Polyline> polylines = [];

      for (var linea in lineas) {
        for (var estacion in linea.estaciones) {
          final markerIcon = await _createCustomMarkerBitmap(Color(int.parse('0xff${linea.colorValue.substring(1)}')));
          final marker = Marker(
            markerId: MarkerId(estacion.nombreEstacion),
            position: LatLng(estacion.latitud, estacion.longitud),
            infoWindow: InfoWindow(
              title: estacion.nombreEstacion,
              snippet: estacion.nombreUbicacion,
            ),
            icon: markerIcon,
          );
          markers.add(marker);
        }

        if (linea.estaciones.length > 1) {
          for (int i = 0; i < linea.estaciones.length - 1; i++) {
            final color = Color(int.parse('0xff${linea.colorValue.substring(1)}'));

            polylines.add(Polyline(
              polylineId: PolylineId('border_polyline_${linea.nombre}_$i'),
              color: Colors.black,
              width: 9,
              points: [
                LatLng(linea.estaciones[i].latitud, linea.estaciones[i].longitud),
                LatLng(linea.estaciones[i + 1].latitud, linea.estaciones[i + 1].longitud),
              ],
            ));

            polylines.add(Polyline(
              polylineId: PolylineId('polyline_${linea.nombre}_$i'),
              color: color,
              width: 5,
              points: [
                LatLng(linea.estaciones[i].latitud, linea.estaciones[i].longitud),
                LatLng(linea.estaciones[i + 1].latitud, linea.estaciones[i + 1].longitud),
              ],
            ));
          }
        }
      }

      onMarkersLoaded(markers);
      onPolylinesLoaded(polylines);
    });
  }

  static Future<BitmapDescriptor> _createCustomMarkerBitmap(Color color) async {
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

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image img = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }
}

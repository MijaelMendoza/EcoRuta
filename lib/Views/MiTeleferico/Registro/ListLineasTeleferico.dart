import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Controllers/MiTeleferico/LineasTelefericoController.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/Registro/EditLineaTeleferico.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/Registro/RegistroLineaScreen.dart';
import 'package:flutter_gmaps/models/MiTeleferico/LineaTeleferico.dart';

class ListLineasTelefericoScreen extends StatefulWidget {
  @override
  _ListLineasTelefericoScreenState createState() => _ListLineasTelefericoScreenState();
}

class _ListLineasTelefericoScreenState extends State<ListLineasTelefericoScreen> {
  final LineaTelefericoController _firebaseController = LineaTelefericoController();
  List<LineaTeleferico> _lineasTeleferico = [];

  @override
  void initState() {
    super.initState();
    _loadLineasTeleferico();
  }

  Future<void> _loadLineasTeleferico() async {
    _firebaseController.getLineasTelefericos().listen((lineas) {
      setState(() {
        _lineasTeleferico = lineas;
      });
    });
  }

  void _editLinea(LineaTeleferico linea) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarLineaScreen(linea: linea)),
    );
  }

  void _deleteLinea(String id) async {
    await _firebaseController.deleteLineaTeleferico(id);
    _loadLineasTeleferico();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Líneas de Teleférico'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegistroLineaScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _lineasTeleferico.length,
        itemBuilder: (context, index) {
          final linea = _lineasTeleferico[index];
          return ListTile(
            title: Text(linea.nombre),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editLinea(linea),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteLinea(linea.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

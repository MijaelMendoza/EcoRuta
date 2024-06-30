import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/Registro/ListLineasTeleferico.dart';
import 'package:flutter_gmaps/Views/lineas/lineas_registered_view.dart';
import 'package:flutter_gmaps/auth/view/welcome.dart';

class MenuDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.map),
            title: Text('Mapa'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Configuración'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('Acerca de'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.directions_bus),
            title: Text('Agregar Líneas de Bus'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LineasScreen()),
              ); // Navigate to LineasScreen
            },
          ),
          ListTile(
            leading: Icon(Icons.directions_bus),
            title: Text('Líneas de Teleferico'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListLineasTelefericoScreen()),
              ); // Navigate to LineasScreen
            },
          ),
          ListTile(
            leading: Icon(Icons.login),
            title: Text('Login'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WelcomePage()),
              ); // Navigate to WelcomePage
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/Registro/ListLineasTeleferico.dart';
import 'package:flutter_gmaps/Views/lineas/lineas_registered_view.dart';
import 'package:flutter_gmaps/auth/view/welcome.dart';
import 'package:flutter_gmaps/user_profile/view/user_profile_view.dart'; // Importar la vista del perfil del usuario
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MenuDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(currentUserAccountProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: userAsyncValue.when(
              data: (user) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menú',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    user != null ? 'Bienvenido, ${user.email}' : 'Bienvenido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              loading: () => CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
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
            title: Text('Líneas de Teleférico'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListLineasTelefericoScreen()),
              ); // Navigate to ListLineasTelefericoScreen
            },
          ), 
          userAsyncValue.when(
            data: (user) {
              return user != null
                  ? Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.person),
                          title: Text('Perfil'),
                          onTap: () {
                            Navigator.push(
                              context,
                              UserProfileView.route(),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.logout),
                          title: Text('Cerrar Sesión'),
                          onTap: () {
                            ref.read(authControllerProvider.notifier).logout(context);
                          },
                        ),
                      ],
                    )
                  : ListTile(
                      leading: Icon(Icons.login),
                      title: Text('Iniciar Sesión'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginView()),
                        ); // Navigate to LoginView
                      },
                    );
            },
            loading: () => Container(),
            error: (err, stack) => Container(),
          ),
        ],
      ),
    );
  }
}

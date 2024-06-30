import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Views/MiTeleferico/Registro/ListLineasTeleferico.dart';
import 'package:flutter_gmaps/Views/lineas/lineas_registered_view.dart';
import 'package:flutter_gmaps/auth/controller/auth_controller.dart';
import 'package:flutter_gmaps/common/error_page.dart';
import 'package:flutter_gmaps/common/loading_page.dart';
import 'package:flutter_gmaps/models/user_model.dart';
import 'package:flutter_gmaps/user_profile/controller/user_profile_controller.dart';
import 'package:flutter_gmaps/user_profile/view/edit_profile_view.dart';
import 'package:flutter_gmaps/utils/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile extends ConsumerWidget {
  final String uid; // Usamos uid para identificar al usuario
  const UserProfile({
    super.key,
    required this.uid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userDetailsProvider(uid));

    void _refreshUserDetails() {
      ref.refresh(userDetailsProvider(uid));
    }

    return userAsyncValue.when(
      data: (user) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.tealAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(user.profilePic),
                          radius: 50,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.teal[700],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ListTile(
                            leading: Icon(Icons.person, color: Colors.white),
                            title: Text(
                              'Datos Personales',
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: Icon(Icons.edit, color: Colors.white),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                EditProfileView.route(),
                              );
                              _refreshUserDetails();
                            },
                          ),
                          if (user.role == 'admin') ...[
                            ListTile(
                              leading: Icon(Icons.cable, color: Colors.white),
                              title: Text('Líneas de Teleférico', style: TextStyle(color: Colors.white)),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ListLineasTelefericoScreen()),
                                );
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.directions_bus, color: Colors.white),
                              title: Text('Agregar Líneas de Bus', style: TextStyle(color: Colors.white)),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => LineasScreen()),
                                );
                              },
                            ),
                          ],
                          ListTile(
                            leading: Icon(Icons.account_balance_wallet, color: Colors.white),
                            title: Text('Saldo', style: TextStyle(color: Colors.white)),
                          ),
                          ListTile(
                            leading: Icon(Icons.eco, color: Colors.white),
                            title: Text('EcoDatos', style: TextStyle(color: Colors.white)),
                          ),
                          ListTile(
                            leading: Icon(Icons.announcement, color: Colors.white),
                            title: Text('Anuncios', style: TextStyle(color: Colors.white)),
                          ),
                          ListTile(
                            leading: Icon(Icons.help, color: Colors.white),
                            title: Text('Preguntas Frecuentes', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(height: 20),
                          Divider(color: Colors.tealAccent),
                          ListTile(
                            title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red), textAlign: TextAlign.center),
                            onTap: () {
                              ref.read(authControllerProvider.notifier).logout(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Loader(),
      error: (err, stack) => ErrorText(error: err.toString()),
    );
  }
}

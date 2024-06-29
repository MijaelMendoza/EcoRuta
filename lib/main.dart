import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gmaps/firebase_options.dart';
import 'package:flutter_gmaps/utils/theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: MapScreen(toggleTheme: _toggleTheme, isDarkMode: _themeMode == ThemeMode.dark),
    );
  }
}

class MapScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  MapScreen({required this.toggleTheme, required this.isDarkMode});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(-16.4897, -68.1193),
    zoom: 14.5,
  );

  late GoogleMapController _googleMapController;
  late LatLng _currentPosition;
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _traveledPoints = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _getCurrentLocation();
    _listenToLocationChanges();
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _traveledPoints.add(_currentPosition);
    });

    _googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 14.5,
        ),
      ),
    );
  }

  void _listenToLocationChanges() {
    _positionStream = Geolocator.getPositionStream().listen((position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _traveledPoints.add(_currentPosition);
      });

      _googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition,
            zoom: 14.5,
          ),
        ),
      );
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateMapStyle() async {
    if (widget.isDarkMode) {
      _googleMapController.setMapStyle(darkMapStyle);
    } else {
      _googleMapController.setMapStyle(null); // Default style
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateMapStyle();

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) {
              _googleMapController = controller;
              _updateMapStyle();
            },
            polylines: _createPolylines(),
          ),
          Column(
            children: [
              AppBar(
                centerTitle: false,
                title: const Text('EcoRuta'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.brightness_6),
                    onPressed: widget.toggleTheme,
                  ),
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              ),
              Expanded(child: Container()), // Space for the map
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 10,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: BottomNavigationBar(
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.directions_bus),
                        label: 'MinuBus',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.directions_transit),
                        label: 'PumaKatari',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.cable),
                        label: 'Teleferico',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.local_taxi),
                        label: 'Taxis',
                      ),
                    ],
                    currentIndex: _selectedIndex,
                    selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
                    unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                    onTap: _onItemTapped,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 80,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.black,
              onPressed: () {
                _googleMapController.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _currentPosition,
                      zoom: 14.5,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.center_focus_strong),
            ),
          ),
        ],
      ),
    );
  }

  Set<Polyline> _createPolylines() {
    Set<Polyline> polylines = {};
    polylines.add(Polyline(
      polylineId: const PolylineId('traveled_route'),
      color: Colors.grey,
      width: 5,
      points: _traveledPoints,
    ));
    return polylines;
  }
}

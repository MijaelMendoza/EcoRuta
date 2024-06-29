import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_gmaps/utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeView extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  HomeView({required this.toggleTheme, required this.isDarkMode});

  static Route route({required VoidCallback toggleTheme, required bool isDarkMode}) {
    return MaterialPageRoute<void>(
        builder: (_) => HomeView(toggleTheme: toggleTheme, isDarkMode: isDarkMode));
  }

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(-16.4897, -68.1193),
    zoom: 14.5,
  );

  late GoogleMapController _googleMapController;
  late LatLng _currentPosition;
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _traveledPoints = [];
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadThemePreference();
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

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? widget.isDarkMode;
      _updateMapStyle();
    });
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
    if (_isDarkMode) {
      _googleMapController.setMapStyle(darkMapStyle);
    } else {
      _googleMapController.setMapStyle(null); // Default style
    }
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = !_isDarkMode;
    await prefs.setBool('isDarkMode', isDarkMode);
    setState(() {
      _isDarkMode = isDarkMode;
      widget.toggleTheme();
      _updateMapStyle();
    });
  }

  @override
  Widget build(BuildContext context) {
    _updateMapStyle();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('EcoRuta'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: _toggleTheme,
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Stack(
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

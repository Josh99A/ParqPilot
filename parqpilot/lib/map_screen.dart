import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  late BitmapDescriptor customIcon;

  final LatLng _cocisParkingLot = const LatLng(0.3316, 32.5705);
  final Map<String, dynamic> _slotStatus = {
    "SlotA1": {"status": "occupied"},
    "SlotA2": {"status": "free"},
  };

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Position? _currentPosition;
  bool _directionsShown = false;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _determinePosition();
  }

  void _loadCustomMarker() async {
    customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(72, 72)),
      'assets/parqpilot.png.png',
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('MakerereCocis'),
        position: _cocisParkingLot,
        infoWindow: InfoWindow(
          title: 'Makerere COCIS Parking Lot',
          snippet: _getSlotSummary(),
          onTap: _showParkingInfo,
        ),
        icon: customIcon,
      ),
    );
    setState(() {});
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  String _getSlotSummary() {
    int total = _slotStatus.length;
    int free = _slotStatus.values.where((slot) => slot['status'] == 'free').length;
    return 'Slots: $free free / $total total';
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _getDirections() async {
    if (_currentPosition == null) return;

    final origin = "${_currentPosition!.latitude},${_currentPosition!.longitude}";
    final destination = "${_cocisParkingLot.latitude},${_cocisParkingLot.longitude}";

    const apiKey = 'AIzaSyDzC0p_RphQL4xdbOZEv_XcYWCJK4kQzB8';

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return;

    final data = json.decode(response.body);
    final polylinePoints = _decodePolyline(data['routes'][0]['overview_polyline']['points']);

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
      _directionsShown = true;
    });

    mapController.animateCamera(CameraUpdate.newLatLngBounds(
      _boundsFromLatLngList([
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        _cocisParkingLot,
      ]),
      100,
    ));
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double x0 = list[0].latitude, x1 = list[0].latitude;
    double y0 = list[0].longitude, y1 = list[0].longitude;
    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  void _showParkingInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/cocis_parking.jpg',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Makerere COCIS Parking Lot',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(_getSlotSummary()),
              const SizedBox(height: 16),
              if (!_directionsShown)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); 
                    _getDirections();        
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 36, 36, 217),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ParqPilot'),
        backgroundColor: const Color.fromARGB(255, 36, 36, 217),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        initialCameraPosition: CameraPosition(
          target: _cocisParkingLot,
          zoom: 15,
        ),
        markers: _markers,
        polylines: _polylines,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'home_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(0.3316, 32.5705);

  // Parking lot data
  final LatLng _cocisParkingLot = const LatLng(0.3156, 32.5825);

  final Map<String, dynamic> _slotStatus = {
    "SlotA1": {
      "status": "occupied",
      "lastUpdated": "2025-07-15T14:23:00Z",
    },
    "SlotA2": {
      "status": "free",
      "lastUpdated": "2025-07-15T14:23:00Z",
    },
  };

  late final Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('MakerereCocis'),
        position: _cocisParkingLot,
        infoWindow: InfoWindow(
          title: 'Makerere COCIS Parking Lot',
          snippet: _getSlotSummary(),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };
  }

  String _getSlotSummary() {
    int total = _slotStatus.length;
    int free = _slotStatus.values.where((slot) => slot['status'] == 'free').length;
    return 'Slots: $free free / $total total';
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 13.0,
        ),
        markers: _markers,
      ),
    );
  }
}

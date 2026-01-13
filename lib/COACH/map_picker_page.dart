import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? selectedLatLng;
  String address = "";
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      selectedLatLng = LatLng(pos.latitude, pos.longitude);
    });

    _reverseGeocode();
  }

  Future<void> _reverseGeocode() async {
    if (selectedLatLng == null) return;

    final placemarks = await placemarkFromCoordinates(
      selectedLatLng!.latitude,
      selectedLatLng!.longitude,
    );

    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      setState(() {
        address =
            "${p.name}, ${p.locality}, ${p.administrativeArea}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
      ),
      body: selectedLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: selectedLatLng!,
                    initialZoom: 16,
                    onTap: (_, latLng) {
                      setState(() => selectedLatLng = latLng);
                      _reverseGeocode();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.myskates.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLatLng!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        "lat": selectedLatLng!.latitude,
                        "lng": selectedLatLng!.longitude,
                        "address": address,
                      });
                    },
                    child: const Text("Confirm Location"),
                  ),
                ),
              ],
            ),
    );
  }
}

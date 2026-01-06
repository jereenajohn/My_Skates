import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({super.key});

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng? selectedLatLng;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initDefaultLocation();
  }

  // ---------------------------
  // PERMISSION (YOUR STYLE)
  // ---------------------------
  Future<bool> askLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // ---------------------------
  // DEFAULT = CURRENT LOCATION
  // ---------------------------
  Future<void> _initDefaultLocation() async {
    try {
      final allowed = await askLocationPermission();

      if (!allowed) {
        // fallback if permission not granted
        selectedLatLng = const LatLng(20.5937, 78.9629);
        setState(() => loading = false);
        return;
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        // fallback if GPS off
        selectedLatLng = const LatLng(20.5937, 78.9629);
        setState(() => loading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      selectedLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() => loading = false);
    } catch (e) {
      selectedLatLng = const LatLng(20.5937, 78.9629);
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Select Location"),
        actions: [
          TextButton(
            onPressed: (selectedLatLng == null)
                ? null
                : () => Navigator.pop(context, selectedLatLng),
            child: const Text(
              "CONFIRM",
              style: TextStyle(
                color: Color(0xFF00D8CC),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D8CC)),
            )
          : FlutterMap(
              options: MapOptions(
                initialCenter: selectedLatLng!,
                initialZoom: 15,
                onTap: (_, latLng) {
                  setState(() {
                    selectedLatLng = latLng;
                  });
                },
              ),
              children: [
                // ✅ Your Jawg template
                TileLayer(
                  urlTemplate:
                      "https://tile.jawg.io/jawg-dark/{z}/{x}/{y}.png?access-token=2B7dgDmr4GbsgqSaMLKgFwKHXVuhFAcIAJ7sD1TgNjB9Mmto5m9L4rcDGNKHl4GQ",
                  userAgentPackageName: "my_skates",
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLatLng!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        size: 46,
                        color: Color(0xFF00D8CC),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

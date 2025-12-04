import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class SelectLocationOSM extends StatefulWidget {
  const SelectLocationOSM({super.key});

  @override
  State<SelectLocationOSM> createState() => _SelectLocationOSMState();
}

class _SelectLocationOSMState extends State<SelectLocationOSM> {
  LatLng? selectedPoint;
  bool isLoading = true;
  String selectedAddress = "";
  MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        selectedPoint = LatLng(pos.latitude, pos.longitude);
        isLoading = false;
      });

      _updateAddress(pos.latitude, pos.longitude);

    } catch (e) {
      print("LOCATION ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateAddress(double lat, double lng) async {
    try {
      List<Placemark> places = await placemarkFromCoordinates(lat, lng);
      Placemark p = places.first;

      setState(() {
        selectedAddress =
            "${p.name ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}";
      });
    } catch (e) {
      print("ADDRESS ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || selectedPoint == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      // appBar: AppBar(
      //   backgroundColor: Colors.black,
      //   title: const Text("Select Location", style: TextStyle(color: Colors.white)),
      // ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: selectedPoint!,
              initialZoom: 15,
              onTap: (tapPos, point) {
                setState(() => selectedPoint = point);
                _updateAddress(point.latitude, point.longitude);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://tile.jawg.io/jawg-dark/{z}/{x}/{y}.png?access-token=2B7dgDmr4GbsgqSaMLKgFwKHXVuhFAcIAJ7sD1TgNjB9Mmto5m9L4rcDGNKHl4GQ",
                // Premium dark style (free token available)
                userAgentPackageName: 'my_skates',
              ),

              // Animated Custom Marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedPoint!,
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.8),
                                blurRadius: 15,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                        ),
                        const Icon(Icons.location_on,
                            color: Colors.redAccent, size: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ZOOM BUTTONS
          Positioned(
            right: 10,
            top: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoom_in",
                  mini: true,
                  backgroundColor: Colors.teal,
                  child: const Icon(Icons.add),
                  onPressed: () {
                    mapController.move(
                        selectedPoint!, mapController.camera.zoom + 1);
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoom_out",
                  mini: true,
                  backgroundColor: Colors.teal,
                  child: const Icon(Icons.remove),
                  onPressed: () {
                    mapController.move(
                        selectedPoint!, mapController.camera.zoom - 1);
                  },
                ),
              ],
            ),
          ),

          // SELECTED ADDRESS CARD
          Positioned(
            left: 10,
            right: 10,
            bottom: 100,
            child: Card(
              color: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  selectedAddress.isEmpty
                      ? "Selecting location…"
                      : selectedAddress,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          // CONFIRM BUTTON WITH GRADIENT
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.teal, Colors.greenAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pop(context, {
                    "lat": selectedPoint!.latitude,
                    "lng": selectedPoint!.longitude,
                    "address": selectedAddress,
                  });
                },
                child: const Text(
                  "Confirm Location",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

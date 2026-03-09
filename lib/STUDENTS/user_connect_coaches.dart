import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/coach_details_page.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserConnectCoaches extends StatefulWidget {
  const UserConnectCoaches({super.key});

  @override
  State<UserConnectCoaches> createState() => _UserConnectCoachesState();
}

class _UserConnectCoachesState extends State<UserConnectCoaches> {
  LatLng? userLocation;
  List coaches = [];

  Set<Marker> markers = {};
  Set<Circle> circles = {};

  bool isLoading = true;
  double selectedRadiusKm = 5.0;

  GoogleMapController? mapController;
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    initPage();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> initPage() async {
    await getUserCurrentLocation();
    await fetchCoaches();
    addCoachMarkers();
    setState(() => isLoading = false);
  }

  Future<void> getUserCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    userLocation = LatLng(pos.latitude, pos.longitude);

    print("USER LOCATION → Lat:${pos.latitude}, Lng:${pos.longitude}");
  }

  Future<void> fetchCoaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final url = "$api/api/myskates/coach/details/";
      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        coaches = jsonDecode(res.body);
        print("COACHES FETCHED: ${coaches.length}");
      } else {
        print("FAILED TO FETCH COACHES → ${res.statusCode}");
      }
    } catch (e) {
      print("API ERROR → $e");
    }
  }

  double distanceInKm(LatLng a, LatLng b) {
    final meters = Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
    return meters / 1000;
  }

  void updateRadiusCircle() {
    if (userLocation == null) return;

    circles = {
      Circle(
        circleId: const CircleId("user_radius"),
        center: userLocation!,
        radius: selectedRadiusKm * 1000,
        fillColor: Colors.teal.withOpacity(0.09),
        strokeColor: Colors.teal,
        strokeWidth: 2,
      ),
    };
  }

  // ADD ALL COACH MARKERS (Default)
  void addCoachMarkers() {
    if (userLocation == null) return;

    final Set<Marker> newMarkers = {};
    final double maxKm = selectedRadiusKm;

    for (var coach in coaches) {
      if (coach["latitude"] == null || coach["longitude"] == null) continue;

      final double? lat = double.tryParse("${coach["latitude"]}");
      final double? lng = double.tryParse("${coach["longitude"]}");

      if (lat == null || lng == null) continue;

      final LatLng coachPos = LatLng(lat, lng);
      final double km = distanceInKm(userLocation!, coachPos);

      if (km <= maxKm) {
        newMarkers.add(
          Marker(
            markerId: MarkerId("coach_${coach["id"]}"),
            position: coachPos,
            infoWindow: InfoWindow(
              title: "${coach['first_name']} ${coach['last_name'] ?? ''}".trim(),
              snippet: "${km.toStringAsFixed(2)} km away",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            onTap: () => showCoachBottomSheet(coach, km),
          ),
        );
      }
    }

    newMarkers.add(
      Marker(
        markerId: const MarkerId("user_location"),
        position: userLocation!,
        infoWindow: const InfoWindow(title: "You"),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
      ),
    );

    markers = newMarkers;
    updateRadiusCircle();
  }

  // SEARCH LOGIC
  void filterSearch(String query) async {
    if (query.isEmpty) {
      addCoachMarkers();
      setState(() {});
      return;
    }

    List result = coaches.where((coach) {
      final name = "${coach['first_name']} ${coach['last_name']}"
          .toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    if (result.isEmpty) {
      addCoachMarkers();
      setState(() {});
      return;
    }

    final coach = result.first;

    final double? lat = double.tryParse(coach["latitude"].toString());
    final double? lng = double.tryParse(coach["longitude"].toString());

    if (lat == null || lng == null) return;

    final LatLng target = LatLng(lat, lng);

    await mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16),
      ),
    );

    markers = {
      Marker(
        markerId: MarkerId("search_coach_${coach["id"]}"),
        position: target,
        infoWindow: InfoWindow(
          title: "${coach["first_name"]} ${coach["last_name"] ?? ""}".trim(),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        onTap: () => showCoachBottomSheet(coach, 0),
      ),
      if (userLocation != null)
        Marker(
          markerId: const MarkerId("user_location"),
          position: userLocation!,
          infoWindow: const InfoWindow(title: "You"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
    };

    updateRadiusCircle();
    setState(() {});
  }

  // COACH DETAIL POPUP
  void showCoachBottomSheet(dynamic coach, double km) {
    showModalBottomSheet(
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: coach["profile"] != null
                        ? NetworkImage("$api${coach["profile"]}")
                        : null,
                    backgroundColor: Colors.grey.shade800,
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(
                      "${coach["first_name"]} ${coach["last_name"]}",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CoachDetailsPage(coachId: coach['id']),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.remove_red_eye,
                      color: Colors.tealAccent,
                      size: 30,
                    ),
                  ),
                ],
              ),
              Text(
                "${km.toStringAsFixed(2)} km away",
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 35),
            ],
          ),
        );
      },
    );
  }

  // SEARCH BAR UI
  Widget buildSearchBar() {
    return Positioned(
      top: 120,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [
              Colors.tealAccent.withOpacity(0.8),
              Colors.teal.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchCtrl,
                onChanged: filterSearch,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: "Search coach",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRadiusSelector() {
    return Positioned(
      bottom: 145,
      left: 40,
      right: 40,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${selectedRadiusKm.toInt()} km radius",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(
              height: 26,
              child: Slider(
                value: selectedRadiusKm,
                min: 1,
                max: 50,
                divisions: 49,
                activeColor: Colors.tealAccent,
                inactiveColor: Colors.grey,
                label: "${selectedRadiusKm.toInt()} km",
                onChanged: (value) {
                  setState(() {
                    selectedRadiusKm = value;
                    addCoachMarkers();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ZOOM BUTTONS (bottom right)
  Widget buildZoomButtons() {
    return Positioned(
      bottom: 40,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: "zoom_in",
            mini: true,
            backgroundColor: Colors.teal,
            child: const Icon(Icons.add,color: Colors.white,),
            onPressed: () async {
              final currentZoom = await mapController?.getZoomLevel() ?? 14.0;
              await mapController?.animateCamera(
                CameraUpdate.zoomTo(currentZoom + 1),
              );
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "zoom_out",
            mini: true,
            backgroundColor: Colors.teal,
            child: const Icon(Icons.remove,color: Colors.white),
            onPressed: () async {
              final currentZoom = await mapController?.getZoomLevel() ?? 14.0;
              await mapController?.animateCamera(
                CameraUpdate.zoomTo(currentZoom - 1),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || userLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: userLocation!,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              mapController = controller;
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            markers: markers,
            circles: circles,
          ),

          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Find a coach near you",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          buildSearchBar(),
          buildZoomButtons(),
          buildRadiusSelector(),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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
  List<Marker> markers = [];
  bool isLoading = true;

  final Distance dist = const Distance();
  final MapController mapController = MapController();
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    initPage();
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
      await Geolocator.requestPermission();
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

  // ADD ALL COACH MARKERS (Default)
  void addCoachMarkers() {
    markers = [];
    const double maxKm = 5.0;

    for (var coach in coaches) {
      if (coach["latitude"] == null || coach["longitude"] == null) continue;

      double lat = double.parse("${coach["latitude"]}");
      double lng = double.parse("${coach["longitude"]}");

      LatLng coachPos = LatLng(lat, lng);
      double km = dist.as(LengthUnit.Kilometer, userLocation!, coachPos);

      if (km <= maxKm) {
        markers.add(
          Marker(
            point: coachPos,
            width: 140,
            height: 140,
            child: GestureDetector(
              onTap: () => showCoachBottomSheet(coach, km),
              child: Column(
                children: [
                  // IMAGE + NAME ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: coach["profile"] != null
                            ? NetworkImage("$api${coach["profile"]}")
                            : null,
                        backgroundColor: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${coach['first_name']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Icon(
                    Icons.location_on,
                    size: 45,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // USER MARKER
    markers.add(
      Marker(
        point: userLocation!,
        width: 120,
        height: 120,
        child: const Icon(
          Icons.person_pin_circle,
          size: 48,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  // 🎯 SEARCH LOGIC
  void filterSearch(String query) {
    if (query.isEmpty) {
      addCoachMarkers();
      setState(() {});
      return;
    }

    List result = coaches.where((coach) {
      final name = "${coach['first_name']} ${coach['last_name']}".toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    if (result.isEmpty) {
      addCoachMarkers();
      setState(() {});
      return;
    }

    final coach = result.first;

    double lat = double.parse(coach["latitude"].toString());
    double lng = double.parse(coach["longitude"].toString());
    LatLng target = LatLng(lat, lng);

    mapController.move(target, 16);

    markers = [
      Marker(
        point: target,
        width: 160,
        height: 160,
        child: GestureDetector(
          onTap: () => showCoachBottomSheet(coach, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: coach["profile"] != null
                        ? NetworkImage("$api${coach["profile"]}")
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    coach["first_name"],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Icon(Icons.location_on, size: 45, color: Colors.redAccent),
            ],
          ),
        ),
      ),
    ];

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
              // IMAGE + NAME + EYE ICON
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
                  Text(
                    "${coach["first_name"]} ${coach["last_name"]}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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

              // const SizedBox(height: 14),
              Text(
                "${km.toStringAsFixed(2)} km away",
                style: const TextStyle(color: Colors.tealAccent, fontSize: 16),
              ),

              const SizedBox(height: 35),
            ],
          ),
        );
      },
    );
  }

  //  SEARCH BAR UI
  Widget buildSearchBar() {
    return Positioned(
      top: 120, // moved higher
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

  //  ZOOM BUTTONS (bottom right)
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
            child: const Icon(Icons.add),
            onPressed: () => mapController.move(
              userLocation!,
              mapController.camera.zoom + 1,
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "zoom_out",
            mini: true,
            backgroundColor: Colors.teal,
            child: const Icon(Icons.remove),
            onPressed: () => mapController.move(
              userLocation!,
              mapController.camera.zoom - 1,
            ),
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
          // MAP
          FlutterMap(
            mapController: mapController,
            options: MapOptions(initialCenter: userLocation!, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate:
                    "https://tile.jawg.io/jawg-dark/{z}/{x}/{y}.png?access-token=2B7dgDmr4GbsgqSaMLKgFwKHXVuhFAcIAJ7sD1TgNjB9Mmto5m9L4rcDGNKHl4GQ",
                userAgentPackageName: "my_skates",
              ),
              MarkerLayer(markers: markers),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: userLocation!,
                    radius: 5000,
                    useRadiusInMeter: true,
                    color: Colors.teal.withOpacity(0.09),
                    borderColor: Colors.teal,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            ],
          ),

          // HEADING
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
                SizedBox(height: 5),
                Text(
                  "within 5 km",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),

          buildSearchBar(),
          buildZoomButtons(),
        ],
      ),
    );
  }
}

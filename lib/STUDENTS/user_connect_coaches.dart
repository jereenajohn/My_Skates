import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/coach_details_page.dart';
import 'package:my_skates/COACH/coach_homepage.dart';
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserConnectCoaches extends StatefulWidget {
  const UserConnectCoaches({super.key});

  @override
  State<UserConnectCoaches> createState() => _UserConnectCoachesState();
}

class _UserConnectCoachesState extends State<UserConnectCoaches>
    with SingleTickerProviderStateMixin {
  LatLng? userLocation;
  List coaches = [];

  Set<Marker> markers = {};
  Set<Circle> circles = {};

  bool isLoading = true;
  double selectedRadiusKm = 5.0;

  GoogleMapController? mapController;
  final TextEditingController searchCtrl = TextEditingController();

  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    initPage();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    mapController?.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _handleBackNavigation() async {
    final prefs = await SharedPreferences.getInstance();

    final String userType =
        (prefs.getString("usertype") ??
                prefs.getString("user_type") ??
                prefs.getString("role") ??
                "")
            .toLowerCase()
            .trim();

    Widget destination;

    if (userType == "admin") {
      destination = const DashboardPage();
    } else if (userType == "coach") {
      destination = const CoachHomepage();
    } else {
      destination = const HomePage();
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> initPage() async {
    try {
      await getUserCurrentLocation();
      await fetchCoaches();
      addCoachMarkers();
    } catch (e) {
      debugPrint("INIT PAGE ERROR: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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

    debugPrint("USER LOCATION → Lat:${pos.latitude}, Lng:${pos.longitude}");
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
        debugPrint("COACHES FETCHED: ${coaches.length}");
      } else {
        debugPrint("FAILED TO FETCH COACHES → ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("API ERROR → $e");
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
              title: "${coach['first_name']} ${coach['last_name'] ?? ''}"
                  .trim(),
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
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    markers = newMarkers;
    updateRadiusCircle();
  }

  void filterSearch(String query) async {
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

    final double? lat = double.tryParse(coach["latitude"].toString());
    final double? lng = double.tryParse(coach["longitude"].toString());

    if (lat == null || lng == null) return;

    final LatLng target = LatLng(lat, lng);

    await mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16)),
    );

    final double km = userLocation != null
        ? distanceInKm(userLocation!, target)
        : 0.0;

    markers = {
      Marker(
        markerId: MarkerId("search_coach_${coach["id"]}"),
        position: target,
        infoWindow: InfoWindow(
          title: "${coach["first_name"]} ${coach["last_name"] ?? ""}".trim(),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () => showCoachBottomSheet(coach, km),
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
                style: const TextStyle(color: Colors.tealAccent, fontSize: 16),
              ),
              const SizedBox(height: 35),
            ],
          ),
        );
      },
    );
  }

  Widget buildSearchBar() {
    return Positioned(
      top: 120,
      left: 20,
      right: 20,
      child: IgnorePointer(
        ignoring: isLoading,
        child: Opacity(
          opacity: isLoading ? 0.75 : 1,
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
                    decoration: InputDecoration(
                      hintText: isLoading
                          ? "Loading coaches..."
                          : "Search coach",
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRadiusSelector() {
    return Positioned(
      bottom: 145,
      left: 40,
      right: 40,
      child: IgnorePointer(
        ignoring: isLoading,
        child: Opacity(
          opacity: isLoading ? 0.75 : 1,
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
                  isLoading
                      ? "Loading nearby coaches..."
                      : "${selectedRadiusKm.toInt()} km radius",
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
        ),
      ),
    );
  }

  Widget buildZoomButtons() {
    return Positioned(
      bottom: 40,
      right: 20,
      child: IgnorePointer(
        ignoring: isLoading,
        child: Opacity(
          opacity: isLoading ? 0.75 : 1,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: "zoom_in",
                mini: true,
                backgroundColor: Colors.teal,
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () async {
                  final currentZoom =
                      await mapController?.getZoomLevel() ?? 14.0;
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
                child: const Icon(Icons.remove, color: Colors.white),
                onPressed: () async {
                  final currentZoom =
                      await mapController?.getZoomLevel() ?? 14.0;
                  await mapController?.animateCamera(
                    CameraUpdate.zoomTo(currentZoom - 1),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMapSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final double value = _shimmerController.value;

        return Container(
          color: const Color(0xFFF8F9FB),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
              Positioned(
                top: -120,
                left: -80 + (220 * value),
                child: Transform.rotate(
                  angle: 0.25,
                  child: Container(
                    width: 140,
                    height: MediaQuery.of(context).size.height * 1.4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withOpacity(0.00),
                          Colors.white.withOpacity(0.35),
                          Colors.white.withOpacity(0.55),
                          Colors.white.withOpacity(0.35),
                          Colors.white.withOpacity(0.00),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 210,
                left: 80,
                child: _fakeMarker(Colors.redAccent),
              ),
              Positioned(
                top: 300,
                right: 90,
                child: _fakeMarker(Colors.redAccent),
              ),
              Positioned(
                top: 430,
                left: 150,
                child: _fakeMarker(Colors.redAccent),
              ),
              Positioned(
                top: 360,
                left: MediaQuery.of(context).size.width / 2 - 18,
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal.withOpacity(0.08),
                        border: Border.all(
                          color: Colors.teal.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _fakeMarker(Colors.lightBlue),
                  ],
                ),
              ),
              Positioned(
                bottom: 95,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Loading map and nearby coaches...",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fakeMarker(Color color) {
    return Column(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.20),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        Container(width: 3, height: 12, color: color.withOpacity(0.75)),
      ],
    );
  }

  Widget buildRealMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: userLocation!, zoom: 14),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool mapReady = !isLoading && userLocation != null;

    return WillPopScope(
      onWillPop: () async {
        await _handleBackNavigation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(
              child: mapReady ? buildRealMap() : buildMapSkeleton(),
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
                      fontSize: 18,
                      color: Colors.black,
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
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint roadPaint = Paint()
      ..color = const Color(0xFFD9DEE5)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final Paint roadPaint2 = Paint()
      ..color = const Color(0xFFE9EDF2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Path p1 = Path()
      ..moveTo(0, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.12,
        size.width * 0.62,
        size.height * 0.23,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.29,
        size.width,
        size.height * 0.22,
      );

    final Path p2 = Path()
      ..moveTo(0, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.47,
        size.width * 0.48,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.68,
        size.width,
        size.height * 0.60,
      );

    final Path p3 = Path()
      ..moveTo(size.width * 0.22, 0)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.25,
        size.width * 0.18,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.10,
        size.height * 0.76,
        size.width * 0.18,
        size.height,
      );

    final Path p4 = Path()
      ..moveTo(size.width * 0.78, 0)
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.22,
        size.width * 0.73,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.74,
        size.width * 0.72,
        size.height,
      );

    final Path p5 = Path()
      ..moveTo(size.width * 0.08, size.height * 0.34)
      ..lineTo(size.width * 0.92, size.height * 0.82);

    final Path p6 = Path()
      ..moveTo(size.width * 0.12, size.height * 0.85)
      ..lineTo(size.width * 0.88, size.height * 0.35);

    canvas.drawPath(p1, roadPaint);
    canvas.drawPath(p2, roadPaint);
    canvas.drawPath(p3, roadPaint);
    canvas.drawPath(p4, roadPaint);
    canvas.drawPath(p5, roadPaint2);
    canvas.drawPath(p6, roadPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
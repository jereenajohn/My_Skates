import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ActivityReviewScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const ActivityReviewScreen({super.key, required this.activity});

  @override
  State<ActivityReviewScreen> createState() => _ActivityReviewScreenState();
}

class _ActivityReviewScreenState extends State<ActivityReviewScreen> {
  GoogleMapController? _mapController;

  List<LatLng> _routePoints = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _prepareMapData();
  }

  void _prepareMapData() {
    final routePointsRaw = widget.activity["route_points"];

    if (routePointsRaw is List) {
      final List<LatLng> points = [];

      for (final item in routePointsRaw) {
        if (item is Map) {
          final lat = double.tryParse("${item["latitude"] ?? ""}");
          final lng = double.tryParse("${item["longitude"] ?? ""}");

          if (lat != null && lng != null) {
            points.add(LatLng(lat, lng));
          }
        }
      }

      _routePoints = points;

      if (_routePoints.isNotEmpty) {
        _polylines = {
          Polyline(
            polylineId: const PolylineId("activity_route"),
            points: _routePoints,
            width: 5,
            color: const Color(0xFF08B79E),
          ),
        };

        _markers = {
          Marker(
            markerId: const MarkerId("start"),
            position: _routePoints.first,
            infoWindow: const InfoWindow(title: "Start"),
          ),
          Marker(
            markerId: const MarkerId("end"),
            position: _routePoints.last,
            infoWindow: const InfoWindow(title: "Finish"),
          ),
        };
      }
    }
  }

  String _formatDuration(dynamic seconds) {
    final int total = int.tryParse("${seconds ?? 0}") ?? 0;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;

    if (h > 0) {
      return "${h}h ${m}m ${s}s";
    } else if (m > 0) {
      return "${m}m ${s}s";
    } else {
      return "${s}s";
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return "";
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? "PM" : "AM";
      final minute = dt.minute.toString().padLeft(2, '0');
      return "${dt.day}/${dt.month}/${dt.year} at $hour:$minute $ampm";
    } catch (_) {
      return iso;
    }
  }

  Widget _statTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  void _fitRouteBounds() {
    if (_mapController == null || _routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (final point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;

    final title = activity["title"]?.toString() ?? "Activity";
    final startedAt = activity["started_at"]?.toString();
    final distance = activity["distance_km"]?.toString() ?? "0.00";
    final movingSeconds = activity["moving_seconds"];
    final avgSpeed = activity["average_speed_kmh"]?.toString() ?? "0.0";
    final maxSpeed = activity["max_speed_kmh"]?.toString() ?? "0.0";
    final sport = activity["sport"]?.toString() ?? "Ride";
    final description = activity["description"]?.toString() ?? "";

    final LatLng initialTarget = _routePoints.isNotEmpty
        ? _routePoints.first
        : const LatLng(9.9312, 76.2673);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  if (_routePoints.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: initialTarget,
                          zoom: 15,
                        ),
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        compassEnabled: true,
                        polylines: _polylines,
                        markers: _markers,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              _fitRouteBounds();
                            }
                          });
                        },
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF111827),
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          const Center(
                            child: Icon(
                              Icons.map_outlined,
                              color: Colors.white24,
                              size: 90,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sport,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(startedAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.emoji_events_outlined,
                              color: Color.fromARGB(255, 5, 192, 182),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Great job! Your activity has been saved successfully.",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _statTile("Distance", "$distance km"),
                          ),
                          Expanded(
                            child: _statTile("Avg Speed", "$avgSpeed km/h"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _statTile(
                              "Moving Time",
                              _formatDuration(movingSeconds),
                            ),
                          ),
                          Expanded(
                            child: _statTile("Max Speed", "$maxSpeed km/h"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              7,
                              188,
                              158,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "Done",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
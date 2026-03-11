import 'dart:convert';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/STUDENTS/bottomnavigation_student.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserActivities extends StatefulWidget {
  const UserActivities({super.key});

  @override
  State<UserActivities> createState() => _UserActivitiesState();
}

class _UserActivitiesState extends State<UserActivities>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool isRefreshingData = false;
  bool isLoadingMore = false;

  double totalDistanceKm = 0;
  bool hasDistanceBadge = false;

  List<Map<String, dynamic>> activities = [];
  String? errorMessage;

  int currentPage = 1;
  int totalCount = 0;
  String? nextPageUrl;
  String? previousPageUrl;
  bool hasMore = true;

  String userName = "";

  final ScrollController _scrollController = ScrollController();
  final String apiUrl = "$api/api/myskates/user/activities/";

  static const Color bgColor = Color(0xFF07141A);
  static const Color cardColor = Color(0xFF0C1C23);
  static const Color softCardColor = Color(0xFF10252E);
  static const Color accentColor = Color(0xFF1FC8B4);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);

  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scrollController.addListener(_onScroll);
    getActivities(initial: true, refresh: true);
    getActivityStats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  double sw(BuildContext context) => MediaQuery.of(context).size.width;
  double sh(BuildContext context) => MediaQuery.of(context).size.height;

  bool isSmallPhone(BuildContext context) => sw(context) < 360;
  bool isTablet(BuildContext context) => sw(context) >= 700;

  double responsiveHorizontalPadding(BuildContext context) {
    if (isTablet(context)) return 32;
    if (isSmallPhone(context)) return 12;
    return 20;
  }

  double responsiveCardRadius(BuildContext context) {
    if (isTablet(context)) return 32;
    if (isSmallPhone(context)) return 22;
    return 24;
  }

  double responsiveMapHeight(BuildContext context) {
    if (isTablet(context)) return 280;
    if (isSmallPhone(context)) return 180;
    return 200;
  }

  double responsiveAvatarSize(BuildContext context) {
    if (isTablet(context)) return 56;
    if (isSmallPhone(context)) return 42;
    return 48;
  }

  double responsiveTitleFont(BuildContext context) {
    if (isTablet(context)) return 22;
    if (isSmallPhone(context)) return 18;
    return 20;
  }

  double responsiveNameFont(BuildContext context) {
    if (isTablet(context)) return 20;
    if (isSmallPhone(context)) return 16;
    return 18;
  }

  double responsiveBodyFont(BuildContext context) {
    if (isTablet(context)) return 16;
    if (isSmallPhone(context)) return 13;
    return 14;
  }

  double responsiveHeaderFont(BuildContext context) {
    if (isTablet(context)) return 28;
    if (isSmallPhone(context)) return 22;
    return 24;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      loadMoreActivities();
    }
  }

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  Future<void> getActivities({
    bool initial = false,
    bool refresh = false,
    String? url,
  }) async {
    try {
      setState(() {
        if (initial) {
          isLoading = true;
        } else if (refresh) {
          isRefreshingData = true;
        } else {
          isLoadingMore = true;
        }
        errorMessage = null;
      });

      final token = await getTokenFromPrefs();

      final Uri uri;
      if (url != null && url.isNotEmpty) {
        uri = Uri.parse(url);
      } else {
        uri = Uri.parse("$apiUrl?page=1");
      }

      print("REQUEST URL: $uri");

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("STATUS CODE: ${response.statusCode}");
      print("RAW BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        if (parsed["data"] is Map) {
          final stats = parsed["data"];
          totalDistanceKm =
              double.tryParse(stats["total_distance_km"].toString()) ?? 0;
          hasDistanceBadge = totalDistanceKm >= 0.2;
        }

        List rawList = [];

        if (parsed is Map) {
          if (parsed["results"] is Map && parsed["results"]["data"] is List) {
            rawList = parsed["results"]["data"];
          } else if (parsed["data"] is List) {
            rawList = parsed["data"];
          }
        }

        print("RAW LIST LENGTH: ${rawList.length}");

        final List<Map<String, dynamic>> loadedActivities = rawList
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map),
            )
            .toList();

        print("LOADED ACTIVITIES LENGTH: ${loadedActivities.length}");

        final String? next = normalizePaginationUrl(parsed["next"]);
        final String? previous = normalizePaginationUrl(parsed["previous"]);
        final int count = parsed["count"] is int
            ? parsed["count"]
            : int.tryParse("${parsed["count"] ?? 0}") ?? 0;

        int pageNumber = 1;
        final pageParam = uri.queryParameters["page"];
        if (pageParam != null) {
          pageNumber = int.tryParse(pageParam) ?? 1;
        }

        setState(() {
          totalCount = count;
          nextPageUrl = next;
          previousPageUrl = previous;
          hasMore = nextPageUrl != null;
          currentPage = pageNumber;

          if (refresh || initial) {
            activities = loadedActivities;
          } else {
            activities.addAll(loadedActivities);
          }

          isLoading = false;
          isRefreshingData = false;
          isLoadingMore = false;
        });

        print("FINAL ACTIVITIES LENGTH IN STATE: ${activities.length}");
        print("NEXT PAGE URL: $nextPageUrl");
      } else {
        setState(() {
          errorMessage = "Failed to load activities (${response.statusCode})";
          isLoading = false;
          isRefreshingData = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      print("GET ACTIVITIES ERROR: $e");
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
        isRefreshingData = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> getActivityStats() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse("$api/api/myskates/activity/stats/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      final parsed = jsonDecode(response.body);

      if (response.statusCode == 200 && parsed["data"] != null) {
        final stats = parsed["data"];

        setState(() {
          totalDistanceKm =
              double.tryParse(stats["total_distance_km"].toString()) ?? 0;
          hasDistanceBadge = totalDistanceKm >= 0.2;
          userName =
              "${stats["user_first_name"] ?? ""} ${stats["user_last_name"]}"
                  .trim();
        });

        print("TOTAL KM: $totalDistanceKm");
        print("BADGE: $hasDistanceBadge");
      } else {
        print("Failed to fetch stats: ${response.body}");
      }
    } catch (e) {
      print("STATS ERROR: $e");
    }
  }

  String? normalizePaginationUrl(dynamic rawUrl) {
    if (rawUrl == null) return null;

    final String url = rawUrl.toString().trim();
    if (url.isEmpty) return null;

    try {
      final Uri rawUri = Uri.parse(url);
      final Uri baseUri = Uri.parse(apiUrl);

      final Uri fixedUri = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : null,
        path: rawUri.path,
        queryParameters: rawUri.queryParameters.isEmpty
            ? null
            : rawUri.queryParameters,
      );

      return fixedUri.toString();
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshActivities() async {
    nextPageUrl = null;
    previousPageUrl = null;
    currentPage = 1;
    hasMore = true;
    await getActivities(refresh: true, url: "$apiUrl?page=1");
  }

  Future<void> loadMoreActivities() async {
    if (isLoading || isRefreshingData || isLoadingMore || !hasMore) return;
    if (nextPageUrl == null || nextPageUrl!.isEmpty) return;

    await getActivities(url: nextPageUrl);
  }

  String formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return "";
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat("MMMM d, yyyy 'at' h:mm a").format(dt);
    } catch (e) {
      return "";
    }
  }

  String formatDuration(dynamic seconds) {
    final int total = int.tryParse("${seconds ?? 0}") ?? 0;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;

    if (h > 0) {
      return "${h}h ${m}m";
    } else if (m > 0) {
      return "${m}m ${s}s";
    } else {
      return "${s}s";
    }
  }

  String formatDistance(dynamic km) {
    final double value = double.tryParse("${km ?? 0}") ?? 0.0;
    if (value < 0.1) {
      return "${(value * 1000).toStringAsFixed(0)} m";
    }
    return "${value.toStringAsFixed(2)} km";
  }

  String formatSpeed(dynamic kmh) {
    final double value = double.tryParse("${kmh ?? 0}") ?? 0.0;
    return value.toStringAsFixed(1);
  }

  IconData getSportIcon(String? sportKey) {
    switch ((sportKey ?? "").toLowerCase()) {
      case "ride":
        return Icons.directions_bike_rounded;
      case "walk":
        return Icons.directions_walk_rounded;
      case "run":
        return Icons.directions_run_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  String getLocationText(Map<String, dynamic> activity) {
    final lat = activity["start_latitude"];
    final lng = activity["start_longitude"];

    if (lat == null || lng == null) return "Location unavailable";
    return "Lat $lat, Lng $lng";
  }

  List<LatLng> getRoutePoints(List<dynamic>? points) {
    if (points == null || points.isEmpty) return [];

    final List<LatLng> route = [];
    for (final point in points) {
      final lat = double.tryParse("${point["latitude"] ?? ""}");
      final lng = double.tryParse("${point["longitude"] ?? ""}");
      if (lat != null && lng != null) {
        route.add(LatLng(lat, lng));
      }
    }
    return route;
  }

  CameraPosition getInitialCamera(Map<String, dynamic> activity) {
    final route = getRoutePoints(activity["route_points"]);
    if (route.isNotEmpty) {
      return CameraPosition(target: route.first, zoom: 17.5);
    }

    final lat = double.tryParse("${activity["start_latitude"] ?? ""}");
    final lng = double.tryParse("${activity["start_longitude"] ?? ""}");

    if (lat != null && lng != null) {
      return CameraPosition(target: LatLng(lat, lng), zoom: 17.5);
    }

    return const CameraPosition(target: LatLng(9.9645, 76.2691), zoom: 17);
  }

  LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude;
    double x1 = list.first.latitude;
    double y0 = list.first.longitude;
    double y1 = list.first.longitude;

    for (final latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }

    return LatLngBounds(southwest: LatLng(x0, y0), northeast: LatLng(x1, y1));
  }

  Widget buildMapPreview(Map<String, dynamic> activity) {
    final List<LatLng> points = getRoutePoints(activity["route_points"]);
    final mapHeight = responsiveMapHeight(context);

    if (points.isEmpty) {
      return Container(
        height: mapHeight,
        decoration: BoxDecoration(
          color: softCardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 32,
                color: textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                "No route data",
                style: TextStyle(
                  color: textSecondary.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Set<Polyline> polylines = {
      Polyline(
        polylineId: PolylineId("route_${activity["id"]}"),
        points: points,
        color: accentColor,
        width: 5,
      ),
    };

    final Set<Marker> markers = {
      Marker(
        markerId: MarkerId("start_${activity["id"]}"),
        position: points.first,
        infoWindow: const InfoWindow(title: "Start"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: MarkerId("end_${activity["id"]}"),
        position: points.last,
        infoWindow: const InfoWindow(title: "End"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    return SizedBox(
      height: mapHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: getInitialCamera(activity),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              polylines: polylines,
              markers: markers,
              onMapCreated: (GoogleMapController controller) async {
                if (points.length > 1) {
                  await Future.delayed(const Duration(milliseconds: 250));
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(
                      boundsFromLatLngList(points),
                      40,
                    ),
                  );
                }
              },
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.terrain_rounded, size: 14, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      "${points.length} points",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopHeader() {
    final hPad = responsiveHorizontalPadding(context);
    final headerFont = responsiveHeaderFont(context);

    return Container(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile avatar
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accentColor.withOpacity(0.2), accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // User name and badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          userName.isNotEmpty ? userName : "You",
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: headerFont,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (hasDistanceBadge) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.straighten_rounded,
                                size: 14,
                                color: accentColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${totalDistanceKm.toStringAsFixed(2)} km total",
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // if (hasDistanceBadge) ...[
                        //   const SizedBox(width: 8),
                        //   Container(
                        //     padding: const EdgeInsets.all(4),
                        //     decoration: BoxDecoration(
                        //       color: Colors.amber.withOpacity(0.15),
                        //       shape: BoxShape.circle,
                        //     ),
                        //     child: const Icon(
                        //       Icons.emoji_events,
                        //       color: Colors.amber,
                        //       size: 16,
                        //     ),
                        //   ),
                        // ],
                      ],
                    ),
                  ],
                ),
              ),
              // Action icons
              Row(
                children: [
                  _buildActionIcon(Icons.add_rounded),
                  const SizedBox(width: 8),
                  _buildActionIcon(Icons.settings),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Tab indicator
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: accentColor, width: 3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "Activities",
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Activity count
          if (activities.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent activities",
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: softCardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${activities.length} of $totalCount",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
    );
  }

  Widget buildStatTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget buildActivityCard(Map<String, dynamic> activity, int index) {
    final title = "${activity["title"] ?? "Untitled Activity"}";
    final userName = "${activity["user_name"] ?? "Unknown User"}";
    final sport = "${activity["sport"] ?? ""}";
    final date = formatDate(activity["started_at"]);
    final distance = formatDistance(activity["distance_km"]);
    final duration = formatDuration(activity["elapsed_seconds"]);
    final avgSpeed = formatSpeed(activity["average_speed_kmh"]);
    final maxSpeed = formatSpeed(activity["max_speed_kmh"]);
    final description = (activity["description"] ?? "").toString().trim();

    final List appreciations = activity["appreciations"] ?? [];

    String appreciationTitle = "";
    String badgeKey = "";

    if (appreciations.isNotEmpty) {
      appreciationTitle = appreciations[0]["title"] ?? "";
      badgeKey = appreciations[0]["badge_key"] ?? "";
    }

    final radius = responsiveCardRadius(context);
    final avatarSize = responsiveAvatarSize(context);
    final titleFont = responsiveTitleFont(context);
    final bodyFont = responsiveBodyFont(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Padding(
              padding: EdgeInsets.all(isTablet(context) ? 20 : 16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    height: avatarSize,
                    width: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.2),
                          accentColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: avatarSize * 0.45,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: responsiveNameFont(context),
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              getSportIcon(sport),
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                date,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: bodyFont - 1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Sport tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sport.toUpperCase(),
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title and description
            if (title.isNotEmpty ||
                description.isNotEmpty ||
                appreciations.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet(context) ? 20 : 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE + DESCRIPTION
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title.isNotEmpty)
                            Text(
                              title,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: titleFont,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),

                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: bodyFont,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    /// BADGE
                    if (appreciations.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              appreciationTitle,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Stats grid
            Padding(
              padding: EdgeInsets.all(isTablet(context) ? 20 : 16),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  buildStatTile("Distance", distance, Icons.route_rounded),
                  buildStatTile("Duration", duration, Icons.timer_outlined),
                  buildStatTile(
                    "Avg Speed",
                    "$avgSpeed km/h",
                    Icons.speed_rounded,
                  ),
                  buildStatTile(
                    "Max Speed",
                    "$maxSpeed km/h",
                    Icons.bolt_rounded,
                  ),
                ],
              ),
            ),

            // Map preview
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet(context) ? 20 : 16,
                0,
                isTablet(context) ? 20 : 16,
                isTablet(context) ? 20 : 16,
              ),
              child: buildMapPreview(activity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox({
    required double height,
    double width = double.infinity,
    double radius = 12,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final value = _shimmerController.value;
        return Container(
          width: width,
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (2.0 * value), -0.3),
              end: Alignment(1.0 + (2.0 * value), 0.3),
              colors: const [
                Color(0xFF10252E),
                Color(0xFF1A3640),
                Color(0xFF10252E),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildSkeletonCard() {
    final mapHeight = responsiveMapHeight(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(isTablet(context) ? 20 : 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(responsiveCardRadius(context)),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _skeletonBox(
                height: responsiveAvatarSize(context),
                width: responsiveAvatarSize(context),
                radius: responsiveAvatarSize(context) / 2,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(height: 20, width: 150, radius: 8),
                    const SizedBox(height: 10),
                    _skeletonBox(height: 14, width: 200, radius: 8),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _skeletonBox(height: 24, width: 180, radius: 8),
          const SizedBox(height: 16),
          _skeletonBox(height: 40, width: double.infinity, radius: 12),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              4,
              (index) => _skeletonBox(height: 70, radius: 12),
            ),
          ),
          const SizedBox(height: 20),
          _skeletonBox(height: mapHeight, radius: 18),
        ],
      ),
    );
  }

  Widget buildSkeletonList({int count = 3}) {
    final hPad = responsiveHorizontalPadding(context);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
      itemCount: count,
      itemBuilder: (context, index) => buildSkeletonCard(),
    );
  }

  Widget buildBottomPaginationLoader() {
    if (!isLoadingMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: softCardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Loading more...",
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRefreshWrapper({required Widget child}) {
    return CustomMaterialIndicator(
      onRefresh: refreshActivities,
      backgroundColor: Colors.transparent,
      indicatorBuilder: (context, controller) {
        final value = controller.value.clamp(0.0, 1.0);

        if (value < 0.15 &&
            !controller.isLoading &&
            !controller.state.isArmed) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Transform.scale(
                scale: 0.90 + (value * 0.20),
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: controller.isLoading
                          ? (_shimmerController.value * 4)
                          : 0,
                      child: Icon(
                        Icons.refresh_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget buildActivitiesList() {
    final hPad = responsiveHorizontalPadding(context);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
      itemCount: activities.length + 1,
      itemBuilder: (context, index) {
        if (index == activities.length) {
          if (errorMessage != null && !isLoadingMore) {
            return Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 24),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: softCardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: Colors.red.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return buildBottomPaginationLoader();
        }
        return buildActivityCard(activities[index], index);
      },
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return buildRefreshWrapper(child: buildSkeletonList());
    }

    if (activities.isNotEmpty) {
      return buildRefreshWrapper(child: buildActivitiesList());
    }

    if (errorMessage != null) {
      return buildRefreshWrapper(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 60,
                  color: textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: textPrimary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: refreshActivities,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("Try Again"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return buildRefreshWrapper(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_score_rounded,
              size: 60,
              color: textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              "No activities yet",
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start your first activity to see it here",
              style: TextStyle(color: textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0A1A22),
              const Color(0xFF07141A),
              const Color(0xFF041015),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              buildTopHeader(),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }
}

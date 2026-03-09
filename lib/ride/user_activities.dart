import 'dart:convert';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  List<Map<String, dynamic>> activities = [];
  String? errorMessage;

  int currentPage = 1;
  int totalCount = 0;
  String? nextPageUrl;
  String? previousPageUrl;
  bool hasMore = true;

  final ScrollController _scrollController = ScrollController();
  final String apiUrl = "$api/api/myskates/user/activities/";

  static const Color bgColor = Color(0xFF07141A);
  static const Color cardColor = Color(0xFF0C1C23);
  static const Color softCardColor = Color(0xFF10252E);
  static const Color accentColor = Color(0xFF1FC8B4);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB7C9CF);

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
    if (isTablet(context)) return 28;
    if (isSmallPhone(context)) return 12;
    return 16;
  }

  double responsiveCardRadius(BuildContext context) {
    if (isTablet(context)) return 30;
    if (isSmallPhone(context)) return 20;
    return 26;
  }

  double responsiveMapHeight(BuildContext context) {
    if (isTablet(context)) return 260;
    if (isSmallPhone(context)) return 170;
    return 190;
  }

  double responsiveAvatarSize(BuildContext context) {
    if (isTablet(context)) return 68;
    if (isSmallPhone(context)) return 50;
    return 58;
  }

  double responsiveTitleFont(BuildContext context) {
    if (isTablet(context)) return 24;
    if (isSmallPhone(context)) return 18;
    return 20;
  }

  double responsiveNameFont(BuildContext context) {
    if (isTablet(context)) return 24;
    if (isSmallPhone(context)) return 18;
    return 22;
  }

  double responsiveBodyFont(BuildContext context) {
    if (isTablet(context)) return 15;
    if (isSmallPhone(context)) return 13;
    return 14;
  }

  double responsiveHeaderFont(BuildContext context) {
    if (isTablet(context)) return 26;
    if (isSmallPhone(context)) return 20;
    return 22;
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
        queryParameters:
            rawUri.queryParameters.isEmpty ? null : rawUri.queryParameters,
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
      return "${h}h ${m}m ${s}s";
    } else if (m > 0) {
      return "${m}m ${s}s";
    } else {
      return "${s}s";
    }
  }

  String formatDistance(dynamic km) {
    final double value = double.tryParse("${km ?? 0}") ?? 0.0;
    return "${value.toStringAsFixed(2)} km";
  }

  String formatSpeed(dynamic kmh) {
    final double value = double.tryParse("${kmh ?? 0}") ?? 0.0;
    return value.toStringAsFixed(2);
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
        child: const Center(
          child: Text(
            "No route data available",
            style: TextStyle(color: textSecondary, fontSize: 14),
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
      ),
      Marker(
        markerId: MarkerId("end_${activity["id"]}"),
        position: points.last,
        infoWindow: const InfoWindow(title: "End"),
      ),
    };

    return SizedBox(
      height: mapHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: GoogleMap(
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
                CameraUpdate.newLatLngBounds(boundsFromLatLngList(points), 40),
              );
            }
          },
        ),
      ),
    );
  }

  Widget buildTopHeader() {
    final hPad = responsiveHorizontalPadding(context);
    final headerFont = responsiveHeaderFont(context);
    final tabFont = isTablet(context)
        ? 18.0
        : (isSmallPhone(context) ? 14.0 : 16.0);

    return Container(
      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: isTablet(context) ? 46 : 42,
                width: isTablet(context) ? 46 : 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.06),
                  border: Border.all(color: Colors.white.withOpacity(.06)),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "You",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: headerFont,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _headerIcon(Icons.add_rounded),
                  const SizedBox(width: 8),
                  _headerIcon(Icons.settings_outlined),
                ],
              ),
            ],
          ),
          SizedBox(height: isTablet(context) ? 28 : 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      "Progress",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.72),
                        fontSize: tabFont,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(height: 3, color: Colors.transparent),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      "Activities",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: tabFont,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 3,
                      margin: EdgeInsets.symmetric(
                        horizontal: isSmallPhone(context) ? 8 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (activities.isNotEmpty)
            Text(
              "${activities.length} / $totalCount activities",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textSecondary,
                fontSize: isTablet(context) ? 15 : 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon) {
    final size = isTablet(context)
        ? 42.0
        : (isSmallPhone(context) ? 34.0 : 38.0);
    final iconSize = isTablet(context)
        ? 22.0
        : (isSmallPhone(context) ? 18.0 : 20.0);

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(.04),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }

  Widget buildStatTile(String title, String value, IconData icon) {
    final titleFont = isTablet(context)
        ? 13.0
        : (isSmallPhone(context) ? 11.0 : 12.0);
    final valueFont = isTablet(context)
        ? 17.0
        : (isSmallPhone(context) ? 14.0 : 16.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallPhone(context) ? 10 : 12,
        vertical: isSmallPhone(context) ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: softCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: isSmallPhone(context) ? 30 : 34,
            width: isSmallPhone(context) ? 30 : 34,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: isSmallPhone(context) ? 16 : 18,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: titleFont,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: valueFont,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
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

    final radius = responsiveCardRadius(context);
    final avatarSize = responsiveAvatarSize(context);
    final titleFont = responsiveTitleFont(context);
    final nameFont = responsiveNameFont(context);
    final bodyFont = responsiveBodyFont(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.all(isTablet(context) ? 20 : 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withOpacity(.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.22),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: avatarSize,
                  width: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.08),
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet(context)
                            ? 30
                            : (isSmallPhone(context) ? 22 : 28),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallPhone(context) ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: nameFont,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$date • $sport",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: bodyFont,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet(context) ? 24 : 20),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textPrimary,
                fontSize: titleFont,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTablet(context) ? 16 : 14),
                decoration: BoxDecoration(
                  color: softCardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: bodyFont,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: isTablet(context) ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isTablet(context)
                  ? 1.6
                  : (isSmallPhone(context) ? 1.25 : 1.45),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                buildStatTile("Distance", distance, Icons.route_rounded),
                buildStatTile("Avg km/h", avgSpeed, Icons.speed_rounded),
                buildStatTile("Time", duration, Icons.timer_outlined),
                buildStatTile("Max km/h", maxSpeed, Icons.bolt_rounded),
              ],
            ),
            const SizedBox(height: 18),
            buildMapPreview(activity),
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
                    _skeletonBox(height: 20, width: 120, radius: 8),
                    const SizedBox(height: 10),
                    _skeletonBox(height: 14, width: 190, radius: 8),
                    const SizedBox(height: 10),
                    _skeletonBox(height: 14, width: 220, radius: 8),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _skeletonBox(height: 28, width: 180, radius: 8),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: isTablet(context) ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isTablet(context)
                ? 1.6
                : (isSmallPhone(context) ? 1.25 : 1.45),
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              4,
              (index) => _skeletonBox(height: 82, radius: 16),
            ),
          ),
          const SizedBox(height: 18),
          _skeletonBox(height: mapHeight, radius: 18),
        ],
      ),
    );
  }

  Widget buildSkeletonList({int count = 4}) {
    final hPad = responsiveHorizontalPadding(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet(context) ? 820 : double.infinity,
        ),
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
          itemCount: count,
          itemBuilder: (context, index) => buildSkeletonCard(),
        ),
      ),
    );
  }

  Widget buildBottomPaginationLoader() {
    if (!isLoadingMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallPhone(context) ? 12 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: softCardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(.05)),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              ),
              Text(
                "Loading more...",
                style: TextStyle(
                  color: textSecondary,
                  fontSize: isSmallPhone(context) ? 12 : 13,
                  fontWeight: FontWeight.w600,
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
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(.96),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(.35)),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(.16),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: controller.isLoading
                          ? (_shimmerController.value * 4)
                          : 0,
                      child: const Icon(
                        Icons.roller_skating,
                        color: accentColor,
                        size: 20,
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

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet(context) ? 820 : double.infinity,
        ),
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
          itemCount: activities.length + 1,
          itemBuilder: (context, index) {
            if (index == activities.length) {
              if (errorMessage != null && !isLoadingMore) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 24),
                  child: Center(
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }
              return buildBottomPaginationLoader();
            }
            return buildActivityCard(activities[index], index);
          },
        ),
      ),
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
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: sh(context) * .55,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: textPrimary, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return buildRefreshWrapper(
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(
            child: Text(
              "No activities found",
              style: TextStyle(color: textSecondary, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1A22), Color(0xFF07141A), Color(0xFF041015)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              buildTopHeader(),
              Expanded(child: buildBody()),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

const Color accentColor = Color(0xFF00BFA5);

class CoachDetailsPage extends StatefulWidget {
  final int coachId;

  const CoachDetailsPage({super.key, required this.coachId});

  @override
  State<CoachDetailsPage> createState() => _CoachDetailsPageState();
}

class _CoachDetailsPageState extends State<CoachDetailsPage> {
  Map<String, dynamic>? coach;
  bool isLoading = true;
  
  List<Map<String, dynamic>> achievements = [];
  bool achievementsLoading = true;
  
  List<Map<String, dynamic>> feeds = [];
  bool feedsLoading = true;
  
  bool _isPosting = false;
  String? userLocationName;

  @override
  void initState() {
    super.initState();
    fetchCoachDetails();
    fetchAchievements();
    fetchFeed();
  }

  // ==================== FETCH ACHIEVEMENTS ====================
  Future<void> fetchAchievements() async {
    try {
      setState(() {
        achievementsLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        debugPrint("ACCESS TOKEN IS NULL");
        setState(() {
          achievements = [];
          achievementsLoading = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse("$api/api/myskates/achievements/user/${widget.coachId}/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("Achievements response: ${res.body}");

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);

        setState(() {
          achievements = data.cast<Map<String, dynamic>>();
          achievementsLoading = false;
        });
      } else {
        debugPrint("Failed to fetch achievements: ${res.statusCode}");
        setState(() {
          achievements = [];
          achievementsLoading = false;
        });
      }
    } catch (e) {
      debugPrint("FETCH ACHIEVEMENTS ERROR: $e");
      setState(() {
        achievements = [];
        achievementsLoading = false;
      });
    }
  }

  // ==================== FETCH FEED ====================
  Future<void> fetchFeed() async {
    try {
      setState(() {
        feedsLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        debugPrint("ACCESS TOKEN IS NULL");
        setState(() {
          feeds = [];
          feedsLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse("$api/api/myskates/feeds/user/${widget.coachId}/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("Feed response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          feeds = List<Map<String, dynamic>>.from(decoded["data"]);
          feedsLoading = false;
        });
      } else {
        debugPrint("Failed to load feed: ${response.statusCode}");
        setState(() {
          feeds = [];
          feedsLoading = false;
        });
      }
    } catch (e) {
      debugPrint("FETCH FEED ERROR: $e");
      setState(() {
        feeds = [];
        feedsLoading = false;
      });
    }
  }

  // ==================== FETCH COACH DETAILS ====================
  Future<void> fetchCoachDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/user/extras/details/${widget.coachId}/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          coach = jsonDecode(res.body);
        });

        if (coach?["latitude"] != null && coach?["longitude"] != null) {
          getPlaceFromLatLong(coach!["latitude"], coach!["longitude"]);
        }

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching Coach: $e");
      setState(() => isLoading = false);
    }
  }

  // ==================== UTILITIES ====================
  String fullImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return "https://cdn-icons-png.flaticon.com/512/149/149071.png";
    }
    if (path.startsWith("http")) {
      return path;
    }
    String cleanBase = api.endsWith("/") ? api.substring(0, api.length - 1) : api;
    String cleanPath = path.startsWith("/") ? path.substring(1) : path;
    return "$cleanBase/$cleanPath";
  }

  Future<void> getPlaceFromLatLong(String lat, String long) async {
    try {
      double latitude = double.parse(lat);
      double longitude = double.parse(long);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      Placemark place = placemarks.first;
      setState(() {
        userLocationName = "${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}";
      });
    } catch (e) {
      setState(() {
        userLocationName = "Unknown";
      });
    }
  }

  Future<void> openInstagram(String username) async {
    final url = "https://www.instagram.com/$username/";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Unable to open Instagram");
    }
  }

  Future<void> openWhatsApp(String phone) async {
    final url = "https://wa.me/$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Unable to launch WhatsApp");
    }
  }

  void _showConnectPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(25),
            width: 260,
            height: 180,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 33, 30, 30),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    final insta = coach?["instagram"];
                    if (insta != null && insta.isNotEmpty) {
                      openInstagram(insta);
                    }
                  },
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Image.network(
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Instagram_logo_2022.svg/512px-Instagram_logo_2022.svg.png",
                        height: 45,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    final phone = coach?["phone"];
                    if (phone != null && phone.isNotEmpty) {
                      openWhatsApp(phone);
                    }
                  },
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: SvgPicture.network(
                        "https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg",
                        height: 45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color getUserTypeColor(String type) {
    switch (type.toLowerCase()) {
      case "coach":
        return const Color(0xFFFFB800);
      case "student":
        return const Color(0xFF00B8FF);
      case "admin":
        return const Color(0xFFFF0080);
      default:
        return Colors.white70;
    }
  }

  // ==================== BUILD UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildUI(),
    );
  }

  Widget _buildUI() {
    return Stack(
      children: [
        Container(
          height: 260,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00342E), Color(0xFF000000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.topLeft,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.grey.shade900,
                  backgroundImage: NetworkImage(
                    fullImageUrl(coach?["profile"]),
                    headers: {"ngrok-skip-browser-warning": "1"},
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "${coach?["first_name"] ?? ""} ${coach?["last_name"] ?? ""}",
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  userLocationName ?? "Loading...",
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 3),
                const Text(
                  "COACH",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            debugPrint("Follow pressed");
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                          ),
                          child: const Text(
                            "Follow",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _showConnectPopup(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const Text(
                            "Connect",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                  ],
                ),
                const SizedBox(height: 35),

                // ==================== DETAILS SECTION ====================
                _buildDetailsSection(),
                const SizedBox(height: 25),

                // ==================== ACHIEVEMENTS SECTION ====================
                _buildAchievementsSection(),
                const SizedBox(height: 25),

                // ==================== FEED SECTION ====================
                _buildFeedSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== DETAILS SECTION WIDGET ====================
  Widget _buildDetailsSection() {
    if (coach == null) return const SizedBox.shrink();

    final String userType = (coach?["user_type"] ?? "coach").toString();
    final Color typeColor = getUserTypeColor(userType);
    final String firstName = coach?["first_name"] ?? "N/A";
    final String lastName = coach?["last_name"] ?? "";
    final String email = coach?["email"] ?? "";
    final String phone = coach?["phone"] ?? "";
    final String instagram = coach?["instagram"] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Coach Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF00312D), Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF00BFA5).withOpacity(0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: typeColor, width: 2),
                    color: Colors.white.withOpacity(0.08),
                    image: coach?["profile"] != null &&
                            coach!["profile"].toString().isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(
                              fullImageUrl(coach!["profile"]),
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: coach?["profile"] == null ||
                          coach!["profile"].toString().isEmpty
                      ? Icon(Icons.person, color: typeColor, size: 28)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "$firstName $lastName",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: typeColor.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              userType.toUpperCase(),
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (phone.isNotEmpty) _InfoRow(icon: Icons.phone, text: phone),
                      if (email.isNotEmpty) _InfoRow(icon: Icons.email, text: email),
                      if (instagram.isNotEmpty)
                        _InfoRow(icon: Icons.camera_alt, text: "@$instagram"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== ACHIEVEMENTS SECTION ====================
  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Achievements",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        achievementsLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : achievements.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00312D), Colors.black],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: accentColor.withOpacity(0.35)),
                    ),
                    child: const Center(
                      child: Text(
                        "No achievements yet",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00312D), Colors.black],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: accentColor.withOpacity(0.35)),
                    ),
                    child: Column(
                      children: List.generate(achievements.length, (index) {
                        final a = achievements[index];
                        return Column(
                          children: [
                            _AchievementListTile(achievement: a),
                            if (index != achievements.length - 1)
                              Divider(
                                color: Colors.white.withOpacity(0.08),
                                height: 1,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
      ],
    );
  }

  // ==================== FEED SECTION ====================
  Widget _buildFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Posts",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (feedsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
        else if (feeds.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF00312D), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: accentColor.withOpacity(0.35)),
            ),
            child: const Center(
              child: Text(
                "No posts yet",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: feeds.length,
            itemBuilder: (context, index) {
              return _feedCard(feeds[index]);
            },
          ),
      ],
    );
  }

  Widget _feedCard(Map<String, dynamic> feed) {
    final images = feed["feed_image"] ?? [];
    final likesCount = feed["likes_count"] ?? 0;
    final commentsCount = feed["comments_count"] ?? 0;
    final sharesCount = feed["shares_count"] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF00312D), Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF00BFA5).withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feed["user_name"] ?? "",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feed["description"] ?? "",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (_, i) {
                  final imageUrl = images[i]["image"] ?? "";
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      fullImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade800,
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.white54, size: 40),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _count(Icons.favorite_border, likesCount),
              SizedBox(width: 10),
              _count(Icons.comment_outlined, commentsCount),
              SizedBox(width: 10),
              _count(Icons.repeat, sharesCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _count(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

// ==================== ACHIEVEMENT LIST TILE WIDGET ====================
class _AchievementListTile extends StatelessWidget {
  final Map<String, dynamic> achievement;

  const _AchievementListTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final image = achievement["image"];
    final title = achievement["title"] ?? "";
    final org = achievement["organization"] ?? "";
    final duration = achievement["date"] ?? "";
    final location = achievement["location"] ?? "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(0.08),
              image: image != null
                  ? DecorationImage(
                      image: NetworkImage("$api$image"),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: image == null
                ? const Icon(Icons.emoji_events, color: accentColor, size: 22)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (org.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      org,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 13,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (location.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 13,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== INFO ROW WIDGET ====================
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.white54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
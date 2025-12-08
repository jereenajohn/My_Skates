import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class CoachDetailsPage extends StatefulWidget {
  final int coachId;

  const CoachDetailsPage({super.key, required this.coachId});

  @override
  State<CoachDetailsPage> createState() => _CoachDetailsPageState();
}

class _CoachDetailsPageState extends State<CoachDetailsPage> {
  Map<String, dynamic>? coach;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCoachDetails();
  }

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
      print("Error fetching Coach: $e");
    }
  }

  String fullImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return "https://cdn-icons-png.flaticon.com/512/149/149071.png";
    }

    if (path.startsWith("http")) {
      return path;
    }

    String cleanBase = api.endsWith("/")
        ? api.substring(0, api.length - 1)
        : api;
    String cleanPath = path.startsWith("/") ? path.substring(1) : path;

    return "$cleanBase/$cleanPath";
  }

  String? userLocationName;

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
        userLocationName =
            "${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}";
      });
    } catch (e) {
      userLocationName = "Unknown";
    }
  }

  // -----------------------------
  // LAUNCH INSTAGRAM
  // -----------------------------
  Future<void> openInstagram(String username) async {
    final url = "https://www.instagram.com/$username/";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print("Unable to open Instagram");
    }
  }

  // -----------------------------
  // LAUNCH WHATSAPP
  // -----------------------------
  Future<void> openWhatsApp(String phone) async {
    final url = "https://wa.me/$phone";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print("Unable to launch WhatsApp");
    }
  }

  // -----------------------------
  // CONNECT POPUP
  // -----------------------------
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
                // INSTAGRAM
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

                // WHATSAPP
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

  // --------------------------------------------------------------------------
  // UI STARTS HERE
  // --------------------------------------------------------------------------
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

                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: [
                //     Column(
                //       children: [
                //         Text(
                //           (coach?["following"] ?? 0).toString(),
                //           style: const TextStyle(
                //             color: Colors.white,
                //             fontSize: 15,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //         const Text("Following",
                //             style: TextStyle(color: Colors.grey, fontSize: 15)),
                //       ],
                //     ),
                //     Column(
                //       children: [
                //         Text(
                //           (coach?["followers"] ?? 0).toString(),
                //           style: const TextStyle(
                //             color: Colors.white,
                //             fontSize: 15,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //         const Text("Followers",
                //             style: TextStyle(color: Colors.grey, fontSize: 15)),
                //       ],
                //     ),
                //   ],
                // ),

                // const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // CONNECT BUTTON

                    // FOLLOW BUTTON
                    // FOLLOW BUTTON (TRANSPARENT)
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            print("Follow pressed");
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

                const SizedBox(height: 25),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Personal Info",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _personalInfoCard(),

                const SizedBox(height: 25),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Achievements",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                achievementCard(
                  title: "Langham Skating Club",
                  date: "November 18, 2025",
                  location: "Panamballi Nagar, Kochi",
                  subTitle: "Morning training session",
                  time: "1h 12m",
                  distance: "Panamballi Nagar - Kaicor",
                  iconUrl: fullImageUrl(
                    "/media/profile_images/1000004721_K1a26PJ.jpg",
                  ),
                ),

                const SizedBox(height: 20),

                achievementCard(
                  title: "RBT Skating Event",
                  date: "December 01, 2025",
                  location: "Kakkanad, Kochi",
                  time: "4h 54m",
                  distance: "89.05 km",
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _personalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _row("Experience", "${coach?["experience"] ?? "0"} yr"),
          _row("Club/Organisation", coach?["club"] ?? "Not Available"),
          _row("Events", coach?["club"] ?? "Unknown"),
          _row("Area", userLocationName ?? "Unknown"),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget achievementCard({
    required String title,
    required String date,
    required String location,
    String? subTitle,
    String? time,
    String? distance,
    String? iconUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  iconUrl ??
                      "https://cdn-icons-png.flaticon.com/512/2997/2997563.png",
                  height: 45,
                  width: 45,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.yellow,
                          size: 22,
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Text(
                      location,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (subTitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (time != null || distance != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (time != null)
                  Text(
                    time,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                if (distance != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    distance,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

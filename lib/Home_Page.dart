import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/coach_details_page.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/profile_page.dart';
import 'package:my_skates/user_connect_coaches.dart';
import 'package:my_skates/user_settings.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String studentName = "";
  String studentRole = "";
  String? studentImage;
  bool isLoading = true;

  List clubs = [];
  bool noData = false;

  List coaches = [];
  bool coachesLoading = true;
  bool coachesNoData = false;

  // EVENTS
  List events = [];
  bool eventsLoading = true;
  bool eventsNoData = false;
  bool isFollowing = false;

  @override
  initState() {
    super.initState();
    fetchStudentDetails();
    fetchClubs();
    fetchCoaches();
    fetchEvents();
    refreshUserProfile().then((_) => fetchStudentDetails());
    getbanner();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access');
  }

  Future<void> refreshUserProfile() async {
    String? token = await getToken();
    final res = await http.get(
      Uri.parse("$api/api/myskates/profile/"),
      headers: {"Authorization": "Bearer $token"},
    );

    print("PROFILE STATUS: ${res.statusCode}");
    print("PROFILE BODY: ${res.body}");
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      final prefs = await SharedPreferences.getInstance();
      prefs.setString("name", data["name"] ?? "");
      prefs.setString("user_type", data["user_type"] ?? "");
      prefs.setString("profile", data["profile"] ?? "");
    }
  }

  List<Map<String, dynamic>> banner = [];

  Future<void> getbanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var response = await http.get(
        Uri.parse('$api/api/myskates/banner/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> statelist = [];
      print("response.bodyyyyyyyyyyyyyyyyy:${response.body}");
      print(response.statusCode);
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed;

        for (var productData in productsData) {
          String imageUrl = "$api${productData['image']}";
          statelist.add({
            'id': productData['id'],
            'title': productData['title'],
            'image': imageUrl,
          });
        }
        setState(() {
          banner = statelist;
          print("statelistttttttttttttttttttt:$banner");
        });
      }
    } catch (error) {}
  }

  // FETCH COACHES
  Future<void> fetchCoaches() async {
    String? token = await getToken();

    try {
      final response = await http.get(
        Uri.parse("$api/api/myskates/coaches/approved/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("COACHES STATUS: ${response.statusCode}");
      print("COACHES BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() {
            coaches = decoded;
            coachesNoData = decoded.isEmpty;
            coachesLoading = false;
          });
        }
      } else {
        setState(() {
          coachesNoData = true;
          coachesLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        coachesNoData = true;
        coachesLoading = false;
      });
    }
  }

  // FETCH USER
  Future<void> fetchStudentDetails() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      studentName = prefs.getString("name") ?? "User";
      studentRole = prefs.getString("user_type") ?? "Student";
      studentImage = prefs.getString("profile");
      isLoading = false;
    });
  }

  // FETCH CLUBS
  Future<void> fetchClubs() async {
    String? token = await getToken();

    try {
      final response = await http.get(
        Uri.parse("$api/api/myskates/club/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() {
            clubs = decoded;
            noData = decoded.isEmpty;
          });
        }
      } else {
        setState(() {
          noData = true;
        });
      }
    } catch (e) {
      setState(() {
        noData = true;
      });
    }
  }

  // TIME LEFT
  String getTimeLeft(String fromDate, String fromTime) {
    try {
      final dateTime = DateTime.parse("$fromDate $fromTime");
      final diff = dateTime.difference(DateTime.now());
      if (diff.inDays > 0) return "In ${diff.inDays} days";
      if (diff.inHours > 0) return "In ${diff.inHours} hrs";
      if (diff.inMinutes > 0) return "In ${diff.inMinutes} mins";
      return "Started";
    } catch (e) {
      return "";
    }
  }

  // FETCH EVENTS
  Future<void> fetchEvents() async {
    String? token = await getToken();

    try {
      final response = await http.get(
        Uri.parse("$api/api/myskates/events/add/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("EVENT STATUS: ${response.statusCode}");
      print("EVENT BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          setState(() {
            events = decoded;
            eventsLoading = false;
            eventsNoData = decoded.isEmpty;
          });
        }
      } else {
        setState(() {
          eventsLoading = false;
          eventsNoData = true;
        });
      }
    } catch (e) {
      setState(() {
        eventsLoading = false;
        eventsNoData = true;
      });
    }
  }

  // UI BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.black,
              expandedHeight: 80,
              automaticallyImplyLeading: false,
              flexibleSpace: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserSettings(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            studentImage != null && studentImage!.isNotEmpty
                            ? NetworkImage("$api$studentImage")
                            : const AssetImage("lib/assets/img.jpg")
                                  as ImageProvider,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          studentRole,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),

                    const Spacer(),

                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_active,
                        color: Colors.tealAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // CONTENT
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: FlutterCarousel(
                          options: CarouselOptions(
                            height: 160,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 3),
                            viewportFraction: 1,
                            showIndicator: true,
                            slideIndicator: CircularSlideIndicator(),
                          ),
                          items: banner.map((item) {
                            return Stack(
                              children: [
                                // Background Image
                                Positioned.fill(
                                  child: Image.network(
                                    item["image"] ?? "",
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: Colors.grey.shade900,
                                        alignment: Alignment.center,
                                        child:
                                            const CircularProgressIndicator(),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.black,
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Colors.white54,
                                                size: 40,
                                              ),
                                            ),
                                  ),
                                ),

                                // Gradient Overlay (bottom fade)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.6),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Banner Title (Optional)
                                // Positioned(
                                //   bottom: 12,
                                //   left: 12,
                                //   right: 12,
                                //   child: Text(
                                //     item["title"] ?? "",
                                //     style: const TextStyle(
                                //       color: Colors.white,
                                //       fontSize: 18,
                                //       fontWeight: FontWeight.bold,
                                //       shadows: [
                                //         Shadow(
                                //           offset: Offset(0, 1),
                                //           blurRadius: 4,
                                //           color: Colors.black54,
                                //         )
                                //       ],
                                //     ),
                                //     maxLines: 1,
                                //     overflow: TextOverflow.ellipsis,
                                //   ),
                                // ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    const Text(
                      "We offer training and an e-commerce platform\nthat connects students and coaches.",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),

                    const SizedBox(height: 25),

                    buildButton(
                      "Connect Coaches",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserConnectCoaches(),
                        ),
                      ),
                    ),

                    buildButton(
                      "Connect Students",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserConnectCoaches(),
                        ),
                      ),
                    ),

                    buildButton(
                      "Find Clubs",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserConnectCoaches(),
                        ),
                      ),
                    ),

                    buildButton(
                      "Find Events",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserConnectCoaches(),
                        ),
                      ),
                    ),

                    buildButton(
                      "Buy and Sell products",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserConnectCoaches(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Recommended Clubs near you",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      height: MediaQuery.of(context).size.height * 0.28,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: clubs.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: buildClubCardFromApi(clubs[i]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // EVENTS
                    // EVENTS
                    const Text(
                      "Upcoming Events",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    eventsLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : eventsNoData
                        ? const Text(
                            "No events found",
                            style: TextStyle(color: Colors.white70),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: events.length,
                            itemBuilder: (_, i) {
                              final e = events[i];

                              List<dynamic> gallery = e["images"] ?? [];

                              String mainImage = e["image"] ?? "";

                              String clubName = e["club_name"] ?? "Club";

                              String fromDate = e["from_date"] ?? "";
                              String toDate = e["to_date"] ?? "";
                              String fromTime = e["from_time"] ?? "";
                              String description = e["description"] ?? "";
                              String title = e["title"] ?? "";

                              String dateLabel = "$fromDate → $toDate";

                              String timeLeft = getTimeLeft(fromDate, fromTime);

                              // BUILD IMAGE LIST
                              List<String> imageList = [];

                              if (mainImage != null && mainImage.isNotEmpty) {
                                imageList.add("$api$mainImage");
                              }

                              for (var g in gallery) {
                                if (g != null &&
                                    g["image"] != null &&
                                    g["image"].toString().isNotEmpty) {
                                  imageList.add("$api${g["image"]}");
                                }
                              }

                              if (imageList.isEmpty) {
                                return buildEventCard(
                                  clubName: clubName,
                                  date: dateLabel,
                                  location: "",
                                  title: title,
                                  timeLeft: timeLeft,
                                  icon: Icons.favorite_border,
                                );
                              }

                              return buildEventCardWithDynamicImages(
                                clubName: clubName,
                                date: dateLabel,
                                location: "",
                                title: title,
                                images: imageList,
                                description: description,
                                context: context,
                              );
                            },
                          ),
                    const SizedBox(height: 25),

                    const Text(
                      "Suggested Coaches",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),

                    SizedBox(
                      height: 210,
                      child: coachesLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : coachesNoData
                          ? const Center(
                              child: Text(
                                "No coaches found",
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: coaches.length,
                              itemBuilder: (_, i) =>
                                  CoachFollowCard(coach: coaches[i]),
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

  // BUTTON
  Widget buildButton(String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00AFA5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}

// CLUB CARD
Widget buildClubCardFromApi(Map club) {
  String title = club["club_name"] ?? "Club";
  String? img = club["image"];
  String imageUrl = (img != null && img.isNotEmpty) ? "$api$img" : "";

  return Container(
    width: 160,
    height: 100, // Perfect balanced height
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 30,
          backgroundImage: imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : const AssetImage("lib/assets/images.png"),
        ),

        const SizedBox(height: 10),

        // Club Name
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),

        const Spacer(), // push Follow button slightly down
        // Follow Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Follow",
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

// EVENT CARD 1
Widget buildEventCard({
  required String clubName,
  required String date,
  required String location,
  required String title,
  required String timeLeft,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage("lib/assets/images.png"),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clubName,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  location,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),

        Text(
          timeLeft,
          style: const TextStyle(color: Colors.tealAccent, fontSize: 13),
        ),
        const SizedBox(height: 6),

        Text(
          location,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Icon(Icons.thumb_up_alt_outlined, color: Colors.white70, size: 22),
            SizedBox(width: 14),
          ],
        ),
      ],
    ),
  );
}

// POPUP FUNCTION
void showImagePopup(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.black87,
      insetPadding: const EdgeInsets.all(12),

      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    ),
  );
}

// EVENT CARD WITH DYNAMIC IMAGES + POPUP
Widget buildEventCardWithDynamicImages({
  required String clubName,
  required String date,
  required String location,
  required String title,
  required List<String> images,
  required String description,
  required BuildContext context,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage("lib/assets/imagess.png"),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clubName,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  location,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 110,
          child: Row(
            children: List.generate(images.length, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == images.length - 1 ? 0 : 8,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      showImagePopup(context, images[index]);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        height: 110,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info, color: Colors.amberAccent, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Icon(Icons.thumb_up_alt_outlined, color: Colors.white70, size: 22),
            SizedBox(width: 14),
          ],
        ),
      ],
    ),
  );
}

class CoachFollowCard extends StatefulWidget {
  final Map coach;
  const CoachFollowCard({super.key, required this.coach});

  @override
  State<CoachFollowCard> createState() => _CoachFollowCardState();
}

class _CoachFollowCardState extends State<CoachFollowCard> {
  late bool isFollowing;

  @override
  void initState() {
    super.initState();
    // Load initial state only once
    isFollowing = widget.coach["is_following"] == true;
  }

  Future<void> followCoach(int coachId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final url = Uri.parse('$api/api/myskates/follow/user/$coachId/');

    final response = await http.post(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    print("FOLLOW: ${response.statusCode} ${response.body}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      setState(() {
        isFollowing = true;
      });
    }
  }

  Future<void> unfollowCoach(int coachId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final url = Uri.parse('$api/api/myskates/follow/user/$coachId/');

    final response = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      setState(() {
        isFollowing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final coach = widget.coach;

    String name = "${coach['first_name']} ${coach['last_name']}";
    String exp = coach["experience"] != null
        ? "Exp: ${coach["experience"]} yrs"
        : "Experience N/A";
    String city = coach["district_name"] ?? "";
    int coachId = coach["id"];

    String? img = coach["profile"];
    String imageUrl = img != null && img.isNotEmpty ? "$api$img" : "";

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : const AssetImage("lib/assets/img.jpg"),
          ),

          const SizedBox(height: 10),

          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),

          const SizedBox(height: 4),

          Text(
            exp,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          Text(
            city,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (isFollowing) {
                  unfollowCoach(coachId);
                } else {
                  followCoach(coachId);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? Colors.grey
                    : const Color(0xFF00AFA5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isFollowing ? "Following" : "Follow",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

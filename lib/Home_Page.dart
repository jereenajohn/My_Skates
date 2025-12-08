import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';
import 'package:my_skates/profile_page.dart';
import 'package:my_skates/user_connect_coaches.dart';
import 'package:my_skates/user_settings.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  initState() {
    super.initState();
    fetchStudentDetails();
    fetchClubs();  
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access');
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idValue = prefs.get('id');
    if (idValue is int) return idValue;
    if (idValue is String) return int.tryParse(idValue);
    return null;
  }
Future<void> fetchStudentDetails() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      studentName = prefs.getString("name") ?? "User";
      studentRole = prefs.getString("user_type") ?? "Student";
      studentImage = prefs.getString("profile"); 
      isLoading = false;
    });

  } catch (e) {
    print("Error loading user from prefs: $e");
  }
}

Future<void> fetchClubs() async {
  String? token = await getToken();

  try {
    final response = await http.get(
      Uri.parse("$api/api/myskates/club/"),
      headers: {"Authorization": "Bearer $token"},
    );

    print("Clubs status: ${response.statusCode}");
    print("Clubs body: ${response.body}");

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
    print("Error fetching clubs: $e");
    setState(() {
      noData = true;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ---------------------------------------------------------
            // PINNED HEADER (STAYS FIXED WHILE SCROLLING)
            // ---------------------------------------------------------
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
                            fontSize: 20,
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

            // ---------------------------------------------------------
            // ALL YOUR PAGE CONTENT AS IT IS
            // ---------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Image.asset(
                        "lib/assets/banner1.png",
                        height: 88,
                        fit: BoxFit.cover,
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserConnectCoaches(),
                          ),
                        );
                      },
                    ),
                    buildButton("Connect Students", onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserConnectCoaches(),
                          ),
                        );
                      },),
                    buildButton("Find Clubs", onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserConnectCoaches(),
                          ),
                        );
                      },),
                    buildButton("Find Events", onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserConnectCoaches(),
                          ),
                        );
                      },),
                    buildButton("Buy and Sell products", onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserConnectCoaches(),
                          ),
                        );
                      },),

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
SizedBox(
  height: 160,
  child: isLoading
      ? const Center(child: CircularProgressIndicator(color: Colors.white))
      : noData
          ? const Center(
              child: Text("No clubs found", style: TextStyle(color: Colors.white70)),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: clubs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: buildClubCardFromApi(clubs[index]),
                );
              },
            ),
)

,

                    const SizedBox(height: 25),

                    const Text(
                      "Inspired to push your limits every day.",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),

                    const SizedBox(height: 15),

                    buildEventCard(
                      clubName: "Langham Skating Club",
                      date: "November 13, 2025",
                      location: "Ponnurunni nagar - Kaloor",
                      title: "Morning training session",
                      timeLeft: "In 12m",
                      icon: Icons.thumb_up_alt,
                    ),

                    const SizedBox(height: 12),

                    buildEventCardWithImages(
                      clubName: "Strathmore Skating Club",
                      date: "November 18, 2025",
                      location: "Kaloor, Kochi",
                      title: "MG Road Speed Hunters Event",
                      image1: "lib/assets/skate.jpg",
                      image2: "lib/assets/skating.png",
                      description:
                          "Strathmore skating club conducting skating event on 30th Nov. Join with us!",
                      icon: Icons.favorite_border,
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
                      height: 230,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Row(
                          children: [
                            buildCoachCard(
                              name: "Alex Peter",
                              subtitle: "Spark roller skating",
                              city: "Kaloor",
                              image: "lib/assets/img.jpg",
                            ),
                            buildCoachCard(
                              name: "Sundar",
                              subtitle: "Eva skating academy",
                              city: "Kakkanad",
                              image: "lib/assets/img22.jpg",
                            ),
                            buildCoachCard(
                              name: "Sundar",
                              subtitle: "Eva skating academy",
                              city: "Kakkanad",
                              image: "lib/assets/img22.jpg",
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    buildEventCard(
                      clubName: "Langham Skating Club",
                      date: "November 13, 2025",
                      location: "Ponnurunni nagar - Kaloor",
                      title: "Morning training session",
                      timeLeft: "In 12m",
                      icon: Icons.thumb_up_alt,
                    ),

                    const SizedBox(height: 12),

                    buildEventCardWithImages(
                      clubName: "Strathmore Skating Club",
                      date: "November 18, 2025",
                      location: "Kaloor, Kochi",
                      title: "MG Road Speed Hunters Event",
                      image1: "lib/assets/skating1.jpg",
                      image2: "lib/assets/skating2.jpg",
                      description:
                          "Strathmore skating club conducting skating event on 30th Nov. Join with us!",
                      icon: Icons.favorite_border,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.black,
            selectedItemColor: const Color(0xFF00AFA5),
            unselectedItemColor: Colors.white70,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            currentIndex: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ''),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: '',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.event), label: ''),
            ],
          ),
        ),
      ),
    );
  }

  // BUTTON WIDGET
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

// --------------------------- CLUB CARD ----------------------------
Widget buildClubCardFromApi(Map club) {
  String title = club["club_name"] ?? "Club";
  String? img = club["image"];

  String imageUrl = (img != null && img.isNotEmpty)
      ? "$api$img"
      : "";

  return Container(
    width: 160,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        
        // -------------------------
        // CIRCLE LOGO
        // -------------------------
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white24,
          backgroundImage: img != null && img.isNotEmpty
              ? NetworkImage(imageUrl)
              : const AssetImage("lib/assets/images.png") as ImageProvider,
        ),

        const SizedBox(height: 10),

        // -------------------------
        // CLUB NAME
        // -------------------------
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),

        const SizedBox(height: 10),

        // -------------------------
        // FOLLOW BUTTON
        // -------------------------
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Follow",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}



// --------------------------- EVENT CARD 1 ---------------------------
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

// --------------------------- EVENT CARD 2 ---------------------------
Widget buildEventCardWithImages({
  required String clubName,
  required String date,
  required String location,
  required String title,
  required String image1,
  required String image2,
  required String description,
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

        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(image1, height: 110, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(image2, height: 110, fit: BoxFit.cover),
              ),
            ),
          ],
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

// --------------------------- COACH CARD ---------------------------
Widget buildCoachCard({
  required String name,
  required String subtitle,
  required String city,
  required String image,
}) {
  return Container(
    width: 165,
    margin: const EdgeInsets.only(right: 6),
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: 185,
          padding: const EdgeInsets.only(
            top: 60,
            left: 12,
            right: 12,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),

              Text(
                city,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AFA5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Connect",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: -18,
          child: CircleAvatar(radius: 36, backgroundImage: AssetImage(image)),
        ),
      ],
    ),
  );
}

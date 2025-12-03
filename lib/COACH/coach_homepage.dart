import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/coach_settings.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/profile_page.dart';
import 'package:my_skates/user_settings.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CoachHomepage extends StatefulWidget {
  const CoachHomepage({super.key});

  @override
  State<CoachHomepage> createState() => _CoachHomepageState();
}

class _CoachHomepageState extends State<CoachHomepage> {
  String studentName = "";
  String studentRole = "";
  String? studentImage;
  bool isLoading = true;

  @override
  initState() {
    super.initState();
    fetchStudentDetails();
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
      String? token = await getToken();
      int? userId = await getUserId();

      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse("$api/api/myskates/profile/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          studentName = data["first_name"] ?? "User";
          studentRole = data["user_type"] ?? "Student";
          studentImage = data["profile"];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching student: $e");
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
                          MaterialPageRoute(builder: (_) => const CoachSettings()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: studentImage != null && studentImage!.isNotEmpty
                            ? NetworkImage("$api$studentImage")
                            : const AssetImage("lib/assets/img.jpg") as ImageProvider,
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

                    buildButton("Connect Coaches"),
                    buildButton("Connect Students"),
                    buildButton("Find Clubs"),
                    buildButton("Find Events"),
                    buildButton("Buy and Sell products"),

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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            buildClubCard("Spark roller skating", "lib/assets/images.png"),
                            const SizedBox(width: 12),
                            buildClubCard("Kimberley skating", "lib/assets/imagess.png"),
                            const SizedBox(width: 12),
                            buildClubCard("City Skate Club", "lib/assets/images.png"),
                          ],
                        ),
                      ),
                    ),

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
              BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.event), label: ''),
            ],
          ),
        ),
      ),
    );
  }

  // BUTTON WIDGET
  Widget buildButton(String title) {
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
        onPressed: () {},
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}

// --------------------------- CLUB CARD ----------------------------
Widget buildClubCard(String title, String image) {
  return Container(
    width: 160,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Image.asset(image, height: 60),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text("Follow", style: TextStyle(color: Colors.white)),
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

        Text(location, style: const TextStyle(color: Colors.white54, fontSize: 12)),

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
                Text(clubName,
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
                Text(date,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(location,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
          padding: const EdgeInsets.only(top: 60, left: 12, right: 12, bottom: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
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

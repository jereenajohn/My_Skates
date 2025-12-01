import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';
import 'package:my_skates/profile_page.dart';
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

  @override
  initState() {
    super.initState();
    fetchStudentDetails();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idValue = prefs.get('id');
    if (idValue is int) return idValue;
    if (idValue is String) return int.tryParse(idValue);
    return null;
  }

  // Future<int?> getid() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   return prefs.getInt('id');
  // }

  Future<void> fetchStudentDetails() async {
    try {
      String? token = await getToken();
      int? userId = await getUserId();

      print("Fetched UserID: $userId");
      print("Fetched Token: $token");

      if (token == null || userId == null) {
        print("Token or UserID missing");
        return;
      }

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
      } else {
        print("Failed to load details: ${response.body}");
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PROFILE ROW
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
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

              const SizedBox(height: 20),

              // BANNER
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

              // RECOMMENDED CLUBS TITLE
              const Text(
                "Recommended Clubs near you",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              // ⭐ HORIZONTAL CLUB SCROLL
              SizedBox(
                height: 160,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildClubCard(
                        "Spark roller skating",
                        "lib/assets/images.png",
                      ),
                      const SizedBox(width: 12),
                      buildClubCard(
                        "Kimberley skating",
                        "lib/assets/imagess.png",
                      ),
                      const SizedBox(width: 12),
                      buildClubCard(
                        "City Skate Club",
                        "lib/assets/images.png",
                      ), // example extra
                    ],
                  ),
                ),
              ),

              // UPCOMING EVENTS
              const SizedBox(height: 25),
              const Text(
                "Inspired to push your limits every day.",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),

              const SizedBox(height: 15),

              // EVENT CARD 1
              buildEventCard(
                clubName: "Langham Skating Club",
                date: "November 13, 2025",
                location: "Ponnurunni nagar - Kaloor",
                title: "Morning training session",
                timeLeft: "In 12m",
                icon: Icons.thumb_up_alt,
              ),

              const SizedBox(height: 12),

              // EVENT CARD 2 (with images)
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

              // SUGGESTED COACHES
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

              // ⭐ HORIZONTAL COACH SCROLL
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

              // EVENT CARD 1
              buildEventCard(
                clubName: "Langham Skating Club",
                date: "November 13, 2025",
                location: "Ponnurunni nagar - Kaloor",
                title: "Morning training session",
                timeLeft: "In 12m",
                icon: Icons.thumb_up_alt,
              ),

              const SizedBox(height: 12),

              // EVENT CARD 2 (with images)
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

      // BOTTOM NAV
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

  // CLUB CARD (NO EXPANDED)
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
    padding: EdgeInsets.all(14),
    margin: EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TOP ROW (Club details)
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage("lib/assets/images.png"),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clubName,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                Text(
                  date,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  location,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: 10),

        // TITLE
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 6),

        // TIME
        Text(
          timeLeft,
          style: TextStyle(color: Colors.tealAccent, fontSize: 13),
        ),

        SizedBox(height: 6),

        Text(location, style: TextStyle(color: Colors.white54, fontSize: 12)),

        SizedBox(height: 10),

        // LIKE + FAVORITE BUTTONS (BOTTOM RIGHT)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.thumb_up_alt_outlined, color: Colors.white70, size: 22),
            SizedBox(width: 14),
            // Icon(Icons.favorite_border,
            //     color: Colors.white70, size: 22),
          ],
        ),
      ],
    ),
  );
}

// EVENT CARD 2 WITH IMAGES
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
    padding: EdgeInsets.all(14),
    margin: EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage("lib/assets/imagess.png"),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clubName,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                Text(
                  date,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  location,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: 10),

        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 10),

        // IMAGES ROW
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(image1, height: 110, fit: BoxFit.cover),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(image2, height: 110, fit: BoxFit.cover),
              ),
            ),
          ],
        ),

        SizedBox(height: 10),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info, color: Colors.amberAccent, size: 18),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                description,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),

        SizedBox(height: 10),

        // LIKE + FAV BUTTONS BOTTOM RIGHT
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.thumb_up_alt_outlined, color: Colors.white70, size: 22),
            SizedBox(width: 14),
            // Icon(Icons.favorite_border,
            //     color: Colors.white70, size: 22),
          ],
        ),
      ],
    ),
  );
}

// COACH CARD (HORIZONTAL)
Widget buildCoachCard({
  required String name,
  required String subtitle,
  required String city,
  required String image,
}) {
  return Container(
    width: 165, // REDUCED WIDTH (was 200)
    margin: const EdgeInsets.only(
      right: 6, // SMALLER GAP BETWEEN CARDS
    ),
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // MAIN CARD
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

        // FLOATING AVATAR
        Positioned(
          top: -18,
          child: CircleAvatar(radius: 36, backgroundImage: AssetImage(image)),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/CoachApprovalTabs.dart';
import 'package:my_skates/ADMIN/add_banner.dart';
import 'package:my_skates/ADMIN/add_product.dart';
import 'package:my_skates/ADMIN/admin_notificationpage.dart';
import 'package:my_skates/ADMIN/coach_product_view.dart';
import 'package:my_skates/ADMIN/menu.dart';
import 'package:my_skates/ADMIN/productapprove_tab.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/STUDENTS/user_connect_coaches.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/STUDENTS/profile_page.dart';
import 'package:my_skates/bottomnavigation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String studentName = "";
  String studentRole = "";
  String? studentImage;
  bool isLoading = true;
  bool isRefreshing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserApprovedProducts()),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminNotificationpage()),
        );
        break;

      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserConnectCoaches()))  ;
        break;

      case 4: 
      break; 
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([fetchStudentDetails(), getbanner()]);
    setState(() => isLoading = false);
  }

  Future<void> _refreshData() async {
    if (!mounted || isRefreshing) return;

    setState(() => isRefreshing = true);

    // Refresh all data
    await Future.wait([fetchStudentDetails(), getbanner()]);

    setState(() => isRefreshing = false);

    // Hide snackbar after refresh
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
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

  void pushWithSlide(Widget page) {
    Navigator.push(context, slideRightToLeftRoute(page));
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

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<Map<String, dynamic>> statelist = [];

        for (var productData in parsed) {
          String imageUrl = "$api${productData['image']}";
          statelist.add({
            'id': productData['id'],
            'title': productData['title'],
            'image': imageUrl,
          });
        }
        setState(() {
          banner = statelist;
        });
      }
    } catch (error) {
      print("Error fetching banner: $error");
    }
  }

  Future<void> fetchStudentDetails() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      studentName = prefs.getString("name") ?? "User";
      studentRole = prefs.getString("user_type") ?? "";
      studentImage = prefs.getString("profile");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F1D), Color(0xFF003A36), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                )
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  color: Colors.tealAccent,
                  backgroundColor: Colors.black,
                  strokeWidth: 3.0,
                  displacement: 40.0,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PROFILE ROW
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                pushWithSlide(const ProfilePage());
                              },
                              child: CircleAvatar(
                                radius: 28,
                                backgroundImage:
                                    studentImage != null &&
                                        studentImage!.isNotEmpty
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

                            // MENU BUTTON
                            IconButton(
                              onPressed: () {
                                pushWithSlide(MenuPage());
                              },
                              icon: const Icon(
                                Icons.menu,
                                color: Colors.tealAccent,
                                size: 28,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () {
                            pushWithSlide(const AddBanner());
                          },

                          child: Column(
                            children: [
                              // MAIN BANNER
                              Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: banner.isEmpty
                                      ? Container(
                                          color: Colors.grey.shade900,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.tealAccent,
                                            ),
                                          ),
                                        )
                                      : FlutterCarousel(
                                          options: CarouselOptions(
                                            height: 160,
                                            autoPlay: true,
                                            autoPlayInterval: const Duration(
                                              seconds: 3,
                                            ),
                                            viewportFraction: 1,
                                            showIndicator: true,
                                            slideIndicator:
                                                const CircularSlideIndicator(),
                                          ),
                                          items: banner.map((item) {
                                            return Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: Image.network(
                                                    item["image"] ?? "",
                                                    fit: BoxFit.cover,
                                                    loadingBuilder:
                                                        (
                                                          context,
                                                          child,
                                                          progress,
                                                        ) {
                                                          if (progress == null)
                                                            return child;
                                                          return Container(
                                                            color: Colors
                                                                .grey
                                                                .shade900,
                                                            alignment: Alignment
                                                                .center,
                                                            child:
                                                                const CircularProgressIndicator(),
                                                          );
                                                        },
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Container(
                                                          color: Colors.black,
                                                          alignment:
                                                              Alignment.center,
                                                          child: const Icon(
                                                            Icons.broken_image,
                                                            color:
                                                                Colors.white54,
                                                            size: 40,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.black
                                                              .withOpacity(0.6),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          "Weeee offer training and an e-commerce platform\nthat connects students and coaches.",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),

                        const SizedBox(height: 25),

                        buildButton("Approve Coaches"),
                        buildButton("Add Products"),
                        buildButton("Approve Products"),
                        buildButton("Buy and Sell products"),

                        const SizedBox(height: 25),

                        // RECOMMENDED CLUBS TITLE
                        const Text(
                          "Recommended Clubs near you",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // HORIZONTAL CLUB SCROLL
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
                                ),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 15),

                        // HORIZONTAL COACH SCROLL
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
        ),
      ),

      // BOTTOM NAV
      bottomNavigationBar: AppBottomNav(
      currentIndex: 0,
      onTap: _onBottomNavTap,
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
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: () {
          if (title == "Approve Coaches") {
            pushWithSlide(const CoachApprovalTabs());
          }
          if (title == "Buy and Sell products") {
            pushWithSlide(const UserApprovedProducts());
          }
          if (title == "Approve Products") {
            pushWithSlide(const ProductapproveTab());
          }
          if (title == "Add Products") {
            pushWithSlide(const AddProduct());
          }
        },
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
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white12),
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
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 10,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TOP ROW (Club details)
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: const AssetImage("lib/assets/images.png"),
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

        // TITLE
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        // TIME
        Text(
          timeLeft,
          style: const TextStyle(color: Colors.tealAccent, fontSize: 13),
        ),

        const SizedBox(height: 6),

        const SizedBox(height: 10),

        // LIKE + FAVORITE BUTTONS (BOTTOM RIGHT)
        Row(
          children: [
            Text(location, style: TextStyle(color: Colors.white70)),
            SizedBox(width: 120),
            Icon(Icons.thumb_up_alt_outlined, color: Colors.tealAccent),
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
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 12),
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
              backgroundImage: const AssetImage("lib/assets/imagess.png"),
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

        // IMAGES ROW
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

        // LIKE + FAV BUTTONS BOTTOM RIGHT
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.thumb_up_alt_outlined,
              color: Colors.tealAccent,
              size: 22,
            ),
            const SizedBox(width: 14),
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

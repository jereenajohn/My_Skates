import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/coach_menu_page.dart';
import 'package:my_skates/ADMIN/live_tracking.dart';
import 'package:my_skates/ADMIN/user_approved_products.dart';
import 'package:my_skates/COACH/coach_notification_page.dart';
import 'package:my_skates/COACH/coach_settings.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/STUDENTS/profile_page.dart';
import 'package:my_skates/STUDENTS/user_connect_coaches.dart';
import 'package:my_skates/STUDENTS/user_settings.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

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
  List<Map<String, dynamic>> students = [];
  bool studentsLoading = true;
  bool studentsNoData = false;

  // FOLLOW STATUS (same as user homepage)
  List<int> myFollowing = [];
  List<int> myRequests = [];
  List<int> myApprovedSent = [];
  bool followLoaded = false;

  List coaches = [];
  bool coachesLoading = true;
  bool coachesNoData = false;
  int followRequestCount = 0;

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    fetchcoachDetails();
    getbanner();
    fetchFollowRequestCount();

    loadEverything();
     _timer = Timer.periodic(
    const Duration(seconds: 15),
    (_) => fetchFollowRequestCount(),
  );
  }

  
@override
void dispose() {
  _timer.cancel();
  super.dispose();
}

  Future<void> loadEverything() async {
    await fetchFollowStatus();
    await fetchCoaches(); // then load coaches (depends on above)

    await fetchStudents();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access');
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt("id");
  }

  Future<void> fetchFollowRequestCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.get(
      Uri.parse("$api/api/myskates/user/follow/requests/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      setState(() {
        followRequestCount = data.length;
      });
    }
  }

  Future<void> fetchcoachDetails() async {
    try {
      String? token = await getToken();
      int? userId = await getUserId();

      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse("$api/api/myskates/profile/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("PROFILE API STATUS = ${response.statusCode}");
      print("PROFILE API BODY = ${response.body}");

      final data = jsonDecode(response.body);

      if (data is List) {
        // Find the logged-in user
        final user = data.firstWhere(
          (item) => item["id"] == userId,
          orElse: () => null,
        );

        if (user == null) {
          print("Logged-in user not found in profile list");
          return;
        }

        setState(() {
          studentName = user["first_name"] ?? user["name"] ?? "User";
          studentRole = user["user_type"] ?? "Student";
          studentImage = user["profile"];
          isLoading = false;
        });

        print("Loaded PROFILE for user ID $userId");
      } else {
        print("PROFILE API did not return a list.");
      }
    } catch (e) {
      print("Error fetching student: $e");
    }
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

  Future<void> fetchStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse("$api/api/myskates/student/details/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("FETCH STUDENTS STATUS: ${response.statusCode}");
      print("FETCH STUDENTS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          students = data
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
          studentsNoData = students.isEmpty;
          studentsLoading = false;
        });
      } else {
        studentsNoData = true;
        studentsLoading = false;
        setState(() {});
      }
    } catch (e) {
      print("FETCH STUDENTS ERROR: $e");
      studentsNoData = true;
      studentsLoading = false;
      setState(() {});
    }
  }

  Future<void> fetchFollowStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      // Pending sent requests
      final rPending = await http.get(
        Uri.parse("$api/api/myskates/user/follow/sent/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (rPending.statusCode == 200) {
        final data = jsonDecode(rPending.body);
        myRequests = List<int>.from((data as List).map((e) => e["following"]));
      }

      // Approved sent requests
      final rApproved = await http.get(
        Uri.parse("$api/api/myskates/user/follow/sent/approved/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (rApproved.statusCode == 200) {
        final data = jsonDecode(rApproved.body);
        myApprovedSent = List<int>.from(
          (data as List).map((e) => e["following"]),
        );
      }

      followLoaded = true;
      setState(() {});
    } catch (e) {
      print("COACH FOLLOW STATUS ERROR: $e");
    }
  }

  Future<void> followStudent(int studentId) async {
    try {
      print("➡️ followStudent() called with studentId=$studentId");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.post(
        Uri.parse("$api/api/myskates/user/follow/request/"),
        headers: {"Authorization": "Bearer $token"},
        body: {"following_id": studentId.toString()},
      );

      print("📡 FOLLOW API STATUS: ${response.statusCode}");
      print("📡 FOLLOW API BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        print("🔍 FOLLOW RESPONSE PARSEDDD: $decoded");

        if (decoded["status"] == "pending") {
          setState(() {
            if (!myRequests.contains(studentId)) {
              myRequests.add(studentId);
            }
          });
          print("🟡 STATE UPDATE → myRequests=$myRequests");
        }

        if (decoded["status"] == "approved") {
          setState(() {
            myApprovedSent.add(studentId);
            myRequests.remove(studentId);
          });
          print("🟢 STATE UPDATE → myApprovedSent=$myApprovedSent");
        }
      }
    } catch (e) {
      print("❌ FOLLOW STUDENT ERROR: $e");
    }
  }

  Future<void> cancelPendingRequest(int userId) async {
    print("➡️ cancelPendingRequest() called for userId=$userId");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final response = await http.post(
      Uri.parse('$api/api/myskates/user/follow/cancel/'),
      headers: {"Authorization": "Bearer $token"},
      body: {"following_id": userId.toString()},
    );

    print("📡 CANCEL REQUEST STATUS: ${response.statusCode}");
    print("📡 CANCEL REQUEST BODY: ${response.body}");

    setState(() {
      myRequests.remove(userId);
    });

    print("🧹 STATE UPDATE → myRequests=$myRequests");
  }

  Future<void> unfollowUser(int userId) async {
    print("➡️ unfollowUser() called for userId=$userId");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final response = await http.post(
      Uri.parse('$api/api/myskates/user/unfollow/'),
      headers: {"Authorization": "Bearer $token"},
      body: {"following_id": userId.toString()},
    );

    print("📡 UNFOLLOW STATUS: ${response.statusCode}");
    print("📡 UNFOLLOW BODY: ${response.body}");

    setState(() {
      myFollowing.remove(userId);
      myApprovedSent.remove(userId);
      myRequests.remove(userId);
    });

    print("🧹 STATE UPDATE → myFollowing=$myFollowing");
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

  Future<void> sendFollowRequest(int coachId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final response = await http.post(
      Uri.parse('$api/api/myskates/user/follow/request/'),
      headers: {"Authorization": "Bearer $token"},
      body: {"following_id": coachId.toString()},
    );

    print(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Force update cached pending list
      myRequests.add(coachId);
      setState(() {});
    }
  }

  Future<void> unfollowCoach(int coachId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.post(
      Uri.parse('$api/api/myskates/user/unfollow/'),
      headers: {"Authorization": "Bearer $token"},
      body: {"following_id": coachId.toString()},
    );

    print("UNFOLLOW: ${res.body}");

    setState(() {
      myFollowing.remove(coachId); // remove following
      myApprovedSent.remove(coachId); // remove approved
      myRequests.remove(coachId); // remove pending (IMPORTANT FIX)
    });
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
                            builder: (_) => const CoachMenuPage(),
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
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CoachNotificationPage(),
                              ),
                            );

                            // 🔁 Refresh count when coming backkkk
                            fetchFollowRequestCount();
                          },
                          icon: const Icon(
                            Icons.notifications_none,
                            color: Colors.tealAccent,
                          ),
                        ),

                        if (followRequestCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                followRequestCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
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

                    // COACHES
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
                      child: !followLoaded
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : coachesLoading
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
                              itemBuilder: (_, i) => CoachFollowCard(
                                coach: coaches[i],
                                onFollow: sendFollowRequest,
                                onCancelPending: cancelPendingRequest,
                                onUnfollow: unfollowCoach,
                                myFollowing: myFollowing,
                                myRequests: myRequests,
                                myApprovedSent: myApprovedSent,
                                refreshParent: () => setState(() {}),
                              ),
                            ),
                    ),

                    SizedBox(height: 20),

                    const Text(
                      "Suggested Students",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 190,
                      child: studentsLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : studentsNoData
                          ? const Center(
                              child: Text(
                                "No students found",
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: students.length,
                              itemBuilder: (_, i) => StudentFollowCard(
                                student: students[i],
                                myFollowing: myFollowing,
                                myRequests: myRequests,
                                myApprovedSent: myApprovedSent,
                                onFollow: followStudent,
                                onCancelPending: cancelPendingRequest,
                                onUnfollow: unfollowUser,
                                refreshParent: () => setState(() {}),
                              ),
                            ),
                    ),

                    SizedBox(height: 20),

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
        onPressed: () {
          if (title == "Connect Coaches") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserConnectCoaches(),
              ),
            );
          } else if (title == "Connect Students") {

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActivityTrackerPage(),
              ),
            );

          } else if (title == "Find Clubs") {
            // Navigate to Find Clubs page
          } else if (title == "Find Events") {
            // Navigate to Find Events page
          } else if (title == "Buy and Sell products") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserApprovedProducts(),
              ),
            );
          }
        },
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

class SimpleStudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onFollow;

  const SimpleStudentCard({
    super.key,
    required this.student,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        "${student["first_name"] ?? ""} ${student["last_name"] ?? ""}";
    final String standard = student["standard"] ?? "";
    final String institution = student["institution"] ?? "";

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundImage: AssetImage("lib/assets/img.jpg"),
          ),
          const SizedBox(height: 8),

          Text(
            name.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 2),

          Text(
            institution,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          Text(
            standard.isNotEmpty ? "Class $standard" : "",
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AFA5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: onFollow,
              child: const Text(
                "Follow",
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentFollowCard extends StatefulWidget {
  final Map student;
  final List<int> myFollowing;
  final List<int> myRequests;
  final List<int> myApprovedSent;

  final Function(int) onFollow;
  final Function(int) onCancelPending;
  final Function(int) onUnfollow;
  final Function() refreshParent;

  const StudentFollowCard({
    super.key,
    required this.student,
    required this.myFollowing,
    required this.myRequests,
    required this.myApprovedSent,
    required this.onFollow,
    required this.onCancelPending,
    required this.onUnfollow,
    required this.refreshParent,
  });

  @override
  State<StudentFollowCard> createState() => _StudentFollowCardState();
}

class _StudentFollowCardState extends State<StudentFollowCard> {
  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final int userId = student["id"];

    String name = "${student['first_name'] ?? ''} ${student['last_name'] ?? ''}"
        .trim();
    if (name.isEmpty) name = "Student";

    String standard = student["standard"] != null
        ? "Class ${student["standard"]}"
        : "Student";

    String imageUrl =
        student["profile"] != null && student["profile"].toString().isNotEmpty
        ? "$api${student["profile"]}"
        : "";

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : const AssetImage("lib/assets/img.jpg") as ImageProvider,
          ),

          const SizedBox(height: 8),

          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),

          const SizedBox(height: 2),

          Text(
            standard,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 34,
            child: _buildButton(userId),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(int userId) {
    if (widget.myFollowing.contains(userId)) {
      return _followingBtn(userId);
    }

    if (widget.myApprovedSent.contains(userId)) {
      return _followingBtn(userId);
    }

    if (widget.myRequests.contains(userId)) {
      return _requestedBtn(userId);
    }

    return _followBtn(userId);
  }

  Widget _followBtn(int userId) {
    return ElevatedButton(
      onPressed: () async {
        print("🟢 FOLLOW BUTTON CLICKED → userId=$userId");
        await widget.onFollow(userId);
        widget.refreshParent();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00AFA5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("Follow", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _requestedBtn(int userId) {
    return OutlinedButton(
      onPressed: () async {
        print("🟡 REQUESTED BUTTON CLICKED (CANCEL) → userId=$userId");
        await widget.onCancelPending(userId);
        widget.refreshParent();
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white),
      ),
      child: const Text("Requested", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _followingBtn(int userId) {
    return OutlinedButton(
      onPressed: () async {
        print("🔴 FOLLOWING BUTTON CLICKED (UNFOLLOW) → userId=$userId");
        await widget.onUnfollow(userId);
        widget.refreshParent();
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white),
      ),
      child: const Text("Following", style: TextStyle(color: Colors.white)),
    );
  }
}

class CoachFollowCard extends StatefulWidget {
  final Map coach;
  final List<int> myFollowing;
  final List<int> myRequests;
  final Function(int) onFollow;
  final List<int> myApprovedSent;

  final Function(int) onCancelPending;
  final Function(int) onUnfollow;
  final Function() refreshParent;

  const CoachFollowCard({
    super.key,
    required this.coach,
    required this.myFollowing,
    required this.myRequests,
    required this.onFollow,
    required this.myApprovedSent,
    required this.onCancelPending,
    required this.onUnfollow,
    required this.refreshParent,
  });

  @override
  State<CoachFollowCard> createState() => _CoachFollowCardState();
}

class _CoachFollowCardState extends State<CoachFollowCard> {
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
                : const AssetImage("lib/assets/img.jpg") as ImageProvider,
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

          SizedBox(width: double.infinity, child: _buildButton(coachId)),
        ],
      ),
    );
  }

  Widget _buildButton(int coachId) {
    // ALREADY FOLLOWING (from followers list)
    if (widget.myFollowing.contains(coachId)) {
      return _followingBtn(coachId);
    }

    // SENT APPROVED REQUESTS (this is new)
    if (widget.myApprovedSent.contains(coachId)) {
      return _followingBtn(coachId);
    }

    // REQUESTED (pending)
    if (widget.myRequests.contains(coachId)) {
      return _requestedBtn(coachId);
    }

    // DEFAULT — FOLLOW
    return _followBtn(coachId);
  }

  Widget _followingBtn(int coachId) {
    return OutlinedButton(
      onPressed: () async {
        await widget.onUnfollow(coachId);
        widget.refreshParent(); // Refresh parent UI
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white, width: 1.5),
      ),
      child: const Text("Following", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _requestedBtn(int coachId) {
    return OutlinedButton(
      onPressed: () async {
        await widget.onCancelPending(coachId);
        widget.refreshParent(); // THIS FIXES UI
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("Requested", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _followBtn(int coachId) {
    return ElevatedButton(
      onPressed: () async {
        await widget.onFollow(coachId);
        widget.refreshParent(); // FIX
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00AFA5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("Follow", style: TextStyle(color: Colors.white)),
    );
  }
}

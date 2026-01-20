import 'dart:async';
import 'package:my_skates/COACH/coach_home_feedcard.dart';
import 'package:my_skates/Providers/coach_homepage_feed_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/coach_product_view.dart';
import 'package:my_skates/ADMIN/view_all_events.dart';
import 'package:my_skates/COACH/club_list.dart';
import 'package:my_skates/COACH/coach_add_events.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/COACH/coach_menu_page.dart';
import 'package:my_skates/ADMIN/live_tracking.dart';
import 'package:my_skates/COACH/coach_notification_page.dart';
import 'package:my_skates/COACH/coach_settings.dart';
import 'package:my_skates/STUDENTS/products.dart';
import 'package:my_skates/COACH/training_session_page.dart';
import 'package:my_skates/STUDENTS/student_list.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/STUDENTS/profile_page.dart';
import 'package:my_skates/STUDENTS/user_connect_coaches.dart';
import 'package:my_skates/STUDENTS/user_settings.dart';
import 'package:my_skates/bottomnavigation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:intl/intl.dart';

class CoachHomepage extends StatefulWidget {
  const CoachHomepage({super.key});

  @override
  State<CoachHomepage> createState() => _CoachHomepageState();
}

class _CoachHomepageState extends State<CoachHomepage> {
  int _currentIndex = 0;
  String studentName = "";
  String studentRole = "";
  String? studentImage;
  bool isLoading = true;
  List<Map<String, dynamic>> students = [];
  bool studentsLoading = true;
  bool studentsNoData = false;
  List clubs = [];
  bool noData = false;
  bool trainingLoading = true;
  bool trainingNoData = false;

  // FOLLOW STATUS (same as user homepage)
  List<int> myFollowing = [];
  List<int> myRequests = [];
  List<int> myApprovedSent = [];
  bool followLoaded = false;

  List coaches = [];
  bool coachesLoading = true;
  bool coachesNoData = false;
  int followRequestCount = 0;
  List<Map<String, dynamic>> events = [];
  bool eventsLoading = true;
  bool eventsNoData = false;
  bool loading = true;
  // List<Map<String, dynamic>> trainingSessions = [];

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    fetchcoachDetails();
    getbanner();
    fetchFollowRequestCount();
    fetchClubs();
    loadEvents();
    getAllEvents();
    getTrainingSessions();

    loadEverything();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => fetchFollowRequestCount(),
    );
  }

  Future<void> loadEvents() async {
    try {
      final data = await getAllEvents();
      setState(() {
        events = data;
        eventsNoData = events.isEmpty;
        eventsLoading = false;
      });
    } catch (e) {
      eventsLoading = false;
      eventsNoData = true;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        // Home (already here)
        break;

      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserApprovedProducts()),
        );
        break;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CoachNotificationPage()),
        );
        break;

      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserConnectCoaches()),
        );
        break;

      case 4:
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => const CoachAddEvents(),
        //   ),
        // );
        break;
    }
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

  List<Map<String, dynamic>> trainingSessions = [];

  Future<void> getTrainingSessions() async {
    final token = await getToken();

    try {
      final response = await http.get(
        Uri.parse('$api/api/myskates/training/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("Training Sessions STATUS: ${response.statusCode}");
      print("Training Sessions BODY: ${response.body}");
      List<Map<String, dynamic>> trainingList = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var data = parsed['data'];

        for (var item in data) {
          trainingList.add({
            'id': item['id'],
            'title': item['title'],
            'note': item['note'],
            'start_date': item['start_date'],
            'end_date': item['end_date'],
            'start_time': item['start_time'],
            'end_time': item['end_time'],
            'location': item['location'],
            'latitude': item['latitude'],
            'longitude': item['longitude'],
            'images': item['images'],
            'created_at': item['created_at'],
            'updated_at': item['updated_at'],
          });
        }
        print("Training Sessions Fetched: $trainingList");

        setState(() {
          trainingSessions = trainingList;
          trainingLoading = false;
          trainingNoData = trainingList.isEmpty;
        });
      } else {
        setState(() {
          trainingLoading = false;
          trainingNoData = true;
        });
      }
    } catch (e) {
      print("Training session error: $e");
      setState(() {
        trainingLoading = false;
        trainingNoData = true;
      });
    }
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

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) {
      throw Exception("Authentication token missing");
    }

    final response = await http.get(
      Uri.parse("$api/api/myskates/events/add/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    debugPrint("EVENT LIST STATUS: ${response.statusCode}");
    debugPrint("EVENT LIST BODY: ${response.body}");

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);

      return decoded.map<Map<String, dynamic>>((e) {
        return {
          "id": e["id"],
          "title": e["title"],
          "description": e["description"],
          "note": e["note"],
          "from_date": e["from_date"],
          "to_date": e["to_date"],
          "from_time": e["from_time"],
          "to_time": e["to_time"],
          "club_name": e["club_name"],
          "club_image": e["club_image"],
          "images": e["images"], // List of event images
          "created_at": e["created_at"],
        };
      }).toList();
    } else {
      throw Exception("Failed to load events");
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
                              // MaterialPageRoute(
                              //   builder: (_) => const CoachNotificationPage(),
                              // ),
                              slideRightToLeftRoute(CoachNotificationPage()),
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

                    // ChangeNotifierProvider(
                    //   create: (_) => HomeFeedProvider()..fetchHomeFeeds(),
                    //   child: Consumer<HomeFeedProvider>(
                    //     builder: (_, p, __) {
                    //       if (p.loading) {
                    //         return const CircularProgressIndicator();
                    //       }

                    //       return Column(
                    //         children: p.feeds.map((feed) {
                    //           return HomeFeedCard(feed: feed);
                    //         }).toList(),
                    //       );
                    //     },
                    //   ),
                    // ),

                    // CLUBS
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

                    const Text(
                      "Upcoming Training Sessions",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),

                    const SizedBox(height: 15),

                    if (trainingLoading)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else if (trainingNoData)
                      const Text(
                        "No training sessions available",
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      Column(
                        children: trainingSessions.map((session) {
                          final images = session['images'] as List? ?? [];

                          String imageUrl = images.isNotEmpty
                              ? "$api${images[0]['image']}"
                              : "";

                          return buildTrainingSessionRow(
                            title: session['title'] ?? "",
                            note: session['note'] ?? "",
                            location: session['location'] ?? "",
                            startDate: session['start_date'] ?? "",
                            endDate: session['end_date'] ?? "",
                            startTime: session['start_time'] ?? "",
                            endTime: session['end_time'] ?? "",
                            imageUrl: imageUrl,
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 12),

                    const Text(
                      "Upcoming Events",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (eventsLoading)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else if (eventsNoData)
                      const Center(
                        child: Text(
                          "No events found",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    else
                      Column(
                        children: events.map((event) {
                          final images = event["images"] as List? ?? [];

                          String image1 = images.isNotEmpty
                              ? "$api${images[0]['image']}"
                              : "";

                          String image2 = images.length > 1
                              ? "$api${images[1]['image']}"
                              : "";

                          return buildEventCardWithImages(
                            context: context,
                            clubName: event["club_name"] ?? "Skating Club",
                            clubImage: event["club_image"] ?? "",
                            location: event["note"] ?? "",
                            title: event["title"] ?? "",
                            image1: image1,
                            image2: image2,
                            imageCount: images.length,
                            description: event["description"] ?? "",
                            fromDate: event["from_date"] ?? "",
                            toDate: event["to_date"] ?? "",
                            fromTime: event["from_time"] ?? "",
                            toTime: event["to_time"] ?? "",
                            icon: Icons.thumb_up_alt_outlined,
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 12),

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

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: const AppBottomNav(
        currentIndex: 0, // Home tab
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
              MaterialPageRoute(builder: (context) => const StudentList()),
            );
          } else if (title == "Find Clubs") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClubGridPage()),
            );
          } else if (title == "Find Events") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Events()),
            );
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

// CLUB CARD
Widget buildClubCardFromApi(Map club) {
  String title = club["club_name"] ?? "Club";
  String? img = club["image"];
  String imageUrl = (img != null && img.isNotEmpty) ? "$api$img" : "";

  return Container(
    width: 160,
    height: 100,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : const AssetImage("lib/assets/images.png") as ImageProvider,
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        const Spacer(),
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

void showImagePopup(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.9),
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      );
    },
  );
}

String formatDateTimeToAmPm(String date, String time) {
  if (date.isEmpty || time.isEmpty) return "";

  final dt = DateTime.parse("$date $time");
  int hour = dt.hour;
  final minute = dt.minute.toString().padLeft(2, '0');

  final period = hour >= 12 ? "PM" : "AM";
  hour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

  return "$hour:$minute $period";
}

// --------------------------- EVENT CARD 2 ---------------------------
Widget buildEventCardWithImages({
  required BuildContext context,
  required String clubName,
  required String clubImage,
  required int imageCount,
  required String location,
  required String title,
  required String image1,
  required String image2,
  required String description,
  required IconData icon,
  required String fromDate,
  required String toDate,
  required String fromTime,
  required String toTime,
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
            CircleAvatar(
              radius: 22,
              backgroundImage: clubImage.isNotEmpty
                  ? NetworkImage("$api$clubImage")
                  : null,
              backgroundColor: Colors.black26,
              child: clubImage.isEmpty
                  ? const Icon(Icons.groups, color: Colors.white54, size: 18)
                  : null,
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
        // ---------------- IMAGES ----------------
        if (imageCount == 1)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: () => showImagePopup(context, image1),
              child: Image.network(
                image1,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, color: Colors.white54),
                ),
              ),
            ),
          )
        else if (imageCount >= 2)
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () => showImagePopup(context, image1),
                    child: Image.network(
                      image1,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () => showImagePopup(context, image2),
                    child: Image.network(
                      image2,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 10),

        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 10,
              color: Colors.tealAccent,
            ),
            const SizedBox(width: 6),
            Text(
              "$fromDate - $toDate",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.access_time, size: 10, color: Colors.tealAccent),
            const SizedBox(width: 6),
            Text(
              "${formatDateTimeToAmPm(fromDate, fromTime)} - "
              "${formatDateTimeToAmPm(toDate, toTime)}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info, color: Colors.amberAccent, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),

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

String formatDisplayDate(String date) {
  final parsed = DateTime.parse(date);
  return DateFormat('dd-MM-yyyy').format(parsed);
}

String formatDisplayTime(String time) {
  final parsed = DateFormat("HH:mm:ss").parse(time);
  return DateFormat("hh:mm a").format(parsed);
}

Widget _imagePlaceholder() {
  return Container(
    width: 90,
    height: 90,
    color: Colors.black26,
    alignment: Alignment.center,
    child: const Icon(Icons.image, color: Colors.white38, size: 28),
  );
}

Widget buildTrainingSessionRow({
  required String title,
  required String note,
  required String location,
  required String startDate,
  required String endDate,
  required String startTime,
  required String endTime,
  required String imageUrl,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT IMAGE
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
        ),

        const SizedBox(width: 12),

        // RIGHT CONTENT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 13,
                    color: Colors.tealAccent,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Colors.tealAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${formatDisplayDate(startDate)} - ${formatDisplayDate(endDate)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.tealAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${formatDisplayTime(startTime)} - ${formatDisplayTime(endTime)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

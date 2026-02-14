import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/view_all_events.dart';
import 'package:my_skates/COACH/club_list.dart';
import 'package:my_skates/COACH/coach_details_page.dart';
import 'package:my_skates/STUDENTS/bottomnavigation_student.dart';
import 'package:my_skates/STUDENTS/products.dart';
import 'package:my_skates/STUDENTS/student_list.dart';
import 'package:my_skates/STUDENTS/user_menu_page.dart';
import 'package:my_skates/STUDENTS/user_notification%20page.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/STUDENTS/profile_page.dart';
import 'package:my_skates/STUDENTS/user_connect_coaches.dart';
import 'package:my_skates/STUDENTS/user_settings.dart';
import 'package:my_skates/bottomnavigation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:intl/intl.dart';

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

  // NEW: follow status caches
  List<int> myFollowing = [];
  List<int> myRequests = [];
  bool followLoaded = false;
  List<int> myApprovedSent = [];
  // STUDENTS
  List students = [];
  bool studentsLoading = true;
  bool studentsNoData = false;

  int? loggedInUserId;
  int followRequestCount = 0;
  bool trainingLoading = true;
  bool trainingNoData = false;

  @override
  initState() {
    super.initState();
    fetchStudentDetails();
    fetchClubs();
    loadEvents();
    refreshUserProfile().then((_) => fetchStudentDetails());
    getbanner();
    getTrainingSessions();
    fetchRegisteredTrainings();

    loadEverything(); // Single initialization
  }

  Future<void> loadEverything() async {
    await fetchFollowStatus(); // load following + pending
    await fetchCoaches(); // then load coaches (depends on above)
    await fetchStudents();
    setState(() {});
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

  // Future<void> initLoad() async {
  //   await fetchFollowStatus();
  //   await fetchCoaches();
  //   setState(() {});
  // }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access');
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

  Future<void> sendClubJoinRequest(int clubId) async {
    final token = await getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('$api/api/myskates/club/join/$clubId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 🔁 THIS IS THE IMPORTANT LINE
        await fetchClubs(); // ← HERE

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Join request sent successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("CLUB JOIN ERROR: $e");
    }
  }

  Future<void> leaveClub(int clubId) async {
    final token = await getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('$api/api/myskates/club/leave/$clubId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 🔁 REFRESH CLUB LIST FROM BACKEND
        await fetchClubs();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Left club successfully"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("CLUB LEAVE ERROR: $e");
    }
  }

  Future<void> toggleEventLike(int eventId) async {
    final token = await getToken();
    if (token == null) return;

    final index = events.indexWhere((e) => e["id"] == eventId);
    if (index == -1) return;

    final bool wasLiked = events[index]["is_liked"] == true;
    final int currentLikes = events[index]["likes_count"] ?? 0;

    //  Optimistic UI update
    setState(() {
      events[index]["is_liked"] = !wasLiked;
      events[index]["likes_count"] = wasLiked
          ? currentLikes - 1
          : currentLikes + 1;
    });

    try {
      final response = await http.post(
        Uri.parse("$api/api/myskates/events/$eventId/like/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      //  Revert if API fails
      if (response.statusCode != 200 && response.statusCode != 201) {
        setState(() {
          events[index]["is_liked"] = wasLiked;
          events[index]["likes_count"] = currentLikes;
        });
      }
    } catch (e) {
      //  Revert on exception
      setState(() {
        events[index]["is_liked"] = wasLiked;
        events[index]["likes_count"] = currentLikes;
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

  Future<void> fetchStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse("$api/api/myskates/student/details/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("STUDENTS STATUS: ${response.statusCode}");
      print("STUDENTS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() {
            students = decoded
                .where((s) => s["id"] != loggedInUserId) // FILTER SELF
                .toList();

            studentsNoData = students.isEmpty;
            studentsLoading = false;
          });
        }
      } else {
        setState(() {
          studentsNoData = true;
          studentsLoading = false;
        });
      }
    } catch (e) {
      print("STUDENT FETCH ERROR: $e");
      setState(() {
        studentsNoData = true;
        studentsLoading = false;
      });
    }
  }

  Future<void> fetchFollowStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      print("================ FETCH FOLLOW STATUS START ================");

      // 1) FETCH PENDING REQUESTS
      var rPending = await http.get(
        Uri.parse("$api/api/myskates/user/follow/sent/"),
        headers: {"Authorization": "Bearer $token"},
      );
      print("PENDINGGG: ${rPending.body}");

      if (rPending.statusCode == 200) {
        final dataPending = jsonDecode(rPending.body);
        myRequests = List<int>.from(
          (dataPending as List).map((e) => e["following"]),
        );
      }

      // 2) FETCH APPROVED SENT REQUESTS
      var rApproved = await http.get(
        Uri.parse("$api/api/myskates/user/follow/sent/approved/"),
        headers: {"Authorization": "Bearer $token"},
      );
      print("APPROVED SENT: ${rApproved.body}");

      if (rApproved.statusCode == 200) {
        final dataApproved = jsonDecode(rApproved.body);
        myApprovedSent = List<int>.from(
          (dataApproved as List).map((e) => e["following"]),
        );
      }

      followLoaded = true;
      setState(() {});
    } catch (e) {
      print("ERROR IN FOLLOW STATUS: $e");
    }
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
      prefs.setInt("user_id", data["id"]);
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
      loggedInUserId = prefs.getInt("id");
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
          print("CLUBS FETCHED: $clubs");
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
          "images": e["images"] ?? [],
          "likes_count": e["likes_count"] ?? 0,
          "is_liked": e["is_liked"] ?? false,
          "created_at": e["created_at"],
        };
      }).toList();
    } else {
      throw Exception("Failed to load events");
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
      myFollowing.remove(coachId);
      myApprovedSent.remove(coachId);
      myRequests.remove(coachId);
    });
  }

  Future<void> cancelPendingRequest(int coachId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.post(
      Uri.parse('$api/api/myskates/user/follow/cancel/'),
      headers: {"Authorization": "Bearer $token"},
      body: {"following_id": coachId.toString()},
    );

    print("CANCEL PENDING REQUEST: ${res.body}");

    setState(() {
      myRequests.remove(coachId);
    });
  }

  Set<int> registeredTrainingIds = {};
  Future<void> registerTraining(int trainingId) async {
    final token = await getToken();

    try {
      final response = await http.post(
        Uri.parse('$api/api/myskates/training/register/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"training_id": trainingId}),
      );

      print("REGISTER TRAINING STATUS: ${response.statusCode}");
      print("REGISTER TRAINING BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          registeredTrainingIds.add(trainingId); // ✅ DISABLE BUTTON
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Training registered successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("REGISTER TRAINING ERROR: $e");
    }
  }

  Future<void> fetchRegisteredTrainings() async {
    final token = await getToken();

    try {
      final response = await http.get(
        Uri.parse('$api/api/myskates/training/register/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("REGISTERED TRAININGS STATUS: ${response.statusCode}");
      print("REGISTERED TRAININGS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final List data = parsed['data'] ?? [];

        setState(() {
          registeredTrainingIds = data
              .map<int>((e) => e['training'] as int)
              .toSet();
        });
      }
    } catch (e) {
      print("FETCH REGISTERED TRAININGS ERROR: $e");
    }
  }

  Future<void> confirmRegister(int trainingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Confirm Registration",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Do you want to register for this training session?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AFA5),
              ),
              child: const Text("Register"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await registerTraining(trainingId);
    }
  }

  // UI BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF001A18),
              const Color(0xFF002F2B),
              const Color(0xFF000C0B),
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
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
                              builder: (_) => const UserMenuPage(),
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
                                //   builder: (_) => const UserNotificationPage(),
                                // ),
                                slideRightToLeftRoute(UserNotificationPage()),
                              );

                              // 🔁 Refresh count when coming back
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

              // CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BANNER
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
                          child: FlutterCarousel(
                            options: CarouselOptions(
                              height: 160,
                              autoPlay: true,
                              autoPlayInterval: const Duration(seconds: 3),
                              viewportFraction: 1,
                              showIndicator: true,
                              slideIndicator: CircularSlideIndicator(),
                            ),
                            items: banner.map((item) {
                              return Stack(
                                children: [
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
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white54,
                                                  size: 40,
                                                ),
                                              ),
                                    ),
                                  ),
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

                      // BUTTONS
                      buildButton("Connect Coaches"),
                      buildButton("Connect Students"),
                      buildButton("Find Clubs"),
                      buildButton("Find Events"),
                      buildButton("Buy and Sell products"),

                      const SizedBox(height: 25),

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
                        height: MediaQuery.of(context).size.height * 0.22,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: clubs.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: buildClubCardFromApi(
                              clubs[i],
                              onJoinClub: sendClubJoinRequest,
                              onLeaveClub: leaveClub,
                              context: context,
                            ),
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
                              trainingId: session['id'],
                              title: session['title'] ?? "",
                              note: session['note'] ?? "",
                              location: session['location'] ?? "",
                              startDate: session['start_date'] ?? "",
                              endDate: session['end_date'] ?? "",
                              startTime: session['start_time'] ?? "",
                              endTime: session['end_time'] ?? "",
                              imageUrl: imageUrl,
                              isRegistered: registeredTrainingIds.contains(
                                session['id'],
                              ),
                              onRegister: () {
                                confirmRegister(
                                  session['id'],
                                ); // ✅ POPUP + REGISTER
                              },
                            );
                          }).toList(),
                        ),
                      SizedBox(height: 25),

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
                                : "lib/assets/skating1.jpg";

                            String image2 = images.length > 1
                                ? "$api${images[1]['image']}"
                                : image1;

                            return buildEventCardWithImages(
                              clubName: event["club_name"] ?? "Skating Club",
                              clubImage: event["club_image"] ?? "",
                              location: event["note"] ?? "",
                              title: event["title"] ?? "",
                              image1: image1,
                              image2: image2,
                              description: event["description"] ?? "",
                              fromDate: event["from_date"] ?? "",
                              toDate: event["to_date"] ?? "",
                              icon: Icons.thumb_up_alt_outlined,
                              eventId: event["id"],
                              likesCount: event["likes_count"] ?? 0,
                              isLiked: event["is_liked"] ?? false,
                              onLike: toggleEventLike,
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

                      // STUDENTS
                      const Text(
                        "Suggested Students",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 210,
                        child: studentsLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : studentsNoData
                            ? const Center(
                                child: Text(
                                  "No Students found",
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
                                  onFollow: sendFollowRequest,
                                  onCancelPending: cancelPendingRequest,
                                  onUnfollow: unfollowCoach, // same API
                                  refreshParent: () => setState(() {}),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav_student(
        currentIndex: 0, // Home tab
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
            borderRadius: BorderRadius.circular(25),
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
              MaterialPageRoute(builder: (context) => const UserProducts()),
            );
          }
        },
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
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
  required String clubName,
  required String clubImage,

  required String location,
  required String title,
  required String image1,
  required String image2,
  required String description,
  required IconData icon,
  required String fromDate,
  required String toDate,
  required int eventId,
  required int likesCount,
  required bool isLiked,

  required Function(int) onLike,
}) {
  print("FROM DATE: $fromDate");
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
                  formatEventDate(fromDate),
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

        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Builder(
                  builder: (innerContext) => GestureDetector(
                    onTap: () => showImagePopup(innerContext, image1),
                    child: Image.network(
                      image1,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 110,
                        color: Colors.black26,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Builder(
                  builder: (innerContext) => GestureDetector(
                    onTap: () => showImagePopup(innerContext, image2),
                    child: Image.network(
                      image2,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 110,
                        color: Colors.black26,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            const Icon(Icons.info, color: Colors.amberAccent, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.thumb_up_alt,
                color: isLiked ? Colors.tealAccent : Colors.white70,
                size: 22,
              ),
              onPressed: () {
                onLike(eventId);
              },
            ),
          ],
        ),
      ],
    ),
  );
}

Future<bool> confirmLeaveClub(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Leave Club?",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Are you sure you want to leave this club?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text(
                  "Leave",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ) ??
      false;
}

Widget buildClubCardFromApi(
  Map club, {
  required Function(int) onJoinClub,
  required Function(int) onLeaveClub,
  required BuildContext context,
}) {
  String title = club["club_name"] ?? "Club";
  int clubId = club["id"];
  String? img = club["image"];
  String imageUrl = (img != null && img.isNotEmpty) ? "$api$img" : "";

  String? status = club["approval_status"];

  bool isApproved = status == "approved";
  bool isPending = status == "pending";

  String buttonText;
  Color buttonColor;
  VoidCallback? onTap;

  if (isApproved) {
    buttonText = "Joined";
    buttonColor = Colors.redAccent;
    onTap = () async {
      final confirmed = await confirmLeaveClub(context);
      if (confirmed) {
        onLeaveClub(clubId);
      }
    };
  } else if (isPending) {
    buttonText = "Requested";
    buttonColor = Colors.orange;
    onTap = null; // ❌ disabled
  } else {
    buttonText = "Join Club";
    buttonColor = Colors.teal;
    onTap = () => onJoinClub(clubId); 
  }

  return Container(
    width: 160,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
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

        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
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
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
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
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.thumb_up_alt_outlined,
              color: Colors.tealAccent,
              size: 14,
            ),
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
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
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

class StudentCard extends StatelessWidget {
  final Map student;

  const StudentCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
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
            standard,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // TODO: student follow API call (can be added later)
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00AFA5), // teal
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text(
              "Follow",
              style: TextStyle(color: Colors.white, fontSize: 14),
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

    int studentId = student["id"];

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
            standard,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: _buildButton(studentId)),
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
        await widget.onCancelPending(userId);
        widget.refreshParent();
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("Requested", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _followingBtn(int userId) {
    return OutlinedButton(
      onPressed: () async {
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

String formatDisplayDate(String date) {
  final parsed = DateTime.parse(date);
  return DateFormat('dd-MM-yyyy').format(parsed);
}

String formatEventDate(String date) {
  if (date.isEmpty) return "";
  try {
    final parsed = DateTime.parse(date);
    return DateFormat('MMM dd yyy').format(parsed);
  } catch (e) {
    print("Date parsing error:$e");
    return date;
  }
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
  VoidCallback? onRegister, // 👈 NEW
  required bool isRegistered,
  required trainingId,
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

              // Row(
              //   children: [
              //     const Icon(
              //       Icons.access_time,
              //       size: 12,
              //       color: Colors.tealAccent,
              //     ),
              //     const SizedBox(width: 6),
              //     Text(
              //       "${formatDisplayTime(startTime)} - ${formatDisplayTime(endTime)}",
              //       style: const TextStyle(color: Colors.white70, fontSize: 11),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 10),

              // ✅ REGISTER BUTTON
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 34,
                  child: isRegistered
                      ? OutlinedButton(
                          onPressed: null, // ✅ DISABLED
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                          ),
                          child: const Text(
                            "Registered",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: onRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AFA5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Register",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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

import 'dart:async';
import 'dart:ui';
import 'package:my_skates/ADMIN/admin_orders_page.dart';
import 'package:my_skates/COACH/club_detailed_view.dart';
import 'package:my_skates/COACH/coach_chat_support.dart';
import 'package:my_skates/COACH/coach_home_feedcard.dart';
import 'package:my_skates/COACH/coach_timeline_page.dart';
import 'package:my_skates/COACH/used_products.dart';
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
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:intl/intl.dart';
import 'package:my_skates/widgets/coachfeedcommentsheet.dart';
import 'package:share_plus/share_plus.dart';

class CoachHomepage extends StatefulWidget {
  const CoachHomepage({super.key});

  @override
  State<CoachHomepage> createState() => _CoachHomepageState();
}

class _CoachHomepageState extends State<CoachHomepage> {
  int? _myId;

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
  int notificationUnreadCount = 0;

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

  List<Map<String, dynamic>> homeFeeds = [];
  bool homeFeedsLoading = true;
  bool homeFeedsNoData = false;

  Offset _fabOffset = const Offset(20, 520);
  bool _fabMenuOpen = false;

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadMyId();
    fetchcoachDetails();
    getbanner();
    fetchNotificationCount();
    fetchClubs();
    loadEvents();
    getAllEvents();
    getTrainingSessions();

    fetchHomeFeeds();

    loadEverything();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        fetchNotificationCount();
      }
    });
  }

  Future<void> _loadMyId() async {
    _myId = await getUserId();
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      fetchcoachDetails(),
      getbanner(),
      fetchNotificationCount(),
      fetchClubs(),
      loadEvents(),
      getTrainingSessions(),
      fetchHomeFeeds(),
      fetchFollowStatus().then((_) async {
        await fetchCoaches();
        await fetchStudents();
      }),
    ]);
  }

  Map<String, dynamic> safeMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  int safeInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  int getFeedOwnerId(Map<String, dynamic> feed) {
    // Some APIs return user as int
    if (feed["user"] is int) return safeInt(feed["user"]);

    // Some APIs return user as object
    if (feed["user"] is Map) {
      return safeInt(feed["user"]["id"]);
    }

    // Some APIs return created_by as object
    if (feed["created_by"] is Map) {
      return safeInt(feed["created_by"]["id"]);
    }

    // Some APIs return author as object
    if (feed["author"] is Map) {
      return safeInt(feed["author"]["id"]);
    }

    // Extra possible keys
    return safeInt(
      feed["user_id"] ??
          feed["created_by_id"] ??
          feed["author_id"] ??
          feed["posted_by"],
    );
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        // Home (already here)
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
          MaterialPageRoute(
            builder: (_) => const CoachChatSupport(from: "coach"),
          ),
        );
        break;

      case 3:
        Navigator.pushReplacement(
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

  Future<void> fetchNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final userId = prefs.getInt("id") ?? prefs.getInt("user_id");

      if (token == null) return;

      final response = await http.get(
        Uri.parse("$api/api/myskates/notifications/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded["data"] ?? [];

        final filteredUnreadCount = data.where((e) {
          final type = e["notification_type"];

          if (type == "follow_back_accepted") return false;

          if (type == "follow_approved" && e["actor"] == userId) {
            return false;
          }

          return e["is_read"] == false;
        }).length;

        setState(() {
          notificationUnreadCount = filteredUnreadCount;
        });
      }
    } catch (e) {
      print("Notification count error: $e");
    }
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
          studentRole = user["u_name"] ?? "User";
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
          final filtered = decoded.where((c) => c["id"] != _myId).toList();
          setState(() {
            coaches = filtered;
            coachesNoData = filtered.isEmpty;
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
          "images": e["images"],
          "likes_count": e["likes_count"] ?? 0,
          "is_liked": e["is_liked"] ?? false,
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

        final filtered = data.where((s) => s["id"] != _myId).toList();

        setState(() {
          students = filtered
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

  Future<void> toggleEventLike(int eventId) async {
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

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

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
      print(" followStudent() called with studentId=$studentId");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.post(
        Uri.parse("$api/api/myskates/user/follow/request/"),
        headers: {"Authorization": "Bearer $token"},
        body: {"following_id": studentId.toString()},
      );

      print(" FOLLOW API STATUS: ${response.statusCode}");
      print(" FOLLOW API BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        print(" FOLLOW RESPONSE PARSEDDD: $decoded");

        if (decoded["status"] == "pending") {
          setState(() {
            if (!myRequests.contains(studentId)) {
              myRequests.add(studentId);
            }
          });
          print("STATE UPDATE → myRequests=$myRequests");
        }

        if (decoded["status"] == "approved") {
          setState(() {
            myApprovedSent.add(studentId);
            myRequests.remove(studentId);
          });
          print(" STATE UPDATE → myApprovedSent=$myApprovedSent");
        }
      }
    } catch (e) {
      print(" FOLLOW STUDENT ERROR: $e");
    }
  }

  Future<void> cancelPendingRequest(int userId) async {
    print(" cancelPendingRequest() called for userId=$userId");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final response = await http.post(
      Uri.parse('$api/api/myskates/user/follow/cancel/'),
      headers: {"Authorization": "Bearer $token"},
      body: {"following_id": userId.toString()},
    );

    print(" CANCEL REQUEST STATUS: ${response.statusCode}");
    print(" CANCEL REQUEST BODY: ${response.body}");

    setState(() {
      myRequests.remove(userId);
    });

    print("🧹 STATE UPDATE → myRequests=$myRequests");
  }

  Future<void> unfollowUser(int userId) async {
    print(" unfollowUser() called for userId=$userId");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final response = await http.post(
      Uri.parse('$api/api/myskates/user/unfollow/'),
      headers: {"Authorization": "Bearer $token"},
      body: {"following_id": userId.toString()},
    );

    print(" UNFOLLOW STATUS: ${response.statusCode}");
    print(" UNFOLLOW BODY: ${response.body}");

    setState(() {
      myFollowing.remove(userId);
      myApprovedSent.remove(userId);
      myRequests.remove(userId);
    });

    print(" STATE UPDATE → myFollowing=$myFollowing");
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
      myFollowing.remove(coachId);
      myApprovedSent.remove(coachId);
      myRequests.remove(coachId);
    });
  }

  void pushWithSlide(Widget page) {
    Navigator.push(context, slideRightToLeftRoute(page));
  }

  Widget _buildClubShimmer() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.25,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFF001A18),
            highlightColor: const Color(0xFF001A18),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> fetchHomeFeeds() async {
    try {
      if (!mounted) return;

      setState(() {
        homeFeedsLoading = true;
        homeFeedsNoData = false;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id") ?? prefs.getInt("user_id");

      if (token == null || userId == null) {
        if (!mounted) return;
        setState(() {
          homeFeeds = [];
          homeFeedsLoading = false;
          homeFeedsNoData = true;
        });
        return;
      }

      // ✅ HOME PAGE: fetch all posts
      final response = await http.get(
        Uri.parse("$api/api/myskates/feeds/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("HOME ALL FEEDS STATUS: ${response.statusCode}");
      print("HOME ALL FEEDS BODY: ${response.body}");

      List<Map<String, dynamic>> allFeeds = [];

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List data = decoded is List
            ? decoded
            : decoded["data"] ?? decoded["results"] ?? [];

        allFeeds = data
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      }

      // ✅ IMPORTANT FIX:
      // Homepage should show only OTHER PEOPLE'S posts.
      final List<Map<String, dynamic>> otherPeopleFeeds = allFeeds.where((
        feed,
      ) {
        final ownerId = getFeedOwnerId(feed);
        return ownerId != userId;
      }).toList();

      otherPeopleFeeds.sort((a, b) {
        final aDate = (a["created_at"] ?? "").toString();
        final bDate = (b["created_at"] ?? "").toString();

        final aTime =
            DateTime.tryParse(aDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            DateTime.tryParse(bDate) ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bTime.compareTo(aTime);
      });

      if (!mounted) return;

      setState(() {
        homeFeeds = otherPeopleFeeds;
        homeFeedsLoading = false;
        homeFeedsNoData = otherPeopleFeeds.isEmpty;
      });

      print("HOME OTHER PEOPLE FEED COUNT: ${otherPeopleFeeds.length}");
    } catch (e) {
      print("FETCH HOME FEEDS ERROR: $e");

      if (!mounted) return;

      setState(() {
        homeFeeds = [];
        homeFeedsLoading = false;
        homeFeedsNoData = true;
      });
    }
  }

  Future<void> toggleHomeFeedLike(int feedId) async {
    final index = homeFeeds.indexWhere((feed) {
      final bool isRepostFeed = feed["feed"] != null;
      final actualFeed = isRepostFeed ? feed["feed"] : feed;
      return actualFeed["id"] == feedId;
    });

    if (index == -1) return;

    final bool isRepostFeed = homeFeeds[index]["feed"] != null;

    final Map<String, dynamic> displayFeed = isRepostFeed
        ? Map<String, dynamic>.from(homeFeeds[index]["feed"])
        : Map<String, dynamic>.from(homeFeeds[index]);

    final bool wasLiked = displayFeed["is_liked"] == true;
    final int oldLikeCount = displayFeed["likes_count"] ?? 0;

    setState(() {
      displayFeed["is_liked"] = !wasLiked;
      displayFeed["likes_count"] = wasLiked
          ? oldLikeCount - 1
          : oldLikeCount + 1;

      if (isRepostFeed) {
        homeFeeds[index]["feed"] = displayFeed;
      } else {
        homeFeeds[index] = displayFeed;
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.post(
        Uri.parse("$api/api/myskates/feeds/$feedId/like/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        setState(() {
          displayFeed["is_liked"] = wasLiked;
          displayFeed["likes_count"] = oldLikeCount;

          if (isRepostFeed) {
            homeFeeds[index]["feed"] = displayFeed;
          } else {
            homeFeeds[index] = displayFeed;
          }
        });
      }
    } catch (e) {
      debugPrint("HOME FEED LIKE ERROR: $e");

      setState(() {
        displayFeed["is_liked"] = wasLiked;
        displayFeed["likes_count"] = oldLikeCount;

        if (isRepostFeed) {
          homeFeeds[index]["feed"] = displayFeed;
        } else {
          homeFeeds[index] = displayFeed;
        }
      });
    }
  }

  Future<void> toggleHomeFeedRepost(int feedId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) return;

      final response = await http.post(
        Uri.parse("$api/api/myskates/feeds/repost/$feedId/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("HOME FEED REPOST STATUS: ${response.statusCode}");
      print("HOME FEED REPOST BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchHomeFeeds();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reposted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to repost"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("HOME FEED REPOST ERROR: $e");
    }
  }

  void shareHomeFeed(Map<String, dynamic> displayFeed, int feedId) {
    final String desc = (displayFeed["description"] ?? "").toString().trim();

    final String deepLink = "https://myskates.app/feed/$feedId";

    final String shareText = [
      if (desc.isNotEmpty) desc,
      "",
      "Open in MySkates 👇",
      deepLink,
    ].join("\n");

    Share.share(shareText, subject: "MySkates Feed");
  }

  Widget buildHomeFeedsSection() {
    if (homeFeedsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2EE6A6)),
        ),
      );
    }

    if (homeFeedsNoData || homeFeeds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF2EE6A6),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Latest Posts",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2EE6A6).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2EE6A6).withOpacity(0.35),
                ),
              ),
              child: Text(
                "${homeFeeds.length} posts",
                style: const TextStyle(
                  color: Color(0xFF2EE6A6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...homeFeeds.map((feed) {
          return buildHomeFeedCard(feed);
        }).toList(),
      ],
    );
  }

  Widget buildHomeFeedCard(Map<String, dynamic> feed) {
    final bool isRepostFeed = feed["feed"] != null && feed["feed"] is Map;

    final Map<String, dynamic> displayFeed = isRepostFeed
        ? Map<String, dynamic>.from(feed["feed"])
        : Map<String, dynamic>.from(feed);

    final int actualFeedId = safeInt(displayFeed["id"]);

    final List images = displayFeed["feed_image"] is List
        ? displayFeed["feed_image"]
        : [];

    final int likeCount = safeInt(displayFeed["likes_count"]);
    final int repostCount = safeInt(displayFeed["shares_count"]);
    final int commentCount = safeInt(displayFeed["comments_count"]);

    final bool isLiked = displayFeed["is_liked"] == true;
    final bool isReposted =
        feed["is_reposted"] == true || displayFeed["is_reposted"] == true;

    final Map<String, dynamic> user = safeMap(displayFeed["user"]).isNotEmpty
        ? safeMap(displayFeed["user"])
        : safeMap(displayFeed["created_by"]).isNotEmpty
        ? safeMap(displayFeed["created_by"])
        : safeMap(displayFeed["author"]);

    final String apiUserName = (displayFeed["user_name"] ?? "").toString();

    final String firstName = (user["first_name"] ?? "").toString();
    final String lastName = (user["last_name"] ?? "").toString();

    final String fullName = "$firstName $lastName".trim();

    final String userName = apiUserName.isNotEmpty
        ? apiUserName
        : fullName.isNotEmpty
        ? fullName
        : "MySkates User";

    final String profile =
        (displayFeed["profile"] ??
                user["profile"] ??
                user["profile_image"] ??
                "")
            .toString();

    final String description = (displayFeed["description"] ?? "")
        .toString()
        .trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.13),
                  Colors.white.withOpacity(0.055),
                  const Color(0xFF003E38).withOpacity(0.30),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.13),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRepostFeed)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2EE6A6).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFF2EE6A6).withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.repeat,
                                size: 15,
                                color: Color(0xFF2EE6A6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${feed["reposted_by"]?["first_name"] ?? "Someone"} reposted this",
                                style: const TextStyle(
                                  color: Color(0xFFBFFFEF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2EE6A6), Color(0xFF00AFA5)],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 23,
                              backgroundColor: Colors.black,
                              backgroundImage: profile.isNotEmpty
                                  ? NetworkImage(
                                      profile.startsWith("http")
                                          ? profile
                                          : "$api$profile",
                                    )
                                  : const AssetImage("lib/assets/img.jpg")
                                        as ImageProvider,
                            ),
                          ),

                          const SizedBox(width: 11),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.public,
                                      size: 12,
                                      color: Colors.white.withOpacity(0.48),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Shared on MySkates",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.48),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            child: const Icon(
                              Icons.more_horiz,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ],
                      ),

                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: 13.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (images.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 235,
                    child: PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (context, imgIndex) {
                        final imgData = images[imgIndex];

                        final String img = imgData is Map
                            ? (imgData["image"] ?? "").toString()
                            : imgData.toString();

                        final String imageUrl = img.startsWith("http")
                            ? img
                            : "$api$img";

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                debugPrint("POST IMAGE CLICKED: $imageUrl");
                                showHomeFeedImagePopup(context, imageUrl);
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return Container(
                                        color: Colors.white10,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.white54,
                                            size: 34,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  Positioned.fill(
                                    child: IgnorePointer(
                                      ignoring: true,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.18),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => toggleHomeFeedLike(actualFeedId),
                          child: _feedActionButton(
                            icon: isLiked
                                ? Icons.thumb_up
                                : Icons.thumb_up_alt_outlined,
                            count: likeCount,
                            active: isLiked,
                          ),
                        ),

                        const SizedBox(width: 12),

                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => toggleHomeFeedRepost(actualFeedId),
                          child: _feedActionButton(
                            icon: isReposted
                                ? Icons.repeat
                                : Icons.repeat_outlined,
                            count: repostCount,
                            active: isReposted,
                          ),
                        ),

                        const SizedBox(width: 12),

                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) =>
                                  FeedCommentsSheet(feedId: actualFeedId),
                            );

                            fetchHomeFeeds();
                          },
                          child: _feedActionButton(
                            icon: Icons.chat_bubble_outline,
                            count: commentCount,
                            active: false,
                          ),
                        ),

                        const Spacer(),

                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => shareHomeFeed(displayFeed, actualFeedId),
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            child: const Icon(
                              Icons.share_outlined,
                              color: Colors.white70,
                              size: 19,
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
      ),
    );
  }

  Widget _feedActionButton({
    required IconData icon,
    required int count,
    required bool active,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF2EE6A6).withOpacity(0.13)
            : Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? const Color(0xFF2EE6A6).withOpacity(0.35)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? const Color(0xFF2EE6A6) : Colors.white70,
            size: 19,
          ),
          const SizedBox(width: 5),
          Text(
            "$count",
            style: TextStyle(
              color: active ? const Color(0xFF2EE6A6) : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void showHomeFeedImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.88),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          height: 260,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 42,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrainingShimmer() {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFF001A18),
            highlightColor: const Color(0xFF00AFA5).withOpacity(0.25),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventShimmer() {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFF001A18),
            highlightColor: const Color(0xFF00AFA5).withOpacity(0.25),
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoachShimmer() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.28,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFF001A18),
            highlightColor: const Color(0xFF00AFA5).withOpacity(0.25),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateFromFab(Widget page) async {
    setState(() => _fabMenuOpen = false);

    await Future.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    await Navigator.push(context, slideRightToLeftRoute(page));
  }

  Widget _movableFabMenu() {
    final size = MediaQuery.of(context).size;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    const double fabSize = 56;
    const double sideMargin = 12;
    const double topLimit = 100;
    const double bottomNavHeight = 90;

    const double openMenuExtraHeight = 250;

    final double maxX = size.width - fabSize - sideMargin;
    final double maxYClosed =
        size.height - fabSize - bottomNavHeight - bottomSafe;
    final double maxYOpen =
        size.height -
        fabSize -
        bottomNavHeight -
        bottomSafe -
        openMenuExtraHeight;

    double dx = _fabOffset.dx.clamp(sideMargin, maxX);
    double dy = _fabOffset.dy.clamp(
      topLimit,
      _fabMenuOpen ? maxYOpen : maxYClosed,
    );

    final bool openToLeft = dx > size.width / 2;

    return Positioned(
      left: dx,
      top: dy,
      child: Column(
        crossAxisAlignment: openToLeft
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _fabMenuOpen
                ? Column(
                    key: const ValueKey("openMenu"),
                    crossAxisAlignment: openToLeft
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      _fabMiniItem(
                        icon: Icons.person,
                        label: "Profile",
                        openToLeft: openToLeft,
                        onTap: () => _navigateFromFab(const ProfilePage()),
                      ),
                      const SizedBox(height: 10),
                      _fabMiniItem(
                        icon: Icons.settings,
                        label: "Settings",
                        openToLeft: openToLeft,
                        onTap: () => _navigateFromFab(const CoachSettings()),
                      ),
                      const SizedBox(height: 10),
                      _fabMiniItem(
                        icon: Icons.chat_bubble_outline,
                        label: "Support",
                        openToLeft: openToLeft,
                        onTap: () => _navigateFromFab(
                          const CoachChatSupport(from: "coach"),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _fabMiniItem(
                        icon: Icons.notifications_none,
                        label: "Notifications",
                        openToLeft: openToLeft,
                        onTap: () async {
                          await _navigateFromFab(const CoachNotificationPage());
                          fetchNotificationCount();
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                final next = _fabOffset + details.delta;

                _fabOffset = Offset(
                  next.dx.clamp(sideMargin, maxX),
                  next.dy.clamp(
                    topLimit.toDouble(),
                    _fabMenuOpen ? maxYOpen : maxYClosed,
                  ),
                );
              });
            },
            child: Align(
              alignment: openToLeft
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FloatingActionButton(
                heroTag: "movableFab",
                backgroundColor: const Color(0xFF00AFA5),
                onPressed: () {
                  setState(() {
                    _fabMenuOpen = !_fabMenuOpen;

                    if (_fabMenuOpen && _fabOffset.dy > maxYOpen) {
                      _fabOffset = Offset(_fabOffset.dx, maxYOpen);
                    }
                    if (_fabOffset.dx > maxX) {
                      _fabOffset = Offset(maxX, _fabOffset.dy);
                    }
                  });
                },
                child: Icon(
                  _fabMenuOpen ? Icons.close : Icons.skateboarding,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fabMiniItem({
    required IconData icon,
    required String label,
    required bool openToLeft,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 170),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: openToLeft
                ? [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.tealAccent, size: 18),
                  ]
                : [
                    Icon(icon, color: Colors.tealAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCoaches = coaches.where((coach) {
      final int id = coach["id"] ?? 0;
      return !myFollowing.contains(id) && !myApprovedSent.contains(id);
    }).toList();

    final filteredStudents = students.where((student) {
      final int id = student["id"] ?? 0;
      return !myFollowing.contains(id) && !myApprovedSent.contains(id);
    }).toList();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
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
            // child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshAll,
              color: Colors.tealAccent,
              backgroundColor: Colors.black,
              child: CustomScrollView(
                slivers: [
                  // ---------------------------------------------------------
                  // PINNED HEADER (STAYS FIXED WHILE SCROLLING)
                  // ---------------------------------------------------------
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    snap: false,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    toolbarHeight: 86,
                    expandedHeight: 86,
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,

                    flexibleSpace: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF001F1C).withOpacity(0.95),
                                const Color(0xFF001F1C).withOpacity(0.60),
                                Colors.black.withOpacity(0.50),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    titleSpacing: 16,
                    title: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            pushWithSlide(const CoachMenuPage());
                          },
                          child: CircleAvatar(
                            radius: 26,
                            backgroundImage:
                                studentImage != null && studentImage!.isNotEmpty
                                ? NetworkImage("$api$studentImage")
                                : const AssetImage("lib/assets/img.jpg")
                                      as ImageProvider,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName.isEmpty ? "Coach" : studentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                studentRole.isEmpty ? "Coach" : studentRole,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Stack(
                          children: [
                            IconButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  slideRightToLeftRoute(
                                    const CoachNotificationPage(),
                                  ),
                                );
                                fetchNotificationCount();
                              },
                              icon: const Icon(
                                Icons.notifications_none,
                                color: Colors.tealAccent,
                              ),
                            ),
                            if (notificationUnreadCount > 0)
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
                                    notificationUnreadCount.toString(),
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

                  // ---------------------------------------------------------
                  // ALL YOUR PAGE CONTENT AS IT IS
                  // ---------------------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // if (!trainingLoading &&
                          //     trainingSessions.isEmpty &&
                          //     !eventsLoading &&
                          //     events.isEmpty &&
                          //     !coachesLoading &&
                          //     coaches.isEmpty &&
                          //     !studentsLoading &&
                          //     students.isEmpty)
                          //   const SizedBox.shrink()
                          // else ...[
                          Container(
                            height: MediaQuery.of(context).size.height * 0.2,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: Colors.black.withOpacity(0.25),
                              //     blurRadius: 8,
                              //     offset: Offset(0, 4),
                              //   ),
                              // ],
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
                                          loadingBuilder:
                                              (context, child, progress) {
                                                if (progress == null)
                                                  return child;
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
                            "Weee offer training and an e-commerce platform\nthat connects students and coaches.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 25),

                          buildButton("Find Coaches"),
                          buildButton("Find Skaters"),
                          buildButton("Find Clubs"),
                          buildButton("Orders"),
                          buildButton("Find Events"),
                          buildButton("Buy and Sell products"),
                          buildButton("Used products"),

                          // const SizedBox(height: 25),

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
                          // SizedBox(height: 20),
                          // CLUBS
                          // const Text(
                          //   "Recommended Clubs near you",
                          //   style: TextStyle(
                          //     color: Colors.white,
                          //     fontSize: 16,
                          //     fontWeight: FontWeight.w600,
                          //   ),
                          // ),
                          // const SizedBox(height: 10),
                          // if (clubs.isEmpty && !noData)
                          //   _buildClubShimmer()
                          // else
                          //   SizedBox(
                          //     height: MediaQuery.of(context).size.height * 0.25,
                          //     child: ListView.builder(
                          //       scrollDirection: Axis.horizontal,
                          //       itemCount: clubs.length,
                          //       itemBuilder: (_, i) => Padding(
                          //         padding: const EdgeInsets.only(right: 12),
                          //         child: buildClubCardFromApi(context,clubs[i]),
                          //       ),
                          //     ),
                          //   ),
                          // const SizedBox(height: 20),
                          // const Text(
                          //   "Upcoming Training Sessions",
                          //   style: TextStyle(color: Colors.white, fontSize: 14),
                          // ),
                          const SizedBox(height: 15),

                          // ---------------- UPCOMING TRAINING SESSIONS ----------------
                          // Show shimmer only while loading.
                          // After loading, show section only if data exists.
                          if (trainingLoading) ...[
                            _buildTrainingShimmer(),
                            const SizedBox(height: 25),
                          ] else if (trainingSessions.isNotEmpty) ...[
                            const Text(
                              "Upcoming Training Sessions",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 15),

                            Column(
                              children: trainingSessions.map((session) {
                                final images = session['images'] as List? ?? [];
                                final imageUrl = images.isNotEmpty
                                    ? "$api${images[0]['image']}"
                                    : "";

                                return buildTrainingSessionRow(
                                  context: context,
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

                            const SizedBox(height: 25),
                          ],

                          // ---------------- LATEST POSTS ----------------
                          // Important: this must be outside training section.
                          if (homeFeedsLoading) ...[
                            buildHomeFeedsSection(),
                            const SizedBox(height: 25),
                          ] else if (homeFeeds.isNotEmpty) ...[
                            buildHomeFeedsSection(),
                            const SizedBox(height: 25),
                          ],

                          // ---------------- UPCOMING EVENTS ----------------
                          if (eventsLoading) ...[
                            _buildEventShimmer(),
                            const SizedBox(height: 25),
                          ] else if (events.isNotEmpty) ...[
                            const Text(
                              "Upcoming Events",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Column(
                              children: events.map((event) {
                                final images = event["images"] as List? ?? [];

                                final image1 = images.isNotEmpty
                                    ? "$api${images[0]['image']}"
                                    : "";
                                final image2 = images.length > 1
                                    ? "$api${images[1]['image']}"
                                    : "";

                                return buildEventCardWithImages(
                                  context: context,
                                  clubName:
                                      event["club_name"] ?? "Skating Club",
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
                                  eventId: event["id"],
                                  onLike: toggleEventLike,
                                  likesCount: event["likes_count"] ?? 0,
                                  isLiked: event["is_liked"] ?? false,
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 25),
                          ],

                          // ---------------- SUGGESTED COACHES ----------------
                          // Show shimmer while loading.
                          // After loading, hide full section if filteredCoaches is empty.
                          if (!followLoaded || coachesLoading) ...[
                            _buildCoachShimmer(),
                            const SizedBox(height: 25),
                          ] else if (filteredCoaches.isNotEmpty) ...[
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
                              height: MediaQuery.of(context).size.height * 0.28,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: filteredCoaches.length,
                                itemBuilder: (_, i) => CoachFollowCard(
                                  coach: filteredCoaches[i],
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

                            const SizedBox(height: 25),
                          ],

                          // ---------------- SUGGESTED STUDENTS ----------------
                          // Show shimmer while loading.
                          // After loading, hide full section if filteredStudents is empty.
                          if (studentsLoading) ...[
                            _buildCoachShimmer(),
                            const SizedBox(height: 25),
                          ] else if (filteredStudents.isNotEmpty) ...[
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
                              height: MediaQuery.of(context).size.height * 0.25,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: filteredStudents.length,
                                itemBuilder: (_, i) => StudentFollowCard(
                                  student: filteredStudents[i],
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ),
          ),
          _movableFabMenu(),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget buildButton(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.065,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00AFA5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: () {
          if (title == "Find Coaches") {
            pushWithSlide(const UserConnectCoaches());
          } else if (title == "Find Skaters") {
            pushWithSlide(const StudentList());
          } else if (title == "Find Clubs") {
            pushWithSlide(const ClubGridPage());
          } else if (title == "Orders") {
            pushWithSlide(const Admin_order_page());
          } else if (title == "Find Events") {
            pushWithSlide(const Events());
          } else if (title == "Buy and Sell products") {
            pushWithSlide(const UserApprovedProducts());
          } else if (title == "Used products") {
            pushWithSlide(const UsedProducts());
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

// CLUB CARD
Widget buildClubCardFromApi(BuildContext context, Map club) {
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
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ClubView(clubid: club["id"])),
            );
          },
          child: CircleAvatar(
            radius: 30,
            backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : const AssetImage("lib/assets/images.png") as ImageProvider,
          ),
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
            Icon(
              Icons.thumb_up_alt_outlined,
              color: Colors.tealAccent,
              size: 22,
            ),
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
  required int eventId,
  required int likesCount,
  required bool isLiked,

  required Function(int) onLike,
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
        EventImageSlider(
          images: [
            if (image1.isNotEmpty) image1,
            if (image2.isNotEmpty) image2,
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
          children: [
            Text(
              likesCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            IconButton(
              icon: Icon(
                Icons.thumb_up_alt,
                color: isLiked ? Colors.tealAccent : Colors.grey,
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

class EventImageSlider extends StatefulWidget {
  final List<String> images;

  const EventImageSlider({super.key, required this.images});

  @override
  State<EventImageSlider> createState() => _EventImageSliderState();
}

class _EventImageSliderState extends State<EventImageSlider> {
  int currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullImageViewer(int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              StatefulBuilder(
                builder: (context, setDialogState) {
                  final PageController dialogController = PageController(
                    initialPage: initialIndex,
                  );

                  return PageView.builder(
                    controller: dialogController,
                    itemCount: widget.images.length,
                    onPageChanged: (index) {
                      setDialogState(() {
                        currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.network(
                              widget.images[index],
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                                size: 60,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
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

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.white54),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openFullImageViewer(index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white10,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.images.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: currentPage == index ? 8 : 6,
              height: currentPage == index ? 8 : 6,
              decoration: BoxDecoration(
                color: currentPage == index
                    ? Colors.tealAccent
                    : Colors.white38,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
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

    String institution = student["institution"] ?? "";

    String imageUrl =
        student["profile"] != null && student["profile"].toString().isNotEmpty
        ? "$api${student["profile"]}"
        : "";

    return Container(
      width: 160,
      height: 200,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : const AssetImage("lib/assets/img.jpg") as ImageProvider,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              if (institution.isNotEmpty)
                Text(
                  institution,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              const SizedBox(height: 2),
              Text(
                standard,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _buildButton(userId),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(int userId) {
    if (widget.myFollowing.contains(userId) ||
        widget.myApprovedSent.contains(userId)) {
      return _followingBtn(userId);
    }

    if (widget.myRequests.contains(userId)) {
      return _requestedBtn(userId);
    }

    return _followBtn(userId);
  }

  Widget _followingBtn(int userId) {
    return GestureDetector(
      onTap: () async {
        await widget.onUnfollow(userId);
        widget.refreshParent();
      },
      child: const Text(
        "Following",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _requestedBtn(int userId) {
    return GestureDetector(
      onTap: () async {
        await widget.onCancelPending(userId);
        widget.refreshParent();
      },
      child: const Text(
        "Requested",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _followBtn(int userId) {
    return GestureDetector(
      onTap: () async {
        await widget.onFollow(userId);
        widget.refreshParent();
      },
      child: const Text(
        "Follow",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
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
      height: 200,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserConnectCoaches()),
                  );
                },
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : const AssetImage("lib/assets/img.jpg") as ImageProvider,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                exp,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _buildButton(coachId),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(int coachId) {
    if (widget.myFollowing.contains(coachId) ||
        widget.myApprovedSent.contains(coachId)) {
      return _followingBtn(coachId);
    }

    if (widget.myRequests.contains(coachId)) {
      return _requestedBtn(coachId);
    }

    return _followBtn(coachId);
  }

  Widget _followingBtn(int coachId) {
    return GestureDetector(
      onTap: () async {
        await widget.onUnfollow(coachId);
        widget.refreshParent();
      },
      child: const Text(
        "Following",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _requestedBtn(int coachId) {
    return GestureDetector(
      onTap: () async {
        await widget.onCancelPending(coachId);
        widget.refreshParent();
      },
      child: const Text(
        "Requested",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _followBtn(int coachId) {
    return GestureDetector(
      onTap: () async {
        await widget.onFollow(coachId);
        widget.refreshParent();
      },
      child: const Text(
        "Follow",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
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
  required BuildContext context,
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
        // LEFT IMAGE (CLICKABLE)
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: GestureDetector(
            onTap: () {
              if (imageUrl.isNotEmpty) {
                showImagePopup(context, imageUrl);
              }
            },
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

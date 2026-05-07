import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/view_all_events.dart';
import 'package:my_skates/COACH/club_detailed_view.dart';
import 'package:my_skates/COACH/club_list.dart';
import 'package:my_skates/COACH/coach_details_page.dart';
import 'package:my_skates/COACH/used_products.dart';
// import 'package:my_skates/STUDENTS/bottomnavigation_student.dart';
import 'package:my_skates/STUDENTS/products.dart';
import 'package:my_skates/STUDENTS/student_list.dart';
import 'package:my_skates/STUDENTS/user_chat_support.dart';
import 'package:my_skates/STUDENTS/user_menu_page.dart';
import 'package:my_skates/STUDENTS/user_notification%20page.dart';
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
import 'dart:async';
import 'package:my_skates/widgets/coachfeedcommentsheet.dart';
import 'package:share_plus/share_plus.dart';

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
  int notificationUnreadCount = 0;
  Timer? _timer;
  bool trainingLoading = true;
  bool trainingNoData = false;

  List<Map<String, dynamic>> homeFeeds = [];
  bool homeFeedsLoading = true;
  bool homeFeedsNoData = false;

  Offset _fabOffset = const Offset(20, 520);
  bool _fabMenuOpen = false;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  initState() {
    super.initState();

    fetchStudentDetails().then((_) {
      refreshUserProfile();
    });

    fetchClubs();
    loadEvents();
    getbanner();
    getTrainingSessions();
    fetchRegisteredTrainings();
    loadEverything();
    fetchNotificationCount();

    fetchHomeFeeds();

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        fetchNotificationCount();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadUserData() async {
    await refreshUserProfile();
    fetchStudentDetails();
  }

  Future<void> _refreshData() async {
    await Future.wait([
      fetchStudentDetails(),
      fetchClubs(),
      loadEvents(),
      refreshUserProfile(),
      getbanner(),
      getTrainingSessions(),
      fetchRegisteredTrainings(),
      loadEverything(),
      fetchNotificationCount(),

      fetchHomeFeeds(),
    ]);

    if (mounted) {
      setState(() {});
    }
  }

  // Future<void> loadEverything() async {
  //   await fetchFollowStatus();
  //   await fetchCoaches();
  //   await fetchStudents();
  //   setState(() {});
  // }

  Future<void> loadEverything() async {
    await fetchFollowStatus();
    await Future.wait([fetchCoaches(), fetchStudents()]);
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

  Future<void> _navigateFromFab(Widget page) async {
    setState(() => _fabMenuOpen = false);

    await Future.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    await Navigator.push(context, slideRightToLeftRoute(page));
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access');
  }

  Future<void> fetchNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

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

        final unreadCount = data.where((e) {
          return e["is_read"] == false;
        }).length;

        setState(() {
          notificationUnreadCount = unreadCount;
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
        await fetchClubs();

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
    // Find the current feed to get its current repost state
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

    final bool isAlreadyReposted = displayFeed["is_reposted"] == true;

    // Show bottom sheet for repost with comment
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RepostCommentSheet(
        feedId: feedId,
        isAlreadyReposted: isAlreadyReposted,
        onRepostSuccess: () {
          // Refresh feeds after successful repost
          fetchHomeFeeds();
        },
      ),
    );
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

  Future<void> toggleEventLike(int eventId) async {
    final token = await getToken();
    if (token == null) return;

    final index = events.indexWhere((e) => e["id"] == eventId);
    if (index == -1) return;

    final bool wasLiked = events[index]["is_liked"] == true;
    final int currentLikes = events[index]["likes_count"] ?? 0;

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

      if (response.statusCode != 200 && response.statusCode != 201) {
        setState(() {
          events[index]["is_liked"] = wasLiked;
          events[index]["likes_count"] = currentLikes;
        });
      }
    } catch (e) {
      setState(() {
        events[index]["is_liked"] = wasLiked;
        events[index]["likes_count"] = currentLikes;
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
            students = decoded.where((s) => s["id"] != loggedInUserId).toList();
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

  // Future<void> fetchFollowStatus() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString("access");

  //     print("================ FETCH FOLLOW STATUS START ================");

  //     var rPending = await http.get(
  //       Uri.parse("$api/api/myskates/user/follow/sent/"),
  //       headers: {"Authorization": "Bearer $token"},
  //     );
  //     print("PENDINGGG: ${rPending.body}");

  //     if (rPending.statusCode == 200) {
  //       final dataPending = jsonDecode(rPending.body);
  //       myRequests = List<int>.from(
  //         (dataPending as List).map((e) => e["following"]),
  //       );
  //     }

  //     var rApproved = await http.get(
  //       Uri.parse("$api/api/myskates/user/follow/sent/approved/"),
  //       headers: {"Authorization": "Bearer $token"},
  //     );
  //     print("APPROVED SENT: ${rApproved.body}");

  //     if (rApproved.statusCode == 200) {
  //       final dataApproved = jsonDecode(rApproved.body);
  //       myApprovedSent = List<int>.from(
  //         (dataApproved as List).map((e) => e["following"]),
  //       );
  //     }

  //     followLoaded = true;
  //     setState(() {});
  //   } catch (e) {
  //     print("ERROR IN FOLLOW STATUS: $e");
  //   }
  // }

  Future<void> fetchFollowStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        print("No token found");
        followLoaded = true;
        myRequests = [];
        myApprovedSent = [];
        myFollowing = [];
        setState(() {});
        return;
      }

      print("================ FETCH FOLLOW STATUS START ================");

      // Initialize empty lists
      myRequests = [];
      myApprovedSent = [];
      myFollowing = [];

      // Fetch pending requests
      var rPending = await http.get(
        Uri.parse("$api/api/myskates/user/follow/sent/"),
        headers: {"Authorization": "Bearer $token"},
      );
      print("PENDING STATUS: ${rPending.statusCode}");
      print("PENDING RESPONSE: ${rPending.body}");

      if (rPending.statusCode == 200) {
        final dataPending = jsonDecode(rPending.body);
        if (dataPending is List) {
          myRequests = List<int>.from(
            dataPending.map((e) => e["following"]).where((id) => id != null),
          );
        }
      }

      // Fetch approved sent requests
      var rApproved = await http.get(
        Uri.parse("$api/api/myskates/user/follow/sent/approved/"),
        headers: {"Authorization": "Bearer $token"},
      );
      print("APPROVED STATUS: ${rApproved.statusCode}");
      print("APPROVED RESPONSE: ${rApproved.body}");

      if (rApproved.statusCode == 200) {
        final dataApproved = jsonDecode(rApproved.body);
        if (dataApproved is List) {
          myApprovedSent = List<int>.from(
            dataApproved.map((e) => e["following"]).where((id) => id != null),
          );
        }
      }

      // Fetch following list
      var rFollowing = await http.get(
        Uri.parse("$api/api/myskates/user/following/"),
        headers: {"Authorization": "Bearer $token"},
      );
      print("FOLLOWING STATUS: ${rFollowing.statusCode}");
      print("FOLLOWING RESPONSE: ${rFollowing.body}");

      if (rFollowing.statusCode == 200) {
        final dataFollowing = jsonDecode(rFollowing.body);
        if (dataFollowing is List) {
          myFollowing = List<int>.from(
            dataFollowing.map((e) => e["following"]).where((id) => id != null),
          );
        }
      }

      followLoaded = true;
      print("myRequests: $myRequests");
      print("myApprovedSent: $myApprovedSent");
      print("myFollowing: $myFollowing");

      setState(() {});
    } catch (e) {
      print("ERROR IN FOLLOW STATUS: $e");
      // Even on error, set followLoaded to true to show coaches section
      followLoaded = true;
      myRequests = [];
      myApprovedSent = [];
      myFollowing = [];
      setState(() {});
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
      myRequests.add(coachId);
      await fetchCoaches();
      setState(() {});
    }
  }

  Future<void> refreshUserProfile() async {
    String? token = await getToken();

    // Use the correct endpoint that returns student data
    final res = await http.get(
      Uri.parse("$api/api/myskates/student/details/"),
      headers: {"Authorization": "Bearer $token"},
    );

    print("PROFILE STATUS: ${res.statusCode}");
    print("PROFILE BODY: ${res.body}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      final prefs = await SharedPreferences.getInstance();

      // IMPORTANT: Clear old user data first
      // Don't clear all preferences as that would remove the token too
      // Just remove the user-specific keys
      // await prefs.remove("name");
      // await prefs.remove("u_name");
      // await prefs.remove("profile");
      // await prefs.remove("user_id");
      // await prefs.remove("id");

      final currentUserId = prefs.getInt("id");

      print("Logged-in User ID: $currentUserId");

      // Find the current user in the list
      Map<String, dynamic>? userData;

      if (currentUserId != null) {
        userData = data.firstWhere(
          (student) => student["id"] == currentUserId,
          orElse: () => {},
        );
      }

      if (userData == null || userData.isEmpty) {
        print("User not found in list");
        return;
      }

      // userData ??= data.isNotEmpty ? data[0] : {};

      if (userData!.isNotEmpty) {
        print("API USERNAME: ${userData["u_name"]}");
        print("API FIRST NAME: ${userData["first_name"]}");
        print("API LAST NAME: ${userData["last_name"]}");

        String firstName = userData["first_name"] ?? "";
        String lastName = userData["last_name"] ?? "";
        String fullName = "$firstName $lastName".trim();
        String username = userData["u_name"] ?? "";

        await prefs.setString("name", fullName.isEmpty ? "User" : fullName);
        await prefs.setString("u_name", username);
        await prefs.setString("profile", userData["profile"] ?? "");
        await prefs.setInt("user_id", userData["id"] ?? 0);
        await prefs.setInt("id", userData["id"] ?? 0);

        print("USERNAME SAVED TO PREFS: '$username'");
        print("FULL NAME SAVED TO PREFS: '$fullName'");
        print("USER ID SAVED TO PREFS: ${userData["id"]}");

        if (mounted) {
          setState(() {
            studentName = fullName.isEmpty ? "User" : fullName;
            studentRole = username;
            studentImage = userData!["profile"] ?? "";
            loggedInUserId = userData["id"] ?? 0;
            isLoading = false;
          });
        }
      }
    } else {
      print("Failed to load profile: ${res.statusCode}");
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
  // Future<void> fetchCoaches() async {
  //   String? token = await getToken();

  //   try {
  //     final response = await http.get(
  //       Uri.parse("$api/api/myskates/coaches/approved/"),
  //       headers: {"Authorization": "Bearer $token"},
  //     );

  //     print("COACHES STATUS: ${response.statusCode}");
  //     print("COACHES BODY: ${response.body}");

  //     if (response.statusCode == 200) {
  //       final decoded = jsonDecode(response.body);
  //       if (decoded is List) {
  //         setState(() {
  //           coaches = decoded;
  //           coachesNoData = decoded.isEmpty;
  //           coachesLoading = false;
  //         });
  //       }
  //     } else {
  //       setState(() {
  //         coachesNoData = true;
  //         coachesLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       coachesNoData = true;
  //       coachesLoading = false;
  //     });
  //   }
  // }

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
          // Filter out coaches that are already followed or have pending requests
          final filteredCoaches = decoded.where((coach) {
            final coachId = coach["id"];
            // Exclude if already following OR has pending request OR approved sent
            return !myFollowing.contains(coachId) &&
                !myRequests.contains(coachId) &&
                !myApprovedSent.contains(coachId);
          }).toList();

          setState(() {
            coaches = filteredCoaches;
            coachesNoData = filteredCoaches.isEmpty;
            coachesLoading = false;
          });

          print("Original coaches count: ${decoded.length}");
          print("Filtered coaches count: ${filteredCoaches.length}");
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
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        studentName = prefs.getString("name") ?? "User";
        studentRole = prefs.getString("u_name") ?? "";
        studentImage = prefs.getString("profile");
        loggedInUserId = prefs.getInt("user_id") ?? prefs.getInt("id");
        isLoading = false;

        print("USERNAME FROM PREFS: '$studentRole'");
        print("NAME FROM PREFS: '$studentName'");
        print("USER ID FROM PREFS: $loggedInUserId");
      });
    } catch (e) {
      print("Error loading from SharedPreferences: $e");
      setState(() {
        isLoading = false;
      });
    }
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
    await fetchCoaches();
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
    await fetchCoaches();
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
          registeredTrainingIds.add(trainingId);
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

  Widget _movableFabMenu() {
    final size = MediaQuery.of(context).size;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    const double fabSize = 56;
    const double sideMargin = 12;
    const double topLimit = 100;
    const double bottomNavHeight = 80;

    // Total extra height needed when menu is open
    // 4 items + gaps + bottom gap above FAB
    const double openMenuExtraHeight = 230;

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
                        onTap: () => _navigateFromFab(const UserSettings()),
                      ),
                      const SizedBox(height: 10),
                      _fabMiniItem(
                        icon: Icons.groups,
                        label: "Chat Support",
                        openToLeft: openToLeft,
                        onTap: () => _navigateFromFab(const UserChatSupport()),
                      ),
                      const SizedBox(height: 10),
                      _fabMiniItem(
                        icon: Icons.notifications_none,
                        label: "Notifications",
                        openToLeft: openToLeft,
                        onTap: () async {
                          await _navigateFromFab(UserNotificationPage());
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
                  next.dy.clamp(topLimit, _fabMenuOpen ? maxYOpen : maxYClosed),
                );
              });
            },
            child: FloatingActionButton(
              heroTag: "movableFabStudent",
              backgroundColor: const Color(0xFF00AFA5),
              onPressed: () {
                setState(() {
                  _fabMenuOpen = !_fabMenuOpen;

                  // when opening, move FAB upward if needed
                  if (_fabMenuOpen && _fabOffset.dy > maxYOpen) {
                    _fabOffset = Offset(_fabOffset.dx, maxYOpen);
                  }

                  // also keep x inside screen
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
          constraints: const BoxConstraints(maxWidth: 180),
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

  Widget _buildClubShimmer() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.22,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[850]!,
            highlightColor: Colors.grey[700]!,
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

  Widget _buildTrainingShimmer() {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[850]!,
            highlightColor: Colors.grey[700]!,
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
            baseColor: Colors.grey[850]!,
            highlightColor: Colors.grey[700]!,
            child: Container(
              height: 300,
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
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[850]!,
            highlightColor: Colors.grey[700]!,
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

  // UI BUILD
  @override
  Widget build(BuildContext context) {
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
              key: _refreshIndicatorKey,
              onRefresh: _refreshData,
              color: const Color(0xFF00AFA5),
              backgroundColor: Colors.black87,
              strokeWidth: 3,
              displacement: 10,
              child: CustomScrollView(
                slivers: [
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserMenuPage(),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 24,
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
                                studentName.isNotEmpty ? studentName : "User",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                studentRole.isNotEmpty ? studentRole : "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
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
                                  slideRightToLeftRoute(UserNotificationPage()),
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (banner.isNotEmpty) ...[
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
                                    autoPlayInterval: const Duration(
                                      seconds: 3,
                                    ),
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
                                                      alignment:
                                                          Alignment.center,
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
                          ],
                          const SizedBox(height: 22),

                          const Text(
                            "We offer training and an e-commerce platform\nthat connects students and coaches.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 25),

                          buildButton("Connect Coaches"),
                          buildButton("Connect Students"),
                          buildButton("Find Clubs"),
                          buildButton("Find Events"),
                          buildButton("Buy and Sell products"),
                          buildButton("Used products"),

                          const SizedBox(height: 25),

                          if (clubs.isEmpty && !noData) ...[
                            const Text(
                              "Recommended Clubs near you",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildClubShimmer(),
                            const SizedBox(height: 25),
                          ] else if (clubs.isNotEmpty) ...[
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
                          ],

                          if (trainingLoading) ...[
                            const Text(
                              "Upcoming Training Sessions",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildTrainingShimmer(),
                            const SizedBox(height: 25),
                          ] else if (!trainingNoData &&
                              trainingSessions.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Upcoming Training Sessions",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                // Container(
                                //   padding: const EdgeInsets.symmetric(
                                //     horizontal: 10,
                                //     vertical: 5,
                                //   ),
                                //   decoration: BoxDecoration(
                                //     color: Colors.white.withOpacity(0.08),
                                //     borderRadius: BorderRadius.circular(20),
                                //     border: Border.all(
                                //       color: Colors.white.withOpacity(0.15),
                                //     ),
                                //   ),
                                //   child: Row(
                                //     mainAxisSize: MainAxisSize.min,
                                //     children: [
                                //       const Icon(
                                //         Icons.swipe,
                                //         size: 14,
                                //         color: Colors.tealAccent,
                                //       ),
                                //       const SizedBox(width: 4),
                                //       Text(
                                //         "Swipe to see more",
                                //         style: TextStyle(
                                //           color: Colors.tealAccent.withOpacity(
                                //             0.9,
                                //           ),
                                //           fontSize: 11,
                                //           fontWeight: FontWeight.w500,
                                //         ),
                                //       ),
                                //       const Icon(
                                //         Icons.arrow_forward_ios,
                                //         size: 10,
                                //         color: Colors.tealAccent,
                                //       ),
                                //     ],
                                //   ),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              height: 340,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: trainingSessions.length,
                                itemBuilder: (context, index) {
                                  final session = trainingSessions[index];
                                  final images =
                                      session['images'] as List? ?? [];
                                  String imageUrl = images.isNotEmpty
                                      ? "$api${images[0]['image']}"
                                      : "";

                                  return Container(
                                    width: 280,
                                    margin: EdgeInsets.only(
                                      right: 12,
                                      left: index == 0 ? 0 : 0,
                                    ),
                                    child: buildTrainingSessionRow(
                                      trainingId: session['id'],
                                      title: session['title'] ?? "",
                                      note: session['note'] ?? "",
                                      location: session['location'] ?? "",
                                      startDate: session['start_date'] ?? "",
                                      endDate: session['end_date'] ?? "",
                                      startTime: session['start_time'] ?? "",
                                      endTime: session['end_time'] ?? "",
                                      imageUrl: imageUrl,
                                      isRegistered: registeredTrainingIds
                                          .contains(session['id']),
                                      onRegister: () {
                                        confirmRegister(session['id']);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 25),
                          ],
                          if (!homeFeedsNoData || homeFeedsLoading) ...[
                            buildHomeFeedsSection(),
                            const SizedBox(height: 25),
                          ],
                          if (eventsLoading) ...[
                            const Text(
                              "Upcoming Events",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildEventShimmer(),
                            const SizedBox(height: 12),
                          ] else if (!eventsNoData && events.isNotEmpty) ...[
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

                                String image1 = images.isNotEmpty
                                    ? "$api${images[0]['image']}"
                                    : "lib/assets/skating1.jpg";

                                String image2 = images.length > 1
                                    ? "$api${images[1]['image']}"
                                    : image1;

                                return buildEventCardWithImages(
                                  clubName:
                                      event["club_name"] ?? "Skating Club",
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
                          ],

                          if (!followLoaded || coachesLoading) ...[
                            const Text(
                              "Suggested Coaches",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(height: 210, child: _buildCoachShimmer()),
                            const SizedBox(height: 20),
                          ] else if (!coachesNoData && coaches.isNotEmpty) ...[
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
                              child: ListView.builder(
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
                            const SizedBox(height: 20),
                          ],

                          if (studentsLoading) ...[
                            const Text(
                              "Suggested Students",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(height: 210, child: _buildCoachShimmer()),
                          ] else if (!studentsNoData &&
                              students.isNotEmpty) ...[
                            const Text(
                              "Suggested Studentsss",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              height: 210,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: students.length,
                                itemBuilder: (_, i) => StudentFollowCard(
                                  student: students[i],
                                  myFollowing: myFollowing,
                                  myRequests: myRequests,
                                  myApprovedSent: myApprovedSent,
                                  onFollow: sendFollowRequest,
                                  onCancelPending: cancelPendingRequest,
                                  onUnfollow: unfollowCoach,
                                  refreshParent: () => setState(() {}),
                                ),
                              ),
                            ),
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

          // ✅ Movable FAB Menu on top
          _movableFabMenu(),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

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
          } else if (title == "Used products") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UsedProducts()),
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

        EventImageSlider(
          images: [
            if (image1.isNotEmpty) image1,
            if (image2.isNotEmpty && image2 != image1) image2,
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

            // ✅ LIKE COUNT
            Text(
              likesCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 0.5),

            IconButton(
              icon: Icon(
                Icons.thumb_up_alt,
                color: isLiked ? Colors.tealAccent : Colors.white70,
                size: 22,
              ),
              onPressed: () => onLike(eventId),
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

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => showImagePopup(context, widget.images[index]),
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black26,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 6),

        if (widget.images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: currentPage == index ? 8 : 6,
                height: currentPage == index ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentPage == index
                      ? Colors.tealAccent
                      : Colors.white38,
                ),
              ),
            ),
          ),
      ],
    );
  }
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
    onTap = null;
  } else {
    buttonText = "Join Club";
    buttonColor = Colors.teal;
    onTap = () => onJoinClub(clubId);
  }

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClubView(clubid: clubId, isApproved: isApproved),
        ),
      );
    },
    child: Container(
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
    ),
  );
}

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
                textAlign: TextAlign.center,
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
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
                textAlign: TextAlign.center,
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
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              const SizedBox(height: 2),
              Text(
                standard,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
  VoidCallback? onRegister,
  required bool isRegistered,
  required trainingId,
}) {
  return Container(
    width: 280,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.12),
          Colors.white.withOpacity(0.06),
          const Color(0xFF003E38).withOpacity(0.25),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section with overlay gradient
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                // Gradient overlay on image
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                // Date badge on image
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2EE6A6), Color(0xFF00AFA5)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDisplayDate(startDate),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Note/Description
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Location row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.tealAccent.withOpacity(0.9),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Time row
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 13,
                        color: Colors.tealAccent.withOpacity(0.9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$startTime - $endTime",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: isRegistered
                        ? Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.withOpacity(0.2),
                                  Colors.green.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.5),
                              ),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Registered",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: onRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00AFA5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Register Now",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
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

class RepostCommentSheet extends StatefulWidget {
  final int feedId;
  final bool isAlreadyReposted;
  final Function onRepostSuccess;

  const RepostCommentSheet({
    super.key,
    required this.feedId,
    required this.isAlreadyReposted,
    required this.onRepostSuccess,
  });

  @override
  State<RepostCommentSheet> createState() => _RepostCommentSheetState();
}

class _RepostCommentSheetState extends State<RepostCommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRepost() async {
    final comment = _commentController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Authentication token missing"),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      http.Response response;

      if (widget.isAlreadyReposted) {
        // Delete the repost
        // First get the repost ID (you might need to fetch it from somewhere)
        // For now, we'll assume your API supports DELETE without repost ID
        response = await http.delete(
          Uri.parse("$api/api/myskates/feeds/repost/${widget.feedId}/"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );
      } else {
        // Create new repost with optional comment
        final body = <String, dynamic>{};
        if (comment.isNotEmpty) {
          body['text'] = comment;
        }

        response = await http.post(
          Uri.parse("$api/api/myskates/feeds/repost/${widget.feedId}/"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: comment.isNotEmpty ? jsonEncode(body) : null,
        );
      }

      print("REPOST STATUS: ${response.statusCode}");
      print("REPOST RESPONSE: ${response.body}");

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isAlreadyReposted
                    ? "Repost removed"
                    : "Reposted successfully",
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          widget.onRepostSuccess();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Failed to ${widget.isAlreadyReposted ? 'remove repost' : 'repost'}: ${response.statusCode}",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("REPOST ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  widget.isAlreadyReposted ? Icons.repeat : Icons.repeat,
                  color: const Color(0xFF2EE6A6),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.isAlreadyReposted
                      ? "Remove Repost"
                      : "Repost with Comment",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Comment input (only show for new repost)
          if (!widget.isAlreadyReposted) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Add a comment to your repost...",
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "You can add a comment to share your thoughts. This will appear along with your repost.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Are you sure you want to remove this repost?",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Submit button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRepost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isAlreadyReposted
                          ? Colors.redAccent
                          : const Color(0xFF2EE6A6),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.isAlreadyReposted
                                    ? Icons.delete
                                    : Icons.repeat,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.isAlreadyReposted ? "Remove" : "Repost",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
}

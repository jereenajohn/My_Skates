import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_skates/COACH/coach_homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class CoachNotificationPage extends StatefulWidget {
  const CoachNotificationPage({super.key});

  @override
  State<CoachNotificationPage> createState() => _CoachNotificationPageState();
}

class _CoachNotificationPageState extends State<CoachNotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  // ================= FETCH =================
  Future<void> fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() => loading = false);
        return;
      }

      // 🔐 STEP 0: FETCH MUTUAL FOLLOW IDS
      final Set<int> mutualFollowIds = await fetchMutualFollowIds();

      // 🔔 STEP 1: FETCH NOTIFICATIONS
      final res = await http.get(
        Uri.parse("$api/api/myskates/notifications/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode != 200) {
        setState(() => loading = false);
        return;
      }

      final decoded = jsonDecode(res.body);
      final List data = decoded["data"] ?? [];

      // ─────────────────────────────────────────────
      // STEP 2: NORMALIZE NOTIFICATIONS
      // ─────────────────────────────────────────────
      final List<Map<String, dynamic>> temp = data.map<Map<String, dynamic>>((
        e,
      ) {
        final m = Map<String, dynamic>.from(e);

        m["created_at"] =
            DateTime.tryParse(m["created_at"]?.toString() ?? "") ??
            DateTime.now();

        m["is_read"] = m["is_read"] ?? false;
        m["isLoading"] = false;

        switch (m["notification_type"]) {
          case "follow_request":
            m["status_ui"] = "request_pending";
            break;

          case "follow_approved":
            m["status_ui"] = "approved";
            break;

          case "follow_back_request":
            m["status_ui"] = "follow_back_pending";
            break;

          case "follow_back_accepted":
            m["status_ui"] = "following";
            break;

          default:
            m["status_ui"] = "none";
        }

        return m;
      }).toList();

      // ─────────────────────────────────────────────
      // STEP 3: DEDUPLICATE ONLY FOLLOW NOTIFICATIONS
      // ─────────────────────────────────────────────
      int priority(String type) {
        switch (type) {
          case "follow_back_accepted":
            return 4;
          case "follow_back_request":
            return 3;
          case "follow_approved":
            return 2;
          case "follow_request":
            return 1;
          default:
            return 0;
        }
      }

      bool isFollowType(String type) {
        return type == "follow_request" ||
            type == "follow_approved" ||
            type == "follow_back_request" ||
            type == "follow_back_accepted";
      }

      final List<Map<String, dynamic>> finalList = [];
      final Map<int, Map<String, dynamic>> followByActor = {};

      for (final n in temp) {
        final String type = n["notification_type"];
        final int actorId = n["actor"];

        // 1️⃣ FOLLOW TYPE → DEDUPE
        if (isFollowType(type)) {
          // MUTUAL FOLLOW ALWAYS WINS
          if (mutualFollowIds.contains(actorId)) {
            n["notification_type"] = "follow_back_accepted";
            n["status_ui"] = "following";
            followByActor[actorId] = n;
            continue;
          }

          // FOLLOW BACK REQUEST MUST SURVIVE
          if (type == "follow_back_request") {
            n["status_ui"] = "follow_back_pending";
            followByActor[actorId] = n;
            continue;
          }

          if (!followByActor.containsKey(actorId)) {
            followByActor[actorId] = n;
          } else {
            final existing = followByActor[actorId]!;
            if (priority(type) > priority(existing["notification_type"])) {
              followByActor[actorId] = n;
            }
          }
        }
        // 2️⃣ NON FOLLOW TYPE → KEEP ALL
        else {
          finalList.add(n);
        }
      }

      // merge follow notifications
      finalList.addAll(followByActor.values);

      // sort final list
      notifications = finalList
        ..sort(
          (a, b) => (b["created_at"] as DateTime).compareTo(
            a["created_at"] as DateTime,
          ),
        );

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  // ================= MUTUAL FOLLOW LIST =================
  Future<Set<int>> fetchMutualFollowIds() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return {};

    final res = await http.get(
      Uri.parse("$api/api/myskates/followers/user/mutual/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) return {};

    final decoded = jsonDecode(res.body);
    final List data = decoded["data"] ?? [];

    return data.map<int>((e) => e["id"] as int).toSet();
  }

  // ================= CONFIRM FOLLOW REQUEST =================
  Future<void> confirmFollowRequest(int index) async {
    final n = notifications[index];
    n["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/approve/"),
      headers: {"Authorization": "Bearer $token"},
      body: {
        "request_id": n["follow_request_id"].toString(),
        "action": "approved",
      },
    );

    if (res.statusCode == 200) {
      if (n["notification_type"] == "follow_back_request") {
        n["status_ui"] = "following";
        n["notification_type"] = "follow_back_accepted";
      } else {
        n["status_ui"] = "approved";
        n["notification_type"] = "follow_approved";
      }
    }

    n["isLoading"] = false;
    setState(() {});
  }

  // ================= IGNORE FOLLOW REQUEST =================
  Future<void> ignoreFollowRequest(int index) async {
    final n = notifications[index];
    n["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/cancel/"),
      headers: {"Authorization": "Bearer $token"},
      body: {
        "request_id": n["follow_request_id"].toString(),
        "action": "rejected",
      },
    );

    if (res.statusCode == 200) {
      notifications.removeAt(index);
    }

    setState(() {});
  }

  // ================= FOLLOW BACK =================
  Future<void> confirmRequest(int index) async {
    final n = notifications[index];
    n["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/request/"),
      headers: {"Authorization": "Bearer $token"},
      body: {"following_id": n["actor"].toString()},
    );

    if (res.statusCode == 200) {
      n["status_ui"] = "follow_back_sent";
      n["notification_type"] = "follow_back_request";
    }

    n["isLoading"] = false;
    setState(() {});
  }

  // ================= CANCEL REQUEST =================
  Future<void> cancelRequest(int index) async {
    final n = notifications[index];
    n["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/cancel/"),
      headers: {"Authorization": "Bearer $token"},
      body: {
        "request_id": n["follow_request_id"].toString(),
        "action": "rejected",
      },
    );

    if (res.statusCode == 200) {
      notifications.removeAt(index);
    }

    setState(() {});
  }

  // ================= APPROVE CLUB JOIN REQUEST =================
  Future<void> approveClubRequest(int index) async {
    final n = notifications[index];
    n["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.post(
      Uri.parse("$api/api/myskates/club/join/approve/"),
      headers: {"Authorization": "Bearer $token"},
      body: {"actor_id": n["actor"].toString()},
    );

    if (res.statusCode == 200) {
      notifications.removeAt(index);
    }

    setState(() {});
  }

  // ================= REJECT CLUB JOIN REQUEST =================
  Future<void> rejectClubRequest(int index) async {
    final n = notifications[index];
    n["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.post(
      Uri.parse("$api/api/myskates/club/join/reject/"),
      headers: {"Authorization": "Bearer $token"},
      body: {"actor_id": n["actor"].toString()},
    );

    if (res.statusCode == 200) {
      notifications.removeAt(index);
    }

    setState(() {});
  }

  // ================= HELPERS =================
  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    return DateFormat("dd MMM").format(dt);
  }

  String notificationText(Map<String, dynamic> n) {
    final type = n["notification_type"];

    if (n["status_ui"] == "following") {
      return "started following you.";
    }

    if (n["status_ui"] == "follow_back_sent") {
      return "you sent a follow request.";
    }

    switch (type) {
      case "follow_request":
        return "requested to follow you.";

      case "follow_approved":
        return "accepted your follow request.";

      case "follow_back_request":
        return "requested you to follow back.";

      case "follow_back_accepted":
        return "you are now following each other.";

      case "event_like":
        return "liked your event.";

      case "club_join_request":
        return "invited you to join their club.";

      case "club_join_approved":
        return "joined your club.";

      case "post_like":
        return "liked your post.";

      case "comment":
        return "commented on your post.";

      default:
        return "sent you a notification.";
    }
  }

  String getSectionTitle(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return "Highlights";
    if (diff.inHours < 24) return "Today";
    if (diff.inDays < 7) return "Last 7 days";
    return "Earlier";
  }

  // ================= INSTAGRAM AVATAR =================
  Widget instaAvatar(String? imageUrl, String name) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 4, 123, 113), // dark green
            Color(0xFF000000), // black
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.black,
        child: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF1A1A1A),
          backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
              ? NetworkImage(imageUrl)
              : null,
          child: (imageUrl == null || imageUrl.isEmpty)
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ================= SECTION TITLE =================
Widget sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 6),
    child: Text(
      title,
      style: TextStyle(
        color: Colors.grey.shade300,
        fontSize: 13, // ✅ SMALLER TEXT
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

  // ================= TILE =================
  Widget instaNotificationTile(Map<String, dynamic> n, int index) {
    final name =
        "${n['actor_first_name'] ?? ""}${n['actor_last_name'] != null ? " ${n['actor_last_name']}" : ""}";
    final username = name.trim().isEmpty ? "Unknown" : name.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade900, width: 1),
        ),
      ),
      child: Row(
        children: [
          instaAvatar(n["actor_profile"], username),
          const SizedBox(width: 12),

          // TEXT
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13.5, height: 1.3),
                children: [
                  TextSpan(
                    text: username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: " ${notificationText(n)} ",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  TextSpan(
                    text: timeAgo(n["created_at"]),
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // RIGHT SIDE BUTTONS
          if (n["status_ui"] == "following" ||
              n["status_ui"] == "follow_back_sent")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Following",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (n["status_ui"] == "request_pending" ||
              n["status_ui"] == "follow_back_pending")
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: n["isLoading"]
                  ? null
                  : () => confirmFollowRequest(index),
              child: n["isLoading"]
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Confirm",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
            )
          else if (n["status_ui"] == "approved")
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: n["isLoading"] ? null : () => confirmRequest(index),
              child: const Text(
                "Follow",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            )
          else if (n["notification_type"] == "club_join_request")
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 28), // 👈 height smaller
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ), // 👈 smaller
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: n["isLoading"]
                  ? null
                  : () => approveClubRequest(index),
              child: const Text(
                "Approve",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11, // 👈 smaller text
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ================= GROUPED LIST =================
  List<Widget> buildGroupedNotificationWidgets() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var n in notifications) {
      final dt = n["created_at"] as DateTime;
      final title = getSectionTitle(dt);

      grouped.putIfAbsent(title, () => []);
      grouped[title]!.add(n);
    }

    final List<String> order = [
      "Highlights",
      "Today",
      "Last 7 days",
      "Earlier",
    ];

    List<Widget> widgets = [];

    for (final section in order) {
      if (grouped.containsKey(section) && grouped[section]!.isNotEmpty) {
        widgets.add(sectionTitle(section));

        for (final item in grouped[section]!) {
          final index = notifications.indexOf(item);
          widgets.add(instaNotificationTile(item, index));
        }
      }
    }

    return widgets;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CoachHomepage()),
            );
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : notifications.isEmpty
          ? const Center(
              child: Text(
                "No notifications",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView(
              children: [
                // ================= FOLLOW REQUESTS TOP TILE =================
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                //   decoration: BoxDecoration(
                //     color: Colors.black,
                //     border: Border(
                //       bottom: BorderSide(color: Colors.grey.shade900, width: 1),
                //     ),
                //   ),
                //   child: Row(
                //     children: [
                //       CircleAvatar(
                //         radius: 24,
                //         backgroundColor: const Color(0xFF1A1A1A),
                //         child: const Icon(
                //           Icons.person_add_alt_1,
                //           color: Colors.white,
                //           size: 22,
                //         ),
                //       ),
                //       const SizedBox(width: 12),
                //       Expanded(
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             const Text(
                //               "Follow requests",
                //               style: TextStyle(
                //                 color: Colors.white,
                //                 fontWeight: FontWeight.w800,
                //                 fontSize: 14,
                //               ),
                //             ),
                //             const SizedBox(height: 2),
                //             Text(
                //               "Approve or ignore requests",
                //               style: TextStyle(
                //                 color: Colors.grey.shade500,
                //                 fontSize: 12.5,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //       Icon(
                //         Icons.arrow_forward_ios,
                //         size: 15,
                //         color: Colors.grey.shade600,
                //       ),
                //     ],
                //   ),
                // ),

                // ================= GROUPED NOTIFICATIONS =================
                ...buildGroupedNotificationWidgets(),
              ],
            ),
    );
  }
}

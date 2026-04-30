import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_skates/COACH/coach_followers_list.dart';
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
  bool noData = false;

  /// Normalized followers list
  /// Each item will have:
  /// id, first_name, last_name, profile, user_type
  List<Map<String, dynamic>> followers = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    fetchCoachFollowers();
  }

  // ================= FETCH =================
  Future<void> fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id") ?? prefs.getInt("user_id");

      if (token == null) {
        setState(() => loading = false);
        return;
      }

      final res = await http.get(
        Uri.parse("$api/api/myskates/notifications/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("FETCH NOTIFICATIONS STATUS: ${res.statusCode}");
      print("FETCH NOTIFICATIONS BODY: ${res.body}");

      if (res.statusCode != 200) {
        setState(() => loading = false);
        return;
      }

      final decoded = jsonDecode(res.body);
      final List data = decoded["data"] ?? [];

      final List<Map<String, dynamic>> temp = data
          .where((e) {
            final type = e["notification_type"];

            // remove duplicate "follow_back_accepted"
            if (type == "follow_back_accepted") return false;

            // already you have this
            if (type == "follow_approved" && e["actor"] == userId) {
              return false;
            }

            return true;
          })
          .map<Map<String, dynamic>>((e) {
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

              case "follow_back_request":
                m["status_ui"] = "follow_back_pending"; // ✅ NEW
                break;

              case "follow_approved":
              case "follow_back_accepted":
              case "following_each_other":
                m["status_ui"] = "approved";
                break;

              default:
                m["status_ui"] = "none";
            }

            return m;
          })
          .toList();

      notifications = temp
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

  Future<void> confirmFollowBackRequest(int index) async {
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
      notifications.removeAt(index);
    }

    setState(() {});
  }

  Future<void> cancelFollowBackRequest(int index) async {
    final n = notifications[index];
    n["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/request/remove/"),
      headers: {"Authorization": "Bearer $token"},
      body: {"follower_id": n["actor"].toString()},
    );

    if (res.statusCode == 200) {
      notifications.removeAt(index);
    }

    setState(() {});
  }

  // ================= CONFIRM FOLLOW =================
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
      notifications.removeAt(index);
    }

    setState(() {});
  }

  // ================= IGNORE FOLLOW =================
  Future<void> ignoreFollowRequest(int index) async {
    final n = notifications[index];
    n["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/request/remove/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: {"follower_id": n["actor"].toString()},
    );

    if (res.statusCode == 200) {
      notifications.removeAt(index);
    }

    setState(() {});
  }

  // ================= APPROVE CLUB =================
  Future<void> approveClubRequest(int index) async {
    final n = notifications[index];
    n["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    print("==== APPROVE CLICKED ====");
    print("TOKEN: $token");
    print("DATA: club_id=${n["club_id"]}, user_id=${n["actor"]}");

    if (token == null) return;

    final res = await http.put(
      Uri.parse("$api/api/myskates/club/join/approve/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "club_id": n["club_id"],
        "user_id": n["actor"],
        "status": "approved",
      }),
    );

    print("STATUS CODE: ${res.statusCode}");
    print("RESPONSE BODY: ${res.body}");

    if (res.statusCode == 200) {
      notifications.removeAt(index);
    }

    setState(() {});
  }

  // ================= REJECT CLUB =================
  Future<void> rejectClubRequest(int index) async {
    final n = notifications[index];
    n["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    print("==== REJECT CLICKED ====");
    print("TOKEN: $token");
    print("DATA: club_id=${n["club_id"]}, user_id=${n["actor"]}");

    if (token == null) return;

    final res = await http.put(
      Uri.parse("$api/api/myskates/club/join/approve/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "club_id": n["club_id"],
        "user_id": n["actor"],
        "status": "rejected",
      }),
    );

    print("STATUS CODE: ${res.statusCode}");
    print("RESPONSE BODY: ${res.body}");

    if (res.statusCode == 200) {
      notifications.removeAt(index);
    }

    setState(() {});
  }


  Future<void> fetchCoachFollowers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse("$api/api/myskates/user/followers/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("COACH FOLLOWERS STATUS: ${response.statusCode}");
      print("COACH FOLLOWERS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List raw = decoded["data"] ?? [];

        /// 🔹 Normalize API response here
        final List<Map<String, dynamic>> normalized = raw
            .map((e) {
              return {
                "id": e["follower__id"],
                "first_name": e["follower__first_name"],
                "last_name": e["follower__last_name"],
                "profile": e["follower__profile"],
                "user_type": e["follower__user_type"],
                "is_mutual": e["is_mutual"] ?? false,

                // 🔥 USE BACKEND TRUTH
                "follow_requested":
                    e["has_requested"] == true &&
                    e["request_status"] == "pending",

                "isLoading": false,
              };
            })
            .where((e) => e["id"] != null)
            .toList();

        setState(() {
          followers = normalized;
          noData = followers.isEmpty;
          loading = false;
        });
      } else {
        setState(() {
          noData = true;
          loading = false;
        });
      }
    } catch (e) {
      print("COACH FOLLOWERS ERROR: $e");
      setState(() {
        noData = true;
        loading = false;
      });
    }
  }


  // ================= HELPERS =================
  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    return DateFormat("dd MMM").format(dt);
  }

  // String notificationText(Map<String, dynamic> n) {
  //   switch (n["notification_type"]) {
  //     case "follow_request":
  //       return "requested to follow you.";

  //     case "follow_approved":
  //       return "accepted your follow request.";

  //     case "follow_back_accepted":
  //       return "you are now following each other.";

  //     case "following_each_other": //  NEW CASE
  //       return "you are now following each other.";

  //     case "follow_back_request":
  //       return "requested to follow you.";

  //     case "event_like":
  //       return "liked your event.";

  //      case "club_join_request":
  //     return "requested to join ${n["club_name"] ?? "your club"}.";

  //   case "club_join_approved":
  //     return "joined ${n["club_name"] ?? "your club"}.";

  //     case "post_like":
  //       return "liked your post.";

  //     case "comment":
  //       return "commented on your post.";

  //     default:
  //       return "sent you a notification.";
  //   }
  // }

  String notificationText(Map<String, dynamic> n) {
  switch (n["notification_type"]) {
    case "follow_request":
      return "requested to follow you.";

    case "follow_approved":
      return "accepted your follow request.";

    case "follow_back_request":
      return "requested you to follow back.";

    case "follow_back_accepted":
    case "following_each_other":
      return "you are now following each other.";

    case "feed_like":
      return "liked your post.";

    case "feed_repost":
      return "reposted your post.";

    case "comment":
    case "feed_comment":
      return "commented on your post.";

    case "event_like":
      return "liked your event.";

    case "club_join_request":
      return "requested to join ${n["club_name"] ?? "your club"}.";

    case "club_join_approved":
      return "accepted your club join request.";

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

  // ================= AVATAR =================
  Widget instaAvatar(String? imageUrl, String name) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.grey.shade800,
      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
          ? NetworkImage(imageUrl)
          : null,
      child: (imageUrl == null || imageUrl.isEmpty)
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  // ================= TILE =================
  Widget notificationTile(Map<String, dynamic> n, int index) {
    final name = "${n['actor_first_name'] ?? ""} ${n['actor_last_name'] ?? ""}"
        .trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade900, width: 1),
        ),
      ),
      child: Row(
        children: [
          instaAvatar(n["actor_profile"], name),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13.5, height: 1.3),
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: " ${notificationText(n)} ",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  TextSpan(
                    text: "• ${timeAgo(n["created_at"])}",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // ONLY CONFIRM / CANCEL
          // FOLLOW REQUEST
          if (n["status_ui"] == "request_pending")
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: n["isLoading"]
                      ? null
                      : () => confirmFollowRequest(index),
                  child: const Text(
                    "Confirm",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade700),
                  ),
                  onPressed: n["isLoading"]
                      ? null
                      : () => ignoreFollowRequest(index),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            )
          // FOLLOW BACK REQUEST
          else if (n["status_ui"] == "follow_back_pending")
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: n["isLoading"]
                      ? null
                      : () => confirmFollowBackRequest(index),
                  child: const Text(
                    "Confirm",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade700),
                  ),
                  onPressed: n["isLoading"]
                      ? null
                      : () => cancelFollowBackRequest(index),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            )
          else if (n["notification_type"] == "club_join_request")
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () => approveClubRequest(index),
                  child: const Text(
                    "Approve",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade700),
                  ),
                  onPressed: () => rejectClubRequest(index),
                  child: const Text(
                    "Reject",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CoachHomepage()),
            );
          },
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
     body: loading
    ? const Center(child: CircularProgressIndicator(color: Colors.white))
    : Column(
        children: [

          // 🔵 TOP FOLLOW REQUEST DESIGN (STATIC / CLICKABLE)
          if (followers.isNotEmpty)
          InkWell(
            onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CoachFollowersList()),
            );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade900),
                ),
              ),
              child: Row(
                children: [
                  // ICON / AVATAR
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person_add, color: Colors.white),
                  ),

                  const SizedBox(width: 12),

                  // TEXT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Follow Back",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "Tap to view followers",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // BLUE DOT
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.tealAccent,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),

          // 🔽 YOUR EXISTING LIST (UNCHANGED)
          Expanded(
            child: notifications.isEmpty
                ? const Center(
                    child: Text(
                      "No notifications",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) =>
                        notificationTile(notifications[index], index),
                  ),
          ),
        ],
    ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:my_skates/STUDENTS/user_followers_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class UserNotificationPage extends StatefulWidget {
  const UserNotificationPage({super.key});

  @override
  State<UserNotificationPage> createState() => _UserNotificationPageState();
}

class _UserNotificationPageState extends State<UserNotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;
  bool noData = false;
  List followers = [];
  bool showFollowBack = false; // determines whether to show the follow-back banner

  @override
  void initState() {
    super.initState();
    fetchNotifications();

    fetchFollowers();
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

      notifications =
          data.map<Map<String, dynamic>>((e) {
            final m = Map<String, dynamic>.from(e);

            m["created_at"] =
                DateTime.tryParse(m["created_at"] ?? "") ?? DateTime.now();

            m["isLoading"] = false;

            switch (m["notification_type"]) {
              case "follow_request":
                m["status_ui"] = "request_pending";
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
          }).toList()..sort(
            (a, b) => (b["created_at"] as DateTime).compareTo(
              a["created_at"] as DateTime,
            ),
          );

      setState(() => loading = false);
    } catch (e) {
      setState(() => loading = false);
    }
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

  Future<void> fetchFollowers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse("$api/api/myskates/user/followers/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List raw = decoded["data"] ?? [];

        // show the follow-back container only if the API returned at least one follower
        showFollowBack = raw.isNotEmpty;

        final normalized = raw.map<Map<String, dynamic>>((e) {
          return {
            "id": e["follower__id"],
            "first_name": e["follower__first_name"],
            "last_name": e["follower__last_name"],
            "profile": e["follower__profile"],
            "user_type": e["follower__user_type"],
            "is_mutual": e["is_mutual"] ?? false,
            "follow_requested":
                e["has_requested"] == true && e["request_status"] == "pending",
            "isLoading": false,
          };
        }).toList();

        setState(() {
          followers = normalized;
          noData = followers.isEmpty;
          loading = false;
        });
      } else {
        setState(() {
          noData = true;
          loading = false;
          showFollowBack = false;
        });
      }
    } catch (e) {
      setState(() {
        noData = true;
        loading = false;
        showFollowBack = false;
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

  String notificationText(Map<String, dynamic> n) {
    switch (n["notification_type"]) {
      case "follow_request":
        return "requested to follow you.";

      case "follow_approved":
        return "accepted your follow request.";

      case "follow_back_accepted":
        return "you are now following each other.";

      case "following_each_other":
        return "and you are now following each other.";

      case "follow_back_request":
        return "requested you to follow back.";

      case "event_like":
        return "liked your event.";

      case "club_join_request":
        return "requested to join your club.";

      case "club_join_approved":
        return "accepted your club join request.";

      case "post_like":
        return "liked your post.";

      case "comment":
        return "commented on your post.";

      default:
        return "sent you a notification.";
    }
  }

  Widget avatar(String? image, String name) {
    if (image != null && image.isNotEmpty) {
      return CircleAvatar(radius: 22, backgroundImage: NetworkImage(image));
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.tealAccent.withOpacity(0.2),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
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
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
            );
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔵 TOP FOLLOW REQUEST DESIGN
                // show banner only when server data indicated followers > 0
                if (showFollowBack)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserFollowersList(),
                        ),
                      );
                      // 👉 navigate wherever you want later
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade900),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.teal,
                            child: Icon(Icons.person_add, color: Colors.white),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Follow Back ",
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

                          // dot
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

                // 🔽 EXISTING LIST (UNCHANGED)
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
                          itemBuilder: (context, index) {
                            final n = notifications[index];
                            final name =
                                "${n['actor_first_name'] ?? ""} ${n['actor_last_name'] ?? ""}"
                                    .trim();

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  avatar(n['actor_profile'], name),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    " ${notificationText(n)} ",
                                              ),
                                              TextSpan(
                                                text:
                                                    "• ${timeAgo(n['created_at'])}",
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        if (n["status_ui"] == "request_pending")
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor: Colors
                                                            .tealAccent
                                                            .shade700,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  onPressed: n["isLoading"]
                                                      ? null
                                                      : () =>
                                                            confirmFollowRequest(
                                                              index,
                                                            ),
                                                  child: const Text("Confirm"),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton(
                                                  onPressed: n["isLoading"]
                                                      ? null
                                                      : () =>
                                                            ignoreFollowRequest(
                                                              index,
                                                            ),
                                                  child: const Text(
                                                    "Ignore",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

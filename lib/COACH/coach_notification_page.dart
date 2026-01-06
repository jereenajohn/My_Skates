import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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

      final res = await http.get(
        Uri.parse("$api/api/myskates/notifications/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded["data"] ?? [];

        setState(() {
          notifications = data.map<Map<String, dynamic>>((e) {
            final m = Map<String, dynamic>.from(e);

            m["created_at"] =
                DateTime.tryParse(m["created_at"]?.toString() ?? "") ??
                DateTime.now();

            m["is_read"] = m["is_read"] ?? false;
            m["isLoading"] = false;

            // 🔑 IMPORTANT UI STATE
            if (m["notification_type"] == "follow_request" ||
                m["notification_type"] == "started_following") {
              m["status_ui"] = "requested";
            } else {
              m["status_ui"] = m["notification_type"];
            }

            return m;
          }).toList();

          loading = false;
        });

        await syncApprovedFollowBacks();
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  // ================= SYNC MUTUAL FOLLOW =================
  Future<void> syncApprovedFollowBacks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.get(
      Uri.parse("$api/api/myskates/user/follow/sent/approved/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final List approved = jsonDecode(res.body);
      final approvedIds = approved.map((e) => e["following"]).toSet();

      setState(() {
        for (final n in notifications) {
          if (n["status_ui"] == "requested" &&
              approvedIds.contains(n["actor"])) {
            n["status_ui"] = "following"; // mutual → hide buttons
          }
        }
      });
    }
  }

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

    print(res.statusCode);
    print(res.body);

  if (res.statusCode == 200) {
  n["status_ui"] = "following";

  // 🔥 Force UI text
  n["notification_type"] = "started_following";
}


    n["isLoading"] = false;
    setState(() {});
  }

  Future<void> ignoreFollowRequest(int index) async {
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
        "action": "rejected",
      },
    );

    if (res.statusCode == 200) {
      notifications.removeAt(index);
    }

    setState(() {});
  }

  // ================= CONFIRM =================
  Future<void> confirmRequest(int index) async {
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
      n["status_ui"] = "following";
      n["notification_type"] = "follow_approved";
    }

    n["isLoading"] = false;
    setState(() {});
  }

  // ================= CANCEL =================
  Future<void> cancelRequest(int index) async {
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
        "action": "rejected",
      },
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
    switch (n["notification_type"]) {
      case "follow_request":
        return "sent you a follow request";
      case "started_following":
      case "follow_approved":
        return "accepted your follow request";
      default:
        return "sent you a notification";
    }
  }

  Widget avatar(String? image, String name) {
    if (image != null && image.isNotEmpty) {
      return CircleAvatar(radius: 22, backgroundImage: NetworkImage(image));
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
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
                final name = "${n['actor_first_name']} ${n['actor_last_name']}";

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: n["is_read"] == false
                        ? const Color(0xFFF5F8FF)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatar(n['actor_profile'], name),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: " ${notificationText(n)} "),
                                  TextSpan(
                                    text: "• ${timeAgo(n['created_at'])}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 🔥 FOLLOW REQUEST → Confirm / Ignore
                            if (n["notification_type"] == "follow_request")
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: n["isLoading"]
                                          ? null
                                          : () => confirmFollowRequest(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: const Text(
                                        "Confirm",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: n["isLoading"]
                                          ? null
                                          : () => ignoreFollowRequest(index),
                                      style: OutlinedButton.styleFrom(
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: const Text(
                                        "Ignore",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            // 🔥 STARTED FOLLOWING (not mutual) → Follow Back / Cancel
                            else if (n["status_ui"] == "requested")
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: n["isLoading"]
                                          ? null
                                          : () => confirmRequest(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: const Text(
                                        "Follow back",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: n["isLoading"]
                                          ? null
                                          : () => cancelRequest(index),
                                      style: OutlinedButton.styleFrom(
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(fontSize: 12),
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
    );
  }
}

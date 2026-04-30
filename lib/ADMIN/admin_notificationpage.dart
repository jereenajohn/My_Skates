import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminNotificationpage extends StatefulWidget {
  const AdminNotificationpage({super.key});

  @override
  State<AdminNotificationpage> createState() => _AdminNotificationpageState();
}

class _AdminNotificationpageState extends State<AdminNotificationpage> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() => loading = false);
        return;
      }

      final response = await http.get(
        Uri.parse("$api/api/myskates/notifications/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("ADMIN NOTIFICATION STATUS: ${response.statusCode}");
      print("ADMIN NOTIFICATION BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded["data"] ?? [];

        notifications = data.map<Map<String, dynamic>>((e) {
          final m = Map<String, dynamic>.from(e);

          m["created_at"] =
              DateTime.tryParse(m["created_at"]?.toString() ?? "") ??
                  DateTime.now();

          m["is_read"] = m["is_read"] ?? false;

          return m;
        }).toList()
          ..sort(
            (a, b) => (b["created_at"] as DateTime).compareTo(
              a["created_at"] as DateTime,
            ),
          );
      }

      setState(() => loading = false);
    } catch (e) {
      print("ADMIN NOTIFICATION ERROR: $e");
      setState(() => loading = false);
    }
  }

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

  Widget avatar(String? imageUrl, String name) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.teal.withOpacity(0.25),
      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
          ? NetworkImage(imageUrl)
          : null,
      child: imageUrl == null || imageUrl.isEmpty
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

  Widget notificationTile(Map<String, dynamic> n) {
    final name =
        "${n["actor_first_name"] ?? ""} ${n["actor_last_name"] ?? ""}".trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar(n["actor_profile"], name),
          const SizedBox(width: 12),

          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: name.isEmpty ? "Someone" : name,
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
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (n["is_read"] == false)
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.tealAccent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : notifications.isEmpty
              ? const Center(
                  child: Text(
                    "No notifications",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  color: Colors.tealAccent,
                  backgroundColor: Colors.black,
                  onRefresh: fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return notificationTile(notifications[index]);
                    },
                  ),
                ),
    );
  }
}
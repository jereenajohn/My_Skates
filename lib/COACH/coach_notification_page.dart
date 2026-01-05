import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class CoachNotificationPage extends StatefulWidget {
  const CoachNotificationPage({super.key});

  @override
  State<CoachNotificationPage> createState() =>
      _CoachNotificationPageState();
}

class _CoachNotificationPageState extends State<CoachNotificationPage> {
  List<Map<String, dynamic>> requests = [];
  bool loading = true;
  List<Map<String, dynamic>> notifications = [];
bool notifLoading = true;


  @override
  void initState() {
    super.initState();
    initLoad();
  }

  Future<void> initLoad() async {
    await fetchRequests();
    await syncApprovedFollowBacks();
     await fetchNotifications();   
  }
String notificationText(Map<String, dynamic> n) {
  final type = n["notification_type"];
  final name =
      "${n["actor_first_name"] ?? ""} ${n["actor_last_name"] ?? ""}".trim();

  switch (type) {
    case "follow_approved":
      return "$name accepted your follow request";
    case "follow_request":
      return "$name requested to follow you";
    case "repost":
      return "$name reposted your post";
    case "like":
      return "$name liked your post";
    case "comment":
      return "$name commented on your post";
    default:
      return "$name sent a notification";
  }
}


Future<void> fetchNotifications() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.get(
      Uri.parse("$api/api/myskates/notifications/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List data = decoded["data"];

      setState(() {
        notifications = data.map<Map<String, dynamic>>((e) {
          final m = Map<String, dynamic>.from(e);
          m["created_at"] =
              DateTime.tryParse(m["created_at"] ?? "") ??
                  DateTime.now();
          return m;
        }).toList();

        notifLoading = false;
      });
    } else {
      notifLoading = false;
    }
  } catch (e) {
    notifLoading = false;
  }
}

  Future<void> fetchRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/user/follow/requests/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body);

        setState(() {
          requests = raw.map<Map<String, dynamic>>((e) {
            final m = Map<String, dynamic>.from(e);
            m["status_ui"] = "pending";
            m["isLoading"] = false;
            m["created_at"] =
                DateTime.tryParse(m["created_at"] ?? "") ??
                    DateTime.now();
            return m;
          }).toList();
          loading = false;
        });
      } else {
        loading = false;
      }
    } catch (_) {
      loading = false;
    }
  }

  Future<void> confirmRequest(int index) async {
    final r = requests[index];
    r["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/approve/"),
      headers: {"Authorization": "Bearer $token"},
      body: {
        "request_id": r["id"].toString(),
        "action": "approved",
      },
    );

    if (res.statusCode == 200) {
      final approvedRes = await http.get(
        Uri.parse("$api/api/myskates/user/follow/sent/approved/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (approvedRes.statusCode == 200) {
        final List approved = jsonDecode(approvedRes.body);
        final approvedIds =
            approved.map((e) => e["following"]).toSet();

        if (approvedIds.contains(r["follower"])) {
          r["status_ui"] = "mutual";
        } else {
          r["status_ui"] = "follow_back";
        }
      }
    }

    r["isLoading"] = false;
    setState(() {});
  }

  Future<void> followBack(int index) async {
    final r = requests[index];
    r["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/request/"),
      headers: {"Authorization": "Bearer $token"},
      body: {"following_id": r["follower"].toString()},
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      r["status_ui"] =
          data["status"] == "approved" ? "mutual" : "requested";
    }

    r["isLoading"] = false;
    setState(() {});
  }
Future<void> syncApprovedFollowBacks() async {
  print("===== SYNC APPROVED FOLLOW BACKS =====");

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");
  print("TOKEN: $token");

  final res = await http.get(
    Uri.parse("$api/api/myskates/user/follow/sent/approved/"),
    headers: {"Authorization": "Bearer $token"},
  );

  print("SYNC STATUS CODE: ${res.statusCode}");
  print("SYNC RESPONSE BODY: ${res.body}");

  if (res.statusCode == 200) {
    final List approved = jsonDecode(res.body);
    final approvedIds =
        approved.map((e) => e["following"]).toSet();

    print("APPROVED FOLLOWING IDS: $approvedIds");

    setState(() { 
      for (final r in requests) {
        print(
            "CHECKING REQUEST → ${r["follower_name"]} | STATUS: ${r["status_ui"]}");

        if (r["status_ui"] == "requested" &&
            approvedIds.contains(r["follower"])) {
          r["status_ui"] = "following";
          print(
              "STATUS UPDATED → following FOR ${r["follower_name"]}");
        }
      }
    });
  } else {
    print("SYNC FAILED");
  }

  print("===== SYNC END =====");
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
  backgroundColor: Colors.black,
  elevation: 0,
  centerTitle: false,
  title: const Text(
    "Notifications",
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: Colors.white,
    ),
  ),
  actions: [
    IconButton(
      onPressed: () {
        // future: mark all read
      },
      icon: const Icon(
        Icons.more_vert,
        color: Colors.white70,
      ),
    ),
  ],
),

    body: notifLoading
    ? const Center(child: CircularProgressIndicator())
    : ListView(
        children: [
          if (notifications.isNotEmpty)
            ...notifications.map(_notificationItem).toList(),

          if (requests.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                "Follow Requests",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),

          ...requests
              .map((e) =>
                  _notificationTile(Map<String, dynamic>.from(e)))
              .toList(),
        ],
      ),
    );  
  }

  Widget _notificationTile(Map<String, dynamic> r) {
    final index =
        requests.indexWhere((e) => e["id"] == r["id"]);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundImage: AssetImage("lib/assets/img.jpg"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white),
                children: [
                  TextSpan(
                    text: r["follower_name"] ?? "",
                    style:
                        const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: " ${_statusText(r["status_ui"])}",
                    style:
                        const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          if (r["status_ui"] == "pending")
            _primaryBtn("Confirm",
                () => confirmRequest(index),
                loading: r["isLoading"])
          else if (r["status_ui"] == "follow_back")
            _primaryBtn("Follow back",
                () => followBack(index),
                loading: r["isLoading"])
          else
            _outlineBtn(
                r["status_ui"] == "mutual"
                    ? "Following"
                    : "Requested"),
        ],
      ),
    );
  }


  Widget _notificationItem(Map<String, dynamic> n) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: n["actor_profile"] != null
              ? NetworkImage(n["actor_profile"])
              : const AssetImage("lib/assets/img.jpg") as ImageProvider,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notificationText(n),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _timeAgo(n["created_at"]),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);

  if (diff.inMinutes < 1) return "Just now";
  if (diff.inMinutes < 60) return "${diff.inMinutes}m";
  if (diff.inHours < 24) return "${diff.inHours}h";
  if (diff.inDays < 7) return "${diff.inDays}d";
  return "${date.day}/${date.month}/${date.year}";
}


  String _statusText(String status) {
    switch (status) {
      case "pending":
        return "requested to follow you";
      case "follow_back":
        return "started following you";
      case "requested":
        return "follow request sent";
      case "mutual":
        return "you follow each other";
      default:
        return "";
    }
  }

  Widget _primaryBtn(String text, VoidCallback onTap,
      {bool loading = false}) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2EE6A6),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ),
    );
  }

  Widget _outlineBtn(String text) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: null,
        child: Text(text,
            style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}

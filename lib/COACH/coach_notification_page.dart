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

      // 🔐 STEP 0: FETCH MUTUAL FOLLOW (AUTHORITATIVE STATE)
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
      // STEP 3: TRACK ACTORS WHO REACHED FOLLOW-BACK
      // ─────────────────────────────────────────────
      final Set<int> hadFollowBackRequest = {};

      for (final n in temp) {
        if (n["notification_type"] == "follow_back_request" ||
            n["notification_type"] == "follow_back_accepted") {
          hadFollowBackRequest.add(n["actor"]);
        }
      }

      // ─────────────────────────────────────────────
      // STEP 4: DEDUPLICATE BY ACTOR (WITH HARD OVERRIDE)
      // ─────────────────────────────────────────────
      final Map<int, Map<String, dynamic>> byActor = {};

      int priority(String type) {
        switch (type) {
          case "follow_back_accepted":
            return 4; // mutual
          case "follow_back_request":
            return 3; // needs confirm
          case "follow_approved":
            return 2; // one-way
          case "follow_request":
            return 1;
          default:
            return 0;
        }
      }

      for (final n in temp) {
        final int actorId = n["actor"];

        // 1️⃣ FOLLOW BACK REQUEST MUST SURVIVE
        if (n["notification_type"] == "follow_back_request") {
          n["status_ui"] = "follow_back_pending";
          byActor[actorId] = n;
          continue;
        }

        // 2️⃣ MUTUAL FOLLOW IS TERMINAL (ONLY SOURCE OF TRUTH)
        if (mutualFollowIds.contains(actorId)) {
          n["notification_type"] = "follow_back_accepted";
          n["status_ui"] = "following";
          byActor[actorId] = n;
          continue;
        }

        // 3️⃣ NORMAL DEDUPE
        if (!byActor.containsKey(actorId)) {
          byActor[actorId] = n;
        } else {
          final existing = byActor[actorId]!;
          if (priority(n["notification_type"]) >
              priority(existing["notification_type"])) {
            byActor[actorId] = n;
          }
        }
      }

      // ─────────────────────────────────────────────
      // STEP 5: FINAL SORT & ASSIGN
      // ─────────────────────────────────────────────
      notifications = byActor.values.toList()
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
        // ✅ FINAL STEP → MUTUAL FOLLOW
        n["status_ui"] = "following";
        n["notification_type"] = "follow_back_accepted";
      } else {
        // normal follow request approval
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
    print(res.statusCode);
    print(res.body);
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
      // UI-only state (waiting)
      n["status_ui"] = "follow_back_sent";
      n["notification_type"] = "follow_back_request";
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
      Uri.parse("$api/api/myskates/user/follow/cancel/"),
      headers: {"Authorization": "Bearer $token"},
      body: {
        "request_id": n["follow_request_id"].toString(),
        "action": "rejected",
      },
    );

    print(res.statusCode);
    print(res.body);

    if (res.statusCode == 200) {
      notifications.removeAt(index);
    }

    setState(() {});
  }

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

  // ================= HELPERS =================
  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    return DateFormat("dd MMM").format(dt);
  }

  String notificationText(Map<String, dynamic> n) {
    if (n["status_ui"] == "following") {
      return "you are now following each other";
    }
    if (n["status_ui"] == "follow_back_sent") {
      return "you sent a follow request";
    }

    switch (n["notification_type"]) {
      case "follow_request":
        return "has sent you a follow request";

      case "follow_back_request":
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
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
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
                        ? const Color.fromARGB(255, 0, 0, 0) // unread
                        : const Color(0xFF0F0F0F), // read
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
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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
                            if (n["status_ui"] == "following" ||
                                n["status_ui"] == "follow_back_sent")
                              const SizedBox.shrink()
                            // 🔵 FOLLOW REQUEST → Confirm / Ignore
                            else if (n["status_ui"] == "request_pending")
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.tealAccent.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: n["isLoading"]
                                          ? null
                                          : () => confirmFollowRequest(index),
                                      child: const Text("Confirm"),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.tealAccent.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: n["isLoading"]
                                          ? null
                                          : () => ignoreFollowRequest(index),
                                      child: const Text("Ignore"),
                                    ),
                                  ],
                                ),
                              )
                            // 🔵 FOLLOW BACK REQUEST → Confirm / Cancel
                            else if (n["status_ui"] == "follow_back_pending")
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.tealAccent.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: n["isLoading"]
                                          ? null
                                          : () => confirmFollowRequest(index),
                                      child: const Text("Confirm"),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.tealAccent.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: n["isLoading"]
                                          ? null
                                          : () => cancelRequest(index),
                                      child: const Text("Cancel"),
                                    ),
                                  ],
                                ),
                              )
                            // 🟢 AFTER APPROVAL → Follow back / Cancel
                            else if (n["status_ui"] == "approved")
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.tealAccent.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: n["isLoading"]
                                          ? null
                                          : () => confirmRequest(index),
                                      child: const Text("Follow back"),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                        style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.tealAccent.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: n["isLoading"]
                                          ? null
                                          : () => cancelRequest(index),
                                      child: const Text("Cancel"),
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

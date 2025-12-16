import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class CoachActivityPage extends StatefulWidget {
  const CoachActivityPage({super.key});

  @override
  State<CoachActivityPage> createState() => _CoachActivityPageState();
}

class _CoachActivityPageState extends State<CoachActivityPage> {
  bool loading = true;
  List<ActivityItem> activities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ------------------------------------------------------------
  // LOAD DATA (UNCHANGED FUNCTIONALITY)
  // ------------------------------------------------------------
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final reqRes = await http.get(
      Uri.parse("$api/api/myskates/user/follow/requests/"),
      headers: {"Authorization": "Bearer $token"},
    );

    final appRes = await http.get(
      Uri.parse("$api/api/myskates/user/follow/sent/approved/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (reqRes.statusCode == 200 && appRes.statusCode == 200) {
      final List req = jsonDecode(reqRes.body);
      final List app = jsonDecode(appRes.body);

      final List<ActivityItem> temp = [];

      for (final r in req) {
        temp.add(
          ActivityItem(
            id: "req_${r["id"]}",
            requestId: r["id"],
            userId: r["follower"],
            username: r["follower_name"] ?? "User",
            message: "wants to connect with you.",
            statusUi: "pending",
            time: DateTime.parse(r["created_at"]),
          ),
        );
      }

      for (final a in app) {
        temp.add(
          ActivityItem(
            id: "acc_${a["id"]}",
            userId: a["following"],
            username: a["following_name"] ?? "User",
            message: "you’re now connected.",
            statusUi: "following",
            time: DateTime.parse(a["created_at"]),
          ),
        );
      }

      temp.sort((a, b) => b.time.compareTo(a.time));

      setState(() {
        activities = temp;
        loading = false;
      });
    } else {
      // If API fails, still stop loader to avoid infinite spinner
      setState(() {
        loading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // FOLLOW ACTIONS (UNCHANGED FUNCTIONALITY)
  // ------------------------------------------------------------
  Future<void> confirmRequest(ActivityItem a) async {
    a.isLoading = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/approve/"),
      headers: {"Authorization": "Bearer $token"},
      body: {"request_id": a.requestId.toString(), "action": "approved"},
    );

    if (res.statusCode == 200) {
      a.statusUi = "follow_back";
    }

    a.isLoading = false;
    setState(() {});
  }

  Future<void> rejectRequest(ActivityItem a) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/approve/"),
      headers: {"Authorization": "Bearer $token"},
      body: {"request_id": a.requestId.toString(), "action": "rejected"},
    );

    if (res.statusCode == 200) {
      activities.remove(a);
      setState(() {});
    }
  }

  Future<void> followBack(ActivityItem a) async {
    a.isLoading = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/request/"),
      headers: {"Authorization": "Bearer $token"},
      body: {"following_id": a.userId.toString()},
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      // ✅ as requested: do NOT remove item; show Requested
      a.statusUi = "requested";
    }

    a.isLoading = false;
    setState(() {});
  }

  // ------------------------------------------------------------
  // TIME LABEL
  // ------------------------------------------------------------
  String _timeLabel(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return "${d.inMinutes}m";
    if (d.inHours < 24) return "${d.inHours}h";
    return "${d.inDays}d";
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Activity",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : activities.isEmpty
          ? _emptyNotificationsView(context)
          : ListView.separated(
              itemCount: activities.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (_, i) => _notificationRow(activities[i]),
            ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY NOTIFICATIONS DESIGN (AS PER IMAGE)
  // ------------------------------------------------------------
  Widget _emptyNotificationsView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bell + badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 130,
                  width: 130,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: const Center(
                      child: Text(
                        "0",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Text(
              "No Notification to show",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            const Text(
              "You currently have no notifications. We will\nnotify you when something new happens!",
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13.5,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 22),

            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  // Keep it simple: close page or navigate to your Explore page
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 35, 188, 160),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Explore",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PROFESSIONAL NOTIFICATION ROW
  // ------------------------------------------------------------
  Widget _notificationRow(ActivityItem a) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage("lib/assets/img.jpg"),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: a.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: " "),
                      TextSpan(
                        text: a.message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _timeLabel(a.time),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),

          if (_showActions(a)) ...[
            const SizedBox(width: 12),
            _actionButtons(a),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ACTION VISIBILITY
  // ------------------------------------------------------------
  bool _showActions(ActivityItem a) {
    return a.statusUi == "pending" ||
        a.statusUi == "follow_back" ||
        a.statusUi == "requested";
  }

  // ------------------------------------------------------------
  // ACTION BUTTONS (UNCHANGED FUNCTIONALITY)
  // ------------------------------------------------------------
  Widget _actionButtons(ActivityItem a) {
    if (a.statusUi == "pending") {
      return Wrap(
        spacing: 8,
        children: [
          _primaryBtn("Confirm", () => confirmRequest(a), a.isLoading),
          _outlineBtn("Delete", () => rejectRequest(a)),
        ],
      );
    }

    if (a.statusUi == "follow_back") {
      return _primaryBtn("Follow back", () => followBack(a), a.isLoading);
    }

    if (a.statusUi == "requested") {
      return _outlineStatic("Requested");
    }

    return const SizedBox.shrink();
  }

  // ------------------------------------------------------------
  // BUTTON STYLES (POLISHED)
  // ------------------------------------------------------------
  Widget _primaryBtn(String text, VoidCallback onTap, bool loading) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 26, 180, 152),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _outlineBtn(String text, VoidCallback onTap) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white30),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
      ),
    );
  }

  Widget _outlineStatic(String text) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// MODEL (UNCHANGED FUNCTIONALITY)
// ------------------------------------------------------------
class ActivityItem {
  final String id;
  final int userId;
  final int? requestId;
  final String username;
  final String message;
  String statusUi;
  bool isLoading;
  final DateTime time;

  ActivityItem({
    required this.id,
    required this.userId,
    required this.username,
    required this.message,
    required this.statusUi,
    required this.time,
    this.requestId,
    this.isLoading = false,
  });
}

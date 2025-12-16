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

      // Incoming requests
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

      // Approved / mutual
      for (final a in app) {
        temp.add(
          ActivityItem(
            id: "acc_${a["id"]}",
            userId: a["following"],
            username: a["following_name"] ?? "User",
            message: "you're now connected.",
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
      body: {
        "request_id": a.requestId.toString(),
        "action": "approved",
      },
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
      body: {
        "request_id": a.requestId.toString(),
        "action": "rejected",
      },
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
      a.statusUi = "following";
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
        title: const Text("Activity", style: TextStyle(color: Colors.white)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              itemCount: activities.length,
              itemBuilder: (_, i) => _notificationRow(activities[i]),
            ),
    );
  }

  // ------------------------------------------------------------
  // INSTAGRAM-STYLE ROW (DESIGN CHANGE ONLY)
  // ------------------------------------------------------------
  Widget _notificationRow(ActivityItem a) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    children: [
                      TextSpan(
                        text: a.username,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: " "),
                      TextSpan(text: a.message),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeLabel(a.time),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          if (_showActions(a)) ...[
            const SizedBox(width: 10),
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
  // ACTION BUTTONS (CONFIRM + DELETE INCLUDED)
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
      return _primaryBtn("Follow Back", () => followBack(a), a.isLoading);
    }

    if (a.statusUi == "requested") {
      return _outlineStatic("Requested");
    }

    return const SizedBox.shrink();
  }

  // ------------------------------------------------------------
  // BUTTON STYLES (INSTAGRAM-LIKE)
  // ------------------------------------------------------------
  Widget _primaryBtn(
      String text, VoidCallback onTap, bool loading) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F80ED),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _outlineBtn(String text, VoidCallback onTap) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white30),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  Widget _outlineStatic(String text) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
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

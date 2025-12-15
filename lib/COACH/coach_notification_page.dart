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
  Set<String> readIds = {};

  @override
  void initState() {
    super.initState();
    _loadReadState();
    _loadData();
  }

  // ------------------------------------------------------------
  // READ STATE
  // ------------------------------------------------------------
  Future<void> _loadReadState() async {
    final prefs = await SharedPreferences.getInstance();
    readIds = prefs.getStringList("read_activity")?.toSet() ?? {};
  }

  Future<void> _markRead(String id) async {
    if (readIds.contains(id)) return;
    readIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("read_activity", readIds.toList());
    setState(() {});
  }

  // ------------------------------------------------------------
  // SAFE ID
  // ------------------------------------------------------------
  String _safeId(String type, Map m) {
    return "${type}_${m["created_at"]}_${m["follower"] ?? m["following"]}";
  }

  // ------------------------------------------------------------
  // LOAD DATA
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
            id: _safeId("req", r),
            userId: r["follower"],
            username: r["follower_name"] ?? "User",
            message: "wants to connect with you",
            status: ActivityStatus.pending,
            time: DateTime.parse(r["created_at"]),
          ),
        );
      }

      for (final a in app) {
        temp.add(
          ActivityItem(
            id: _safeId("acc", a),
            userId: a["following"],
            username: a["following_name"] ?? "User",
            message: "you’re now connected",
            status: ActivityStatus.mutual,
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
  // TIME HELPERS
  // ------------------------------------------------------------
  bool _isNow(DateTime t) =>
      DateTime.now().difference(t).inMinutes < 5;

  bool _isToday(DateTime t) {
    final n = DateTime.now();
    return n.year == t.year && n.month == t.month && n.day == t.day;
  }

  String _timeLabel(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return "Now";
    if (d.inMinutes < 60) return "${d.inMinutes}m";
    if (d.inHours < 24) return "${d.inHours}h";
    return "${t.day}/${t.month}/${t.year}";
  }


Widget _weeklyGrowthCard() {
  final now = DateTime.now();
  final weekStart = now.subtract(const Duration(days: 7));

  final weeklyCount = activities.where(
    (a) =>
        a.status == ActivityStatus.mutual &&
        a.time.isAfter(weekStart),
  ).length;

  if (weeklyCount == 0) return const SizedBox();

  return Container(
    margin: const EdgeInsets.fromLTRB(20, 12, 20, 18),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.trending_up,
            color: Colors.greenAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Network Growth",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "You gained $weeklyCount new connection${weeklyCount > 1 ? "s" : ""} this week",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        title: const Text("Activity", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : ListView(
  padding: const EdgeInsets.only(top: 12, bottom: 24),
  children: [
    _weeklyGrowthCard(),

    if (activities.any((a) => _isNow(a.time)))
      _section("Now", (a) => _isNow(a.time)),

    if (activities.any(
        (a) => !_isNow(a.time) && _isToday(a.time)))
      _section("Today",
          (a) => !_isNow(a.time) && _isToday(a.time)),

    if (activities.any((a) => !_isToday(a.time)))
      _section("Earlier", (a) => !_isToday(a.time)),
  ],
)

    );
  }

  // ------------------------------------------------------------
  // SECTION
  // ------------------------------------------------------------
  Widget _section(
      String title, bool Function(ActivityItem) test) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...activities.where(test).map(_timelineTile),
      ],
    );
  }

  // ------------------------------------------------------------
  // TIMELINE TILE
  // ------------------------------------------------------------
  Widget _timelineTile(ActivityItem a) {
    final isRead = readIds.contains(a.id);

    return InkWell(
      onTap: () {
        _markRead(a.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfilePage(userId: a.userId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white24 : Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.white12,
                ),
              ],
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          AssetImage("lib/assets/img.jpg"),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                a.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _statusChip(a.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            a.message,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

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
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // STATUS CHIP
  // ------------------------------------------------------------
  Widget _statusChip(ActivityStatus s) {
    final color =
        s == ActivityStatus.mutual ? Colors.greenAccent : Colors.orangeAccent;
    final text = s == ActivityStatus.mutual ? "MUTUAL" : "PENDING";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// MODEL
// ------------------------------------------------------------
enum ActivityStatus { pending, mutual }

class ActivityItem {
  final String id;
  final int userId;
  final String username;
  final String message;
  final ActivityStatus status;
  final DateTime time;

  ActivityItem({
    required this.id,
    required this.userId,
    required this.username,
    required this.message,
    required this.status,
    required this.time,
  });
}

// ------------------------------------------------------------
// PROFILE PLACEHOLDER
// ------------------------------------------------------------
class UserProfilePage extends StatelessWidget {
  final int userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: Text("User ID: $userId"),
      ),
    );
  }
}

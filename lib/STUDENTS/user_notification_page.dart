import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class StudentNotificationPage extends StatefulWidget {
  const StudentNotificationPage({super.key});

  @override
  State<StudentNotificationPage> createState() =>
      _StudentNotificationPageState();
}

class _StudentNotificationPageState extends State<StudentNotificationPage> {
  List<Map<String, dynamic>> requests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    initLoad();
  }

  Future<void> initLoad() async {
    await fetchRequests();
    await syncApprovedFollowBacks();
  }

  // ------------------------------------------------------------
  // FETCH REQUESTS
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // CONFIRM REQUEST
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // FOLLOW BACK
  // ------------------------------------------------------------
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
      r["status_ui"] = "requested";
    }

    r["isLoading"] = false;
    setState(() {});
  }

  // ------------------------------------------------------------
  // SYNC FOLLOW BACK
  // ------------------------------------------------------------
  Future<void> syncApprovedFollowBacks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.get(
      Uri.parse("$api/api/myskates/user/follow/sent/approved/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) return;

    final List approved = jsonDecode(res.body);
    final approvedIds =
        approved.map((e) => e["following"]).toSet();

    setState(() {
      for (final r in requests) {
        if (r["status_ui"] == "requested" &&
            approvedIds.contains(r["follower"])) {
          r["status_ui"] = "following";
        }
      }
    });
  }

  // ------------------------------------------------------------
  // GROUPING
  // ------------------------------------------------------------
  List<Map<String, dynamic>> todayList() {
    return requests.where((r) {
      final d = r["created_at"] as DateTime;
      return d.difference(DateTime.now()).inDays == 0;
    }).toList();
  }

  List<Map<String, dynamic>> weekList() {
    return requests.where((r) {
      final d = r["created_at"] as DateTime;
      return d.difference(DateTime.now()).inDays < 7;
    }).toList();
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (todayList().isNotEmpty)
                  _section("Today", todayList()),
                if (weekList().isNotEmpty)
                  _section("This Week", weekList()),
              ],
            ),
    );
  }

  Widget _section(String title, List<Map<String, dynamic>> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
        ),
        ...data.map((e) => _notificationTile(
              Map<String, dynamic>.from(e),
            )),
      ],
    );
  }

  Widget _notificationTile(Map<String, dynamic> r) {
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
                  if (r["status_ui"] == "mutual")
                    const WidgetSpan(
                      child: Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.all_inclusive,
                            size: 14, color: Colors.green),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _actionButton(r),
        ],
      ),
    );
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

  Widget _actionButton(Map<String, dynamic> r) {
    final index =
        requests.indexWhere((e) => e["id"] == r["id"]);

    if (r["status_ui"] == "pending") {
      return _primaryBtn(
        "Confirm",
        () => confirmRequest(index),
        loading: r["isLoading"],
      );
    }

    if (r["status_ui"] == "follow_back") {
      return _primaryBtn(
        "Follow back",
        () => followBack(index),
        loading: r["isLoading"],
      );
    }

    return _outlineBtn(
      r["status_ui"] == "mutual" ? "Following" : "Requested",
    );
  }

  Widget _primaryBtn(String text, VoidCallback onTap,
      {bool loading = false}) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
        ),
        child: loading
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(text, style: const TextStyle(fontSize: 12)),
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

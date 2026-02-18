import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class CoachFollowRequest extends StatefulWidget {
  const CoachFollowRequest({super.key});

  @override
  State<CoachFollowRequest> createState() => _CoachFollowRequestState();
}

class _CoachFollowRequestState extends State<CoachFollowRequest> {
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
  // FETCH INCOMING FOLLOW REQUESTS
  // ------------------------------------------------------------
  Future<void> fetchRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/user/follow/requests/"),
        headers: {"Authorization": "Bearer $token"},
      );
      print("========== FETCH REQUESTS ==========");
      print("STATUS CODE: ${res.statusCode}");
      print("RESPONSE BODY: ${res.body}");
      print("====================================");
      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body);

        setState(() {
          requests = raw.map<Map<String, dynamic>>((e) {
            final m = Map<String, dynamic>.from(e);
            m["status_ui"] =
                "pending"; // pending | follow_back | requested | following
            m["isLoading"] = false;
              print("MAPPED REQUEST ITEM: $m");
            return m;
          }).toList();
          loading = false;
        });
         print("REQUESTS STATE UPDATED. COUNT: ${requests.length}");
      } else {
              print("❌ NON-200 RESPONSE");

        loading = false;
      }
    } catch (e) {
        print("🔥 FETCH REQUESTS ERROR: $e");
      loading = false;
    }
  }

  // ------------------------------------------------------------
  // CONFIRM (APPROVE) REQUEST
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
    // 🔍 check if already following
    final approvedRes = await http.get(
      Uri.parse("$api/api/myskates/user/follow/sent/approved/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (approvedRes.statusCode == 200) {
      final List approved = jsonDecode(approvedRes.body);
      final approvedIds =
          approved.map((e) => e["following"]).toSet();

      if (approvedIds.contains(r["follower"])) {
        requests.removeAt(index); // already mutual
      } else {
        r["status_ui"] = "follow_back";
      }
    }
  }

  r["isLoading"] = false;
  setState(() {});
}


  // ------------------------------------------------------------
  // FOLLOW BACK (SEND REQUEST)
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
    body: {
      "following_id": r["follower"].toString(),
    },
  );

  if (res.statusCode == 200 || res.statusCode == 201) {
    final data = jsonDecode(res.body);

    /// 🔑 IMPORTANT LOGIC
    if (data["status"] == "approved") {
      // Already following
      r["status_ui"] = "following";
    } else {
      // Request newly sent
      r["status_ui"] = "requested";
    }
  }

  r["isLoading"] = false;
  setState(() {});
}

  // ------------------------------------------------------------
  // REJECT REQUEST
  // ------------------------------------------------------------
Future<void> rejectRequest(int index) async {
  final r = requests[index];

  print("===== REJECT REQUEST =====");
  print("INDEX: $index");
  print("REQUEST ID: ${r["id"]}");

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");
  print("TOKEN: $token");

  final res = await http.post(
    Uri.parse("$api/api/myskates/user/follow/approve/"),
    headers: {"Authorization": "Bearer $token"},
    body: {
      "request_id": r["id"].toString(),
      "action": "rejected",
    },
  );

  print("REJECT STATUS CODE: ${res.statusCode}");
  print("REJECT RESPONSE BODY: ${res.body}");

  if (res.statusCode == 200) {
    print("REQUEST REMOVED FROM UI LIST");
    requests.removeAt(index);
    setState(() {});
  } else {
    print("REJECT FAILED");
  }

  print("===== REJECT END =====");
}

  // ------------------------------------------------------------
  // CHECK WHEN OTHER USER APPROVES FOLLOW BACK
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Follow Requests",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : requests.isEmpty
          ? const Center(
              child: Text(
                "No Follow Requests",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              itemCount: requests.length,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemBuilder: (_, i) {
                final r = requests[i];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundImage: AssetImage("lib/assets/img.jpg"),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r["follower_name"] ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r["status_ui"] == "following"
                                  ? "You are following each other"
                                  : "Requested to follow you",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ---------------- BUTTON STATES ----------------
                      if (r["status_ui"] == "pending") ...[
                        _btn(
                          text: "Confirm",
                          color: Colors.teal,
                          loading: r["isLoading"],
                          onTap: () => confirmRequest(i),
                        ),
                        const SizedBox(width: 8),
                        _outlineBtn(
                          text: "Delete",
                          onTap: () => rejectRequest(i),
                        ),
                      ] else if (r["status_ui"] == "follow_back") ...[
                        _btn(
                          text: "Follow back",
                          color: const Color(0xFF00AFA5),
                          loading: r["isLoading"],
                          onTap: () => followBack(i),
                        ),
                      ] else if (r["status_ui"] == "requested") ...[
                        _outlineBtn(text: "Requested"),
                      ] else ...[
                        _outlineBtn(text: "Following"),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ------------------------------------------------------------
  // BUTTON HELPERS
  // ------------------------------------------------------------
  Widget _btn({
    required String text,
    required Color color,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: loading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _outlineBtn({required String text, VoidCallback? onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white24),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70)),
    );
  }
}
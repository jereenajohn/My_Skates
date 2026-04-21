import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class StudentFollowRequest extends StatefulWidget {
  const StudentFollowRequest({super.key});

  @override
  State<StudentFollowRequest> createState() => _StudentFollowRequestState();
}

class _StudentFollowRequestState extends State<StudentFollowRequest> {
  List<Map<String, dynamic>> requests = [];
  bool loading = true;

  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredRequests = [];

  @override
  void initState() {
    super.initState();
    initLoad();
  }

  Future<void> initLoad() async {
    await fetchRequests();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body);

        setState(() {
          requests = raw.map<Map<String, dynamic>>((e) {
            final m = Map<String, dynamic>.from(e);
            m["status_ui"] = "pending";
            m["isLoading"] = false;
            return m;
          }).toList();

          filteredRequests = List.from(requests);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (_) {
      setState(() {
        loading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // CONFIRM REQUEST
  // ------------------------------------------------------------
  Future<void> confirmRequest(Map<String, dynamic> r) async {
    r["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/approve/"),
      headers: {"Authorization": "Bearer $token"},
      body: {"request_id": r["id"].toString(), "action": "approved"},
    );

    if (res.statusCode == 200) {
      final removedId = r["id"];
      requests.removeWhere((item) => item["id"] == removedId);
      filteredRequests.removeWhere((item) => item["id"] == removedId);
    }

    setState(() {});
  }

  // ------------------------------------------------------------
  // FOLLOW BACK
  // ------------------------------------------------------------

  // ------------------------------------------------------------
  // REJECT REQUEST
  // ------------------------------------------------------------
  Future<void> rejectRequest(Map<String, dynamic> r) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.post(
      Uri.parse("$api/api/myskates/user/follow/approve/"),
      headers: {"Authorization": "Bearer $token"},
      body: {"request_id": r["id"].toString(), "action": "rejected"},
    );

    if (res.statusCode == 200) {
      final removedId = r["id"];
      requests.removeWhere((item) => item["id"] == removedId);
      filteredRequests.removeWhere((item) => item["id"] == removedId);
      setState(() {});
    }
  }

  void filterRequests(String query) {
    final results = requests.where((request) {
      final followerName =
          (request["follower_name"] ?? "").toString().toLowerCase();

      return followerName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredRequests = results;
    });
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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: searchController,
                        onChanged: filterRequests,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Search requests",
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white54,
                          ),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(35),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(35),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredRequests.isEmpty
                          ? const Center(
                              child: Text(
                                "No matching requests",
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredRequests.length,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              itemBuilder: (_, i) {
                                final r = filteredRequests[i];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 28,
                                        backgroundImage: AssetImage(
                                          "lib/assets/img.jpg",
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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

                                      if (r["status_ui"] == "pending") ...[
                                        _btn(
                                          text: "Confirm",
                                          color: Colors.teal,
                                          loading: r["isLoading"],
                                          onTap: () => confirmRequest(r),
                                        ),
                                        const SizedBox(width: 8),
                                        _outlineBtn(
                                          text: "Delete",
                                          onTap: () => rejectRequest(r),
                                        ),
                                      ],
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
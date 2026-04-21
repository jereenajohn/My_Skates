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
            m["status_ui"] = "pending";
            m["isLoading"] = false;
            return m;
          }).toList();

          filteredRequests = List.from(requests);
          loading = false;
        });
        print("REQUESTS STATE UPDATED. COUNT: ${requests.length}");
      } else {
        print(" NON-200 RESPONSE");

        loading = false;
      }
    } catch (e) {
      print(" FETCH REQUESTS ERROR: $e");
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
      body: {"request_id": r["id"].toString(), "action": "approved"},
    );

    if (res.statusCode == 200) {
  // Remove request completely after approval
  requests.removeAt(index);
  filterRequests(searchController.text);
  return;
}

setState(() {});
  }

  // ------------------------------------------------------------
  // FOLLOW BACK (SEND REQUEST)
  // ------------------------------------------------------------

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
      body: {"request_id": r["id"].toString(), "action": "rejected"},
    );

    print("REJECT STATUS CODE: ${res.statusCode}");
    print("REJECT RESPONSE BODY: ${res.body}");

    if (res.statusCode == 200) {
  print("REQUEST REMOVED FROM UI LIST");
  requests.removeAt(index);
  filterRequests(searchController.text);
  return;
} else {
  print("REJECT FAILED");
}       

    print("===== REJECT END =====");
  }

  void filterRequests(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        filteredRequests = List.from(requests);
      } else {
        filteredRequests = requests.where((item) {
          final name = (item["follower_name"] ?? "").toString().toLowerCase();
          return name.contains(value.toLowerCase());
        }).toList();
      }
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterRequests,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search requests",
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                searchController.clear();
                                filterRequests('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredRequests.isEmpty
                      ? const Center(
                          child: Text(
                            "No Follow Requests",
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

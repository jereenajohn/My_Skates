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
  List requests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse("$api/api/myskates/user/follow/requests/"),
        headers: {"Authorization": "Bearer $token"},
      );
print(response.body);
      if (response.statusCode == 200) {
        setState(() {
          requests = jsonDecode(response.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> handleAction(int requestId, String action, int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.post(
        Uri.parse("$api/api/myskates/user/follow/approve/"),
        headers: {"Authorization": "Bearer $token"},
        body: {
          "request_id": requestId.toString(),
          "action": action,
        },
      );

      print("ACTION RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          requests.removeAt(index);
        });
      }
    } catch (e) {
      print("ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Follow Requests", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : requests.isEmpty
              ? const Center(
                  child: Text("No Follow Requests", style: TextStyle(color: Colors.white70, fontSize: 16)),
                )
              : ListView.builder(
                  itemCount: requests.length,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemBuilder: (_, i) {
                    final r = requests[i];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          // PROFILE IMAGE
                          const CircleAvatar(
                            radius: 28,
                            backgroundImage: AssetImage("lib/assets/img.jpg"),
                          ),
                          const SizedBox(width: 12),

                          // NAME + Message
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
                                const Text(
                                  "Requested to follow you",
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),

                          // CONFIRM BUTTON
                          ElevatedButton(
                            onPressed: () =>
                                handleAction(r["id"], "approved", i),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            child: const Text(
                              "Confirm",
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // DELETE BUTTON
                          OutlinedButton(
                            onPressed: () =>
                                handleAction(r["id"], "rejected", i),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.white70, fontSize: 13),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/coach_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class CoachFollowersList extends StatefulWidget {
  const CoachFollowersList({super.key});

  @override
  State<CoachFollowersList> createState() => _CoachFollowersListState();
}

class _CoachFollowersListState extends State<CoachFollowersList> {
  bool loading = true;
  bool noData = false;

  /// Normalized followers list
  /// Each item will have:
  /// id, first_name, last_name, profile, user_type
  List<Map<String, dynamic>> followers = [];

  @override
  void initState() {
    super.initState();
    fetchCoachFollowers();
  }

  // ------------------------------------------------------------
  // FETCH FOLLOWERS
  // ------------------------------------------------------------
  Future<void> fetchCoachFollowers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse("$api/api/myskates/user/followers/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("COACH FOLLOWERS STATUS: ${response.statusCode}");
      print("COACH FOLLOWERS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List raw = decoded["data"] ?? [];

        /// 🔹 Normalize API response here
        final List<Map<String, dynamic>> normalized = raw
            .map((e) {
              return {
                "id": e["follower__id"],
                "first_name": e["follower__first_name"],
                "last_name": e["follower__last_name"],
                "profile": e["follower__profile"],
                "user_type": e["follower__user_type"],
                "is_mutual": e["is_mutual"] ?? false,

                // 🔥 USE BACKEND TRUTH
                "follow_requested":
                    e["has_requested"] == true &&
                    e["request_status"] == "pending",

                "isLoading": false,
              };
            })
            .where((e) => e["id"] != null)
            .toList();

        setState(() {
          followers = normalized;
          noData = followers.isEmpty;
          loading = false;
        });
      } else {
        setState(() {
          noData = true;
          loading = false;
        });
      }
    } catch (e) {
      print("COACH FOLLOWERS ERROR: $e");
      setState(() {
        noData = true;
        loading = false;
      });
    }
  }

  Future<void> followBack(int followerId, int index) async {
    final follower = followers[index];
    follower["isLoading"] = true;
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final response = await http.post(
      Uri.parse("$api/api/myskates/user/follow/request/"),
      headers: {"Authorization": "Bearer $token"},
      body: {"following_id": followerId.toString()},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // 🔥 Do NOT mark mutual
      follower["follow_requested"] = true;
    }

    follower["isLoading"] = false;
    setState(() {});
  }

  // ------------------------------------------------------------
  // REMOVE FOLLOWER
  // ------------------------------------------------------------
  Future<void> removeFollower(int followerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.post(
        Uri.parse("$api/api/myskates/user/follow/remove/follower/"),
        headers: {"Authorization": "Bearer $token"},
        body: {"follower_id": followerId.toString()},
      );

      print("REMOVE FOLLOWER STATUS: ${response.statusCode}");
      print("REMOVE FOLLOWER BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          followers.removeWhere((f) => f["id"] == followerId);
          noData = followers.isEmpty;
        });
      }
    } catch (e) {
      print("REMOVE FOLLOWER ERROR: $e");
    }
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
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => CoachSettings()),
            );
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: const Text(
          "Coach Followers",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : noData
          ? const Center(
              child: Text(
                "No followers yet",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            )
          : ListView.separated(
              itemCount: followers.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, indent: 72),
              itemBuilder: (_, i) => _buildFollowerTile(followers[i]),
            ),
    );
  }

  // ------------------------------------------------------------
  // FOLLOWER TILE
  // ------------------------------------------------------------
  Widget _buildFollowerTile(Map<String, dynamic> follower) {
    final int followerId = follower["id"];
    final String name =
        "${follower["first_name"] ?? ""} ${follower["last_name"] ?? ""}".trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          const CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage("lib/assets/img.jpg"),
          ),

          const SizedBox(width: 14),

          // Name + User type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? "User" : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  follower["user_type"] ?? "",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1️⃣ Show Follow Back
              if (follower["is_mutual"] == false &&
                  follower["follow_requested"] != true)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: follower["isLoading"]
                        ? null
                        : () => followBack(
                            followerId,
                            followers.indexOf(follower),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size(0, 32), // 🔥 controls height
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: follower["isLoading"]
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Follow back",
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                  ),
                )
              // 2️⃣ Show Requested State
              else if (follower["follow_requested"] == true)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                    ),
                    child: const Text(
                      "Requested",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),

              // 3️⃣ Remove button (always visible)
              OutlinedButton(
                onPressed: () => removeFollower(followerId),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 30), // 🔥 smaller height
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize
                      .shrinkWrap, // 🔥 removes extra spacing
                  side: const BorderSide(color: Colors.white38, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  "Remove",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

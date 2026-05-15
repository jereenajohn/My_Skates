import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/bottomnavigation.dart';
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

  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  List<Map<String, dynamic>> filteredFollowers = [];

  @override
  void initState() {
    super.initState();
    fetchCoachFollowers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
          filteredFollowers = List.from(normalized);
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
          filteredFollowers.removeWhere((f) => f["id"] == followerId);
          noData = followers.isEmpty;
        });
      }
    } catch (e) {
      print("REMOVE FOLLOWER ERROR: $e");
    }
  }

  void filterFollowers(String query) {
    searchQuery = query.toLowerCase().trim();

    setState(() {
      if (searchQuery.isEmpty) {
        filteredFollowers = List.from(followers);
      } else {
        filteredFollowers = followers.where((follower) {
          final name =
              "${follower["first_name"] ?? ""} ${follower["last_name"] ?? ""}"
                  .toLowerCase()
                  .trim();

          final userType = (follower["user_type"] ?? "")
              .toString()
              .toLowerCase();

          return name.contains(searchQuery) || userType.contains(searchQuery);
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
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterFollowers,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search followers",
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white54,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController.clear();
                                filterFollowers("");
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white54,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: noData
                      ? const Center(
                          child: Text(
                            "No followers yet",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : filteredFollowers.isEmpty
                      ? const Center(
                          child: Text(
                            "No matching followers found",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredFollowers.length,
                          separatorBuilder: (_, _) =>
                              const Divider(color: Colors.white12, indent: 72),
                          itemBuilder: (_, i) =>
                              _buildFollowerTile(filteredFollowers[i]),
                        ),
                ),
              ],
            ),
            bottomNavigationBar: const AppBottomNav(currentIndex: 4),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
        final List<Map<String, dynamic>> normalized = raw.map((e) {
          return {
            "id": e["follower__id"],
            "first_name": e["follower__first_name"],
            "last_name": e["follower__last_name"],
            "profile": e["follower__profile"],
            "user_type": e["follower__user_type"],
          };
        }).where((e) => e["id"] != null).toList();

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
        body: {
          "follower_id": followerId.toString(),
        },
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
        title: const Text(
          "Coach Followers",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
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
                  itemBuilder: (_, i) =>
                      _buildFollowerTile(followers[i]),
                ),
    );
  }

  // ------------------------------------------------------------
  // FOLLOWER TILE
  // ------------------------------------------------------------
  Widget _buildFollowerTile(Map<String, dynamic> follower) {
    final int followerId = follower["id"];
    final String name =
        "${follower["first_name"] ?? ""} ${follower["last_name"] ?? ""}"
            .trim();

    return ListTile(
      leading: const CircleAvatar(
        radius: 22,
        backgroundImage: AssetImage("lib/assets/img.jpg"),
      ),
      title: Text(
        name.isEmpty ? "User" : name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        follower["user_type"] ?? "",
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: OutlinedButton(
        onPressed: () {
          removeFollower(followerId);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          "Remove",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

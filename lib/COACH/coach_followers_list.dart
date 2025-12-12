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
  List followers = [];

  @override
  void initState() {
    super.initState();
    fetchCoachFollowers();
  }

  // 🔹 Fetch followers of logged-in coach
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
        if (decoded is List) {
          setState(() {
            followers = decoded
                .where((f) => f["status"] == "approved")
                .toList();
            noData = followers.isEmpty;
            loading = false;
          });
        }
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

  // 🔹 Remove follower
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
          followers.removeWhere((f) => f["follower"] == followerId);
        });
      }
    } catch (e) {
      print("REMOVE FOLLOWER ERROR: $e");
    }
  }

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
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: followers.length,
                  itemBuilder: (_, i) =>
                      _buildFollowerTile(followers[i]),
                ),
    );
  }

  // 🔹 Instagram-style follower row
  Widget _buildFollowerTile(Map follower) {
    String name = follower["follower_name"] ?? "User";
    int followerId = follower["follower"];

    return ListTile(
      leading: const CircleAvatar(
        radius: 22,
        backgroundImage: AssetImage("lib/assets/img.jpg"),
      ),
      title: Text(
        name,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      subtitle: const Text(
        "Following you",
        style: TextStyle(color: Colors.white54, fontSize: 12),
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

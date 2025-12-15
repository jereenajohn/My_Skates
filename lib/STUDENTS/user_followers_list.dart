import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class UserFollowersList extends StatefulWidget {
  const UserFollowersList({super.key});

  @override
  State<UserFollowersList> createState() => _UserFollowersListState();
}

class _UserFollowersListState extends State<UserFollowersList> {
  bool loading = true;
  bool noData = false;
  List followers = [];

  @override
  void initState() {
    super.initState();
    fetchFollowers();
  }

  Future<void> fetchFollowers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse("$api/api/myskates/user/followers/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("FOLLOWERS STATUS: ${response.statusCode}");
      print("FOLLOWERS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final List data = decoded["data"] ?? [];

        setState(() {
          followers = data
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
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
      print("FOLLOWERS ERROR: $e");
      setState(() {
        noData = true;
        loading = false;
      });
    }
  }

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
        title: const Text("Followers", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : noData
          ? const Center(
              child: Text(
                "No followers yet",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              itemCount: followers.length,
              itemBuilder: (_, i) => _buildFollowerTile(followers[i]),
            ),
    );
  }

  Widget _buildFollowerTile(Map follower) {
    final String name =
        "${follower["follower__first_name"] ?? ""} ${follower["follower__last_name"] ?? ""}";
    final int followerId = follower["follower__id"];

    return ListTile(
      leading: const CircleAvatar(
        radius: 22,
        backgroundImage: AssetImage("lib/assets/img.jpg"),
      ),
      title: Text(
        name.trim(),
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      subtitle: Text(
        follower["follower__user_type"] ?? "",
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: OutlinedButton(
        onPressed: () {
          removeFollower(followerId);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text("Remove", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

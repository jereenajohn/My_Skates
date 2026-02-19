import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/STUDENTS/user_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class UserFollowing extends StatefulWidget {
  const UserFollowing({super.key});

  @override
  State<UserFollowing> createState() => _UserFollowingState();
}

class _UserFollowingState extends State<UserFollowing> {
  List<Map<String, dynamic>> following = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchFollowing();
  }

  // ------------------------------------------------------------
  // FETCH FOLLOWING LIST
  // ------------------------------------------------------------
  Future<void> fetchFollowing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/user/following/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("===== FETCH FOLLOWING =====");
      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");
      print("==========================");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final List raw = decoded["data"] ?? [];

        setState(() {
          following = raw
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
          loading = false;
        });
      } else {
        loading = false;
      }
    } catch (e) {
      print("FOLLOWING ERROR: $e");
      setState(() => loading = false);
    }
  }
 Future<void> unfollowUser(int followingUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.post(
        Uri.parse("$api/api/myskates/user/unfollow/"),
        headers: {"Authorization": "Bearer $token"},
      body: {"following_id": followingUserId.toString()},
      );

      print("UNFOLLOW STATUS: ${response.statusCode}");
      print("UNFOLLOW BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          following.removeWhere((f) => f["id"] == followingUserId);
        });
      }
    } catch (e) {
      print("UNFOLLOW ERROR: $e");
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
        title: const Text("Following", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : following.isEmpty
          ? const Center(
              child: Text(
                "You are not following anyone",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : ListView.separated(
              itemCount: following.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, indent: 80),
              itemBuilder: (_, i) {
                final f = following[i];

                return ListTile(
                  leading: const CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage("lib/assets/img.jpg"),
                  ),
                  title: Text(
                    "${f["first_name"] ?? ""} ${f["last_name"] ?? ""}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    f["user_type"] ?? "",
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () {
                      unfollowUser(f["id"]);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Unfollow",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

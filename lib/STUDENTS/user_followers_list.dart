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

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List raw = decoded["data"] ?? [];

      final normalized = raw.map<Map<String, dynamic>>((e) {
        return {
          "id": e["follower__id"],
          "first_name": e["follower__first_name"],
          "last_name": e["follower__last_name"],
          "profile": e["follower__profile"],
          "user_type": e["follower__user_type"],
          "is_mutual": e["is_mutual"] ?? false,
          "follow_requested":
              e["has_requested"] == true &&
              e["request_status"] == "pending",
          "isLoading": false,
        };
      }).toList();

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
    follower["follow_requested"] = true;
  }

  follower["isLoading"] = false;
  setState(() {});
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

Widget _buildFollowerTile(Map<String, dynamic> follower) {
  final int followerId = follower["id"];
  final String name =
      "${follower["first_name"] ?? ""} ${follower["last_name"] ?? ""}".trim();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundImage: AssetImage("lib/assets/img.jpg"),
        ),

        const SizedBox(width: 14),

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
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            // Follow back
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
                    minimumSize: const Size(0, 30),
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
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              )

            // Requested state
            else if (follower["follow_requested"] == true)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    "Requested",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),

            // Remove button
            OutlinedButton(
              onPressed: () => removeFollower(followerId),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(color: Colors.white38),
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
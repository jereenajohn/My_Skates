import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class ClubFollowersPage extends StatefulWidget {
  final int clubId;
  const ClubFollowersPage({super.key, required this.clubId});

  @override
  State<ClubFollowersPage> createState() => _ClubFollowersPageState();
}

class _ClubFollowersPageState extends State<ClubFollowersPage> {
  bool loading = true;
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
      if (token == null) return;

      final res = await http.get(
        Uri.parse("$api/api/myskates/club/${widget.clubId}/followers/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          followers = body["data"] ?? [];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (_) {
      setState(() => loading = false);
    }
  }
Future<void> kickFollower(int userId, int index) async {
  print("Calling kick API for userId: $userId");

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");
  if (token == null) return;

  final res = await http.post(
    Uri.parse("$api/api/myskates/club/kick/"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "club_id": widget.clubId,
      "user_id": userId,
    }),
  );

  print("Kick API response status: ${res.statusCode}");

  print("Kick API response body: ${res.body}");

  if (res.statusCode == 200) {
    setState(() {
      followers.removeAt(index);
    });
  }
}

  void confirmKick(int userId, int index, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "Remove follower?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Are you sure you want to remove $name from this club?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              kickFollower(userId, index);
            },
            child: const Text("Remove",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Club Members",style: TextStyle(color: Colors.white,fontSize: 15),),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : followers.isEmpty
              ? const Center(
                  child: Text(
                    "No followers yet",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.separated(
                  itemCount: followers.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: Colors.white12,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final f = followers[index];
                    final userId = f["id"];
                    final name =
                        "${f["first_name"] ?? ""} ${f["last_name"] ?? ""}"
                            .trim();
                    final profile = f["profile"];

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage:
                            (profile != null && profile.isNotEmpty)
                                ? NetworkImage("$api$profile")
                                : null,
                        backgroundColor: Colors.grey.shade800,
                        child: profile == null
                            ? const Icon(Icons.person,
                                color: Colors.white70)
                            : null,
                      ),
                      title: Text(
                        name.isEmpty ? "User" : name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                     trailing: IconButton(
  icon: const Icon(
    Icons.person_remove_alt_1,
    color: Colors.redAccent,
  ),
  onPressed: () {
    print("Kick pressed for userId: $userId");
    confirmKick(userId, index, name);
  },
),

                    );
                  },
                ),
    );
  }
}

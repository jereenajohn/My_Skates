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
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Followers"),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            )
          : followers.isEmpty
              ? const Center(
                  child: Text(
                    "No followers yet",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: followers.length,
                  itemBuilder: (context, index) {
                    final f = followers[index];
                    final String name =
                        "${f["first_name"] ?? ""} ${f["last_name"] ?? ""}";
                    final String? profile = f["profile"];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundImage: (profile != null &&
                                    profile.isNotEmpty)
                                ? NetworkImage("$api$profile")
                                : null,
                            backgroundColor: Colors.grey.shade800,
                            child: profile == null
                                ? const Icon(Icons.person,
                                    color: Colors.white70)
                                : null,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              name.trim().isEmpty ? "User" : name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
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

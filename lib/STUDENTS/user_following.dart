import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class UserFollowing extends StatefulWidget {
  const UserFollowing({super.key});

  @override
  State<UserFollowing> createState() => _UserFollowingState();
}

class _UserFollowingState extends State<UserFollowing> {
  List<Map<String, dynamic>> following = [];
  List<Map<String, dynamic>> filteredFollowing = [];
  final TextEditingController searchController = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchFollowing();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

        final fetchedFollowing = raw
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();

        setState(() {
          following = fetchedFollowing;
          filteredFollowing = List<Map<String, dynamic>>.from(fetchedFollowing);
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
          filteredFollowing.removeWhere((f) => f["id"] == followingUserId);
        });
      }
    } catch (e) {
      print("UNFOLLOW ERROR: $e");
    }
  }

  void filterFollowing(String query) {
    final q = query.toLowerCase().trim();

    if (q.isEmpty) {
      setState(() {
        filteredFollowing = List<Map<String, dynamic>>.from(following);
      });
      return;
    }

    setState(() {
      filteredFollowing = following.where((user) {
        final firstName = (user["first_name"] ?? "").toString().toLowerCase();
        final lastName = (user["last_name"] ?? "").toString().toLowerCase();
        final userType = (user["user_type"] ?? "").toString().toLowerCase();
        final fullName = "$firstName $lastName".trim();

        return fullName.contains(q) ||
            firstName.contains(q) ||
            lastName.contains(q) ||
            userType.contains(q);
      }).toList();
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
        title: const Text("Following", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterFollowing,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search following...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController.clear();
                                filterFollowing("");
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
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
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredFollowing.isEmpty
                      ? const Center(
                          child: Text(
                            "No matching users found",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredFollowing.length,
                          separatorBuilder: (_, _) =>
                              const Divider(color: Colors.white12, indent: 80),
                          itemBuilder: (_, i) {
                            final f = filteredFollowing[i];

                            return ListTile(
                              leading: const CircleAvatar(
                                radius: 26,
                                backgroundImage: AssetImage(
                                  "lib/assets/img.jpg",
                                ),
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
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
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
                ),
              ],
            ),
    );
  }
}

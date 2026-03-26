import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/coach_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class CoachFollowingList extends StatefulWidget {
  const CoachFollowingList({super.key});

  @override
  State<CoachFollowingList> createState() => _CoachFollowingListState();
}

class _CoachFollowingListState extends State<CoachFollowingList> {
  List<Map<String, dynamic>> following = [];
  bool loading = true;

  final TextEditingController searchController = TextEditingController();
String searchQuery = "";

List<Map<String, dynamic>> filteredFollowing = [];

  @override
  void initState() {
    super.initState();
    fetchFollowing();
  }

  // -----------------------------------------------------------
  //                 FETCH FOLLOWING LIST
  // -----------------------------------------------------------
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
        final decoded = jsonDecode(res.body); // Map<String, dynamic>
        final List raw = decoded["data"] ?? [];

        setState(() {
  following = raw
      .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
      .toList();
  filteredFollowing = List.from(following);
  loading = false;
});
      } else {
        loading = false;
      }
    } catch (e) {
      print("FOLLOWING ERROR: $e");
      loading = false;
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
  searchQuery = query.toLowerCase().trim();

  setState(() {
    if (searchQuery.isEmpty) {
      filteredFollowing = List.from(following);
    } else {
      filteredFollowing = following.where((user) {
        final name =
            "${user["first_name"] ?? ""} ${user["last_name"] ?? ""}"
                .toLowerCase()
                .trim();

        final userType = (user["user_type"] ?? "").toString().toLowerCase();

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
        title: const Text("Following", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(onPressed: (){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CoachSettings()));
        }, icon: Icon(Icons.arrow_back)),
      ),
      body: loading
    ? const Center(child: CircularProgressIndicator(color: Colors.white))
    : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              controller: searchController,
              onChanged: filterFollowing,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search following",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          filterFollowing("");
                        },
                        icon: const Icon(Icons.close, color: Colors.white54),
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
            child: following.isEmpty
                ? const Center(
                    child: Text(
                      "You are not following anyone",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : filteredFollowing.isEmpty
                    ? const Center(
                        child: Text(
                          "No matching users found",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredFollowing.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white12, indent: 80),
                        itemBuilder: (_, i) {
                          final f = filteredFollowing[i];

                          return ListTile(
                            leading: const CircleAvatar(
                              radius: 26,
                              backgroundImage:
                                  AssetImage("lib/assets/img.jpg"),
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
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_skates/bottomnavigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';

class StudentList extends StatefulWidget {
  const StudentList({super.key});

  @override
  State<StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];

  bool loading = true;
  bool noData = false;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      setState(() => loading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/student/details/is/follow/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final List decoded = jsonDecode(res.body);

        setState(() {
          students = decoded
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .where((student) {
                final bool isFollowing = student["is_following"] == true;
                final String? followStatus = student["follow_status"];
                return !isFollowing && followStatus != "pending";
              })
              .toList();

          filteredStudents = students;
          loading = false;
          noData = students.isEmpty;
        });
      } else {
        setState(() {
          loading = false;
          noData = true;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        noData = true;
      });
    }
  }

  Future<void> sendFollowRequest(int studentId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final response = await http.post(
      Uri.parse('$api/api/myskates/user/follow/request/'),
      headers: {"Authorization": "Bearer $token"},
      body: {"following_id": studentId.toString()},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        final removedStudent = filteredStudents[index];

        students.removeWhere((s) => s["id"] == removedStudent["id"]);
        filteredStudents.removeAt(index);

        noData = filteredStudents.isEmpty;
      });
    }
  }

  void filterStudents(String query) {
    final results = students.where((student) {
      final firstName = (student["first_name"] ?? "").toString().toLowerCase();
      final lastName = (student["last_name"] ?? "").toString().toLowerCase();
      final instagram = (student["instagram"] ?? "").toString().toLowerCase();

      final fullName = "$firstName $lastName";

      return fullName.contains(query.toLowerCase()) ||
          instagram.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredStudents = results;
      noData = filteredStudents.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,

      /// 🌌 BEAUTIFUL APPBAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Discover people",
          style: TextStyle(
            color: Colors.white,
            fontFamily: "poppins",
            fontSize: 18,
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF001A18),
              Color(0xFF002F2B),
              Color(0xFF000C0B),
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                )
              : RefreshIndicator(
                  onRefresh: fetchStudents,
                  color: Colors.tealAccent,
                  backgroundColor: Colors.black,
                  child: noData
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: const Center(
                              child: Text(
                                "No students to follow",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            /// 🔍 SEARCH BAR
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: TextField(
                                controller: searchController,
                                onChanged: filterStudents,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Search",
                                  hintStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.white54,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.4),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(35),
                                    borderSide: const BorderSide(
                                      color: Colors.white12,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(35),
                                    borderSide: const BorderSide(
                                      color: Colors.white12,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            /// 👥 STUDENT LIST
                            Expanded(
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final student = filteredStudents[index];

                                  final String firstName =
                                      student["first_name"] ?? "";
                                  final String lastName =
                                      student["last_name"] ?? "";
                                  final String fullName = "$firstName $lastName"
                                      .trim();

                                  final String instagram =
                                      student["instagram"] ?? "student";

                                  final String? profile = student["profile"];

                                  final String image =
                                      profile != null && profile.isNotEmpty
                                      ? (profile.startsWith("http")
                                            ? profile
                                            : "$api$profile")
                                      : "";

                                  final int? studentId = student["id"];

                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundColor: Colors.grey.shade800,
                                          backgroundImage: image.isNotEmpty
                                              ? NetworkImage(image)
                                              : null,
                                          child: image.isEmpty
                                              ? const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fullName.isNotEmpty
                                                    ? fullName
                                                    : "Student",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "Instagram • $instagram",
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),

                                        /// FOLLOW BUTTON
                                        ElevatedButton(
                                          onPressed: () {
                                            if (studentId == null) return;
                                            sendFollowRequest(studentId, index);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.tealAccent,
                                            foregroundColor: Colors.black,
                                            elevation: 4,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            "Follow",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 6),

                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              final removed =
                                                  filteredStudents[index];

                                              students.removeWhere(
                                                (s) => s["id"] == removed["id"],
                                              );

                                              filteredStudents.removeAt(index);

                                              noData = filteredStudents.isEmpty;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}
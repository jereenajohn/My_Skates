import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';

class StudentList extends StatefulWidget {
  const StudentList({super.key});

  @override
  State<StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  List<Map<String, dynamic>> students = [];
  bool loading = true;
  bool noData = false;
  List<int> myRequests = [];

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      setState(() {
        loading = true;
      });
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/student/details/is/follow/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print(res.body);

      if (res.statusCode == 200) {
        final List decoded = jsonDecode(res.body);

        print("Fetched ${decoded.length} students");
        print("Raw data: ${res.body}");

        setState(() {
          students = decoded
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .where((student) {
                final bool isFollowing = student["is_following"] == true;
                final String? followStatus = student["follow_status"];

                // SHOW ONLY IF NOT FOLLOWED AND NOT PENDING
                return !isFollowing && followStatus != "pending";
              })
              .toList();

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
      print("Error fetching students: $e");
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

    print("Follow request response: ${response.statusCode} - ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        students.removeAt(index); //  instantly hide student
        noData = students.isEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Discover people",
          style: TextStyle(
            color: Colors.white,
            fontFamily: "poppins",
            fontSize: 16,
          ),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : RefreshIndicator(
              onRefresh: fetchStudents,
              color: Colors.tealAccent,
              backgroundColor: Colors.black,
              strokeWidth: 3.0,
              edgeOffset: 20.0,
              displacement: 40.0,
              child: noData
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people_outline,
                                color: Colors.white54,
                                size: 60,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No students to follow",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Pull down to refresh",
                                style: TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];

                        final String firstName = student["first_name"] ?? "";
                        final String lastName = student["last_name"] ?? "";
                        final String fullName = "$firstName $lastName".trim();

                        final String instagram = student["instagram"] ?? "student";

                        final String? profile = student["profile"];
                        final String image = profile != null ? "$api$profile" : "";
                        final int? studentId = student["id"];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              // Profile image
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.grey.shade800,
                                backgroundImage: image.isNotEmpty
                                    ? NetworkImage(image)
                                    : null,
                                child: image.isEmpty
                                    ? const Icon(Icons.person, color: Colors.white)
                                    : null,
                              ),

                              const SizedBox(width: 12),

                              // Name + subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName.isNotEmpty ? fullName : "Student",
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

                              // Follow button (Teal)
                              ElevatedButton(
                                onPressed: () {
                                  if (studentId == null) return;
                                  sendFollowRequest(studentId, index);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.tealAccent,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Follow",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),

                              const SizedBox(width: 6),

                              // Remove / close
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    students.removeAt(index);
                                    noData = students.isEmpty;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
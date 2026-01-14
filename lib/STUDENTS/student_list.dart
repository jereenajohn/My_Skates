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

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/student/details/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final List decoded = jsonDecode(res.body);
        setState(() {
          students = decoded
              .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(e))
              .toList();
          loading = false;
          noData = students.isEmpty;
        });
        print(students);
      } else {
        loading = false;
        noData = true;
      }
    } catch (e) {
      loading = false;
      noData = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Discover people",
          style: TextStyle(color: Colors.white,
              fontFamily: "poppins",
              fontSize: 14

              ),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.tealAccent,
              ),
            )
          : noData
              ? const Center(
                  child: Text(
                    "No students found",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];

                    final String firstName =
                        student["first_name"] ?? "";
                    final String lastName =
                        student["last_name"] ?? "";
                    final String fullName =
                        "$firstName $lastName".trim();

                    final String instagram =
                        student["instagram"] ?? "student";

                    final String image = student["image"] ?? "";

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          // Profile image
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey.shade800,
                            backgroundImage:
                                image.isNotEmpty ? NetworkImage(image) : null,
                            child: image.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  )
                                : null,
                          ),

                          const SizedBox(width: 12),

                          // Name + subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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

                          // Follow button (Teal)
                          ElevatedButton(
                            onPressed: () {
                              // TODO: follow API
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          // Remove / close
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                students.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserViewEvents extends StatefulWidget {
  const UserViewEvents({super.key});

  @override
  State<UserViewEvents> createState() => _UserViewEventsState();
}

class _UserViewEventsState extends State<UserViewEvents> {
  List<dynamic> events = [];
  bool loading = true;

  // Build full image URL
  String buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";

    // If path already contains /media/ leave it
    if (path.contains("/media/")) {
      return "$api$path";
    }

    // Otherwise prepend /media/
    return "$api/media/$path";
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  // ============================
  // FETCH EVENTS API CALL
  // ============================
  Future<void> fetchEvents() async {
    try {
      final token = await getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse("$api/api/myskates/events/add/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("==== DEBUG EVENTS API ====");
      print("URL: $api/api/myskates/events/add/");
      print("TOKEN: $token");
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");
      print("===========================");

      if (response.statusCode == 200) {
        setState(() {
          events = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Fetch events error: $e");
    }

    setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  // ============================
  // FORMAT DATE & TIME
  // ============================
  String formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return "${d.day.toString().padLeft(2, '0')}-"
          "${d.month.toString().padLeft(2, '0')}-"
          "${d.year}";
    } catch (_) {
      return date;
    }
  }

  String formatTime(String time) {
    try {
      final parsed = DateTime.parse("2020-01-01 $time");
      final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
      final minute = parsed.minute.toString().padLeft(2, '0');
      final period = parsed.hour >= 12 ? "pm" : "am";
      return "$hour:$minute $period";
    } catch (_) {
      return time;
    }
  }

  // ============================
  // EVENT CARD DESIGN
  // ============================
  Widget eventCard(Map<String, dynamic> event) {
    final banner = buildImageUrl(event["image"]);
    final fromDate = formatDate(event["from_date"]);
    final fromTime = formatTime(event["from_time"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      color: const Color(0xFF111111),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER TITLE & TIME
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundImage: NetworkImage(
                    buildImageUrl(event['club_image']),
                  ),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Spark roller skating club",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$fromTime  -  $fromDate",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // EVENT IMAGE
          if (event["image"] != null)
            SizedBox(
              width: double.infinity,
              child: Image.network(banner, fit: BoxFit.cover),
            ),

          const SizedBox(height: 12),

          // TITLE + DESCRIPTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              event["title"] ?? "",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              event["description"] ?? "",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ============================
  // MAIN UI
  // ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Your Events",
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Column(
        children: [
          const SizedBox(height: 45),

          // ================= FIXED UPLOAD BUTTON =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                // Add event upload page navigation
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white54, width: 1.2),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Upload your Activities ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ================= SCROLLABLE EVENTS =================
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                : events.isEmpty
                ? const Center(
                    child: Text(
                      "No events found",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return eventCard(
                        Map<String, dynamic>.from(events[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

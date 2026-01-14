import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_skates/COACH/coach_add_events.dart';
import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ClubView extends StatefulWidget {
  final int clubid;
  const ClubView({super.key, required this.clubid});

  @override
  State<ClubView> createState() => _ClubViewState();
}

class _ClubViewState extends State<ClubView> {
  Map<String, dynamic>? club;
  bool loading = true;
  List<dynamic> feedPosts = [];
  bool isFeedLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClubDetails();
    fetchClubEvents();
    // fetchFeed();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  // Future<void> fetchFeed() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString("access");
  //     final userId = prefs.getInt("id");

  //     if (token == null || userId == null) return;

  //     final url = Uri.parse("$api/api/myskates/feed/view/${widget.clubid}/");

  //     final response = await http.get(
  //       url,
  //       headers: {"Authorization": "Bearer $token"},
  //     );

  //     if (response.statusCode == 200) {
  //       setState(() {
  //         feedPosts = jsonDecode(response.body);
  //         isFeedLoading = false;
  //       });
  //     } else {
  //       setState(() {
  //         isFeedLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       isFeedLoading = false;
  //     });
  //   }
  // }

  Future<void> submitFeedPost(String text, XFile? imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null || userId == null) return;

      final url = Uri.parse("$api/api/myskates/feed/add/");

      final request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";

      request.fields.addAll({
        "club": widget.clubid.toString(),
        "user": userId.toString(),
        "text": text,
      });

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", imageFile.path),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text(
              "Posted successfully",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );

        // fetchFeed(); // Refresh feed
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to post")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }


  Future<void> fetchClubDetails() async {
    String? token = await getToken();
    if (token == null) {
      setState(() {
        loading = false;
        club = {};
      });
      return;
    }

    final response = await http.get(
      Uri.parse("$api/api/myskates/club/${widget.clubid}/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      setState(() {
        club = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
        club = {}; // prevent null crash
      });
    }
  }

  // ================== EVENT SUBMIT ==================

  Future<void> submitEvent(
    String title,
    String note,
    String description,
    String fromDate,
    String toDate,
    String fromTime,
    String toTime,
    XFile? imageFile,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null || userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in")));
        return;
      }

      final url = Uri.parse("$api/api/myskates/events/add/");

      final request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";

      request.fields.addAll({
        "user": userId.toString(),
        "club": widget.clubid.toString(),
        "title": title,
        "note": note,
        "description": description,
        "from_date": fromDate,
        "to_date": toDate,
        "from_time": fromTime,
        "to_time": toTime,
      });

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", imageFile.path),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      print("EVENT RESPONSE: $respStr");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal, // TEAL
            content: const Text(
              "Event added successfully",
              style: TextStyle(color: Colors.white), // white text for contrast
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add event: $respStr")),
        );
      }
    } catch (e) {
      print("Event Submit Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  List<dynamic> clubEvents = [];
  bool isEventsLoading = true;

  Future<void> fetchClubEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null || userId == null) return;

      final url = Uri.parse(
        "$api/api/myskates/events/view/$userId/${widget.clubid}/",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      print("Event fetch response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          clubEvents = jsonDecode(response.body);
          isEventsLoading = false;
        });
      } else {
        setState(() {
          clubEvents = [];
          isEventsLoading = false;
        });
      }
    } catch (e) {
      print("Event fetch error: $e");
      setState(() {
        clubEvents = [];
        isEventsLoading = false;
      });
    }
  }

  Future<void> _deleteEvent(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final url = Uri.parse("$api/api/myskates/events/delete/$eventId/");

      final response = await http.delete(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal,
            content: const Text(
              "Event deleted",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );

        fetchClubEvents(); // refresh list
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to delete event")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  String formatDate(String date) {
    try {
      final parts = date.split("-");
      if (parts.length == 3) {
        final yyyy = parts[0];
        final mm = parts[1];
        final dd = parts[2];
        return "$dd/$mm/$yyyy"; // dd/mm/yyyy
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  Future<void> _uploadMedia(XFile file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null || userId == null) return;

      final url = Uri.parse("$api/api/myskates/club-media/add/");

      final request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";

      request.fields.addAll({
        "club": widget.clubid.toString(),
        "user": userId.toString(),
      });

      request.files.add(await http.MultipartFile.fromPath("image", file.path));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text(
              "Media added successfully",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $respStr")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _openAddMediaSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00332D), Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Add Media",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Gallery Button
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF00AFA5),
                  size: 28,
                ),
                title: const Text(
                  "Choose from Gallery",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  Navigator.pop(context);

                  if (image != null) {
                    _uploadMedia(image);
                  }
                },
              ),

              // Camera Button
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF00AFA5),
                  size: 28,
                ),
                title: const Text(
                  "Take a Photo",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                  );

                  Navigator.pop(context);

                  if (image != null) {
                    _uploadMedia(image);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String formatTime(String time24) {
    try {
      final parts = time24.split(":");
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      String period = hour >= 12 ? "PM" : "AM";

      hour = hour % 12;
      if (hour == 0) hour = 12;

      return "${hour.toString()}:${minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      return time24;
    }
  }

Widget _eventTile(Map event) {
  // -----------------------------------------------------
  // BUILD IMAGE LIST (main image + gallery images)
  // -----------------------------------------------------
  List<String> images = [];

  // Add main image if exists
  if (event["image"] != null && event["image"].toString().isNotEmpty) {
    images.add(event["image"]);
  }

  // Add gallery images
  if (event["images"] != null) {
    for (var g in event["images"]) {
      if (g["image"] != null && g["image"].toString().isNotEmpty) {
        images.add(g["image"]);
      }
    }
  }

  // Convert to full URLs
  images = images.map((path) {
    return path.startsWith("http")
        ? path
        : "$api${path.startsWith("/") ? path : "/$path"}";
  }).toList();

  // -----------------------------------------------------

  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -----------------------------------------------------
        // IMAGE SECTION (auto adjust)
        // -----------------------------------------------------
        if (images.isNotEmpty)
          Container(
            height: images.length == 1 ? 170 : 140,
            child: images.length == 1
                ? 
                // ---------- ONE IMAGE (full width) ----------
                GestureDetector(
                    onTap: () => _openSquareMediaViewer(images[0]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        images[0],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  )

                :

                // ---------- TWO OR MORE IMAGES ----------
                Row(
                  children: [
                    // LEFT IMAGE
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openSquareMediaViewer(images[0]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            images[0],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // RIGHT IMAGE with +N overlay if needed
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openSquareMediaViewer(images[1]),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                images[1],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),

                            // More images overlay
                            if (images.length > 2)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    "+${images.length - 2}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          ),

        const SizedBox(height: 12),

        // -----------------------------------------------------
        // TITLE
        // -----------------------------------------------------
        Text(
          event["title"] ?? "",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        // -----------------------------------------------------
        // DESCRIPTION
        // -----------------------------------------------------
        Text(
          event["description"] ?? "",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),

        const SizedBox(height: 10),

        // -----------------------------------------------------
        // DATE RANGE
        // -----------------------------------------------------
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF00AFA5)),
            const SizedBox(width: 5),
            Text(
              "${formatDate(event["from_date"])} → ${formatDate(event["to_date"])}",
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),

        const SizedBox(height: 5),

        // -----------------------------------------------------
        // TIME RANGE + MENU
        // -----------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Color(0xFF00AFA5)),
                const SizedBox(width: 5),
                Text(
                  "${formatTime(event["from_time"])} → ${formatTime(event["to_time"])}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),

            // OPTIONS (UPDATE / DELETE)
            PopupMenuButton<String>(
              color: const Color.fromARGB(225, 4, 19, 13),
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (value) {
                if (value == "update") {
                  print("Update event clicked");
                }
                if (value == "delete") {
                  _deleteEvent(event["id"]);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: "update",
                  child: Text("Update", style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(
                  value: "delete",
                  child: Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}


  Widget _fancySwipeEventTile(Map event) {
    return Dismissible(
      key: Key(event["id"].toString()),
      direction: DismissDirection.horizontal, // right & left
      // ======== BACKGROUND: SWIPE RIGHT (UPDATE) ========
      background: Container(
        padding: const EdgeInsets.only(left: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00AFA5), Colors.black],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.edit, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text("Update", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),

      // ======== SECONDARY BACKGROUND: SWIPE LEFT (DELETE) ========
      secondaryBackground: Container(
        padding: const EdgeInsets.only(right: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red, Colors.black],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text("Delete", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),

      // ======== CONFIRM DISMISS (SWIPE ACTION) ========
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // RIGHT SWIPE = UPDATE
          print("Update clicked");
          return false; // do not remove card
        } else {
          // LEFT SWIPE = DELETE → ASK CONFIRMATION
          bool? confirm = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF06201A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: const Text(
                  "Delete Event?",
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  "Are you sure you want to delete this event?",
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white70),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              );
            },
          );

          if (confirm == true) {
            _deleteEvent(event["id"]);
            return true; // allow dismiss
          } else {
            return false; // do not remove tile
          }
        }
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: Transform.scale(scale: 1.00, child: _eventTile(event)),
      ),
    );
  }

  Widget _dateField(
    String label,
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                suffixIcon: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF00AFA5),
                ),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _openProfileImageViewer(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context), // close on tap
          child: Stack(
            alignment: Alignment.center,
            children: [
              // PINCH-TO-ZOOM VIEWER
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CircleAvatar(
                  radius: 100, // BIG SIZE like Instagram
                  backgroundImage: NetworkImage(imageUrl),
                ),
              ),

              // CLOSE ICON (Top-right)
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    // Local non-null map
    final Map<String, dynamic> c = club ?? {};

    final String clubName = (c["club_name"] ?? "").toString();
    final String place = (c["place"] ?? "").toString();
    final String districtName = (c["district_name"] ?? "").toString();
    final String stateName = (c["state_name"] ?? "").toString();
    final String description = (c["description"] ?? "").toString();
    final String instagram = (c["instagram"] ?? "").toString();
    final String website = (c["website"] ?? "").toString();
    final String? imagePath = c["image"]?.toString();

    return Scaffold(
      backgroundColor: Colors.black,

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00332D), Colors.black],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BACK ARROW
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- TOP HEADER ----------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CLUB IMAGE
                  GestureDetector(
                    onTap: () {
                      if (imagePath != null && imagePath!.isNotEmpty) {
                        _openProfileImageViewer("$api$imagePath");
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          (imagePath != null && imagePath!.isNotEmpty)
                          ? NetworkImage("$api$imagePath")
                          : const AssetImage("lib/assets/placeholder.png")
                                as ImageProvider,
                    ),
                  ),

                  const SizedBox(width: 15),

                  // CLUB NAME + LOCATION
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clubName,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          [
                            if (place.isNotEmpty) place,
                            if (districtName.isNotEmpty) districtName,
                            if (stateName.isNotEmpty) stateName,
                          ].join(", "),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ---------------- FOLLOWING / FOLLOWERS ----------------
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: const [
                        Text(
                          "973",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Following",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: const [
                        Text(
                          "1535",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Followers",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ---------------- OVERVIEW ----------------
              const Text(
                "Overview",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.4,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 12),

              if (instagram.isNotEmpty)
                Text(
                  instagram,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),

              if (website.isNotEmpty)
                Text(
                  website,
                  style: const TextStyle(
                    color: Color(0xFF00AFA5),
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),

              const SizedBox(height: 35),

              // ---------------- CLUB RATING ----------------
              const Text(
                "Club Rating",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    borderData: FlBorderData(show: true),
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, _) {
                            switch (value.toInt()) {
                              case 4:
                                return const Text(
                                  "Excellent",
                                  style: TextStyle(color: Colors.white70),
                                );
                              case 3:
                                return const Text(
                                  "High",
                                  style: TextStyle(color: Colors.white70),
                                );
                              case 2:
                                return const Text(
                                  "Low",
                                  style: TextStyle(color: Colors.white70),
                                );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            switch (value.toInt()) {
                              case 0:
                                return const Text(
                                  "Aug",
                                  style: TextStyle(color: Colors.white70),
                                );
                              case 1:
                                return const Text(
                                  "Sept",
                                  style: TextStyle(color: Colors.white70),
                                );
                              case 2:
                                return const Text(
                                  "Oct",
                                  style: TextStyle(color: Colors.white70),
                                );
                              case 3:
                                return const Text(
                                  "Nov",
                                  style: TextStyle(color: Colors.white70),
                                );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: const Color(0xFF00E5D0),
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        spots: const [
                          FlSpot(0, 3),
                          FlSpot(1, 4),
                          FlSpot(2, 3),
                          FlSpot(3, 2),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // ---------------- FEED SECTION ----------------
              const Text(
                "Feed",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              _feedInputBox(),
              const SizedBox(height: 20),

              // if (isFeedLoading)
              //   const Center(child: CircularProgressIndicator(color: Colors.teal))
              // else if (feedPosts.isEmpty)
              //   const Text("No posts yet.", style: TextStyle(color: Colors.white70))
              // else
              //   Column(
              //     children: feedPosts.map((post) => _feedTile(post)).toList(),
              //   ),

              // const SizedBox(height: 35),

              // ---------------- MEDIA ----------------
              const Text(
                "Media",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _mediaItem("https://picsum.photos/200"),
                    _mediaItem("https://picsum.photos/210"),
                    _mediaItem("https://picsum.photos/220"),
                    _mediaItem("https://picsum.photos/230"),
                    Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "View\nall",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // ---------------- COACHES ----------------
              const Text(
                "Coaches",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              _coachTile(
                "Alex Peter",
                "https://randomuser.me/api/portraits/men/22.jpg",
              ),
              _coachTile(
                "Mary John",
                "https://randomuser.me/api/portraits/women/26.jpg",
              ),

              const SizedBox(height: 40),

              // ---------------- EVENTS ----------------
              const Text(
                "Events",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              if (isEventsLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                )
              else if (clubEvents.isEmpty)
                const Text(
                  "No events found.",
                  style: TextStyle(color: Colors.white70),
                )
              else
                Column(
                  children: clubEvents.map((event) {
                    return _fancySwipeEventTile(event);
                  }).toList(),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // ---------------- ADD MEDIA BUTTON ----------------
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add Media Button
          FloatingActionButton(
            heroTag: "media_btn",
            backgroundColor: const Color(0xFF00AFA5),
            elevation: 5,
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              color: Color.fromARGB(255, 252, 252, 252),
              size: 30,
            ),
            onPressed: _openAddMediaSheet,
          ),
          const SizedBox(height: 12),

          // Existing Add Event Button
          FloatingActionButton(
            heroTag: "event_btn",
            backgroundColor: const Color(0xFF00AFA5),
            child: const Icon(Icons.event, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoachAddEvents(clubid: widget.clubid),
                ),
              );
            },
          ),
        ],
      ),

      // ---------------- BOTTOM NAV ----------------
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFF00AFA5),
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: ""),
        ],
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00AFA5),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00AFA5),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Convert to 24-hour format
      final now = DateTime.now();
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      controller.text =
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
  }

  Widget _timeField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.access_time, color: Color(0xFF00AFA5)),
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          readOnly: true,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ================== ADD EVENT DIALOG ==================

  // void _openAddEventDialog() {
  //   final TextEditingController titleCtrl = TextEditingController();
  //   final TextEditingController noteCtrl = TextEditingController();
  //   final TextEditingController descCtrl = TextEditingController();
  //   final TextEditingController fromDateCtrl = TextEditingController();
  //   final TextEditingController toDateCtrl = TextEditingController();
  //   final TextEditingController fromTimeCtrl = TextEditingController();
  //   final TextEditingController toTimeCtrl = TextEditingController();

  //   XFile? pickedImage;

  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setStateDialog) {
  //           return Dialog(
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(20),
  //             ),
  //             child: Container(
  //               decoration: const BoxDecoration(
  //                 gradient: LinearGradient(
  //                   begin: Alignment.topLeft,
  //                   end: Alignment.bottomRight,
  //                   colors: [Color(0xFF00332D), Colors.black],
  //                 ),
  //                 borderRadius: BorderRadius.all(Radius.circular(20)),
  //               ),
  //               padding: const EdgeInsets.all(20),
  //               child: SingleChildScrollView(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     const Text(
  //                       "Add Event",
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 20,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),

  //                     const SizedBox(height: 20),

  //                     _inputField("Title", titleCtrl),
  //                     _inputField("Note", noteCtrl),
  //                     _inputField("Description", descCtrl, maxLines: 3),

  //                     // FROM DATE (with calendar)
  //                     _dateField(
  //                       "From Date",
  //                       fromDateCtrl,
  //                       () => _pickDate(context, fromDateCtrl),
  //                     ),

  //                     // TO DATE (with calendar)
  //                     _dateField(
  //                       "To Date",
  //                       toDateCtrl,
  //                       () => _pickDate(context, toDateCtrl),
  //                     ),

  //                     GestureDetector(
  //                       onTap: () => _pickTime(context, fromTimeCtrl),
  //                       child: AbsorbPointer(
  //                         child: _timeField("From Time", fromTimeCtrl),
  //                       ),
  //                     ),
  //                     GestureDetector(
  //                       onTap: () => _pickTime(context, toTimeCtrl),
  //                       child: AbsorbPointer(
  //                         child: _timeField("To Time", toTimeCtrl),
  //                       ),
  //                     ),

  //                     const SizedBox(height: 10),

  //                     GestureDetector(
  //                       onTap: () async {
  //                         final ImagePicker picker = ImagePicker();
  //                         pickedImage = await picker.pickImage(
  //                           source: ImageSource.gallery,
  //                         );
  //                         setStateDialog(() {});
  //                       },
  //                       child: Container(
  //                         padding: const EdgeInsets.all(12),
  //                         decoration: BoxDecoration(
  //                           color: Colors.white12,
  //                           borderRadius: BorderRadius.circular(10),
  //                         ),
  //                         child: Row(
  //                           children: [
  //                             const Icon(Icons.image, color: Colors.white70),
  //                             const SizedBox(width: 10),
  //                             Text(
  //                               pickedImage == null
  //                                   ? "Upload Image"
  //                                   : "Image Selected",
  //                               style: const TextStyle(color: Colors.white),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ),

  //                     const SizedBox(height: 20),

  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.end,
  //                       children: [
  //                         TextButton(
  //                           child: const Text(
  //                             "Cancel",
  //                             style: TextStyle(color: Colors.white70),
  //                           ),
  //                           onPressed: () => Navigator.pop(context),
  //                         ),
  //                         const SizedBox(width: 10),
  //                         ElevatedButton(
  //                           style: ElevatedButton.styleFrom(
  //                             backgroundColor: const Color(0xFF00AFA5),
  //                           ),
  //                           child: const Text(
  //                             "Submit",
  //                             style: TextStyle(color: Colors.white),
  //                           ),
  //                           onPressed: () async {
  //                             await submitEvent(
  //                               titleCtrl.text.trim(),
  //                               noteCtrl.text.trim(),
  //                               descCtrl.text.trim(),
  //                               fromDateCtrl.text.trim(),
  //                               toDateCtrl.text.trim(),
  //                               fromTimeCtrl.text.trim(),
  //                               toTimeCtrl.text.trim(),
  //                               pickedImage,
  //                             );
  //                             Navigator.pop(context);
  //                           },
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  void _openAddEventDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachAddEvents(clubid: widget.clubid),
      ),
    );
  }

  // ================== HELPERS ==================

  Widget _inputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _mediaItem(String url) {
    return GestureDetector(
      onTap: () => _openSquareMediaViewer(url),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
      ),
    );
  }

 void _openSquareMediaViewer(String imageUrl) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.9),
    builder: (context) {
      return GestureDetector(
        onTap: () => Navigator.pop(context), // close on tap outside
        child: Stack(
          children: [
            // FULL SCREEN ZOOM VIEW
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // CLOSE BUTTON
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _coachTile(String name, String img) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundImage: NetworkImage(img)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 17),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
        ],
      ),
    );
  }
}

Widget _feedInputBox() {
  final TextEditingController postCtrl = TextEditingController();
  XFile? pickedImage;

  return StatefulBuilder(
    builder: (context, setStateSB) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   "What’s on your mind?",
            //   style: TextStyle(color: Colors.white70, fontSize: 14),
            // ),
            const SizedBox(height: 8),

            // Slightly bigger TextField
            TextField(
              controller: postCtrl,
              minLines: 2,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ), // Larger typing space
                hintText: "What’s on your mind?",
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                filled: true,
                fillColor: Colors.white10,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 10),
            if (pickedImage != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(pickedImage!.path),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Image Picker Icon
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    pickedImage = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    setStateSB(() {});
                  },
                  child: const Icon(
                    Icons.image,
                    color: Color(0xFF00AFA5),
                    size: 26,
                  ),
                ),

                // Post Button
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AFA5),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: () {
                      // submitFeedPost(postCtrl.text.trim(), pickedImage);
                    },
                    child: const Text(
                      "Post",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _feedTile(Map post) {
  final String? image = post["image"];
  final String text = post["text"] ?? "";
  final String time = post["created_at"] ?? "";

  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),

        const SizedBox(height: 10),

        // Image if exists
        if (image != null && image.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              "$api$image",
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),

        const SizedBox(height: 10),

        Text(time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    ),
  );
}
class SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: borderRadius,
      ),
    );
  }
}

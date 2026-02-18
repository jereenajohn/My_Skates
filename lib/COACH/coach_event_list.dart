import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:my_skates/COACH/coach_homepage.dart';
import 'package:my_skates/bottomnavigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class CoachEvents extends StatefulWidget {
  const CoachEvents({super.key});

  @override
  State<CoachEvents> createState() => _CoachEventsState();
}

class _CoachEventsState extends State<CoachEvents> {
  Map<String, dynamic>? clubDetails;
  List<dynamic> clubEvents = [];

  bool loadingClub = true;
  bool loadingEvents = true;

  String buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    return "$api$path";
  }

  @override
  void initState() {
    super.initState();
    fetchClubEvents();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt("id");
  }

  Future<void> _deleteEvent(int id) async {
    try {
      final token = await getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse("$api/api/myskates/events/updates/$id/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Event deleted successfully",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        fetchClubEvents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _deleteEventImage(int eventId, int imageId) async {
    try {
      final token = await getToken();
      if (token == null) return;

      final url = Uri.parse(
        "$api/api/myskates/events/$eventId/images/$imageId/delete/",
      );

      final response = await http.delete(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      debugPrint(
        "Delete image $imageId of event $eventId => "
        "${response.statusCode} - ${response.body}",
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete image: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting image: $e")),
      );
    }
  }

  Future<void> updateEvent(
    int eventId,
    String title,
    String note,
    String description,
    String fromDate,
    String toDate,
    String fromTime,
    String toTime,
    List<XFile> newImages,
    List<int> imagesToDelete,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      for (final imgId in imagesToDelete) {
        await _deleteEventImage(eventId, imgId);
      }

      final url = Uri.parse("$api/api/myskates/events/updates/$eventId/");
      final request = http.MultipartRequest("PUT", url);
      request.headers["Authorization"] = "Bearer $token";

      request.fields.addAll({
        "title": title,
        "note": note,
        "description": description,
        "from_date": fromDate,
        "to_date": toDate,
        "from_time": fromTime,
        "to_time": toTime,
      });

      final limitedImages =
          newImages.length > 2 ? newImages.sublist(0, 2) : newImages;

      for (var img in limitedImages) {
        request.files.add(
          await http.MultipartFile.fromPath("images", img.path),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      debugPrint("Update Event Response: ${response.statusCode} - $respStr");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text(
              "Event updated successfully",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        fetchClubEvents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $respStr")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> fetchClubEvents() async {
    try {
      setState(() => loadingEvents = true); 
      
      final token = await getToken();
      final userId = await getUserId();

      if (token == null || userId == null) {
        setState(() => loadingEvents = false);
        return;
      }

      final url = Uri.parse("$api/api/myskates/events/add/by/user/");

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          clubEvents = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to fetch events: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error fetching events: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => loadingEvents = false);
    }
  }

  void _openUpdateEventDialog(Map<String, dynamic> event) {
    final TextEditingController titleCtrl =
        TextEditingController(text: event["title"] ?? "");
    final TextEditingController noteCtrl =
        TextEditingController(text: event["note"] ?? "");
    final TextEditingController descCtrl =
        TextEditingController(text: event["description"] ?? "");
    final TextEditingController fromDateCtrl =
        TextEditingController(text: event["from_date"] ?? "");
    final TextEditingController toDateCtrl =
        TextEditingController(text: event["to_date"] ?? "");
    final TextEditingController fromTimeCtrl =
        TextEditingController(text: event["from_time"] ?? "");
    final TextEditingController toTimeCtrl =
        TextEditingController(text: event["to_time"] ?? "");

    final List<dynamic> existingImages =
        List<dynamic>.from(event["images"] ?? []);
    List<int> imagesToDelete = [];

    List<XFile> pickedImages = [];

    String existingBanner = buildImageUrl(event["image"]);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            int activeExisting = existingImages
                .where((img) => img["_deleted"] != true)
                .length;
            int currentImageCount = activeExisting + pickedImages.length;
            int remainingSlots = 2 - currentImageCount;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00332D), Colors.black],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Update Event",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _inputField("Title", titleCtrl),
                      _inputField("Note", noteCtrl),
                      _inputField("Description", descCtrl, maxLines: 3),

                      _dateField(
                        "From Date",
                        fromDateCtrl,
                        () => _pickDate(context, fromDateCtrl),
                      ),
                      const SizedBox(height: 10),

                      _dateField(
                        "To Date",
                        toDateCtrl,
                        () => _pickDate(context, toDateCtrl),
                      ),
                      const SizedBox(height: 10),

                      GestureDetector(
                        onTap: () => _pickTime(context, fromTimeCtrl),
                        child: AbsorbPointer(
                          child: _timeField("From Time", fromTimeCtrl),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _pickTime(context, toTimeCtrl),
                        child: AbsorbPointer(
                          child: _timeField("To Time", toTimeCtrl),
                        ),
                      ),
                      const SizedBox(height: 15),

                      const Text(
                        "Event Images (max 2)",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),

                      if (currentImageCount >= 2)
                        const Text(
                          "Maximum 2 images allowed",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),

                      const SizedBox(height: 6),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        onPressed: remainingSlots <= 0
                            ? null
                            : () async {
                                final ImagePicker picker = ImagePicker();
                                final images = await picker.pickMultiImage();

                                if (images == null || images.isEmpty) return;

                                if (images.length > remainingSlots) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "You can add only $remainingSlots more image(s)",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }

                                pickedImages.addAll(
                                  images.take(remainingSlots),
                                );
                                setStateDialog(() {});
                              },
                        icon: const Icon(Icons.image),
                        label: const Text(
                          "Pick Images",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (existingImages.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: existingImages.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                          itemBuilder: (context, index) {
                            final img = existingImages[index];

                            if (img["_deleted"] == true) {
                              return const SizedBox();
                            }

                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    buildImageUrl(img["image"]),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      imagesToDelete.add(img["id"]);
                                      existingImages[index]["_deleted"] = true;
                                      setStateDialog(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                      if (existingImages.isNotEmpty) const SizedBox(height: 10),

                      if (event["image"] != null && existingImages.isEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            existingBanner,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                      if (event["image"] != null && existingImages.isEmpty)
                        const SizedBox(height: 10),

                      if (pickedImages.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pickedImages.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(pickedImages[index].path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      pickedImages.removeAt(index);
                                      setStateDialog(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white70),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00AFA5),
                            ),
                            child: const Text(
                              "Update",
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              await updateEvent(
                                event["id"],
                                titleCtrl.text.trim(),
                                noteCtrl.text.trim(),
                                descCtrl.text.trim(),
                                fromDateCtrl.text.trim(),
                                toDateCtrl.text.trim(),
                                fromTimeCtrl.text.trim(),
                                toTimeCtrl.text.trim(),
                                pickedImages,
                                imagesToDelete,
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.teal),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _dateField(
    String label,
    TextEditingController controller,
    Function onTap,
  ) {
    return GestureDetector(
      onTap: () => onTap(),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
            labelStyle: const TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.teal),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time, color: Colors.white70),
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.teal),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController ctrl,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ctrl.text = "${picked.year}-${picked.month}-${picked.day}";
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    TextEditingController ctrl,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      ctrl.text = "${picked.hour}:${picked.minute}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CoachHomepage()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            clubDetails?["club_name"] ?? "My Club Events",
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
        body: loadingEvents
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : RefreshIndicator(
                onRefresh: fetchClubEvents,
                color: Colors.tealAccent,
                backgroundColor: Colors.black,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.swipe, color: Colors.teal, size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Swipe right to update an event, swipe left to delete.",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
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
                    if (clubEvents.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.event_busy,
                                color: Colors.white70,
                                size: 50,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No events found",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Pull down to refresh",
                                style: TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _fancySwipeEventTile(
                              Map<String, dynamic>.from(clubEvents[index]),
                            );
                          },
                          childCount: clubEvents.length,
                        ),
                      ),
                  ],
                ),
              ),
        bottomNavigationBar: const AppBottomNav(
          currentIndex: 4,
        ),
      ),
    );
  }

  String formatDate(String date) {
    try {
      DateTime d = DateTime.parse(date);
      return "${d.day.toString().padLeft(2, '0')}-"
          "${d.month.toString().padLeft(2, '0')}-"
          "${d.year}";
    } catch (e) {
      return date;
    }
  }

  String formatTime(String time) {
    try {
      final parsed = DateTime.parse("2020-01-01 $time");
      final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
      final minute = parsed.minute.toString().padLeft(2, '0');
      final period = parsed.hour >= 12 ? "PM" : "AM";
      return "$hour:$minute $period";
    } catch (e) {
      return time;
    }
  }

  Widget _fancySwipeEventTile(Map<String, dynamic> event) {
    return Dismissible(
      key: Key(event["id"].toString()),
      direction: DismissDirection.horizontal,
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
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _openUpdateEventDialog(event);
          return false;
        } else {
          bool? confirm = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: const Text(
                  "Delete Event?",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                content: const Text(
                  "Are you sure you want to delete this event?",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
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
                      backgroundColor: Colors.red,
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
            await _deleteEvent(event["id"]);
            return false;
          } else {
            return false;
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: Transform.scale(
          scale: 1.00,
          child: buildEventCard(
            event,
            buildImageUrl(event["club_image"]),
            event["club_name"] ?? "",
          ),
        ),
      ),
    );
  }

  Widget buildEventCard(
    Map<String, dynamic> event,
    String clubLogo,
    String clubName,
  ) {
    final String bannerImagePath = event["image"] ?? "";
    final List<dynamic> gallery = event["images"] ?? [];
    final List<dynamic> firstTwoImages = gallery.take(2).toList();

    final fromDate = formatDate(event["from_date"] ?? "");
    final toDate = formatDate(event["to_date"] ?? "");
    final fromTime = formatTime(event["from_time"] ?? "");
    final toTime = formatTime(event["to_time"] ?? "");

    return Container(
      color: const Color.fromARGB(255, 20, 19, 19),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage:
                    clubLogo.isNotEmpty ? NetworkImage(clubLogo) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  clubName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_month,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                "$fromDate • $fromTime  →  $toDate • $toTime",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (firstTwoImages.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: firstTwoImages.map<Widget>((img) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GestureDetector(
                          onTap: () {
                            _showFullImage(buildImageUrl(img["image"]));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              buildImageUrl(img["image"]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          else if (bannerImagePath.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                buildImageUrl(bannerImagePath),
                fit: BoxFit.cover,
              ),
            ),

          const SizedBox(height: 10),
          Text(
            event["title"] ?? "",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            event["description"] ?? "",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black,
              child: InteractiveViewer(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      },
    );
  }
}
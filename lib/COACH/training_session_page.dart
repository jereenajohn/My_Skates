import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:latlong2/latlong.dart'; // <-- REQUIRED

import 'map_picker_page.dart';

class CreateTrainingSessionPage extends StatefulWidget {
  const CreateTrainingSessionPage({super.key});

  @override
  State<CreateTrainingSessionPage> createState() =>
      _CreateTrainingSessionPageState();
}

class _CreateTrainingSessionPageState extends State<CreateTrainingSessionPage> {
  static const Color accentColor = Color(0xFF2EE6A6);

  final _formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final typedLocationCtrl = TextEditingController(); // MANUAL LOCATION
  final notesCtrl = TextEditingController();

  String? mapAddress;
  double? latitude;
  double? longitude;

  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  File? sessionImage;
  final ImagePicker _picker = ImagePicker();

  bool submitting = false;

  @override
  void initState() {
    super.initState();
  }

  String formatDisplayDate(String date) {
    final parsed = DateTime.parse(date);
    return DateFormat('dd-MM-yyyy').format(parsed);
  }

  String formatDisplayTime(String time) {
    final parsed = DateFormat("HH:mm:ss").parse(time);
    return DateFormat("hh:mm a").format(parsed);
  }

  Future<List<TrainingSession>> fetchTrainingSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) {
      throw Exception("Authentication token not found");
    }

    final response = await http.get(
      Uri.parse("$api/api/myskates/training/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded['status'] == true) {
        return (decoded['data'] as List)
            .map((e) => TrainingSession.fromJson(e))
            .toList();
      } else {
        throw Exception("API returned status false");
      }
    } else {
      throw Exception(
        "Failed to fetch training sessions (${response.statusCode})",
      );
    }
  }

  // ───────────────────────── BUILD ─────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Training Session"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Session Details"),

                  _inputField(
                    controller: titleCtrl,
                    label: "Training Title",
                    icon: Icons.fitness_center,
                  ),

                  /// 🔹 MANUAL LOCATION FIELD
                  _inputField(
                    controller: typedLocationCtrl,
                    label: "Location Name / Landmark",
                    icon: Icons.edit_location_alt,
                  ),

                  /// 🔹 MAP LOCATION PICKER
                  _mapLocationTile(),

                  const SizedBox(height: 18),
                  _sectionTitle("Training Schedule"),

                  /// ───── START & END DATE (ROW) ─────
                  Row(
                    children: [
                      Expanded(
                        child: _dateTile(
                          label: "Start Date",
                          date: startDate,
                          icon: Icons.play_circle_outline,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) setState(() => startDate = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dateTile(
                          label: "End Date",
                          date: endDate,
                          icon: Icons.stop_circle_outlined,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: startDate ?? DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) setState(() => endDate = d);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// ───── START & END TIME (ROW) ─────
                  Row(
                    children: [
                      Expanded(
                        child: _timeTile(
                          label: "Start Time",
                          time: startTime,
                          icon: Icons.schedule,
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (t != null) setState(() => startTime = t);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timeTile(
                          label: "End Time",
                          time: endTime,
                          icon: Icons.schedule_outlined,
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (t != null) setState(() => endTime = t);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _sectionTitle("Training Image"),
                  _imagePicker(),

                  const SizedBox(height: 20),
                  _sectionTitle("Coach Notes"),
                  _inputField(
                    controller: notesCtrl,
                    label: "Focus / Drills",
                    icon: Icons.note_alt,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 30),
                  _submitButton(),

                  const SizedBox(height: 30),
                  _sectionTitle("Existing Training Sessions"),
                  _trainingSessionList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _trainingSessionList() {
    return FutureBuilder<List<TrainingSession>>(
      future: fetchTrainingSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: accentColor)),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "Failed to load training sessions",
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "No training sessions created yet",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Column(children: sessions.map(_trainingSessionCard).toList());
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.black45,
      child: const Icon(Icons.image, color: Colors.white38),
    );
  }

  Widget _trainingSessionCard(TrainingSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: _glassBox(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: session.imageUrl != null
                ? Image.network(
                    "$api${session.imageUrl}",
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _imagePlaceholder();
                    },
                  )
                : _imagePlaceholder(),
          ),

          const SizedBox(width: 12),

          // DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  session.location,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${formatDisplayDate(session.startDate)} → ${formatDisplayDate(session.endDate)}",
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      "${formatDisplayTime(session.startTime)} - ${formatDisplayTime(session.endTime)}",
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── LOCATION TILE ─────────────────────────

  Widget _mapLocationTile() {
    return GestureDetector(
      onTap: _openMapPicker,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: _glassBox(),
        child: Row(
          children: [
            const Icon(Icons.map, color: accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mapAddress ?? "Select Location from Map",
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );

    if (result != null) {
      setState(() {
        latitude = result["lat"];
        longitude = result["lng"];
        mapAddress = result["address"];
      });
    }
  }

  // ───────────────────────── UI HELPERS ─────────────────────────

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: _glassBox(),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: accentColor),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _glassBox(),
        child: Row(
          children: [
            Icon(icon, color: accentColor),
            const SizedBox(width: 12),
            Text(
              date == null ? label : "${date.day}-${date.month}-${date.year}",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeTile({
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _glassBox(),
        child: Row(
          children: [
            Icon(icon, color: accentColor),
            const SizedBox(width: 12),
            Text(
              time == null ? label : time.format(context),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        decoration: _glassBox(),
        child: Row(
          children: [
            const SizedBox(width: 16),
            sessionImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      sessionImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: Colors.white54,
                      size: 32,
                    ),
                  ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "Upload Training Image",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const Icon(Icons.upload, color: accentColor),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: submitting ? null : _submit,
        child: submitting
            ? const CircularProgressIndicator(color: Colors.black)
            : const Text(
                "Create Training Session",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  BoxDecoration _glassBox() {
    return BoxDecoration(
      color: Colors.black.withOpacity(0.55),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white12),
    );
  }

  // ───────────────────────── LOGIC ─────────────────────────

  Future<void> _pickImage() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (picked != null) setState(() => sessionImage = File(picked.path));
  }

  String formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (startDate == null ||
        endDate == null ||
        startTime == null ||
        endTime == null) {
      _showError("Please complete all required fields");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) {
      _showError("Session expired");
      return;
    }

    setState(() => submitting = true);

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$api/api/myskates/training/"),
    );

    request.headers["Authorization"] = "Bearer $token";

    request.fields.addAll({
      "title": titleCtrl.text.trim(),
      "location": typedLocationCtrl.text.trim(),
      "latitude": latitude?.toString() ?? "",
      "longitude": longitude?.toString() ?? "",
      "note": notesCtrl.text.trim(),

      // ✅ FIXED FORMATS
      "start_date": formatDate(startDate!),
      "end_date": formatDate(endDate!),
      "start_time": formatTime(startTime!),
      "end_time": formatTime(endTime!),
    });

    if (sessionImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath("images", sessionImage!.path),
      );
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    setState(() => submitting = false);

    // ✅ PRINT FULL RESPONSE (VERY IMPORTANT FOR DEBUG)
    debugPrint("TRAINING CREATE STATUS: ${streamedResponse.statusCode}");
    debugPrint("TRAINING CREATE BODY: $responseBody");

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      // ✅ SUCCESS MESSAGE
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Training session created successfully"),
          backgroundColor: Colors.green,
        ),
      );

      // Small delay so snackbar is visible before pop
      Future.delayed(const Duration(milliseconds: 600), () {
        Navigator.pop(context, true);
      });
    } else {
      // ❌ FAILURE MESSAGE
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            responseBody.isNotEmpty
                ? responseBody
                : "Failed to create training session",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }
}

class TrainingSession {
  final String title;
  final String location;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final String? imageUrl;

  TrainingSession({
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    this.imageUrl,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    String? image;

    // ✅ SAFELY extract first image from images array
    if (json['images'] != null &&
        json['images'] is List &&
        json['images'].isNotEmpty) {
      image = json['images'][0]['image'];
    }

    return TrainingSession(
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      imageUrl: image,
    );
  }
}

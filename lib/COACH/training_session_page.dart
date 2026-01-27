import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/coach_view_training_registered_details.dart';
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
  String? existingImageUrl; // existing backend image
  bool isEditMode = false;
  int? editingSessionId;

  String? mapAddress;
  double? latitude;
  double? longitude;

  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  File? sessionImage;

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

  void _attachFields(http.MultipartRequest request) {
    request.fields.addAll({
      "title": titleCtrl.text.trim(),
      "location": typedLocationCtrl.text.trim(),
      "latitude": latitude?.toString() ?? "",
      "longitude": longitude?.toString() ?? "",
      "note": notesCtrl.text.trim(),
      "start_date": formatDate(startDate!),
      "end_date": formatDate(endDate!),
      "start_time": formatTime(startTime!),
      "end_time": formatTime(endTime!),
    });
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

  TimeOfDay _parseTime(String time) {
    final parsed = DateFormat("HH:mm:ss").parse(time);
    return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
  }

  void _confirmDelete(TrainingSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "Delete Training Session",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to permanently delete this session?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete"),
            onPressed: () {
              Navigator.pop(context);
              _deleteTrainingSession(session.id);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTrainingSession(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final response = await http.delete(
      Uri.parse("$api/api/myskates/training/$id/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Training session deleted"),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {}); // refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to delete session"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _editTrainingSession(TrainingSession session) {
    setState(() {
      isEditMode = true;
      editingSessionId = session.id;

      // TEXT FIELDS
      titleCtrl.text = session.title;
      typedLocationCtrl.text = session.location;
      notesCtrl.text = session.note ?? "";

      // DATES
      startDate = DateTime.parse(session.startDate);
      endDate = DateTime.parse(session.endDate);

      // TIMES
      startTime = _parseTime(session.startTime);
      endTime = _parseTime(session.endTime);

      // IMAGE
      existingImageUrl = session.imageUrl;
      sessionImage = null; // reset picked image

      // MAP LOCATION
      latitude = session.latitude;
      longitude = session.longitude;
      mapAddress = session.location;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Editing training session"),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  Widget _trainingSessionCard(TrainingSession session) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoachViewTrainingRegisteredDetails(
              sessionId: session.id.toString(),
              sessionTitle: session.title,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: _glassBox(),
        child: Stack(
          children: [
            Row(
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
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
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
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: accentColor,
                          ),
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

            // ───── 3 DOT MENU (BOTTOM RIGHT) ─────
            Positioned(
              bottom: 0,
              right: 0,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white70,
                  size: 22,
                ),
                onSelected: (value) {
                  if (value == "edit") {
                    _editTrainingSession(session);
                  } else if (value == "delete") {
                    _confirmDelete(session);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: "edit",
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 10),
                        Text("Edit"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: "delete",
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text(
                          "Delete",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

            // IMAGE PRIORITY:
            // 1. Newly picked image
            // 2. Existing backend image
            // 3. Placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: sessionImage != null
                  ? Image.file(
                      sessionImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : existingImageUrl != null
                  ? Image.network(
                      "$api$existingImageUrl",
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),

            const SizedBox(width: 16),
            Expanded(
              child: Text(
                isEditMode
                    ? "Tap to change training image"
                    : "Upload Training Image",
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const Icon(Icons.upload, color: accentColor),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      isEditMode = false;
      editingSessionId = null;

      titleCtrl.clear();
      typedLocationCtrl.clear();
      notesCtrl.clear();

      startDate = null;
      endDate = null;
      startTime = null;
      endTime = null;

      latitude = null;
      longitude = null;
      mapAddress = null;

      sessionImage = null;
      existingImageUrl = null;
    });
  }

  void _onSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
    setState(() {});
  }

  void _onFailure(String body) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(body.isNotEmpty ? body : "Operation failed"),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) {
      _showError("Session expired");
      return null;
    }
    return token;
  }

  Future<void> _updateTrainingSession() async {
    if (!_validateForm()) return;

    if (editingSessionId == null) {
      _showError("Invalid training session");
      return;
    }

    final token = await _getToken();
    if (token == null) return;

    setState(() => submitting = true);

    final request = http.MultipartRequest(
      "PUT",
      Uri.parse("$api/api/myskates/training/$editingSessionId/"),
    );

    request.headers["Authorization"] = "Bearer $token";

    _attachFields(request);

    // Image is optional in update
    if (sessionImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath("images", sessionImage!.path),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    setState(() => submitting = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      _onSuccess("Training session updated");
      _resetForm();
    } else {
      _onFailure(body);
    }
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
        onPressed: submitting
            ? null
            : isEditMode
            ? _updateTrainingSession
            : _createTrainingSession,
        child: submitting
            ? const CircularProgressIndicator(color: Colors.black)
            : Text(
                isEditMode
                    ? "Update Training Session"
                    : "Create Training Session",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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

  Future<void> _createTrainingSession() async {
    if (!_validateForm()) return;

    final token = await _getToken();
    if (token == null) return;

    setState(() => submitting = true);

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$api/api/myskates/training/"),
    );

    request.headers["Authorization"] = "Bearer $token";

    _attachFields(request);

    if (sessionImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath("images", sessionImage!.path),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    setState(() => submitting = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      _onSuccess("Training session created");
    } else {
      _onFailure(body);
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;

    if (startDate == null ||
        endDate == null ||
        startTime == null ||
        endTime == null) {
      _showError("Please complete all required fields");
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }
}

class TrainingSession {
  final int id;
  final String title;
  final String location;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final String? note;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  TrainingSession({
    required this.id,
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    this.note,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    String? image;

    if (json['images'] != null &&
        json['images'] is List &&
        json['images'].isNotEmpty) {
      image = json['images'][0]['image'];
    }

    return TrainingSession(
      id: json['id'],
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      note: json['note'],
      imageUrl: image,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}

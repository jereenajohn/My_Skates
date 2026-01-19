import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class studentAchievementsUpdate extends StatefulWidget {
  final Map<String, dynamic> achievement;

  const studentAchievementsUpdate({super.key, required this.achievement});

  @override
  State<studentAchievementsUpdate> createState() =>
      _studentAchievementsUpdateState();
}

class _studentAchievementsUpdateState extends State<studentAchievementsUpdate> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController noteController;


  DateTime? selectedDate;
  File? imageFile;
  String? existingImage;
  bool loading = false;

  static const Color bgTop = Color(0xFF0A332E);
  static const Color bgBottom = Colors.black;
  static const Color accent = Color(0xFF2EE6A6);
  static const Color glass = Color.fromRGBO(255, 255, 255, 0.10);
  static const Color border = Color.fromRGBO(255, 255, 255, 0.18);

  @override
  void initState() {
    super.initState();
    final a = widget.achievement;

    titleController = TextEditingController(text: a["title"] ?? "");
    descriptionController = TextEditingController(text: a["description"] ?? "");
    noteController = TextEditingController(text: a["note"] ?? "");

    selectedDate = a["date"] != null ? DateTime.tryParse(a["date"]) : null;
    existingImage = a["image"];
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
        existingImage = null;
      });
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> updateAchievement() async {
    if (!_formKey.currentState!.validate() || selectedDate == null) return;

    try {
      setState(() => loading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final id = widget.achievement["id"];
      final request = http.MultipartRequest(
        "PUT",
        Uri.parse("$api/api/myskates/achievements/$id/"),
      );

      request.headers["Authorization"] = "Bearer $token";
      request.fields["title"] = titleController.text.trim();
      request.fields["description"] = descriptionController.text.trim();
      request.fields["note"] = noteController.text.trim();

      request.fields["date"] =
          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", imageFile!.path),
        );
      }

      final res = await request.send();
      setState(() => loading = false);

      if (res.statusCode == 200 || res.statusCode == 204) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("UPDATE ERROR: $e");
    }
  }

  Widget glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: glass,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
          ),
          child: child,
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      border: InputBorder.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Colors.black, 
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  /// BACK
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// IMAGE
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 110,
                      width: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: glass,
                        border: Border.all(color: border),
                        image: imageFile != null
                            ? DecorationImage(
                                image: FileImage(imageFile!),
                                fit: BoxFit.cover,
                              )
                            : existingImage != null
                            ? DecorationImage(
                                image: NetworkImage("$api$existingImage"),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageFile == null && existingImage == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 36,
                              color: Colors.white70,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// TITLE
                  glassCard(
                    child: TextFormField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: inputDecoration("Achievement Title"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// DESCRIPTION
                  glassCard(
                    child: TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: inputDecoration("Achievement Description"),
                    ),
                  ),

                  const SizedBox(height: 18),

                   glassCard(
                    child: TextFormField(
                      controller: noteController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: inputDecoration("Note (Optional)"),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// DATE
                  glassCard(
                    child: InkWell(
                      onTap: pickDate,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedDate == null
                                ? "Select Date"
                                : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: loading ? null : updateAchievement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 3, 224, 202),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text(
                              "Update Achievement",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

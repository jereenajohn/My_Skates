import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class AddCoachAchievements extends StatefulWidget {
  const AddCoachAchievements({super.key});

  @override
  State<AddCoachAchievements> createState() => _AddCoachAchievementsState();
}

class _AddCoachAchievementsState extends State<AddCoachAchievements> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// CONTROLLERS
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  /// STATE
  DateTime? selectedDate;
  File? imageFile;
  bool loading = false;

  /// THEME COLORS (YOUR REQUIRED COLORS)
  static const Color primaryGreen = Color(0xFF0A332E);
  static const Color glassColor = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color borderColor = Color.fromRGBO(255, 255, 255, 0.15);

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    noteController.dispose();
    locationController.dispose();
    super.dispose();
  }

  /// IMAGE PICKER
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => imageFile = File(picked.path));
    }
  }

  /// DATE PICKER
  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  /// API – ADD ACHIEVEMENT
  Future<void> addAchievement() async {
    if (!_formKey.currentState!.validate() || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) return;

      final uri = Uri.parse("$api/api/myskates/achievements/");
      final request = http.MultipartRequest("POST", uri);

      request.headers["Authorization"] = "Bearer $token";

      request.fields["title"] = titleController.text.trim();
      request.fields["description"] = descriptionController.text.trim();
      request.fields["note"] = noteController.text.trim();
      request.fields["location"] = locationController.text.trim();
      request.fields["date"] =
          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", imageFile!.path),
        );
      }

      final res = await request.send();
      final response = await http.Response.fromStream(res);

      print("ADD ACHIEVEMENT STATUS: ${response.statusCode}");
      print("ADD ACHIEVEMENT BODY: ${response.body}");

      setState(() => loading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Achievement added successfully")),
        );
        Navigator.pop(context, true);
      } else {
        debugPrint(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add achievement")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("ADD ACHIEVEMENT ERROR: $e");
    }
  }

  /// GLASS CARD
  Widget glassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
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
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryGreen, Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  /// BACK
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  /// UPLOAD IMAGE
                  GestureDetector(
                    onTap: pickImage,
                    child: Column(
                      children: [
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: glassColor,
                            border: Border.all(color: borderColor),
                            image: imageFile != null
                                ? DecorationImage(
                                    image: FileImage(imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: imageFile == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white70,
                                  size: 40,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Upload Photo",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  glassCard(
                    TextFormField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration("Achievement Title"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                  ),

                  glassCard(
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration("Description"),
                    ),
                  ),

                  glassCard(
                    TextFormField(
                      controller: noteController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration("Note (optional)"),
                    ),
                  ),

                  glassCard(
                    InkWell(
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
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),

                  glassCard(
                    TextFormField(
                      controller: locationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: inputDecoration("Location"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 3, 205, 184),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: loading ? null : addAchievement,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              "Save Achievement",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterationPage extends StatefulWidget {
  final String phone;
  const RegisterationPage({super.key, required this.phone});

  @override
  State<RegisterationPage> createState() => _RegisterationPageState();
}

class _RegisterationPageState extends State<RegisterationPage> {
  int currentStep = 1;
  String? selectedRole;

  // Controllers
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController altPhoneCtrl = TextEditingController();
  final TextEditingController dobCtrl = TextEditingController();
  final TextEditingController zipCodeCtrl = TextEditingController();
  final TextEditingController whatsappCtrl = TextEditingController();
  final TextEditingController instaCtrl = TextEditingController();
  final TextEditingController qualificationCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();

  // Student ONLY
  final TextEditingController standardCtrl = TextEditingController();
  final TextEditingController instituteCtrl = TextEditingController();
  final TextEditingController experience = TextEditingController();

  String? selectedGender;
  double? userLat;
  double? userLong;

  File? selectedDocumentFile;
  String? selectedDocName;

  @override
  void initState() {
    super.initState();
    whatsappCtrl.text = widget.phone;

    print("REGISTER PHONE: ${widget.phone}");
  }

  // -------------------------------------------------------------------------
  // LOCATION PICKER
  // -------------------------------------------------------------------------
  Future<void> getCurrentLocation() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      error("Enable GPS first");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        error("Location permission denied");
        return;
      }
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    userLat = pos.latitude;
    userLong = pos.longitude;

    success("Location fetched");
    setState(() {});
  }

  // -------------------------------------------------------------------------
  // DOB PICKER
  // -------------------------------------------------------------------------
  Future<void> pickDOB() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      builder: (_, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00D8CC),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      dobCtrl.text =
          "${picked.year}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}";
      setState(() {});
    }
  }

  // -------------------------------------------------------------------------
  // DOCUMENT PICKER
  // -------------------------------------------------------------------------
  Future<void> pickCoachDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      selectedDocumentFile = File(result.files.single.path!);
      selectedDocName = result.files.single.name;

      success("Document selected");
      setState(() {});
    } else {
      error("No file selected");
    }
  }

  // -------------------------------------------------------------------------
  // VALIDATION
  // -------------------------------------------------------------------------
  bool validateStudent() {
    if (firstNameCtrl.text.isEmpty ||
        lastNameCtrl.text.isEmpty ||
        dobCtrl.text.isEmpty ||
        standardCtrl.text.isEmpty ||
        instituteCtrl.text.isEmpty ||
        zipCodeCtrl.text.isEmpty ||
        instaCtrl.text.isEmpty) {
      error("Please fill all student fields");
      return false;
    }

    if (whatsappCtrl.text.length != 10) {
      error("WhatsApp number must be 10 digits");
      return false;
    }

    return true;
  }

  bool validateCoach() {
    if (firstNameCtrl.text.isEmpty ||
        lastNameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        dobCtrl.text.isEmpty ||
        selectedGender == null ||
        zipCodeCtrl.text.isEmpty ||
        instaCtrl.text.isEmpty ||
        selectedDocumentFile == null) {
      error("Fill all coach fields & upload document");
      return false;
    }
    return true;
  }

  // -------------------------------------------------------------------------
  // API POST (MULTIPART)
  // -------------------------------------------------------------------------
  Future<void> postUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      print("REGISTER TOKEN: $token");

      if (token == null) {
        error("Login expired");
        return;
      }

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$api/api/myskates/profile/"),
      );

      request.headers["Authorization"] = "Bearer $token";

      request.fields.addAll({
        "user_type": selectedRole ?? "",
        "first_name": firstNameCtrl.text.trim(),
        "last_name": lastNameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "alt_phone": altPhoneCtrl.text.trim(),
        "gender": selectedGender ?? "",
        "dob": dobCtrl.text.trim(),
        "zip_code": zipCodeCtrl.text.trim(),
        "instagram": instaCtrl.text.trim(),
        "qualification": qualificationCtrl.text.trim(),
        "description": descriptionCtrl.text.trim(),
        // "phone": widget.phone,
        "latitude": (userLat ?? "").toString(),
        "longitude": (userLong ?? "").toString(),
        "experience": experience.text.trim(),
      });

      if (selectedRole == "student") {
        request.fields["standard"] = standardCtrl.text.trim();
        request.fields["institution"] = instituteCtrl.text.trim();
      }

      if (selectedRole == "coach" && selectedDocumentFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "document",
            selectedDocumentFile!.path,
          ),
        );
      }

      var response = await request.send();
      String result = await response.stream.bytesToString();

      print("UPLOAD RESPONSE: $result");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();

        prefs.setString("name", "${firstNameCtrl.text} ${lastNameCtrl.text}");
        prefs.setString("user_type", selectedRole ?? "");
        prefs.setString("profile", "");

        success("Profile updated");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        error(result);
      }
    } catch (e) {
      error("Error: $e");
    }
  }

  // -------------------------------------------------------------------------
  // NEXT BUTTON LOGIC
  // -------------------------------------------------------------------------
  void _handleNext() {
    if (currentStep == 1) {
      if (selectedRole == null) {
        error("Please choose coach or student");
        return;
      }
      setState(() => currentStep = 2);
      return;
    }

    if (currentStep == 2) {
      if (selectedRole == "student") {
        if (!validateStudent()) return;
      } else {
        if (!validateCoach()) return;
      }
      setState(() => currentStep = 3);
      return;
    }

    if (currentStep == 3) {
      if (userLat == null || userLong == null) {
        error("Please fetch location first");
        return;
      }
      postUserProfile();
    }
  }

  // -------------------------------------------------------------------------
  // MAIN UI
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Register",
                style: TextStyle(
                  color: Color(0xFF00D8CC),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildStepBar(currentStep == 1),
                  const SizedBox(width: 8),
                  buildStepBar(currentStep == 2),
                  const SizedBox(width: 8),
                  buildStepBar(currentStep == 3),
                ],
              ),

              const SizedBox(height: 25),

              Expanded(child: _buildCurrentStep()),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D8CC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    currentStep == 3 ? "Register" : "Next",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // STEP BAR
  // -------------------------------------------------------------------------
  Widget buildStepBar(bool active) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white30,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // STEP SWITCHER
  // -------------------------------------------------------------------------
  Widget _buildCurrentStep() {
    if (currentStep == 1) return step1();
    if (currentStep == 2) {
      return selectedRole == "student" ? studentForm() : coachForm();
    }
    return step3();
  }

  // -------------------------------------------------------------------------
  // STEP 1 : ROLE
  // -------------------------------------------------------------------------
  Widget step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Are you a coach or student?",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        const SizedBox(height: 20),

        buildRoleOption("coach"),
        buildRoleOption("student"),
      ],
    );
  }

  Widget buildRoleOption(String role) {
    return Row(
      children: [
        Radio(
          value: role,
          groupValue: selectedRole,
          activeColor: const Color(0xFF00D8CC),
          onChanged: (v) => setState(() => selectedRole = v.toString()),
        ),
        Text(
          role.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // STEP 2 : STUDENT FORM
  // -------------------------------------------------------------------------
  Widget studentForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          rowTwo(
            input("First Name", firstNameCtrl),
            input("Last Name", lastNameCtrl),
          ),
          const SizedBox(height: 15),

          dobPicker(),
          const SizedBox(height: 15),

          input("Standard", standardCtrl),
          const SizedBox(height: 15),

          input("Institute Name", instituteCtrl),
          const SizedBox(height: 15),

          input("Zip Code", zipCodeCtrl),
          const SizedBox(height: 15),

          input("Instagram ID", instaCtrl),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // STEP 2 : COACH FORM
  // -------------------------------------------------------------------------
  Widget coachForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          rowTwo(
            input("First Name", firstNameCtrl),
            input("Last Name", lastNameCtrl),
          ),
          const SizedBox(height: 15),

          input("Email", emailCtrl),

          const SizedBox(height: 15),
          dobGenderRow(),
          const SizedBox(height: 15),

          input("Experience", experience),
          const SizedBox(height: 15),

          input("Alternate Phone", altPhoneCtrl),
          const SizedBox(height: 15),

          // genderDropdownCompact(),
          // const SizedBox(height: 15),
          input("Zip Code", zipCodeCtrl),
          const SizedBox(height: 15),

          input("Instagram ID", instaCtrl),
          const SizedBox(height: 25),

          // DOCUMENT UPLOAD UI
          GestureDetector(
            onTap: pickCoachDocument,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF00D8CC)),
                borderRadius: BorderRadius.circular(20),
                color: Colors.white12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    selectedDocumentFile == null
                        ? "Upload Coaching Document"
                        : "Document Selected ✓",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          if (selectedDocName != null) ...[
            const SizedBox(height: 8),
            Text(
              selectedDocName!,
              style: const TextStyle(color: Colors.white70),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // STEP 3 : LOCATION
  // -------------------------------------------------------------------------
  Widget step3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Add your location",
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        const SizedBox(height: 30),

        bigButton("Use Current Location", getCurrentLocation),
        const SizedBox(height: 20),

        if (userLat != null)
          Text(
            "Selected: $userLat , $userLong",
            style: const TextStyle(color: Colors.white70),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // REUSABLE WIDGETS
  // -------------------------------------------------------------------------
  Widget rowTwo(Widget a, Widget b) {
    return Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 15),
        Expanded(child: b),
      ],
    );
  }

  Widget input(String label, TextEditingController ctrl) {
    bool readOnly = label == "WhatsApp Number";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF00D8CC)),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: ctrl,
            readOnly: readOnly,
            keyboardType: readOnly ? TextInputType.phone : TextInputType.text,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Widget dobPicker() {
    return GestureDetector(
      onTap: pickDOB,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF00D8CC)),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dobCtrl.text.isEmpty ? "Select DOB" : dobCtrl.text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Icon(Icons.calendar_today, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget dobGenderRow() {
    return Row(
      children: [
        Expanded(child: dobPickerCompact()),
        const SizedBox(width: 12),
        Expanded(child: genderDropdownCompact()),
      ],
    );
  }

  Widget dobPickerCompact() {
    return GestureDetector(
      onTap: pickDOB,
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF00D8CC)),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                dobCtrl.text.isEmpty ? "Select DOB" : dobCtrl.text,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget genderDropdownCompact() {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFF00D8CC)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true, // ← FIX OVERFLOW
          dropdownColor: Colors.black87,
          value: selectedGender,
          hint: const Text("Gender", style: TextStyle(color: Colors.white70)),
          items: ["Male", "Female", "Other"].map((e) {
            return DropdownMenuItem<String>(
              value: e,
              child: Text(
                e,
                overflow: TextOverflow.ellipsis, // safety
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => selectedGender = v),
        ),
      ),
    );
  }

  Widget bigButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006F67),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void error(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void success(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }
}

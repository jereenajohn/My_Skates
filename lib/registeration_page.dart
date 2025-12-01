import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/Home_Page.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterationPage extends StatefulWidget {
  final String phone;
  const RegisterationPage({super.key, required this.phone});

  @override
  State<RegisterationPage> createState() => _RegisterationPageState();
}

class _RegisterationPageState extends State<RegisterationPage> {
  int currentStep = 1; // 1,2,3
  String? selectedRole;

  // Step 2 controllers

  final TextEditingController stdCtrl = TextEditingController();
  final TextEditingController instCtrl = TextEditingController();
  final TextEditingController whatsappCtrl = TextEditingController();
  final TextEditingController instaCtrl = TextEditingController();
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController dobCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
      whatsappCtrl.text = widget.phone;
  }


double? userLat;
double? userLong;

// REQUEST PERMISSION & GET CURRENT LOCATION
Future<void> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if GPS is ON
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    error("Please enable location services");
    return;
  }

  // Check permission
  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      error("Location permission denied");
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    error("Location permissions are permanently denied.");
    return;
  }

  // Fetch location
  Position pos = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  setState(() {
    userLat = pos.latitude;
    userLong = pos.longitude;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: Colors.green,
      content: Text("Location fetched successfully"),
    ),
  );

  print("LAT: $userLat  LONG: $userLong");
}

Future<void> pickDOB() async {
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime(2010),
    firstDate: DateTime(1960),
    lastDate: DateTime.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D8CC),
            onPrimary: Colors.white,
            surface: Colors.black87,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      );
    },
  );

  if (pickedDate != null) {
    setState(() {
      dobCtrl.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
    });
  }
}

String formatDob(String dob) {
  final parts = dob.split('/'); // [dd, mm, yyyy]

  if (parts.length != 3) return dob; // fallback

  final day = parts[0].padLeft(2, '0');
  final month = parts[1].padLeft(2, '0');
  final year = parts[2];

  return "$year-$month-$day";  // yyyy-mm-dd
}


  Future<void> postUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        error("Not authenticated. Please log in again.");
        return;
      }

      final body = {
        "user_type": selectedRole,
        "first_name": firstNameCtrl.text.trim(),
        "last_name": lastNameCtrl.text.trim(),
        "dob": formatDob(dobCtrl.text.trim()),
        "standard": stdCtrl.text.trim(),
        "institution": instCtrl.text.trim(),
        "phone": widget.phone,
        "instagram": "https://www.instagram.com/${instaCtrl.text.trim()}",
        "latitude": userLat?.toString(),
        "longitude": userLong?.toString(),
      };

      final response = await http.post(
        Uri.parse('$api/api/myskates/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print("Profile Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Profile updated successfully'),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        error("Update failed: ${response.body}");
      }
    } catch (e) {
      error("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // TITLE
              const Center(
                child: Text(
                  "Registerr",
                  style: TextStyle(
                    color: Color(0xFF00D8CC),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // SUBTITLE
              const Center(
                child: Text(
                  "This is the platform where\nstudents and coaches meet together.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // STEP INDICATOR (4 steps)
              // STEP INDICATOR (3 steps)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildStepBar(active: currentStep == 1),
                  const SizedBox(width: 8),
                  buildStepBar(active: currentStep == 2),
                  const SizedBox(width: 8),
                  buildStepBar(active: currentStep == 3),
                ],
              ),

              const SizedBox(height: 40),

              // CONTENT SWITCHER
              Expanded(child: _buildCurrentStep()),

              const SizedBox(height: 10),

              // BOTTOM BUTTON
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

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  bool validateStep2() {
    if (firstNameCtrl.text.trim().isEmpty ||
        lastNameCtrl.text.trim().isEmpty ||
        dobCtrl.text.trim().isEmpty ||
        stdCtrl.text.trim().isEmpty ||
        instCtrl.text.trim().isEmpty ||
        whatsappCtrl.text.trim().isEmpty ||
        instaCtrl.text.trim().isEmpty) {
      error("Please fill all the required fields");
      return false;
    }

    // WhatsApp number must be exactly 10 digits
    if (whatsappCtrl.text.trim().length != 10) {
      error("WhatsApp number must be 10 digits");
      return false;
    }

    return true;
  }

  void error(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(msg)));
  }

  // BUTTON LOGIC
  void _handleNext() {
    if (currentStep == 1) {
      if (selectedRole == null) {
        error("Please select a role");
        return;
      }
      setState(() => currentStep = 2);
    } else if (currentStep == 2) {
      if (!validateStep2()) return;
      setState(() => currentStep = 3);
    } else if (currentStep == 3) {
  if (userLat == null || userLong == null) {
    error("Please pick your location first");
    return;
  }
  postUserProfile();
}

  }

  // STEP BAR UI
  Widget buildStepBar({required bool active}) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white30,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  // Decide which step content to show
  Widget _buildCurrentStep() {
    if (currentStep == 1) return _step1();
    if (currentStep == 2) return _step2();
    return _step3();
  }

  // STEP 1 UI
  Widget _step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Are you a coach or student?",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Radio(
              value: "coach",
              groupValue: selectedRole,
              activeColor: const Color(0xFF00D8CC),
              onChanged: (v) => setState(() => selectedRole = v.toString()),
            ),
            const Text(
              "Coach",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),

        Row(
          children: [
            Radio(
              value: "student",
              groupValue: selectedRole,
              activeColor: const Color(0xFF00D8CC),
              onChanged: (v) => setState(() => selectedRole = v.toString()),
            ),
            const Text(
              "Student",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 2 UI
  Widget _step2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add your details",
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
          const SizedBox(height: 20),

          // FIRST NAME + LAST NAME (ROW 1)
          Row(
            children: [
              Expanded(child: buildInput("First Name", firstNameCtrl)),
              const SizedBox(width: 15),
              Expanded(child: buildInput("Last Name", lastNameCtrl)),
            ],
          ),

          const SizedBox(height: 20),

          // DOB + STANDARD (ROW 2)
          Row(
            children: [
              // DOB PICKER
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Date of Birth",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: pickDOB,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF00D8CC)),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          dobCtrl.text.isEmpty ? "Select DOB" : dobCtrl.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 15),

              // STANDARD
              Expanded(child: buildInput("Standard", stdCtrl)),
            ],
          ),

          const SizedBox(height: 20),

          // INSTITUTE NAME
          buildInput("Institute Name", instCtrl),
          const SizedBox(height: 20),

          // WHATSAPP NUMBER
          buildInput("WhatsApp Number", whatsappCtrl),
          const SizedBox(height: 20),

          // INSTAGRAM ID
          buildInput("Instagram ID", instaCtrl),
        ],
      ),
    );
  }

  // STEP 3 UI — LOCATION SCREEN
  Widget _step3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Add your Location",
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        const SizedBox(height: 30),

      buildBigButton("Use current location", () async {
  await getCurrentLocation();
}),

        const SizedBox(height: 20),

        buildBigButton("Use pincode", () {
          print("Using pin code...");
        }),
      ],
    );
  }

  Widget buildBigButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006F67),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  // INPUT FIELD REUSABLE WIDGET
 Widget buildInput(String label, TextEditingController controller) {
  bool isWhatsapp = label == "WhatsApp Number";

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00D8CC)),
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: controller,
          readOnly: isWhatsapp, // only WhatsApp field locked
          keyboardType: isWhatsapp ? TextInputType.phone : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
    ],
  );
}
}
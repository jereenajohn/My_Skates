import 'package:flutter/material.dart';

class RegisterationPage extends StatefulWidget {
  const RegisterationPage({super.key});

  @override
  State<RegisterationPage> createState() => _RegisterationPageState();
}

class _RegisterationPageState extends State<RegisterationPage> {
  int currentStep = 1; // 1,2,3
  String? selectedRole;

  // Step 2 controllers
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController ageCtrl = TextEditingController();
  final TextEditingController stdCtrl = TextEditingController();
  final TextEditingController instCtrl = TextEditingController();
  final TextEditingController whatsappCtrl = TextEditingController();
  final TextEditingController instaCtrl = TextEditingController();

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
                  "Registerrr",
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

  // BUTTON LOGIC
  void _handleNext() {
    if (currentStep == 1 && selectedRole != null) {
      setState(() => currentStep = 2);
    } else if (currentStep == 2) {
      setState(() => currentStep = 3);
    } else if (currentStep == 3) {
      // Final submit
      print("REGISTER COMPLETE");
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

          buildInput("Name", nameCtrl),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: buildInput("Age", ageCtrl)),
              const SizedBox(width: 15),
              Expanded(child: buildInput("Standard", stdCtrl)),
            ],
          ),

          const SizedBox(height: 20),
          buildInput("Institute Name", instCtrl),

          const SizedBox(height: 20),
          buildInput("WhatsApp Number", whatsappCtrl),

          const SizedBox(height: 20),
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

        buildBigButton("Use current location", () {
          print("Fetching current location...");
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
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }
}

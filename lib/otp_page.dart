import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/COACH/coach_homepage.dart';
import 'package:my_skates/Home_Page.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/loginpage.dart';
import 'package:my_skates/registeration_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  const OtpPage({super.key, required this.phoneNumber});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  // ------------------------------------------------------
  // FIXED: POST OTP FUNCTION
  // ------------------------------------------------------
  Future<void> postOtp(String enteredOtp) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final response = await http.post(
        Uri.parse('$api/api/myskates/verify/otp/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"otp": enteredOtp, "phone": widget.phoneNumber}),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ------------------------------------------------
        // FIX: SAVE DATA USING CORRECT KEYS
        // ------------------------------------------------
        await prefs.setString("access", data["access"]); // FIXED
        await prefs.setString("refresh", data["refresh"]);
        await prefs.setInt("id", data["user"]["id"]);
        await prefs.setString("user_type", data["user"]["user_type"]);
        prefs.setString("name", data["user"]["name"]);
        await prefs.setString("phone", widget.phoneNumber); // IMPORTANT

        print("SAVED TOKEN: ${data["access"]}");
        print("SAVED USER ID: ${data["user"]["id"]}");

        bool firstTime = data["first_time"] ?? false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 26, 164, 143),
            content: Text('OTP verified successfully'),
          ),
        );

        // SUCCESS — Navigate Properly
        String userType = data["user"]["user_type"] ?? "";

        if (firstTime) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RegisterationPage(phone: widget.phoneNumber),
            ),
          );
        } else {
          // CHECK USER TYPE & NAVIGATE
          if (userType == "admin") {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
              (route) => false,
            );
          } else if (userType == "student") {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          } 
           else if (userType == "coach") {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CoachHomepage()),
              (route) => false,
            );
          }
          else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("OTP Verification Failed: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Error: $e")),
      );
    }
  }

  // ------------------------------------------------------
  // OVERRIDE BUILD
  // ------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 80),

                    Image.asset("lib/assets/myskates.png", height: 120),

                    const SizedBox(height: 60),

                    const Text(
                      "Get starts with your\nPhone number",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ------------------------------------------------------
                    // OTP FIELDS
                    // ------------------------------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 45,
                          height: 55,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: TextField(
                            controller: otpControllers[index],
                            focusNode: focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              counterText: "",
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white38,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(focusNodes[index + 1]);
                              } else if (value.isEmpty && index > 0) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(focusNodes[index - 1]);
                              }
                            },
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 50),

                    // ------------------------------------------------------
                    // VERIFY BUTTON
                    // ------------------------------------------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            String otp = otpControllers
                                .map((e) => e.text)
                                .join();

                            if (otp.length != 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text("Please enter 6 digit OTP"),
                                ),
                              );
                              return;
                            }

                            await postOtp(otp);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D8CC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Verify",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Loginpage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Edit phone number?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              "Send again",
                              style: TextStyle(
                                color: Color(0xFF00D8CC),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/otp_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController phoneController = TextEditingController();

  Future<void> _postPhoneNumber() async {
    print("Posting phone number...");
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      _showMessage("Please enter your mobile number");
      return;
    }

    if (phone.length != 10) {
      _showMessage("Phone number must be 10 digits");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$api/api/myskates/request/otp/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone}),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage("OTP sent successfully ${response.body}");

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpPage(phoneNumber: phone)),
        );
      } else {
        _showMessage("OTP send failed");
      }
    } catch (e) {
      print("Error occurred: $e");
      _showMessage("Network error. Please try again.");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color.fromARGB(255, 26, 164, 143),
      ),
    );
  }

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
            child: Column(
              children: [
                const SizedBox(height: 80),

                Image.asset("lib/assets/myskates.png", height: 120),

                const SizedBox(height: 60),

                const Text(
                  "Get started with your\nPhone number",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          "+91",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Phone number",
                              hintStyle: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _postPhoneNumber,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 216, 204),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Get OTP",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
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
    );
  }
}

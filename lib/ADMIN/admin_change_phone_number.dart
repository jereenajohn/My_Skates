import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class AdminChangePhoneNumber extends StatefulWidget {
  const AdminChangePhoneNumber({super.key});

  @override
  State<AdminChangePhoneNumber> createState() => _AdminChangePhoneNumberState();
}

class _AdminChangePhoneNumberState extends State<AdminChangePhoneNumber> {
  TextEditingController newPhoneController = TextEditingController();
  TextEditingController oldOtpController = TextEditingController();
  TextEditingController newOtpController = TextEditingController();

  bool loading = false;

  int step =
      1; // 1=new phone, 2=verify old otp, 3=request new otp, 4=verify new otp

  @override
  void dispose() {
    newPhoneController.dispose();
    oldOtpController.dispose();
    newOtpController.dispose();
    super.dispose();
  }

  // ================= TOKEN =================
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  // ================= REQUEST OLD OTP =================
  Future<void> requestOldOtp() async {
    try {
      setState(() => loading = true);

      final token = await getToken();
      if (token == null) return;

      final res = await http.post(
        Uri.parse("$api/api/myskates/change/phone/request/old/otp/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"new_phone": newPhoneController.text.trim()}),
      );

      print("Request Old OTP Status: ${res.statusCode}");
      print("Request Old OTP Body: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => step = 2);
        showMsg("OTP sent to your old phone number.");
      } else {
        showMsg("Failed to send OTP. Try again.");
      }
    } catch (e) {
      showMsg("Error: $e");
    }

    setState(() => loading = false);
  }

  // ================= VERIFY OLD OTP =================
  Future<void> verifyOldOtp() async {
    try {
      setState(() => loading = true);

      final token = await getToken();
      if (token == null) return;

      final res = await http.post(
        Uri.parse("$api/api/myskates/change/phone/verify/old/otp/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"otp": oldOtpController.text.trim()}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => step = 3);
        showMsg("Old OTP verified. Request OTP for new phone.");
      } else {
        showMsg("Invalid OTP. Try again.");
      }
    } catch (e) {
      showMsg("Error: $e");
    }

    setState(() => loading = false);
  }

  // ================= REQUEST NEW OTP =================
  Future<void> requestNewOtp() async {
    try {
      setState(() => loading = true);

      final token = await getToken();
      if (token == null) return;

      final res = await http.post(
        Uri.parse("$api/api/myskates/change/phone/request/new/otp/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => step = 4);
        showMsg("OTP sent to your new phone number.");
      } else {
        showMsg("Failed to send OTP to new phone.");
      }
    } catch (e) {
      showMsg("Error: $e");
    }

    setState(() => loading = false);
  }

  // ================= VERIFY NEW OTP =================
  Future<void> verifyNewOtp() async {
    try {
      setState(() => loading = true);

      final token = await getToken();
      if (token == null) return;

      final res = await http.post(
        Uri.parse("$api/api/myskates/change/phone/verify/new/otp/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"otp": newOtpController.text.trim()}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        showMsg("Phone number updated successfully. Please login again.");

        await logoutAndGoLogin();
      } else {
        showMsg("Invalid OTP. Try again.");
      }
    } catch (e) {
      showMsg("Error: $e");
    }

    setState(() => loading = false);
  }

  // ================= LOGOUT =================
  Future<void> logoutAndGoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("access");
    await prefs.remove("refresh");

    if (!mounted) return;

    Navigator.popUntil(context, (route) => route.isFirst);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Loginpage()),
    );
  }

  // ================= SNACK =================
  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  // ================= TEXTFIELD STYLE =================
  Widget customField(
    TextEditingController controller,
    String hint, {
    bool otp = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: otp ? TextInputType.number : TextInputType.phone,
      maxLength: otp ? 6 : 10,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        counterText: "",
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 1),
        ),
      ),
    );
  }

  // ================= BUTTON =================
  Widget tealButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Widget _glassBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F1D), Color(0xFF003A36), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        "Change Phone Number",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Step $step of 4",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      "Secure Phone Change",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Verify your old number first, then confirm the new number.",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12.5,
                      ),
                    ),

                    const SizedBox(height: 25),

                    if (step == 1) ...[
                      customField(newPhoneController, "Enter New Phone Number"),
                      const SizedBox(height: 16),
                      tealButton("Request OTP (Old Phone)", requestOldOtp),
                    ],

                    if (step == 2) ...[
                      customField(
                        oldOtpController,
                        "Enter OTP from Old Phone",
                        otp: true,
                      ),
                      const SizedBox(height: 16),
                      tealButton("Verify Old OTP", verifyOldOtp),
                    ],

                    if (step == 3) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_android,
                              color: Colors.teal,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "New phone: ${newPhoneController.text.trim()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      tealButton("Request OTP (New Phone)", requestNewOtp),
                    ],

                    if (step == 4) ...[
                      customField(
                        newOtpController,
                        "Enter OTP from New Phone",
                        otp: true,
                      ),
                      const SizedBox(height: 16),
                      tealButton("Verify New OTP", verifyNewOtp),
                    ],
                  ],
                ),

                const Spacer(),

                Text(
                  "After successful verification, you will be logged out for security.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

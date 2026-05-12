import 'package:flutter/material.dart';
import 'package:my_skates/loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoachApprovalRejectedScreen extends StatelessWidget {
  const CoachApprovalRejectedScreen({super.key});

  Future<void> _goToLogin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("access");
    await prefs.remove("refresh");
    await prefs.remove("user_type");
    await prefs.remove("user_id");
    await prefs.remove("name");
    await prefs.remove("profile");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const Loginpage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A0000), Color(0xFF000000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),

                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.redAccent,
                    size: 58,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  "Approval Rejected",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Your coach profile was rejected by admin. Please contact support for more details.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Rejected",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                Column(
                  children: [
                    const Text(
                      "You can go back to login and contact admin if needed.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 14),

                    GestureDetector(
                      onTap: () => _goToLogin(context),
                      child: const Text(
                        "Go to Login",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
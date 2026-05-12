import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/rejected_screen.dart';

class CoachApprovalPendingScreen extends StatefulWidget {
  final int userId;

  const CoachApprovalPendingScreen({super.key, required this.userId});

  @override
  State<CoachApprovalPendingScreen> createState() =>
      _CoachApprovalPendingScreenState();
}

class _CoachApprovalPendingScreenState
    extends State<CoachApprovalPendingScreen> {
  bool isChecking = false;
  String approvalStatus = "pending";

  @override
  void initState() {
    super.initState();
  }

  Future<void> checkCoachApprovalStatus() async {
    if (isChecking) return;

    if (widget.userId == 0) {
      setState(() {
        approvalStatus = "pending";
      });
      return;
    }

    setState(() {
      isChecking = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login expired"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.get(
        Uri.parse("$api/api/myskates/coach/approval/${widget.userId}/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("COACH APPROVAL STATUS CODE: ${response.statusCode}");
      print("COACH APPROVAL BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final String status =
            decoded["approval_status"]?.toString().toLowerCase() ?? "pending";

        if (!mounted) return;

        setState(() {
          approvalStatus = status;
        });

        if (status == "approved") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        } else if (status == "disapproved") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const CoachApprovalRejectedScreen(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print("COACH APPROVAL CHECK ERROR: $e");
    } finally {
      if (mounted) {
        setState(() {
          isChecking = false;
        });
      }
    }
  }

  Color get statusColor {
    switch (approvalStatus.toLowerCase()) {
      case "approved":
        return Colors.greenAccent;
      case "disapproved":
        return Colors.redAccent;
      default:
        return const Color(0xFF00D8CC);
    }
  }

  String get statusText {
    switch (approvalStatus.toLowerCase()) {
      case "approved":
        return "Approved";
      case "disapproved":
        return "Disapproved";
      case "waiting_for_approval":
        return "Waiting For Approval";
      default:
        return "Pending Approval";
    }
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
              colors: [Color(0xFF00312D), Color(0xFF000000)],
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
                    color: const Color(0xFF00D8CC).withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00D8CC).withOpacity(0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: Color(0xFF00D8CC),
                    size: 52,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  "Approval Pending",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF00D8CC),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Your coach profile has been submitted successfully. Please wait until admin reviews and approves your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: statusColor.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isChecking)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Color(0xFF00D8CC),
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Icon(
                          Icons.info_outline_rounded,
                          color: statusColor,
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: isChecking ? null : checkCoachApprovalStatus,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00D8CC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF00D8CC),
                    ),
                    label: const Text(
                      "Check Status",
                      style: TextStyle(
                        color: Color(0xFF00D8CC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                Column(
                  children: [
                    const Text(
                      "Please check your approval status manually after admin review.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),

                    const SizedBox(height: 14),

                    GestureDetector(
                      onTap: _goToLogin,
                      child: const Text(
                        "Go to Login",
                        style: TextStyle(
                          color: Color(0xFF00D8CC),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF00D8CC),
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

  Future<void> _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("access");
    await prefs.remove("refresh");
    await prefs.remove("user_type");
    await prefs.remove("user_id");
    await prefs.remove("name");
    await prefs.remove("profile");

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Loginpage()),
      (route) => false,
    );
  }
}

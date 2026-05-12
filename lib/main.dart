import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_skates/COACH/coach_timeline_page.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/pending_screen.dart';
import 'package:my_skates/rejected_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/loginpage.dart';
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/COACH/coach_homepage.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';

import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ✅ Ride tracking provider
import 'package:my_skates/ride/ride_provider.dart';

// 🔑 REQUIRED FOR DEEP LINKS (PRODUCTION)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  // ✅ Professional error screen (no red/yellow)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
              const SizedBox(height: 12),
              const Text(
                "Oops! Something went wrong",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Please try again later.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontFamily: "Poppins",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // ✅ Keeps error log in console (for developer)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ----------------------------------------------------------
  // CHECK LOGIN STATUS (UNCHANGED LOGIC)
  // ----------------------------------------------------------
Future<Widget> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();

  final token = prefs.getString("access");
  final userType = prefs.getString("user_type");

  final int userId =
      prefs.getInt("id") ??
      prefs.getInt("user_id") ??
      0;

  print("User Type from prefs: $userType");
  print("User ID from prefs: $userId");

  if (token != null && token.isNotEmpty) {
    final normalizedUserType = userType?.toLowerCase().trim();

    if (normalizedUserType == "admin") {
      return DashboardPage();
    }

    if (normalizedUserType == "student") {
      return const HomePage();
    }

    if (normalizedUserType == "coach") {
      return await _checkCoachApprovalStatusOnStart(
        userId: userId,
        token: token,
      );
    }
  }

  return Loginpage();
}

  Future<Widget> _checkCoachApprovalStatusOnStart({
  required int userId,
  required String token,
}) async {
  if (userId == 0) {
    return Loginpage();
  }

  try {
    final response = await http.get(
      Uri.parse("$api/api/myskates/coach/approval/$userId/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("APP START COACH APPROVAL STATUS CODE: ${response.statusCode}");
    print("APP START COACH APPROVAL BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      final String approvalStatus =
          decoded["approval_status"]?.toString().toLowerCase().trim() ??
              "pending";

      if (approvalStatus == "approved") {
        return const CoachHomepage();
      }

      if (approvalStatus == "rejected" || approvalStatus == "disapproved") {
        return const CoachApprovalRejectedScreen();
      }

      return CoachApprovalPendingScreen(userId: userId);
    }

    return CoachApprovalPendingScreen(userId: userId);
  } catch (e) {
    print("APP START COACH APPROVAL CHECK ERROR: $e");

    return CoachApprovalPendingScreen(userId: userId);
  }
}

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RideProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        // REQUIRED FOR DEEP LINK NAVIGATION
        navigatorKey: navigatorKey,

        home: _DeepLinkWrapper(
          child: FutureBuilder<Widget>(
            future: checkLoginStatus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  ),
                );
              }

              return snapshot.data ?? Loginpage();
            },
          ),
        ),
      ),
    );
  }
}

// ===================================================================
//  DEEP LINK HANDLER (PRODUCTION SAFE, NO LOGIC CHANGE)
// ===================================================================
class _DeepLinkWrapper extends StatefulWidget {
  final Widget child;
  const _DeepLinkWrapper({required this.child});

  @override
  State<_DeepLinkWrapper> createState() => _DeepLinkWrapperState();
}

class _DeepLinkWrapperState extends State<_DeepLinkWrapper> {
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();

    // Cold start
    _appLinks.getInitialAppLink().then((uri) {
      if (uri != null) _handleLink(uri);
    });

    // App in background / foreground
    _appLinks.uriLinkStream.listen((uri) {
      try {
        _handleLink(uri);
      } catch (e) {
        debugPrint("Deep Link Error: $e");
      }
    });
  }

  void _handleLink(Uri uri) {
    if (uri.pathSegments.length == 2 && uri.pathSegments.first == "feed") {
      final feedId = int.tryParse(uri.pathSegments[1]);
      if (feedId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => CoachTimelinePage(feedId: feedId)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
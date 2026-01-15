import 'package:flutter/material.dart';
import 'package:my_skates/COACH/coach_timeline_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_skates/loginpage.dart';
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/COACH/coach_homepage.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';

import 'package:app_links/app_links.dart';

// 🔑 REQUIRED FOR DEEP LINKS (PRODUCTION)
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

print("User Type from prefs: $userType");
    if (token != null && token.isNotEmpty) {
      if (userType == "admin") {
        return DashboardPage();
      } else if (userType == "coach") {
        return CoachHomepage();
      } else {
        return const HomePage();
      }
    }

    return Loginpage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ REQUIRED FOR DEEP LINK NAVIGATION
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
    );
  }
}

// ===================================================================
// 🔗 DEEP LINK HANDLER (PRODUCTION SAFE, NO LOGIC CHANGE)
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

    // 🔹 Cold start
    _appLinks.getInitialAppLink().then((uri) {
      if (uri != null) _handleLink(uri);
    });

    // 🔹 App in background / foreground
    _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

 void _handleLink(Uri uri) {
  if (uri.pathSegments.length == 2 &&
      uri.pathSegments.first == "feed") {
    final feedId = int.tryParse(uri.pathSegments[1]);
    if (feedId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => CoachTimelinePage(feedId: feedId),
        ),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

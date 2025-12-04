import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/Home_Page.dart';
import 'package:my_skates/loginpage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ----------------------------------------------------------
  // CHECK LOGIN STATUS HERE
  // ----------------------------------------------------------
  Future<Widget> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    final userType = prefs.getString("user_type");

    if (token != null && token.isNotEmpty) {
      if (userType == "admin") {
        return DashboardPage();
      } else {
        return HomePage();
      }
    }

    return Loginpage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ----------------------------------------------------------
      // LOAD SCREEN BASED ON checkLoginStatus()
      // ----------------------------------------------------------
      home: FutureBuilder<Widget>(
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
    );
  }
}

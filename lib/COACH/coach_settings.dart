import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/add_address.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/view_address.dart';
import 'package:my_skates/COACH/add_club.dart';
import 'package:my_skates/COACH/coach_add_events.dart';
import 'package:my_skates/COACH/coach_follow_request.dart';
import 'package:my_skates/COACH/coach_followers_list.dart';
import 'package:my_skates/COACH/coach_following_list.dart';
import 'package:my_skates/COACH/coach_profile.dart';
import 'package:my_skates/COACH/view_clubs.dart';
import 'package:my_skates/coach/add_coach_achievements.dart';
import 'package:my_skates/loginpage.dart';
import 'package:my_skates/STUDENTS/profile_page.dart'; // <-- Navigation Target Example
import 'package:shared_preferences/shared_preferences.dart';

class CoachSettings extends StatefulWidget {
  const CoachSettings({super.key});

  @override
  State<CoachSettings> createState() => _CoachSettingsState();
}

class _CoachSettingsState extends State<CoachSettings> {
  @override
  void initState() {
    super.initState();
  }

  // ADD THIS INSIDE _UserSettingsState

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();

    // Debug check before logout
    print("Token BEFORE logout: ${prefs.getString('token')}");
    print("ID BEFORE logout: ${prefs.getInt('id')}");

    // Remove saved login data
    await prefs.remove('token');
    await prefs.remove('id');

    // Debug check after logout
    print("Token AFTER logout: ${prefs.getString('token')}");
    print("ID AFTER logout: ${prefs.getInt('id')}");

    // Snackbar message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Logout successfully",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );

    // Delay slightly so snackbar is visible before redirect
    await Future.delayed(const Duration(milliseconds: 600));

    // Navigate to Login Page & clear all previous screens
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const Loginpage(),
      ), // <-- your login page
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Dark IG-style background

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings and activity",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Search Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white60),
                    SizedBox(width: 10),
                    Text(
                      "Search",
                      style: TextStyle(color: Colors.white60, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // SECTION: YOUR ACCOUNT
              const Text(
                "Your account",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // Accounts Center → navigate to ProfilePage()
              _menuTile(
                icon: Icons.person_outline,
                text: "Accounts Center",
                subtitle: "Profile Update and more",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CoachProfile()),
                  );
                },
              ),

              const SizedBox(height: 25),

              // SECTION: HOW YOU USE INSTAGRAM
              const Text(
                "How you use MySkates",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),
              _menuTile(icon: Icons.phone, text: "Change Phone Number"),
              _divider(),
              _menuTile(
                icon: Icons.home,
                text: "Add Achievements",
                onTap: () {
                  Navigator.push(
                    context,
                    slideRightToLeftRoute(AddCoachAchievements()),
                  );
                },
              ),
              _divider(),

              _menuTile(
                icon: Icons.home,
                text: "Add Club",
                onTap: () {
                  Navigator.push(context, slideRightToLeftRoute(AddClub()));
                },
              ),
              _divider(),
              _menuTile(
                icon: Icons.home,
                text: "Add address",
                onTap: () {
                  Navigator.push(context, slideRightToLeftRoute(ViewAddress()));
                },
              ),
              _divider(),
              _menuTile(
                icon: Icons.home,
                text: "View Club",
                onTap: () {
                  Navigator.push(context, slideRightToLeftRoute(ViewClubs()));
                },
              ),
              _divider(),
              _menuTile(
                icon: Icons.home,
                text: "Follow Requests",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CoachFollowRequest(),
                    ),
                  );
                },
              ),
              _divider(),

              _menuTile(
                icon: Icons.home,
                text: "Followers",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CoachFollowersList(),
                    ),
                  );
                },
              ),
              _divider(),

              _menuTile(
                icon: Icons.home,
                text: "Following",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CoachFollowingList(),
                    ),
                  );
                },
              ),
              _divider(),

              _menuTile(icon: Icons.show_chart_outlined, text: "Your activity"),
              _divider(),

              _menuTile(
                icon: Icons.notifications_outlined,
                text: "Notifications",
              ),
              _divider(),

              const SizedBox(height: 25),

              // SECTION: WHO CAN SEE YOUR CONTENT
              const Text(
                "Other settings",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _menuTile(
                icon: Icons.lock_outline,
                text: "Logout",
                onTap: logoutUser,
              ),

              _divider(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.black,
            selectedItemColor: const Color(0xFF00AFA5),
            unselectedItemColor: Colors.white70,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            currentIndex: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ''),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: '',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.event), label: ''),
            ],
          ),
        ),
      ),
    );
  }

  // MENU TILE WIDGET WITH NAVIGATION SUPPORT
  Widget _menuTile({
    required IconData icon,
    required String text,
    String? subtitle,
    String? trailingText,
    VoidCallback? onTap, // <-- Added
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap, // <-- Enables tapping
          contentPadding: EdgeInsets.zero,

          leading: Icon(icon, color: Colors.white, size: 26),

          title: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),

          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                )
              : null,

          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Text(
                  trailingText,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white38,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // DIVIDER
  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Divider(color: Colors.grey[800], thickness: 0.6),
    );
  }
}

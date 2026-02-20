import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/add_address.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/view_address.dart';
import 'package:my_skates/COACH/add_club.dart';
import 'package:my_skates/COACH/coach_add_events.dart';
import 'package:my_skates/COACH/coach_change_phone_number.dart';
import 'package:my_skates/COACH/coach_follow_request.dart';
import 'package:my_skates/COACH/coach_followers_list.dart';
import 'package:my_skates/COACH/coach_following_list.dart';
import 'package:my_skates/COACH/coach_notification_page.dart';
import 'package:my_skates/COACH/coach_profile.dart';
import 'package:my_skates/COACH/myorders.dart';
import 'package:my_skates/COACH/view_clubs.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:my_skates/STUDENTS/products.dart';
import 'package:my_skates/STUDENTS/user_connect_coaches.dart';
import 'package:my_skates/coach/add_coach_achievements.dart';
import 'package:my_skates/loginpage.dart';
import 'package:my_skates/STUDENTS/profile_page.dart';
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

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void pushWithSlide(Widget page) {
    Navigator.push(context, slideRightToLeftRoute(page));
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

    // Snackbar message[]
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
      backgroundColor: const Color(0xFF0F0F0F),

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
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.white60),
                    hintText: "Search",
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
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
              if ("Accounts Center".toLowerCase().contains(_searchQuery))
                _menuTile(
                  icon: Icons.person_outline,
                  text: "Accounts Center",
                  subtitle: "Profile Update and more",
                  onTap: () {
                    pushWithSlide(const CoachProfilePage());
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
              if ("Change Phone Number".toLowerCase().contains(_searchQuery))
                _menuTile(
                  icon: Icons.phone_android_outlined,
                  text: "Change Phone Number",
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRightToLeftRoute(ChangePhonePage()),
                    );
                  },
                ),

              _divider(),
              if ("My Orders".toLowerCase().contains(_searchQuery))
                _menuTile(
                  icon: Icons.shopping_bag,
                  text: "My Orders",
                  onTap: () {
                    Navigator.push(context, slideRightToLeftRoute(Myorders()));
                  },
                ),
              _divider(),
              if ("Add Achievements".toLowerCase().contains(_searchQuery))
                _menuTile(
                  icon: Icons.home,
                  text: "Add Achievements",
                  onTap: () {
                    pushWithSlide(AddCoachAchievements());
                  },
                ),
              _divider(),
              if ("Add Club".toLowerCase().contains(_searchQuery))
                _menuTile(
                  icon: Icons.home,
                  text: "Add Club",
                  onTap: () {
                    Navigator.push(context, slideRightToLeftRoute(AddClub()));
                  },
                ),
              _divider(),
              if ("Add address".toLowerCase().contains(_searchQuery))
                _menuTile(
                  icon: Icons.home,
                  text: "Add address",
                  onTap: () {
                    Navigator.push(
                      context,
                      slideRightToLeftRoute(ViewAddress()),
                    );
                  },
                ),
              _divider(),
              if ("View Club".toLowerCase().contains(_searchQuery))
                _menuTile(
                  icon: Icons.home,
                  text: "View Club",
                  onTap: () {
                    Navigator.push(context, slideRightToLeftRoute(ViewClubs()));
                  },
                ),
              _divider(),
              if ("Follow Requests".toLowerCase().contains(_searchQuery))
                _menuTile(
                  icon: Icons.home,
                  text: "Follow Requests",
                  onTap: () {
                    pushWithSlide(const CoachFollowRequest());
                  },
                ),
              _divider(),

              if ("Followers".toLowerCase().contains(_searchQuery))
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
                    pushWithSlide(CoachFollowersList());
                  },
                ),
              _divider(),
              if ("Following".toLowerCase().contains(_searchQuery))
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

                    pushWithSlide(CoachFollowingList());
                  },
                ),
              _divider(),

              if ("Your activity".toLowerCase().contains(_searchQuery))
                _menuTile(
                  icon: Icons.show_chart_outlined,
                  text: "Your activity",
                ),
              _divider(),
              if ("Notifications".toLowerCase().contains(_searchQuery))
                _menuTile(
                  icon: Icons.notifications_outlined,
                  text: "Notifications",
                ),
              _divider(),

              const SizedBox(height: 15),
              if ("Other Settings".toLowerCase().contains(_searchQuery))
                // SECTION: WHO CAN SEE YOUR CONTENT
                const Text(
                  "Other settings",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              const SizedBox(height: 8),
              if ("Logout".toLowerCase().contains(_searchQuery))
                _menuTile(
                  icon: Icons.lock_outline,
                  text: "Logout",
                  onTap: logoutUser,
                ),
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
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                  break;
                case 1:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const UserProducts()),
                  );
                  break;
                case 2:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CoachNotificationPage(),
                    ),
                  );
                  break;
                case 3:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserConnectCoaches(),
                    ),
                  );
                  break;
                case 4:
                  break;
              }
            },
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

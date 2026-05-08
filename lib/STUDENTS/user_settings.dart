import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/add_address.dart';
import 'package:my_skates/ADMIN/admin_usedproducts.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/view_address.dart';
import 'package:my_skates/COACH/add_bank_details.dart';
import 'package:my_skates/COACH/bank_details_page.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:my_skates/STUDENTS/add_student_achievements.dart';
import 'package:my_skates/STUDENTS/products.dart';
import 'package:my_skates/STUDENTS/student_change_phone_number.dart';
import 'package:my_skates/STUDENTS/student_order_page.dart';
import 'package:my_skates/STUDENTS/user_chat_support.dart';
import 'package:my_skates/STUDENTS/user_connect_coaches.dart';
import 'package:my_skates/loginpage.dart';
import 'package:my_skates/STUDENTS/profile_page.dart';
import 'package:my_skates/STUDENTS/user_follow_requests.dart';
import 'package:my_skates/STUDENTS/user_followers_list.dart';
import 'package:my_skates/STUDENTS/user_following.dart';
import 'package:my_skates/STUDENTS/user_view_events.dart';
import 'package:my_skates/ride/ride_map_screen.dart';
import 'package:my_skates/ride/user_activities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/bottomnavigation.dart';

class UserSettings extends StatefulWidget {
  const UserSettings({super.key});

  @override
  State<UserSettings> createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  // same vibe as CoachSettings
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = "";

  void pushWithSlide(Widget page) {
    Navigator.push(context, slideRightToLeftRoute(page));
  }

  bool _match(String text) => text.toLowerCase().contains(_searchQuery);

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() {});
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Remove saved login data (keep same logic you had)
    await prefs.remove('token');
    await prefs.remove('id');

    if (!mounted) return;

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

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Loginpage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // ✅ glass appbar like CoachSettings
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings and activity",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF001F1C).withOpacity(0.95),
                    const Color(0xFF001F1C).withOpacity(0.65),
                    Colors.black.withOpacity(0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                color: Colors.black.withOpacity(0.25),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.18),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          // ✅ same gradient bg
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF001F1C), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.white,
            backgroundColor: const Color(0xFF001F1C),
            displacement: 60,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    /// 🔍 GLASS SEARCH (same as coach settings)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
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
                                _searchQuery = value.toLowerCase().trim();
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    /// SECTION: YOUR ACCOUNT
                    // const Text(
                    //   "Your account",
                    //   style: TextStyle(
                    //     color: Colors.white70,
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.w700,
                    //     letterSpacing: 0.5,
                    //   ),
                    // ),
                    // const SizedBox(height: 14),
                    if (_match("Accounts Center"))
                      _menuTile(
                        icon: Icons.person_outline,
                        text: "Accounts Center",
                        subtitle: "Profile Update and more",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(const ProfilePage()),
                          );
                        },
                      ),

                    const SizedBox(height: 15),

                    /// SECTION: HOW YOU USE
                    const Text(
                      "How you use MySkates",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_match("Ride"))
                      _menuTile(
                        icon: Icons.map_outlined,
                        text: "Ride",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(
                              const RideMapScreen(),
                            ), // ✅ same animation + no white
                          );
                        },
                      ),

                    if (_match("Activitiess") || _match("Activities"))
                      _menuTile(
                        icon: Icons.local_activity_outlined,
                        text: "Activitiess",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(const UserActivities()),
                          );
                        },
                      ),

                    if (_match("Change Phone Number"))
                      _menuTile(
                        icon: Icons.phone_android_outlined,
                        text: "Change Phone Number",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(
                              const StudentChangePhoneNumber(),
                            ),
                          );
                        },
                      ),

                    if (_match("Chat Support"))
                      _menuTile(
                        icon: Icons.support_agent_outlined,
                        text: "Chat Support",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(const UserChatSupport()),
                          );
                        },
                      ),

                    if (_match("My Orders"))
                      _menuTile(
                        icon: Icons.shopping_bag,
                        text: "My Orders",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(
                              const Student_order_page(),
                            ), // ✅ same animation + no white
                          );
                        },
                      ),

                      if (_match("Used Product Orders"))
                      _menuTile(
                        icon: Icons.shopping_bag,
                        text: "Used Product Orders",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(
                              const UsedProductOrdersPage(),
                            ), // ✅ same animation + no white
                          );
                        },
                      ),

                    // if (_match("View Events"))
                    //   _menuTile(
                    //     icon: Icons.event_outlined,
                    //     text: "View Events",
                    //     onTap: () {
                    //       Navigator.push(
                    //         context,
                    //         slideRightToLeftRoute(const UserViewEvents()),
                    //       );
                    //     },
                    //   ),
                    if (_match("Add Achievements"))
                      _menuTile(
                        icon: Icons.emoji_events_outlined,
                        text: "Add Achievements",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(
                              const AddstudentAchievements(),
                            ),
                          );
                        },
                      ),
                    if (_match("Add Bank Details"))
                      _menuTile(
                        icon: Icons.account_balance_outlined,
                        text: "Add Bank Details",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(const AddBankDetailsPage()),
                          );
                        },
                      ),
                      if (_match("View Bank Details"))
                      _menuTile(
                        icon: Icons.account_balance_outlined,
                        text: "View Bank Details",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(const BankDetailsPage()),
                          );
                        },
                      ),

                    if (_match("Add Address"))
                      _menuTile(
                        icon: Icons.location_on_outlined,
                        text: "Add Address",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(const AddAddress()),
                          );
                        },
                      ),

                    if (_match("Add Address"))
                      _menuTile(
                        icon: Icons.location_on_outlined,
                        text: "Add Address",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(const ViewAddress()),
                          );
                        },
                      ),

                    if (_match("Follow Requests"))
                      _menuTile(
                        icon: Icons.person_add_alt_1_outlined,
                        text: "Follow Requests",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(const StudentFollowRequest()),
                          );
                        },
                      ),

                    if (_match("Followers"))
                      _menuTile(
                        icon: Icons.people_outline,
                        text: "Followers",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(const UserFollowersList()),
                          );
                        },
                      ),

                    if (_match("Following"))
                      _menuTile(
                        icon: Icons.groups_outlined,
                        text: "Following",
                        onTap: () {
                          Navigator.push(
                            context,
                            slideRightToLeftRoute(const UserFollowing()),
                          );
                        },
                      ),

                    if (_match("Your activity"))
                      _menuTile(
                        icon: Icons.show_chart_outlined,
                        text: "Your activity",
                        onTap: () {
                          // keep as-is (no navigation in your original)
                        },
                      ),

                    // if (_match("Notifications"))
                    //   _menuTile(
                    //     icon: Icons.notifications_outlined,
                    //     text: "Notifications",
                    //     onTap: () {
                    //       // keep as-is (no navigation in your original)
                    //     },
                    //   ),

                    // const SizedBox(height: 18),

                    /// SECTION: OTHER SETTINGS
                    const Text(
                      "Other settings",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_match("Logout"))
                      _menuTile(
                        icon: Icons.logout,
                        text: "Logout",
                        onTap: logoutUser,
                        isDanger: true,
                      ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ✅ keep your bottom nav EXACT navigation, only icon style okay
      // bottomNavigationBar: Container(
      //   decoration: const BoxDecoration(
      //     color: Colors.black,
      //     borderRadius: BorderRadius.only(
      //       topLeft: Radius.circular(30),
      //       topRight: Radius.circular(30),
      //     ),
      //   ),
      //   child: ClipRRect(
      //     borderRadius: const BorderRadius.only(
      //       topLeft: Radius.circular(30),
      //       topRight: Radius.circular(30),
      //     ),
      //     child: BottomNavigationBar(
      //       backgroundColor: Colors.black,
      //       selectedItemColor: const Color(0xFF00AFA5),
      //       unselectedItemColor: Colors.white70,
      //       showSelectedLabels: false,
      //       showUnselectedLabels: false,
      //       type: BottomNavigationBarType.fixed,
      //       currentIndex: 4,
      //       onTap: (index) {
      //         switch (index) {
      //           case 0:
      //             Navigator.pushReplacement(
      //               context,
      //               MaterialPageRoute(builder: (_) => const HomePage()),
      //             );
      //             break;
      //           case 1:
      //             Navigator.pushReplacement(
      //               context,
      //               MaterialPageRoute(builder: (_) => const UserProducts()),
      //             );
      //             break;
      //           case 2:
      //             Navigator.pushReplacement(
      //               context,
      //               MaterialPageRoute(
      //                 builder: (_) => const CoachNotificationPage(),
      //               ),
      //             );
      //             break;
      //           case 3:
      //             Navigator.pushReplacement(
      //               context,
      //               MaterialPageRoute(
      //                 builder: (_) => const UserConnectCoaches(),
      //               ),
      //             );
      //             break;
      //           case 4:
      //             break;
      //         }
      //       },
      //       items: const [
      //         BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ''),
      //         BottomNavigationBarItem(
      //           icon: Icon(Icons.shopping_bag),
      //           label: '',
      //         ),
      //         BottomNavigationBarItem(
      //           icon: Icon(Icons.chat_bubble_rounded),
      //           label: '',
      //         ),
      //         BottomNavigationBarItem(icon: Icon(Icons.group), label: ''),
      //         BottomNavigationBarItem(icon: Icon(Icons.event), label: ''),
      //       ],
      //     ),
      //   ),
      // ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  /// 💎 PREMIUM GLASS TILE (same style as CoachSettings)
  Widget _menuTile({
    required IconData icon,
    required String text,
    String? subtitle,
    VoidCallback? onTap,
    bool isDanger = false,
  }) {
    final Color iconColor = isDanger ? Colors.redAccent : Colors.white;
    final Color textColor = isDanger ? Colors.redAccent : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: ListTile(
              onTap: onTap,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: Icon(icon, color: iconColor, size: 26),
              title: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: subtitle != null
                  ? Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    )
                  : null,
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: isDanger
                    ? Colors.redAccent.withOpacity(0.7)
                    : Colors.white38,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

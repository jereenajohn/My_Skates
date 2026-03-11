import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/add_attributes.dart';
import 'package:my_skates/ADMIN/add_chat_support_questions.dart';
import 'package:my_skates/ADMIN/add_product_banner.dart';
import 'package:my_skates/ADMIN/add_skaters_type.dart';
import 'package:my_skates/ADMIN/add_values.dart';
import 'package:my_skates/ADMIN/admin_change_phone_number.dart';
import 'package:my_skates/loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('id');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Loginpage()),
      (route) => false,
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF001F1D),
            Color(0xFF003A36),
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [

            /// HEADER (same style as dashboard)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [

                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),

                  const SizedBox(width: 6),

                  const Text(
                    "Admin Settings",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ],
              ),
            ),

            /// BODY
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildSearch(),

                    const SizedBox(height: 25),

                    sectionTitle("Product Management"),

                    sectionCard([
                      sectionTile(
                        icon: Icons.tune,
                        title: "Attributes",
                        page: const attributes(),
                      ),
                      sectionTile(
                        icon: Icons.data_object,
                        title: "Values",
                        page: const AddValues(),
                      ),
                      sectionTile(
                        icon: Icons.photo_library,
                        title: "Product Banners",
                        page: const AddproductBanner(),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    sectionTitle("User Settings"),

                    sectionCard([
                      sectionTile(
                        icon: Icons.sports_handball,
                        title: "Skaters Type",
                        page: const AddSkatersType(),
                      ),
                      sectionTile(
                        icon: Icons.phone_android,
                        title: "Change Phone Number",
                        page: const AdminChangePhoneNumber(),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    sectionTitle("Support"),

                    sectionCard([
                      sectionTile(
                        icon: Icons.chat,
                        title: "Chat Support Questions",
                        page: const AddChatSupportQuestions(),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    sectionTitle("System"),

                    sectionCard([
                      logoutTile(),
                    ]),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "Search settings",
          hintStyle: TextStyle(color: Colors.white60),
          icon: Icon(Icons.search, color: Colors.tealAccent),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget sectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }

  Widget sectionTile({
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return ListTile(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF00AFA5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white38,
        size: 16,
      ),
    );
  }

  Widget logoutTile() {
    return ListTile(
      onTap: logoutUser,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.logout, color: Colors.white),
      ),
      title: const Text("Logout", style: TextStyle(color: Colors.white)),
    );
  }
}

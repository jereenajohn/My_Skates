import 'package:flutter/material.dart';
import 'package:my_skates/loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {


  @override

void initState() {
    // TODO: implement initState
    super.initState();
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
              _menuTile(
                icon: Icons.person_outline,
                text: "Accounts Center",
                subtitle: "Password, security, personal details, ad preferences",
              ),

              const SizedBox(height: 25),

              // SECTION: HOW YOU USE INSTAGRAM
              const Text(
                "How you use Instagram",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),
              _menuTile(icon: Icons.bookmark_outline, text: "Saved"),
              _divider(),
              _menuTile(icon: Icons.history, text: "Archive"),
              _divider(),
              _menuTile(icon: Icons.show_chart_outlined, text: "Your activity"),
              _divider(),
              _menuTile(icon: Icons.notifications_outlined, text: "Notifications"),
              _divider(),
              _menuTile(icon: Icons.access_time, text: "Time management"),
              

              const SizedBox(height: 25),

              // SECTION: WHO CAN SEE YOUR CONTENT
              const Text(
                "Who can see your content",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),
              _menuTile(
                icon: Icons.lock_outline,
                text: "Account privacy",
                trailingText: "Private",
              ),
              _divider(),
              _menuTile(icon: Icons.star_outline, text: "Close Friends"),

            ],
          ),
        ),
      ),
    );
  }

  // MENU TILE WIDGET
  Widget _menuTile({
    required IconData icon,
    required String text,
    String? subtitle,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
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

          onTap: onTap,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Text(
                  trailingText,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              const SizedBox(width: 5),
              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
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
      child: Divider(
        color: Colors.grey[800],
        thickness: 0.6,
      ),
    );
  }
}

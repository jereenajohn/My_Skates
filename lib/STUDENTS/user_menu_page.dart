import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_skates/COACH/coach_settings.dart';
import 'package:my_skates/COACH/coach_timeline_page.dart';
import 'package:my_skates/STUDENTS/user_settings.dart';
import 'package:my_skates/STUDENTS/user_timeline_page.dart';
import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserMenuPage extends StatefulWidget {
  const UserMenuPage({super.key});

  @override
  State<UserMenuPage> createState() => _UserMenuPageState();
}

class _UserMenuPageState extends State<UserMenuPage>
    with SingleTickerProviderStateMixin {
  static const Color accentColor = Color.fromARGB(255, 46, 230, 172);

  late final AnimationController _controller;
  Animation<double> _fade = const AlwaysStoppedAnimation(1);
  Animation<Offset> _slide = const AlwaysStoppedAnimation(Offset.zero);
  String studentName = "";
  String studentRole = "";
  String? studentImage;
  bool isLoading = true;
  List<Map<String, dynamic>> students = [];
  bool studentsLoading = true;
  bool studentsNoData = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    fetchcoachDetails();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access');
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt("id");
  }

  Future<void> fetchcoachDetails() async {
    try {
      String? token = await getToken();
      int? userId = await getUserId();

      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse("$api/api/myskates/profile/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("PROFILE API STATUS = ${response.statusCode}");
      print("PROFILE API BODY = ${response.body}");

      final data = jsonDecode(response.body);

      if (data is List) {
        // Find the logged-in user
        final user = data.firstWhere(
          (item) => item["id"] == userId,
          orElse: () => null,
        );

        if (user == null) {
          print("Logged-in user not found in profile list");
          return;
        }

        setState(() {
          final String firstName = (user["first_name"] ?? "").toString().trim();
          final String lastName = (user["last_name"] ?? "").toString().trim();
          final String userName = (user["u_name"] ?? "").toString().trim();

          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            studentName = "$firstName $lastName".trim();
          } else if (userName.isNotEmpty) {
            studentName = userName;
          } else {
            studentName = "Coach";
          }
          studentRole = user["user_type"] ?? "Student";
          studentImage = user["profile"];
          isLoading = false;
        });

        print("Loaded PROFILE for user ID $userId");
      } else {
        print("PROFILE API did not return a list.");
      }
    } catch (e) {
      print("Error fetching student: $e");
    }
  }

  // ───────────────── BUILD ─────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _coachHeader(),
                    const SizedBox(height: 18),
                    _quickActionCard(),
                    const SizedBox(height: 20),
                    _menuGrid(),
                    const SizedBox(height: 24),
                    _reportCard(),
                    const SizedBox(height: 14),
                    _supportCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ───────────────── REPORT CARD ─────────────────
  Widget _reportCard() {
    return _pressableCard(
      child: Row(
        children: const [
          Icon(
            Icons.bar_chart,
            color: Color.fromARGB(186, 46, 230, 172),
            size: 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Reports & Analytics",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          AnimatedSlide(
            offset: const Offset(0.05, 0),
            duration: Duration(milliseconds: 200),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── SUPPORT CARD ─────────────────
  Widget _supportCard() {
    return _pressableCard(
      child: Row(
        children: const [
          Icon(Icons.help_outline, color: accentColor, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Support",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    if (role.isEmpty) return "Certified Skating Coach";
    return role[0].toUpperCase() + role.substring(1);
  }

  // ───────────────── APP BAR ─────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        "",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserSettings()),
            );
          },
        ),
      ],
    );
  }

  // ───────────────── HEADER ─────────────────
  Widget _coachHeader() {
    return _pressableCard(
      onTap: () async {
        int? userId = await getUserId();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserTimelinePage(
              // name: studentName,
              // role: studentRole,
              // image: studentImage,
              // coachId: userId,
            ),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage:
                (studentImage != null &&
                    studentImage!.isNotEmpty &&
                    studentImage != "/media/profile_images/none.jpeg")
                ? NetworkImage("$api$studentImage")
                : const AssetImage("lib/assets/img.jpg") as ImageProvider,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLoading
                    ? "Loading..."
                    : (studentName.isNotEmpty ? studentName : "Coach"),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                studentRole.isNotEmpty
                    ? _formatRole(studentRole)
                    : "Certified Skating Coach",
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────── QUICK ACTION ─────────────────
  Widget _quickActionCard() {
    return _pressableCard(
      child: Row(
        children: const [
          Icon(Icons.event_available, color: accentColor, size: 28),
          SizedBox(width: 12),
          Text(
            "Create Training / Event",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── SPORTY GRID ─────────────────
  Widget _menuGrid() {
    return Column(
      children: [
        _doubleRow(
          _SportCard(
            title: "Athletes",
            subtitle: "Active Skaters",
            icon: Icons.groups,
          ),
          _SportCard(
            title: "Performance",
            subtitle: "Speed & Rankings",
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(height: 14),
        _doubleRow(
          _SportCard(
            title: "Training Plans",
            subtitle: "Schedules & Drills",
            icon: Icons.schedule,
          ),
          _SportCard(
            title: "Events",
            subtitle: "Competitions",
            icon: Icons.event,
          ),
        ),
        const SizedBox(height: 14),
        // _statGrid(),
      ],
    );
  }

  Widget _doubleRow(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }

  // ───────────────── BOTTOM NAV ─────────────────
  Widget _bottomNav() {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: accentColor,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      currentIndex: 4,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Athletes"),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"),
      ],
    );
  }

  // ───────────────── HELPERS ─────────────────
  BoxDecoration _glassBox({double radius = 14}) {
    return BoxDecoration(
      color: Colors.black.withOpacity(0.55),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white12),
    );
  }

  Widget _pressableCard({required Widget child, VoidCallback? onTap}) {
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _glassBox(),
        child: child,
      ),
    );
  }
}

class _ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ScaleOnTap({required this.child, this.onTap});

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ───────────────── SPORT CARD ─────────────────
class _SportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  static const Color accentColor = Color(0xFF2EE6A6);

  const _SportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {},
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.65),
              Colors.black.withOpacity(0.45),
            ],
          ),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: 30),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

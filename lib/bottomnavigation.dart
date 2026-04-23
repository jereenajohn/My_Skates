import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/add_chat_support_questions.dart';
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/ADMIN/coach_product_view.dart';
import 'package:my_skates/COACH/coach_chat_support.dart';
import 'package:my_skates/COACH/coach_event_list.dart';
import 'package:my_skates/COACH/coach_homepage.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:my_skates/STUDENTS/user_connect_coaches.dart';
import 'package:my_skates/STUDENTS/user_view_events.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  String userType = "";

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString("user_type")?.toLowerCase().trim() ?? "";

    if (mounted) {
      setState(() {
        userType = type;
      });
    }
  }

  Future<void> _onTap(BuildContext context, int index) async {
    if (index == widget.currentIndex) return;

    if (widget.onTap != null) {
      widget.onTap!(index);
      return;
    }

    Widget targetPage;

    if (userType == "admin") {
      switch (index) {
        case 0:
          targetPage = const DashboardPage();
          break;
        case 1:
          targetPage = const UserApprovedProducts();
          break;
        case 2:
          targetPage = const AddChatSupportQuestions();
          break;
        case 3:
          targetPage = const UserConnectCoaches();
          break;
        case 4:
          targetPage = const CoachEvents();
          break;
        default:
          targetPage = const DashboardPage();
      }
    } else if (userType == "student") {
      switch (index) {
        case 0:
          targetPage = const HomePage();
          break;
        case 1:
          targetPage = const UserApprovedProducts();
          break;
        case 2:
          targetPage = const CoachChatSupport(from: "student");
          break;
        case 3:
          targetPage = const UserConnectCoaches();
          break;
        case 4:
          targetPage = const CoachEvents();
          break;
        default:
          targetPage = const HomePage();
      }
    } else {
      switch (index) {
        case 0:
          targetPage = const CoachHomepage();
          break;
        case 1:
          targetPage = const UserApprovedProducts();
          break;
        case 2:
          targetPage = const CoachChatSupport(from: "coach");
          break;
        case 3:
          targetPage = const UserConnectCoaches();
          break;
        case 4:
          targetPage = const CoachEvents();
          break;
        default:
          targetPage = const CoachHomepage();
      }
    }

    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (_) => targetPage),
    // );

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => targetPage,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  List<BottomNavigationBarItem> _buildItems() {
    if (userType == "admin") {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_outlined), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.production_quantity_limits), label: ''),
      ];
    } else if (userType == "student") {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: ''),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_outlined),
          label: '',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: ''),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: ''),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_rounded),
          label: '',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: ''),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          currentIndex: widget.currentIndex,
          selectedItemColor: const Color(0xFF00AFA5),
          unselectedItemColor: Colors.white70,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => _onTap(context, i),
          items: _buildItems(),
        ),
      ),
    );
  }
}
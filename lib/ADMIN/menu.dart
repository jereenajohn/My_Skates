import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/add_attributes.dart';
import 'package:my_skates/ADMIN/add_chat_support_questions.dart';
import 'package:my_skates/ADMIN/add_product_banner.dart';
import 'package:my_skates/ADMIN/add_skaters_type.dart';
import 'package:my_skates/ADMIN/add_values.dart';
import 'package:my_skates/ADMIN/admin_change_phone_number.dart';
import 'package:my_skates/ADMIN/admin_orders_page.dart';
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/ADMIN/payable_products.dart';
import 'package:my_skates/COACH/add_club.dart';
import 'package:my_skates/COACH/coach_return_products.dart';
import 'package:my_skates/COACH/product_review_approval_page.dart';
import 'package:my_skates/loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('id');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Loginpage()),
      (route) => false,
    );
  }

  bool matchesSearch(String text) {
    if (_searchQuery.trim().isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery.toLowerCase().trim());
  }

  @override
  Widget build(BuildContext context) {
    final bool showProductManagement =
        matchesSearch("Attributes") ||
        matchesSearch("Return/Refund Requests") ||
        matchesSearch("Values") ||
        matchesSearch("Product Banners") ||
        matchesSearch("Payable Products");

    final bool showUserSettings =
        matchesSearch("Skaters Type") || matchesSearch("Change Phone Number");

    final bool showSupport = matchesSearch("Chat Support Questions");

    final bool showSystem = matchesSearch("Logout");

    final bool showNoResults =
        !showProductManagement &&
        !showUserSettings &&
        !showSupport &&
        !showSystem;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F1D), Color(0xFF003A36), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearch(),
                      const SizedBox(height: 25),

                      if (showProductManagement) ...[
                        sectionTitle("Product Management"),
                        sectionCard([
                          if (matchesSearch("Attributes"))
                            sectionTile(
                              icon: Icons.tune,
                              title: "Attributes",
                              page: const attributes(),
                            ),
                          if (matchesSearch("Return/Refund Requests"))
                            sectionTile(
                              icon: Icons.tune,
                              title: "Return/Refund Requests",
                              page: const ReturnRefundProductsScreen(
                                initialViewType: RefundRequestViewType.orders,
                                showViewDropdown: true,
                                allowStatusUpdate: true,
                              ),
                            ),
                          if (matchesSearch("Payable Products"))
                            sectionTile(
                              icon: Icons.tune,
                              title: "Payable Products",
                              page: const ExpiredReturnPolicyProductsPage(),
                            ),
                          if (matchesSearch("Values"))
                            sectionTile(
                              icon: Icons.data_object,
                              title: "Values",
                              page: const AddValues(),
                            ),
                          if (matchesSearch("Product Banners"))
                            sectionTile(
                              icon: Icons.photo_library,
                              title: "Product Banners",
                              page: const AddproductBanner(),
                            ),
                          if (matchesSearch("Product Review Approval"))
                            sectionTile(
                              icon: Icons.shopping_bag,
                              title: "Product Review Approval",
                              page: const ProductReviewApprovalPage(
                                productId: null,
                                productName: "All Products",
                              ),
                            ),
                        ]),
                        const SizedBox(height: 20),
                      ],

                      if (showUserSettings) ...[
                        sectionTitle("User Settings"),
                        sectionCard([
                          if (matchesSearch("Skaters Type"))
                            sectionTile(
                              icon: Icons.sports_handball,
                              title: "Skaters Type",
                              page: const AddSkatersType(),
                            ),
                          if (matchesSearch("Change Phone Number"))
                            sectionTile(
                              icon: Icons.phone_android,
                              title: "Change Phone Number",
                              page: const AdminChangePhoneNumber(),
                            ),
                        ]),
                        const SizedBox(height: 20),
                      ],

                      if (showSupport) ...[
                        sectionTitle("Support"),
                        sectionCard([
                          if (matchesSearch("Chat Support Questions"))
                            sectionTile(
                              icon: Icons.chat,
                              title: "Chat Support Questions",
                              page: const AddChatSupportQuestions(),
                            ),
                        ]),
                        const SizedBox(height: 20),
                      ],

                      if (showSystem) ...[
                        sectionTitle("System"),
                        sectionCard([
                          if (matchesSearch("Logout")) logoutTile(),
                        ]),
                        const SizedBox(height: 20),
                      ],

                      if (showNoResults)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: Text(
                              "No settings found",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

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
            _searchQuery = value;
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
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white38,
        size: 16,
      ),
    );
  }
}

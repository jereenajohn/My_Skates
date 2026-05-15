import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/add_attributes.dart';
import 'package:my_skates/ADMIN/add_values.dart';
import 'package:my_skates/ADMIN/admin_orders_page.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/view_address.dart';
import 'package:my_skates/COACH/add_bank_details.dart';
import 'package:my_skates/COACH/add_club.dart';
import 'package:my_skates/COACH/add_couch_company.dart';
import 'package:my_skates/COACH/bank_details_page.dart';
import 'package:my_skates/COACH/coach_change_phone_number.dart';
import 'package:my_skates/COACH/coach_chat_support.dart';
import 'package:my_skates/COACH/coach_follow_request.dart';
import 'package:my_skates/COACH/coach_followers_list.dart';
import 'package:my_skates/COACH/coach_following_list.dart';
import 'package:my_skates/COACH/coach_profile_page.dart';
import 'package:my_skates/COACH/coach_return_products.dart';
import 'package:my_skates/COACH/product_review_approval_page.dart';
import 'package:my_skates/COACH/used_product_orders_page.dart';
import 'package:my_skates/COACH/view_clubs.dart';
import 'package:my_skates/COACH/add_coach_achievements.dart';
import 'package:my_skates/loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoachSettings extends StatefulWidget {
  const CoachSettings({super.key});

  @override
  State<CoachSettings> createState() => _CoachSettingsState();
}

class _CoachSettingsState extends State<CoachSettings> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = "";

  void pushWithSlide(Widget page) {
    Navigator.push(context, slideRightToLeftRoute(page));
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {});
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('id');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Logout successfully",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.teal,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 600));

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

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
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
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF001F1C).withOpacity(0.95),
                    const Color(0xFF001F1C).withOpacity(0.60),
                    Colors.black.withOpacity(0.50),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.15),
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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF001A18), Color(0xFF000000)],
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

                    /// 🔍 GLASS SEARCH
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
                                _searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    /// SECTION TITLE
                    const Text(
                      "Your account",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    if ("Accounts Center".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.person_outline,
                        text: "Accounts Center",
                        subtitle: "Profile Update and more",
                        onTap: () => pushWithSlide(const CoachProfilePage()),
                      ),

                    const SizedBox(height: 26),

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

                    if ("Change Phone Number".toLowerCase().contains(
                      _searchQuery,
                    ))
                      _menuTile(
                        icon: Icons.phone_android_outlined,
                        text: "Change Phone Number",
                        onTap: () => pushWithSlide(ChangePhonePage()),
                      ),

                    if ("Chat Support".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.support_agent_outlined,
                        text: "Chat Support",
                        onTap: () =>
                            pushWithSlide(CoachChatSupport(from: "coach")),
                      ),

                    if ("My Orders".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.shopping_bag_outlined,
                        text: "My Orders",
                        onTap: () => pushWithSlide(Admin_order_page()),
                      ),

                    if ("Used product Orders".toLowerCase().contains(
                      _searchQuery,
                    ))
                      _menuTile(
                        icon: Icons.inventory_2_outlined,
                        text: "Used product Orders",
                        onTap: () => pushWithSlide(CoachUsedProductOrdersPage()),
                      ),

                    if ("Product Review Approval".toLowerCase().contains(
                      _searchQuery,
                    ))
                      _menuTile(
                        icon: Icons.approval,
                        text: "Product Review Approval",
                        onTap: () => pushWithSlide(
                          const ProductReviewApprovalPage(
                            productId: null,
                            productName: "All Products",
                          ),
                        ),
                      ),

                    if ("Add Bank Details".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.account_balance_wallet_outlined,
                        text: "Add Bank Details",
                        onTap: () => pushWithSlide(AddBankDetailsPage()),
                      ),

                    if ("View Bank Details".toLowerCase().contains(
                      _searchQuery,
                    ))
                      _menuTile(
                        icon: Icons.account_balance_wallet_outlined,
                        text: "View Bank Details",
                        onTap: () => pushWithSlide(BankDetailsPage()),
                      ),

                    if ("Add Achievements".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.emoji_events_outlined,
                        text: "Add Achievements",
                        onTap: () => pushWithSlide(AddCoachAchievements()),
                      ),

                    if ("Add Club".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.groups_outlined,
                        text: "Add Club",
                        onTap: () => pushWithSlide(AddClub()),
                      ),

                    if ("Add address".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.home_outlined,
                        text: "Add address",
                        onTap: () => pushWithSlide(ViewAddress()),
                      ),
                    if ("Add company".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.business_outlined,
                        text: "Add company",
                        onTap: () => pushWithSlide(AdminCoachCompaniesPage()),
                      ),
                    if ("Return/Refund Products".toLowerCase().contains(
                      _searchQuery,
                    ))
                      _menuTile(
                        icon: Icons.production_quantity_limits_rounded,
                        text: "Return/Refund Products",
                        onTap: () =>
                            pushWithSlide(const ReturnRefundProductsScreen(
  initialViewType: RefundRequestViewType.orders,
  showViewDropdown: true,
  allowStatusUpdate: true,
)),
                      ),

                    if ("Attributes".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.category_outlined,
                        text: "Attributes",
                        onTap: () => pushWithSlide(attributes()),
                      ),

                    if ("Values".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.category_outlined,
                        text: "Values",
                        onTap: () => pushWithSlide(AddValues()),
                      ),

                    if ("View Club".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.groups_outlined,
                        text: "View Club",
                        onTap: () => pushWithSlide(ViewClubs()),
                      ),

                    if ("Follow Requests".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.person_add_alt_1_outlined,
                        text: "Follow Requests",
                        onTap: () => pushWithSlide(const CoachFollowRequest()),
                      ),

                    if ("Followers".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.person_outline,
                        text: "Followers",
                        onTap: () => pushWithSlide(const CoachFollowersList()),
                      ),

                    if ("Following".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.person_pin_outlined,
                        text: "Following",
                        onTap: () => pushWithSlide(const CoachFollowingList()),
                      ),

                    if ("Your activity".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.show_chart_outlined,
                        text: "Your activity",
                      ),

                    if ("Notifications".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.notifications_outlined,
                        text: "Notifications",
                      ),

                    const SizedBox(height: 18),

                    const Text(
                      "Other settings",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if ("Logout".toLowerCase().contains(_searchQuery))
                      _menuTile(
                        icon: Icons.lock_outline,
                        text: "Logout",
                        onTap: logoutUser,
                      ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 💎 PREMIUM GLASS TILE
  Widget _menuTile({
    required IconData icon,
    required String text,
    String? subtitle,
    VoidCallback? onTap,
  }) {
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
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withOpacity(0.35),
              //     blurRadius: 18,
              //     offset: const Offset(0, 8),
              //   ),
              // ],
            ),
            child: ListTile(
              onTap: onTap,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: Icon(icon, color: Colors.white, size: 26),
              title: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white38,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

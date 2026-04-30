import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/CoachApprovalTabs.dart';
import 'package:my_skates/ADMIN/add_attributes.dart';
import 'package:my_skates/ADMIN/add_banner.dart';
import 'package:my_skates/ADMIN/add_category.dart';
import 'package:my_skates/ADMIN/add_chat_support_questions.dart';
import 'package:my_skates/ADMIN/add_country.dart';
import 'package:my_skates/ADMIN/add_coupon.dart';
import 'package:my_skates/ADMIN/add_district.dart';
import 'package:my_skates/ADMIN/add_payment_method.dart';
import 'package:my_skates/ADMIN/add_product.dart';
import 'package:my_skates/ADMIN/add_state.dart';
import 'package:my_skates/ADMIN/admin_notificationpage.dart';
import 'package:my_skates/ADMIN/admin_orders_page.dart';
import 'package:my_skates/ADMIN/approved_products.dart';
import 'package:my_skates/ADMIN/coach_product_view.dart';
import 'package:my_skates/ADMIN/menu.dart';
import 'package:my_skates/ADMIN/platform_fee.dart';
import 'package:my_skates/ADMIN/productapprove_tab.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/COACH/coach_chat_support.dart';
import 'package:my_skates/STUDENTS/user_connect_coaches.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/STUDENTS/profile_page.dart';
import 'package:my_skates/bottomnavigation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:shimmer/shimmer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String studentName = "";
  String studentRole = "";
  String studentUName = "";
  String? studentImage;
  bool isLoading = true;
  bool isRefreshing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Offset _fabOffset = const Offset(20, 520);
  bool _fabMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserApprovedProducts()),
        );
        break;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddChatSupportQuestions()),
        );
        break;

      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Admin_order_page()),
        );
        break;

      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductapproveTab()),
        );
        break;
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);

    try {
      await Future.wait([fetchStudentDetails(), getbanner()]);
    } catch (e) {
      print("Error loading initial data: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    if (!mounted || isRefreshing) return;

    setState(() => isRefreshing = true);

    await Future.wait([fetchStudentDetails(), getbanner()]);

    setState(() => isRefreshing = false);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  Future<void> _navigateFromFab(Widget page) async {
    setState(() => _fabMenuOpen = false);

    await Future.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    await Navigator.push(context, slideRightToLeftRoute(page));
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access');
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idValue = prefs.get('id');
    if (idValue is int) return idValue;
    if (idValue is String) return int.tryParse(idValue);
    return null;
  }

  void pushWithSlide(Widget page) {
    Navigator.push(context, slideRightToLeftRoute(page));
  }

  List<Map<String, dynamic>> banner = [];

  Future<void> getbanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var response = await http.get(
        Uri.parse('$api/api/myskates/banner/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<Map<String, dynamic>> statelist = [];

        for (var productData in parsed) {
          String imageUrl = "$api${productData['image']}";
          statelist.add({
            'id': productData['id'],
            'title': productData['title'],
            'image': imageUrl,
          });
        }
        setState(() {
          banner = statelist;
        });
      }
    } catch (error) {
      print("Error fetching banner: $error");
    }
  }

  Future<void> fetchStudentDetails() async {
    final prefs = await SharedPreferences.getInstance();

    print("Stored u_name: ${prefs.getString("u_name")}");
    print("Stored name: ${prefs.getString("name")}");

    String name = prefs.getString("name") ?? "User";
    String role = prefs.getString("user_type") ?? "user_type";
    String uName = prefs.getString("u_name") ?? "";
    String? image = prefs.getString("profile");

    if (uName.isEmpty) {
      print("🔄 u_name not in prefs, fetching from API...");

      final userData = await fetchDetailsSection();

      if (userData != null) {
        print(" Got user data from API: $userData");

        uName = userData['u_name'] ?? '';
        name = userData['first_name'] ?? userData['name'] ?? name;
        role = userData['user_type'] ?? role;
        image = userData['profile'] ?? image;

        if (uName.isNotEmpty) {
          await prefs.setString('u_name', uName);
          print(" Saved u_name to prefs: $uName");
        }
        if (name.isNotEmpty) {
          await prefs.setString('name', name);
        }
        if (role.isNotEmpty) {
          await prefs.setString('user_type', role);
        }
        if (image != null && image.isNotEmpty) {
          await prefs.setString('profile', image);
        }
      } else {
        print("Failed to fetch user data from API");
      }
    } else {
      print(" Using u_name from prefs: $uName");
    }

    setState(() {
      studentName = name;
      studentRole = role;
      studentUName = uName;
      studentImage = image;
    });

    print(' Final display - Name: $name, u_name: "$uName"');
  }

  Future<Map<String, dynamic>?> fetchDetailsSection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        debugPrint("ACCESS TOKEN IS NULL");
        return null;
      }

      final res = await http.get(
        Uri.parse("$api/api/myskates/profile/user/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } else {
        debugPrint("API ERROR: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("FETCH PERSON DETAILS ERROR: $e");
    }

    return null;
  }

  Widget _movableFabMenu() {
    final size = MediaQuery.of(context).size;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    const double fabSize = 56;
    const double sideMargin = 12;
    const double topLimit = 90;
    const double bottomNavHeight = 90;

    const double menuWidth = 210;
    const double menuHeight = 270;

    final double maxX = size.width - fabSize - sideMargin;
    final double maxY = size.height - fabSize - bottomNavHeight - bottomSafe;

    final double dx = _fabOffset.dx.clamp(sideMargin, maxX);
    final double dy = _fabOffset.dy.clamp(topLimit, maxY);

    final bool openToLeft = dx > size.width / 2;
    final bool openUp = dy > size.height / 2;

    final double menuLeft = openToLeft
        ? (dx + fabSize - menuWidth).clamp(
            sideMargin,
            size.width - menuWidth - sideMargin,
          )
        : dx.clamp(sideMargin, size.width - menuWidth - sideMargin);

    final double menuTop = openUp
        ? (dy - menuHeight - 12).clamp(
            topLimit,
            size.height - menuHeight - bottomNavHeight,
          )
        : (dy + fabSize + 12).clamp(
            topLimit,
            size.height - menuHeight - bottomNavHeight,
          );

    return Stack(
      children: [
        if (_fabMenuOpen)
          Positioned(
            left: menuLeft,
            top: menuTop,
            child: SizedBox(width: menuWidth, child: _fabMenuItems(openToLeft)),
          ),

        Positioned(
          left: dx,
          top: dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                final next = _fabOffset + details.delta;

                _fabOffset = Offset(
                  next.dx.clamp(sideMargin, maxX),
                  next.dy.clamp(topLimit, maxY),
                );
              });
            },
            child: FloatingActionButton(
              heroTag: "movableFabAdmin",
              backgroundColor: const Color(0xFF00AFA5),
              onPressed: () {
                setState(() {
                  _fabMenuOpen = !_fabMenuOpen;

                  _fabOffset = Offset(
                    _fabOffset.dx.clamp(sideMargin, maxX),
                    _fabOffset.dy.clamp(topLimit, maxY),
                  );
                });
              },
              child: Icon(
                _fabMenuOpen ? Icons.close : Icons.skateboarding,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fabMenuItems(bool openToLeft) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Column(
        key: const ValueKey("openMenu"),
        crossAxisAlignment: openToLeft
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _fabMiniItem(
            icon: Icons.person,
            label: "Profile",
            openToLeft: openToLeft,
            onTap: () => _navigateFromFab(const ProfilePage()),
          ),
          const SizedBox(height: 10),

          _fabMiniItem(
            icon: Icons.notifications_none,
            label: "Notifications",
            openToLeft: openToLeft,
            onTap: () => _navigateFromFab(AdminNotificationpage()),
          ),
          const SizedBox(height: 10),

          _fabMiniItem(
            icon: Icons.shopping_bag,
            label: "Orders",
            openToLeft: openToLeft,
            onTap: () => _navigateFromFab(Admin_order_page()),
          ),
          const SizedBox(height: 10),

          _fabMiniItem(
            icon: Icons.check_circle_outline,
            label: "Approve Products",
            openToLeft: openToLeft,
            onTap: () => _navigateFromFab(const ProductapproveTab()),
          ),
          const SizedBox(height: 10),

          _fabMiniItem(
            icon: Icons.support_agent,
            label: "Support",
            openToLeft: openToLeft,
            onTap: () => _navigateFromFab(const AddChatSupportQuestions()),
          ),
        ],
      ),
    );
  }

  Widget _fabMiniItem({
    required IconData icon,
    required String label,
    required bool openToLeft,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 190),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: openToLeft
                ? [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.tealAccent, size: 18),
                  ]
                : [
                    Icon(icon, color: Colors.tealAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  // SHIMMER METHODS
  Widget _buildBannerShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF001A18),
      highlightColor: const Color(0xFF00AFA5).withOpacity(0.25),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildClubShimmer() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFF001A18),
            highlightColor: const Color(0xFF00AFA5).withOpacity(0.25),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF001A18),
      highlightColor: const Color(0xFF00AFA5).withOpacity(0.25),
      child: Container(
        height: 200,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget buildAdminQuickActions() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        adminCard(
          icon: Icons.public,
          title: "Country",
          onTap: () {
            pushWithSlide(const AddCountry());
          },
        ),

        adminCard(
          icon: Icons.map,
          title: "State",
          onTap: () {
            pushWithSlide(const state());
          },
        ),

        adminCard(
          icon: Icons.location_city,
          title: "District",
          onTap: () {
            pushWithSlide(const district());
          },
        ),

        adminCard(
          icon: Icons.category,
          title: "Category",
          onTap: () {
            pushWithSlide(const AddCategory());
          },
        ),

        adminCard(
          icon: Icons.tune,
          title: "Attributes",
          onTap: () {
            pushWithSlide(const attributes());
          },
        ),

        adminCard(
          icon: Icons.confirmation_number,
          title: "Coupons",
          onTap: () {
            pushWithSlide(const AddCoupon());
          },
        ),

        adminCard(
          icon: Icons.photo,
          title: "Banners",
          onTap: () {
            pushWithSlide(const AddBanner());
          },
        ),

        adminCard(
          icon: Icons.chat,
          title: "Support",
          onTap: () {
            pushWithSlide(const AddChatSupportQuestions());
          },
        ),

        adminCard(
          icon: Icons.chat,
          title: "Fee\nManagement",
          onTap: () {
            pushWithSlide(const AdminPlatformFeePage());
          },
        ),
        adminCard(
          icon: Icons.chat,
          title: "Payment\nMethod",
          onTap: () {
            pushWithSlide(const AdminPaymentMethodsPage());
          },
        ),
      ],
    );
  }

  Widget adminCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00AFA5).withOpacity(0.25),
              const Color(0xFF00AFA5).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00AFA5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventWithImagesShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF001A18),
      highlightColor: const Color(0xFF00AFA5).withOpacity(0.25),
      child: Container(
        height: 300,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildCoachShimmer() {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFF001A18),
            highlightColor: const Color(0xFF00AFA5).withOpacity(0.25),
            child: Container(
              width: 165,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF001F1D), Color(0xFF003A36), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: Colors.tealAccent,
                backgroundColor: Colors.black,
                strokeWidth: 3.0,
                displacement: 40.0,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PROFILE ROW
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              pushWithSlide(const ProfilePage());
                            },
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  studentImage != null &&
                                      studentImage!.isNotEmpty
                                  ? NetworkImage("$api$studentImage")
                                  : const AssetImage("lib/assets/img.jpg")
                                        as ImageProvider,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              Text(
                                studentUName.isNotEmpty
                                    ? studentUName
                                    : studentRole,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  pushWithSlide(AdminNotificationpage());
                                },
                                icon: Icon(
                                  Icons.notifications_none,
                                  color: Colors.tealAccent,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  pushWithSlide(MenuPage());
                                },
                                icon: const Icon(
                                  Icons.menu,
                                  color: Colors.tealAccent,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () {
                          pushWithSlide(const AddBanner());
                        },
                        child: Column(
                          children: [
                            banner.isEmpty
                                ? _buildBannerShimmer()
                                : Container(
                                    height: 160,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: FlutterCarousel(
                                        options: CarouselOptions(
                                          height: 160,
                                          autoPlay: true,
                                          autoPlayInterval: const Duration(
                                            seconds: 3,
                                          ),
                                          viewportFraction: 1,
                                          showIndicator: true,
                                          slideIndicator:
                                              const CircularSlideIndicator(),
                                        ),
                                        items: banner.map((item) {
                                          return Stack(
                                            children: [
                                              Positioned.fill(
                                                child: Image.network(
                                                  item["image"] ?? "",
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (
                                                        context,
                                                        child,
                                                        progress,
                                                      ) {
                                                        if (progress == null)
                                                          return child;
                                                        return Container(
                                                          color: Colors
                                                              .grey
                                                              .shade900,
                                                          alignment:
                                                              Alignment.center,
                                                          child:
                                                              const CircularProgressIndicator(),
                                                        );
                                                      },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        color: Colors.black,
                                                        alignment:
                                                            Alignment.center,
                                                        child: const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.white54,
                                                          size: 40,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                              Positioned.fill(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter,
                                                      colors: [
                                                        Colors.transparent,
                                                        Colors.black
                                                            .withOpacity(0.6),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        "Weeee offer training and an e-commerce platform\nthat connects students and coaches.",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),

                      const SizedBox(height: 25),

                      // BUTTONS
                      buildButton("Approve Coaches"),
                      buildButton("Add Products"),
                      buildButton("Approve Products"),
                      buildButton("Orders"),
                      buildButton("Buy and Sell products"),

                      const SizedBox(height: 20),

                      // const Text(
                      //   "Admin Controls",
                      //   style: TextStyle(
                      //     color: Colors.white,
                      //     fontSize: 18,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                      const SizedBox(height: 15),

                      buildAdminQuickActions(),

                      // RECOMMENDED CLUBS TITLE
                      // const Text(
                      //   "Recommended Clubs near you",
                      //   style: TextStyle(
                      //     color: Colors.white,
                      //     fontSize: 18,
                      //     fontWeight: FontWeight.bold,
                      //     letterSpacing: 0.5,
                      //   ),
                      // ),

                      // const SizedBox(height: 25),

                      // // CLUB SECTION WITH SHIMMER
                      // _buildClubShimmer(),

                      // // UPCOMING EVENTS
                      // const SizedBox(height: 25),
                      // const Text(
                      //   "Inspired to push your limits every day.",
                      //   style: TextStyle(color: Colors.white, fontSize: 14),
                      // ),

                      // const SizedBox(height: 15),

                      // // EVENT CARD 1 WITH SHIMMER
                      // _buildEventShimmer(),

                      // const SizedBox(height: 12),

                      // // EVENT CARD 2 (with images) WITH SHIMMER
                      // _buildEventWithImagesShimmer(),

                      // // SUGGESTED COACHES
                      // const SizedBox(height: 25),
                      // const Text(
                      //   "Suggested Coaches",
                      //   style: TextStyle(
                      //     color: Colors.white,
                      //     fontSize: 18,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),

                      // const SizedBox(height: 15),

                      // // COACH SECTION WITH SHIMMER
                      // _buildCoachShimmer(),

                      // const SizedBox(height: 20),

                      // // EVENT CARD 1 WITH SHIMMER
                      // _buildEventShimmer(),

                      // const SizedBox(height: 12),

                      // // EVENT CARD 2 (with images) WITH SHIMMER
                      // _buildEventWithImagesShimmer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _movableFabMenu(),
        ],
      ),

      // BOTTOM NAV
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: _onBottomNavTap,
      ),
    );
  }

  // BUTTON WIDGET
  Widget buildButton(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00AFA5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: () {
          if (title == "Approve Coaches") {
            pushWithSlide(const CoachApprovalTabs());
          }
          if (title == "Buy and Sell products") {
            pushWithSlide(const UserApprovedProducts());
          }
          if (title == "Approve Products") {
            pushWithSlide(const ProductapproveTab());
          }
          if (title == "Add Products") {
            pushWithSlide(const AddProduct());
          }
          if (title == "Orders") {
            pushWithSlide(const Admin_order_page());
          }
        },
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  // CLUB CARD (NO EXPANDED)
  Widget buildClubCard(String title, String image) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Image.asset(image, height: 60),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("Follow", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// EVENT CARD 1
Widget buildEventCard({
  required String clubName,
  required String date,
  required String location,
  required String title,
  required String timeLeft,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 10,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TOP ROW (Club details)
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: const AssetImage("lib/assets/images.png"),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clubName,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  location,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // TITLE
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        // TIME
        Text(
          timeLeft,
          style: const TextStyle(color: Colors.tealAccent, fontSize: 13),
        ),

        const SizedBox(height: 6),

        const SizedBox(height: 10),

        // LIKE + FAVORITE BUTTONS (BOTTOM RIGHT)
        Row(
          children: [
            Text(location, style: TextStyle(color: Colors.white70)),
            SizedBox(width: 120),
            Icon(Icons.thumb_up_alt_outlined, color: Colors.tealAccent),
          ],
        ),
      ],
    ),
  );
}

// EVENT CARD 2 WITH IMAGES
Widget buildEventCardWithImages({
  required String clubName,
  required String date,
  required String location,
  required String title,
  required String image1,
  required String image2,
  required String description,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: const AssetImage("lib/assets/imagess.png"),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clubName,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  location,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        // IMAGES ROW
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(image1, height: 110, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(image2, height: 110, fit: BoxFit.cover),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info, color: Colors.amberAccent, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // LIKE + FAV BUTTONS BOTTOM RIGHT
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.thumb_up_alt_outlined,
              color: Colors.tealAccent,
              size: 22,
            ),
            const SizedBox(width: 14),
          ],
        ),
      ],
    ),
  );
}

// COACH CARD (HORIZONTAL)
Widget buildCoachCard({
  required String name,
  required String subtitle,
  required String city,
  required String image,
}) {
  return Container(
    width: 165,
    margin: const EdgeInsets.only(right: 6),
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: 185,
          padding: const EdgeInsets.only(
            top: 60,
            left: 12,
            right: 12,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),

              Text(
                city,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AFA5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Connect",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -18,
          child: CircleAvatar(radius: 36, backgroundImage: AssetImage(image)),
        ),
      ],
    ),
  );
}

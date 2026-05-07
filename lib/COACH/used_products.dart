import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/COACH/add_used_product_page.dart';
import 'package:my_skates/COACH/coach_homepage.dart';
import 'package:my_skates/COACH/my_used_products_page.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/bottomnavigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class UsedProducts extends StatefulWidget {
  const UsedProducts({super.key});

  @override
  State<UsedProducts> createState() => _UsedProductsState();
}

class _UsedProductsState extends State<UsedProducts> {
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> usedProducts = [];
  List<Map<String, dynamic>> allUsedProducts = [];
  List<Map<String, dynamic>> banner = [];

  bool pageLoading = true;
  bool productsLoading = false;
  bool _animatePage = false;
  String _userType = "";

  @override
  void initState() {
    super.initState();
    _getUserType();
    loadInitialData();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _animatePage = true;
        });
      }
    });
  }

  Future<void> _getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = (prefs.getString("user_type") ?? "").toLowerCase().trim();
    });
  }

  Future<void> loadInitialData() async {
    await Future.wait([getbanner(), fetchUsedProducts()]);

    setState(() {
      pageLoading = false;
    });
  }

  Future<void> refreshAllData() async {
    await getbanner();
    await fetchUsedProducts();
  }

  Future<void> getbanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse('$api/api/myskates/product/banner/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> statelist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        for (var item in parsed) {
          statelist.add({
            'id': item['id'],
            'title': item['title'],
            'image': "$api${item['image']}",
          });
        }

        setState(() {
          banner = statelist;
        });
      }
    } catch (e) {
      print("Banner error: $e");
    }
  }

  Future<void> fetchUsedProducts() async {
    setState(() {
      productsLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse("$api/api/myskates/used/products/view/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("USED PRODUCTS STATUS: ${response.statusCode}");
      print("USED PRODUCTS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded["data"] ?? [];

        final productsList = data.map<Map<String, dynamic>>((item) {
          final price = double.tryParse(item["price"]?.toString() ?? "0") ?? 0;
          final discount =
              double.tryParse(item["discount"]?.toString() ?? "0") ?? 0;
                   final List images = item["images"] ?? [];

        String productImage = "";

        if (images.isNotEmpty) {
          productImage = images.first["image"]?.toString() ?? "";
        }

          

        return {
          "id": item["id"],
          "title": item["title"] ?? "",
          "category_name": item["category_name"] ?? "",
          "description": item["description"] ?? "",
          "image": productImage,
          "images": images,
          "price": price,
          "discount": discount,
          "final_price": discount > 0 ? price - discount : price,
          "status": (item["status"] ?? "").toString().toLowerCase(),
          "created_at": item["created_at"] ?? "",
          "return_policy_days": item["return_policy_days"] ?? 0,
          "shipment_charge": item["shipment_charge"] ?? "0.00",
          "user_name": item["user_name"] ?? "",
        };
        }).toList();

        setState(() {
          usedProducts = productsList;
          allUsedProducts = List.from(productsList);
        });
      } else {
        setState(() {
          usedProducts = [];
          allUsedProducts = [];
        });
      }
    } catch (e) {
      print("Used products error: $e");
      setState(() {
        usedProducts = [];
        allUsedProducts = [];
      });
    }

    setState(() {
      productsLoading = false;
    });
  }

  void _searchProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        usedProducts = List.from(allUsedProducts);
      });
      return;
    }

    final results = allUsedProducts.where((product) {
      final title = product['title'].toString().toLowerCase();
      final category = product['category_name'].toString().toLowerCase();
      final desc = product['description'].toString().toLowerCase();
      final status = product['status'].toString().toLowerCase();

      return title.contains(query.toLowerCase()) ||
          category.contains(query.toLowerCase()) ||
          desc.contains(query.toLowerCase()) ||
          status.contains(query.toLowerCase());
    }).toList();

    setState(() {
      usedProducts = results;
    });
  }

  Future<void> _goToAddUsedProduct() async {
    final result = await Navigator.push(
      context,
      slideRightToLeftRoute(const AddUsedProductPage()),
    );

    if (result == true) {
      await fetchUsedProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final prefs = await SharedPreferences.getInstance();
        final userType =
            prefs.getString("user_type")?.toLowerCase().trim() ?? "";

        Widget dashboardPage;
        if (userType == "coach") {
          dashboardPage = const CoachHomepage();
        } else if (userType == "student") {
          dashboardPage = const HomePage();
        } else {
          dashboardPage = const DashboardPage();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => dashboardPage),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        // floatingActionButton: _userType != "student"
        //     ? FloatingActionButton(
        //         backgroundColor: Colors.tealAccent,
        //         onPressed: _goToAddUsedProduct,
        //         child: const Icon(Icons.add, color: Colors.black),
        //       )
        //     : null,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF00312D), Color(0xFF000000)],
              stops: [0.0, 0.35],
            ),
          ),
          child: SafeArea(
            child: pageLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  )
                : RefreshIndicator(
                    onRefresh: refreshAllData,
                    color: Colors.tealAccent,
                    backgroundColor: Colors.black,
                    displacement: 40,
                    edgeOffset: 10,
                    strokeWidth: 3,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 600),
                        opacity: _animatePage ? 1 : 0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 600),
                          offset: _animatePage
                              ? Offset.zero
                              : const Offset(0, 0.05),
                          curve: Curves.easeOutCubic,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      height: 50,
                                      width: 68,
                                      child: Image.asset(
                                        "lib/assets/myskates.png",
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          icon: const Icon(
                                            Icons.arrow_back_ios_new,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.25),
                                          border: Border.all(
                                            color: Colors.white24,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: searchController,
                                          onChanged: _searchProducts,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          decoration: const InputDecoration(
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color: Colors.white54,
                                              size: 20,
                                            ),
                                            hintText: "Search used products",
                                            hintStyle: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 10,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: GestureDetector(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            slideRightToLeftRoute(
                                              const MyUsedProductsPage(),
                                            ),
                                          );
                                          await fetchUsedProducts();
                                        },
                                        child: Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.25,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            border: Border.all(
                                              color: Colors.white24,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "Products",
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w400,
                                                letterSpacing: 0.2,
                                                color: Colors.white,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 15),

                                banner.isEmpty
                                    ? _bannerSkeleton()
                                    : Container(
                                        height: 160,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.25,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
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
                                                      errorBuilder:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => Container(
                                                            color: Colors.black,
                                                            alignment: Alignment
                                                                .center,
                                                            child: const Icon(
                                                              Icons
                                                                  .broken_image,
                                                              color: Colors
                                                                  .white54,
                                                              size: 40,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                  Positioned.fill(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                            Colors.transparent,
                                                            Colors.black
                                                                .withOpacity(
                                                                  0.6,
                                                                ),
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

                                const SizedBox(height: 15),

                                const Text(
                                  "Used Products",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                if (productsLoading)
                                  _productGridSkeleton()
                                else if (usedProducts.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 40,
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: const [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            color: Colors.white54,
                                            size: 60,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            "No used products found",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: usedProducts.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisExtent: 285,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                    itemBuilder: (context, index) {
                                      final p = usedProducts[index];

                                      return TweenAnimationBuilder<double>(
                                        duration: Duration(
                                          milliseconds: 400 + (index * 80),
                                        ),
                                        tween: Tween<double>(begin: 0, end: 1),
                                        curve: Curves.easeOut,
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                30 * (1 - value),
                                              ),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: _productCard(p),
                                      );
                                    },
                                  ),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    final bool isSold = p['status'] == "sold";
    final bool hasDiscount = (p['discount'] ?? 0) > 0;

    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 400),
      transitionType: ContainerTransitionType.fadeThrough,
      openElevation: 0,
      closedElevation: 0,
      closedColor: Colors.transparent,
      openColor: Colors.transparent,
      middleColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      openBuilder: (context, _) => UsedProductDetailPage(product: p),
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: openContainer,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: Image.network(
                          p['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Colors.white10,
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.15),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSold
                              ? Colors.redAccent.withOpacity(0.85)
                              : Colors.tealAccent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSold ? "Sold" : "Active",
                          style: TextStyle(
                            color: isSold ? Colors.white : Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      p['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        height: 1.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 3),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    p['category_name'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 11.5,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    p['description']?.toString().isNotEmpty == true
                        ? p['description']
                        : "No description",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: hasDiscount
                      ? Row(
                          children: [
                            Text(
                              "₹${p['price'].toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11.5,
                                decoration: TextDecoration.lineThrough,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "₹${p['final_price'].toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "₹${p['price'].toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _productGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 285,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF001A18),
          highlightColor: const Color(0xFF00AFA5).withOpacity(0.25),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    height: 14,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bannerSkeleton() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class UsedProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;
  const UsedProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final bool isSold = product["status"] == "sold";
    final bool hasDiscount = (product['discount'] ?? 0) > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share functionality can be added here
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              // Favorite functionality can be added here
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      product["image"],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade900,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSold
                            ? Colors.redAccent.withOpacity(0.9)
                            : Colors.tealAccent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isSold ? "Sold Out" : "Available",
                        style: TextStyle(
                          color: isSold ? Colors.white : Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Details Section
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.tealAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        product["category_name"] ?? "",
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Product Title
                    Text(
                      product["title"] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Price Section
                    Row(
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            "₹${product['price'].toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 18,
                              decoration: TextDecoration.lineThrough,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          "₹${product['final_price'].toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "-₹${product['discount'].toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Description Section
                    const Text(
                      "Description",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      product["description"]?.toString().isNotEmpty == true
                          ? product["description"]
                          : "No description available for this product.",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSold ? null : () {
                              // Contact seller functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Contact seller functionality"),
                                  backgroundColor: Colors.tealAccent,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSold
                                  ? Colors.grey.shade700
                                  : Colors.tealAccent,
                              foregroundColor: isSold ? Colors.white : Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isSold ? "Sold Out" : "Contact Seller",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // Message functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Message seller functionality"),
                                  backgroundColor: Colors.tealAccent,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.message,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Additional Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.tealAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Listed on ${product["created_at"]?.toString().isNotEmpty == true ? product["created_at"] : "N/A"}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
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
    );
  }
}

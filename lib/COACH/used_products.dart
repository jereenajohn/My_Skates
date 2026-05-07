import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/add_address.dart';
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
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:my_skates/ADMIN/order_failure_page.dart';
import 'package:my_skates/ADMIN/order_success_page.dart';

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

class UsedProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const UsedProductDetailPage({super.key, required this.product});

  @override
  State<UsedProductDetailPage> createState() => _UsedProductDetailPageState();
}

class _UsedProductDetailPageState extends State<UsedProductDetailPage> {
  Map<String, dynamic>? productDetail;

  bool detailLoading = true;
  bool detailError = false;

  final PageController _imagePageController = PageController();
  int selectedImageIndex = 0;
  bool productOverviewExpanded = false;

List<Map<String, dynamic>> addresses = [];
bool addressLoading = false;
bool checkoutLoading = false;
bool priceDetailsLoading = false;
Map<String, dynamic>? usedProductPriceDetails;

Map<String, dynamic>? selectedCheckoutAddress;
String selectedPaymentMethod = "COD";

final TextEditingController checkoutNoteController = TextEditingController();

final List<String> paymentMethods = [
  "COD",
  "ONLINE",
];

late Razorpay _razorpay;
String? usedRazorpayOrderId;
String? usedRazorpayPaymentId;
String? usedRazorpaySignature;
String? usedRazorpayAmount;
String? usedBackendOrderId;
String? usedOrderNo;

  @override
  void initState() {
    super.initState();
    fetchUsedProductDetail();

    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handleUsedProductPaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handleUsedProductPaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleUsedProductExternalWallet,
    );
  }

@override
void dispose() {
  _imagePageController.dispose();
  checkoutNoteController.dispose();
  _razorpay.clear();
  super.dispose();
}

  Future<void> fetchUsedProductDetail() async {
    setState(() {
      detailLoading = true;
      detailError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final productId = widget.product["id"];

      final response = await http.get(
        Uri.parse("$api/api/myskates/used/products/detail/view/$productId/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("USED PRODUCT DETAIL STATUS: ${response.statusCode}");
      print("USED PRODUCT DETAIL BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["success"] == true && decoded["data"] != null) {
          final data = decoded["data"];

          final price =
              double.tryParse(data["price"]?.toString() ?? "0") ?? 0.0;
          final discount =
              double.tryParse(data["discount"]?.toString() ?? "0") ?? 0.0;

          final List imagesData = data["images"] ?? [];

          final List<String> images = imagesData
              .map<String>((item) => item["image"]?.toString() ?? "")
              .where((image) => image.trim().isNotEmpty)
              .toList();

          setState(() {
            productDetail = {
              "id": data["id"],
              "user_name": data["user_name"] ?? "",
              "images": images,
              "payment_methods": data["payment_methods"] ?? [],
              "title": data["title"] ?? "",
              "description": data["description"] ?? "",
              "price": price,
              "discount": discount,
              "final_price": discount > 0 ? price - discount : price,
              "status": (data["status"] ?? "").toString().toLowerCase(),
              "return_policy_days": data["return_policy_days"],
              "shipment_charge": data["shipment_charge"] ?? "0.00",
              "created_at": data["created_at"] ?? "",
              "updated_at": data["updated_at"] ?? "",
              "category": data["category"],
              "user": data["user"],
              "attribute": data["attribute"],
              "attribute_value": data["attribute_value"],
            };

            detailLoading = false;
            detailError = false;
          });
        } else {
          setState(() {
            detailLoading = false;
            detailError = true;
          });
        }
      } else {
        setState(() {
          detailLoading = false;
          detailError = true;
        });
      }
    } catch (e) {
      print("Used product detail error: $e");

      setState(() {
        detailLoading = false;
        detailError = true;
      });
    }
  }


  String _readAddressValue(Map<String, dynamic> address, List<String> keys) {
  for (final key in keys) {
    final value = address[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return "";
}

String _formatAddress(Map<String, dynamic> address) {
  final line1 = _readAddressValue(address, ["address_line1", "address", "line1"]);
  final line2 = _readAddressValue(address, ["address_line2", "landmark", "line2"]);
  final city = _readAddressValue(address, ["city"]);
  final state = _readAddressValue(address, ["state"]);
  final pincode = _readAddressValue(address, ["pincode", "pin_code", "zipcode"]);
  final country = _readAddressValue(address, ["country"]);

  final parts = [
    line1,
    line2,
    city,
    state,
    pincode,
    country,
  ].where((item) => item.trim().isNotEmpty).toList();

  return parts.join(", ");
}

Future<void> fetchAddresses() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  if (!mounted) return;

  setState(() {
    addressLoading = true;
  });

  try {
    final res = await http.get(
      Uri.parse("$api/api/myskates/user/addresses/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("Address fetch status: ${res.statusCode}");
    print("Address fetch response: ${res.body}");

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      List<Map<String, dynamic>> fetchedAddresses = [];

      if (decoded is List) {
        fetchedAddresses = List<Map<String, dynamic>>.from(decoded);
      } else if (decoded is Map && decoded["data"] is List) {
        fetchedAddresses = List<Map<String, dynamic>>.from(decoded["data"]);
      } else if (decoded is Map && decoded["results"] is List) {
        fetchedAddresses = List<Map<String, dynamic>>.from(decoded["results"]);
      }

      if (!mounted) return;

      setState(() {
        addresses = fetchedAddresses;

        if (selectedCheckoutAddress == null && addresses.isNotEmpty) {
          selectedCheckoutAddress = addresses.first;
        }

        addressLoading = false;
      });
    } else {
      if (!mounted) return;

      setState(() {
        addresses = [];
        selectedCheckoutAddress = null;
        addressLoading = false;
      });
    }
  } catch (e) {
    debugPrint("Address fetch error: $e");

    if (!mounted) return;

    setState(() {
      addressLoading = false;
    });
  }
}


Future<void> fetchUsedProductPriceDetails() async {
  if (productDetail == null) return;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  if (!mounted) return;

  setState(() {
    priceDetailsLoading = true;
  });

  try {
    final productId = productDetail!["id"];

    final response = await http.get(
      Uri.parse("$api/api/myskates/used/product/price/details/$productId/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("USED PRODUCT PRICE DETAILS STATUS: ${response.statusCode}");
    print("USED PRODUCT PRICE DETAILS BODY: ${response.body}");

    if (!mounted) return;

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map &&
          decoded["success"] == true &&
          decoded["data"] != null) {
        setState(() {
          usedProductPriceDetails = Map<String, dynamic>.from(decoded["data"]);
          priceDetailsLoading = false;
        });
      } else {
        setState(() {
          usedProductPriceDetails = null;
          priceDetailsLoading = false;
        });
      }
    } else {
      setState(() {
        usedProductPriceDetails = null;
        priceDetailsLoading = false;
      });
    }
  } catch (e) {
    debugPrint("Used product price details error: $e");

    if (!mounted) return;

    setState(() {
      usedProductPriceDetails = null;
      priceDetailsLoading = false;
    });
  }
}

Map<String, dynamic>? _buildUsedProductCheckoutBody({
  required String paymentMethod,
}) {
  if (productDetail == null) return null;

  if (selectedCheckoutAddress == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select delivery address"),
        backgroundColor: Colors.redAccent,
      ),
    );
    return null;
  }

  final address = selectedCheckoutAddress!;

  final fullName = _readAddressValue(address, ["full_name", "name", "customer_name"]);
  final phone = _readAddressValue(address, ["phone", "mobile", "phone_number"]);
  final addressLine1 = _readAddressValue(address, ["address_line1", "address", "line1"]);
  final addressLine2 = _readAddressValue(address, ["address_line2", "landmark", "line2"]);
  final city = _readAddressValue(address, ["city"]);
  final state = _readAddressValue(address, ["state", "state_name"]);
  final pincode = _readAddressValue(address, ["pincode", "pin_code", "zipcode"]);
  final country = _readAddressValue(address, ["country", "country_name"]);

  if (fullName.isEmpty || phone.isEmpty || addressLine1.isEmpty || city.isEmpty || state.isEmpty || pincode.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Selected address is incomplete"),
        backgroundColor: Colors.redAccent,
      ),
    );
    return null;
  }

  return {
    "payment_method": paymentMethod,
    "full_name": fullName,
    "phone": phone,
    "address_line1": addressLine1,
    "address_line2": addressLine2,
    "city": city,
    "state": state,
    "pincode": pincode,
    "country": country.isNotEmpty ? country : "India",
    "note": checkoutNoteController.text.trim(),
    "product_id": productDetail!["id"],
  };
}

Future<void> checkoutUsedProduct() async {
  final body = _buildUsedProductCheckoutBody(paymentMethod: "COD");
  if (body == null) return;

  setState(() => checkoutLoading = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final response = await http.post(
      Uri.parse("$api/api/myskates/used/product/checkout/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("USED PRODUCT COD CHECKOUT STATUS: ${response.statusCode}");
    print("USED PRODUCT COD CHECKOUT BODY: ${response.body}");

    if (!mounted) return;
    setState(() => checkoutLoading = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully"), backgroundColor: Colors.teal),
      );
      await fetchUsedProductDetail();
    } else {
      String message = "Checkout failed. Please try again.";
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded["message"] != null) message = decoded["message"].toString();
        else if (decoded is Map && decoded["error"] != null) message = decoded["error"].toString();
        else if (decoded is Map && decoded["detail"] != null) message = decoded["detail"].toString();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
    }
  } catch (e) {
    debugPrint("Used product COD checkout error: $e");
    if (!mounted) return;
    setState(() => checkoutLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Something went wrong while placing order"), backgroundColor: Colors.redAccent),
    );
  }
}

Future<void> createUsedProductRazorpayOrder() async {
  final body = _buildUsedProductCheckoutBody(paymentMethod: "ONLINE");
  if (body == null) return;

  setState(() => checkoutLoading = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final response = await http.post(
      Uri.parse("$api/api/myskates/used/product/razorpay/create/order/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("USED PRODUCT RAZORPAY CREATE STATUS: ${response.statusCode}");
    print("USED PRODUCT RAZORPAY CREATE BODY: ${response.body}");

    if (!mounted) return;
    setState(() => checkoutLoading = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded["success"] == true && decoded["data"] != null) {
        final data = decoded["data"];
        usedBackendOrderId = data["order_id"]?.toString();
        usedOrderNo = data["order_no"]?.toString();
        usedRazorpayOrderId = data["razorpay_order_id"]?.toString();
        usedRazorpayAmount = data["final_payable"]?.toString();
        final int amount = int.tryParse(data["amount"]?.toString() ?? "0") ?? 0;
        final String key = data["key"]?.toString() ?? "";

        if (usedRazorpayOrderId == null || usedRazorpayOrderId!.isEmpty || amount <= 0 || key.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid Razorpay order response"), backgroundColor: Colors.redAccent),
          );
          return;
        }

        Navigator.pop(context);
        openUsedProductRazorpayCheckout(key: key, amount: amount, razorpayOrderId: usedRazorpayOrderId!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to create Razorpay order"), backgroundColor: Colors.redAccent),
        );
      }
    } else {
      String message = "Unable to create Razorpay order.";
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded["message"] != null) message = decoded["message"].toString();
        else if (decoded is Map && decoded["error"] != null) message = decoded["error"].toString();
        else if (decoded is Map && decoded["detail"] != null) message = decoded["detail"].toString();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
    }
  } catch (e) {
    debugPrint("Used product Razorpay create error: $e");
    if (!mounted) return;
    setState(() => checkoutLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Something went wrong while creating payment"), backgroundColor: Colors.redAccent),
    );
  }
}

void openUsedProductRazorpayCheckout({required String key, required int amount, required String razorpayOrderId}) {
  final address = selectedCheckoutAddress;

  final options = {
    "key": key,
    "amount": amount,
    "name": "My Skates",
    "description": productDetail?["title"]?.toString() ?? "Used Product Payment",
    "order_id": razorpayOrderId,
    "currency": "INR",
    "timeout": 300,
    "prefill": {
      "contact": _readAddressValue(address ?? {}, ["phone", "mobile", "phone_number"]),
      "email": _readAddressValue(address ?? {}, ["email"]),
    },
    "theme": {"color": "#00C2A8"},
  };

  try {
    _razorpay.open(options);
  } catch (e) {
    debugPrint("Used product Razorpay open error: $e");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unable to open Razorpay: $e"), backgroundColor: Colors.redAccent));
  }
}

Future<bool> verifyUsedProductRazorpayPayment({required String razorpayOrderId, required String razorpayPaymentId, required String razorpaySignature}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final response = await http.post(
      Uri.parse("$api/api/myskates/used/product/razorpay/verify/payment/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "order_id": usedBackendOrderId,
        "razorpay_order_id": razorpayOrderId,
        "razorpay_payment_id": razorpayPaymentId,
        "razorpay_signature": razorpaySignature,
      }),
    );

    print("USED PRODUCT RAZORPAY VERIFY STATUS: ${response.statusCode}");
    print("USED PRODUCT RAZORPAY VERIFY BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && (decoded["success"] == true || decoded["verified"] == true || decoded["status"] == "success")) return true;
    }
    return false;
  } catch (e) {
    debugPrint("Used product Razorpay verify error: $e");
    return false;
  }
}

void _handleUsedProductPaymentSuccess(PaymentSuccessResponse response) async {
  usedRazorpayPaymentId = response.paymentId;
  usedRazorpaySignature = response.signature;
  setState(() => checkoutLoading = true);

  final bool verified = await verifyUsedProductRazorpayPayment(
    razorpayOrderId: response.orderId ?? usedRazorpayOrderId ?? "",
    razorpayPaymentId: response.paymentId ?? "",
    razorpaySignature: response.signature ?? "",
  );

  if (!mounted) return;
  setState(() => checkoutLoading = false);

  if (verified) {
    await fetchUsedProductDetail();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSuccessPage(
          orderId: usedOrderNo ?? usedBackendOrderId ?? response.orderId ?? "",
          paymentId: response.paymentId ?? "",
          amount: usedRazorpayAmount ?? "",
        ),
      ),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentFailedPage(reason: "Payment verification failed", amount: usedRazorpayAmount ?? ""),
      ),
    );
  }
}

void _handleUsedProductPaymentError(PaymentFailureResponse response) {
  setState(() => checkoutLoading = false);
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => PaymentFailedPage(reason: response.message ?? "Payment cancelled or failed", amount: usedRazorpayAmount ?? ""),
    ),
  );
}

void _handleUsedProductExternalWallet(ExternalWalletResponse response) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Wallet selected: ${response.walletName}"), backgroundColor: Colors.teal),
  );
}

Future<void> _openCheckoutBottomSheet() async {
  await Future.wait([
    fetchAddresses(),
    fetchUsedProductPriceDetails(),
  ]);

  if (!mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (bottomSheetContext) {
      return StatefulBuilder(
        builder: (context, sheetSetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
            ),
            padding: EdgeInsets.fromLTRB(
              18,
              16,
              18,
              MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF080808),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Checkout",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (productDetail != null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.055),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 54,
                                  width: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Colors.tealAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productDetail!["title"]?.toString() ??
                                            "",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "₹${productDetail!["final_price"].toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          color: Colors.tealAccent,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 18),
_checkoutPriceDetailsCard(),

const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Select Address",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddAddress(),
                                  ),
                                );

                                await fetchAddresses();

                                if (addresses.isNotEmpty) {
                                  selectedCheckoutAddress = addresses.first;
                                }

                                sheetSetState(() {});
                              },
                              icon: const Icon(
                                Icons.add,
                                color: Colors.tealAccent,
                                size: 18,
                              ),
                              label: const Text(
                                "Add Address",
                                style: TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        if (addressLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.tealAccent,
                              ),
                            ),
                          )
                        else if (addresses.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.045),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              children: const [
                                Icon(
                                  Icons.location_off_outlined,
                                  color: Colors.white54,
                                  size: 36,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "No saved address found",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13.5,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: addresses.map((address) {
                              final bool selected =
                                  selectedCheckoutAddress != null &&
                                      selectedCheckoutAddress!["id"] ==
                                          address["id"];

                              final name = _readAddressValue(
                                address,
                                ["full_name", "name", "customer_name"],
                              );
                              final phone = _readAddressValue(
                                address,
                                ["phone", "mobile", "phone_number"],
                              );

                              return GestureDetector(
                                onTap: () {
                                  selectedCheckoutAddress = address;
                                  sheetSetState(() {});
                                },
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.tealAccent.withOpacity(0.12)
                                        : Colors.white.withOpacity(0.045),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected
                                          ? Colors.tealAccent.withOpacity(0.55)
                                          : Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        selected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: selected
                                            ? Colors.tealAccent
                                            : Colors.white38,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name.isNotEmpty
                                                  ? name
                                                  : "Saved Address",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            if (phone.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                phone,
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 12.5,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 6),
                                            Text(
                                              _formatAddress(address),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12.5,
                                                height: 1.45,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 18),

                        const Text(
                          "Payment Method",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.055),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedPaymentMethod,
                              dropdownColor: const Color(0xFF111111),
                              iconEnabledColor: Colors.tealAccent,
                              isExpanded: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                              items: paymentMethods.map((method) {
                                return DropdownMenuItem<String>(
                                  value: method,
                                  child: Text(
                                    method == "COD"
                                        ? "Cash on Delivery"
                                        : "Online Payment",
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;

                                selectedPaymentMethod = value;
                                sheetSetState(() {});
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          "Delivery Note",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextField(
                          controller: checkoutNoteController,
                          maxLines: 3,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: "Example: Please deliver in the evening",
                            hintStyle: const TextStyle(
                              color: Colors.white38,
                              fontFamily: 'Poppins',
                              fontSize: 12.5,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.055),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Colors.tealAccent,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: checkoutLoading
                        ? null
                        : () async {
                            if (selectedPaymentMethod == "COD") {
                              await checkoutUsedProduct();
                            } else {
                              await createUsedProductRazorpayOrder();
                            }

                            sheetSetState(() {});
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade800,
                      disabledForegroundColor: Colors.white54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: checkoutLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            selectedPaymentMethod == "COD"
                                ? "Place Order"
                                : "Pay Now",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    if (detailLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF050505),
        extendBodyBehindAppBar: true,
        appBar: _detailAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      );
    }

    if (detailError || productDetail == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF050505),
        extendBodyBehindAppBar: true,
        appBar: _detailAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 62,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Unable to load product details",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Please check your connection and try again.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: fetchUsedProductDetail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Retry",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final product = productDetail!;
    final bool isSold = product["status"] == "sold";
    final bool isActive = product["status"] == "active";
    final bool hasDiscount = (product['discount'] ?? 0) > 0;
    final List<String> images = List<String>.from(product["images"] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      extendBodyBehindAppBar: true,
      appBar: _detailAppBar(),
      bottomNavigationBar: _bottomActionBar(isSold: isSold),
      body: RefreshIndicator(
        onRefresh: fetchUsedProductDetail,
        color: Colors.tealAccent,
        backgroundColor: Colors.black,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imageGallery(images: images, isSold: isSold, isActive: isActive),
              Transform.translate(
                offset: const Offset(0, -26),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF050505),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sellerAndStatusSection(product: product),
                        const SizedBox(height: 16),
                        _titleAndPriceSection(
                          product: product,
                          hasDiscount: hasDiscount,
                        ),
                        const SizedBox(height: 18),
                        _usedProductTrustStrip(product: product),
                        const SizedBox(height: 18),
                        _sectionCard(
                          title: "Product Overview",
                          child: _productOverviewText(
                            description:
                                product["description"]
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                    true
                                ? product["description"].toString()
                                : "No description available for this product.",
                          ),
                        ),
                        const SizedBox(height: 14),
                        _sectionCard(
                          title: "Used Product Details",
                          child: Column(
                            children: [
                              _detailRow(
                                icon: Icons.verified_outlined,
                                label: "Availability",
                                value: isSold ? "Sold Out" : "Available",
                              ),
                              _detailDivider(),
                              _detailRow(
                                icon: Icons.person_outline,
                                label: "Seller",
                                value:
                                    product["user_name"]
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? product["user_name"].toString()
                                    : "Seller",
                              ),
                              _detailDivider(),
                              _detailRow(
                                icon: Icons.assignment_return_outlined,
                                label: "Return Policy",
                                value:
                                    "${product["return_policy_days"]?.toString() ?? "0"} days",
                              ),
                              _detailDivider(),
                              _detailRow(
                                icon: Icons.local_shipping_outlined,
                                label: "Shipment Charge",
                                value:
                                    "₹${product["shipment_charge"]?.toString() ?? "0.00"}",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buyerSafetyCard(),
                        const SizedBox(height: 14),
                        _sectionCard(
                          title: "Listing Information",
                          child: Column(
                            children: [
                              _detailRow(
                                icon: Icons.access_time,
                                label: "Listed On",
                                value:
                                    product["created_at"]
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? product["created_at"].toString()
                                    : "N/A",
                              ),
                              _detailDivider(),
                              _detailRow(
                                icon: Icons.update,
                                label: "Last Updated",
                                value:
                                    product["updated_at"]
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? product["updated_at"].toString()
                                    : "N/A",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _detailAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 62,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.45),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.45),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white, size: 21),
            onPressed: () {
              // Share functionality can be added here
            },
          ),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.45),
          child: IconButton(
            icon: const Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () {
              // Favorite functionality can be added here
            },
          ),
        ),
        const SizedBox(width: 14),
      ],
    );
  }

  Widget _imageGallery({
    required List<String> images,
    required bool isSold,
    required bool isActive,
  }) {
    return Container(
      height: 430,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          if (images.isNotEmpty)
            PageView.builder(
              controller: _imagePageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  selectedImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return Container(
                      color: Colors.grey.shade900,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.tealAccent,
                          strokeWidth: 2.5,
                        ),
                      ),
                    );
                  },
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
                );
              },
            )
          else
            Container(
              color: Colors.grey.shade900,
              child: const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white54,
                  size: 80,
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.45),
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 58,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.tealAccent,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    images.isEmpty
                        ? "0 Photos"
                        : "${selectedImageIndex + 1}/${images.length} Photos",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 58,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: isSold
                    ? Colors.redAccent.withOpacity(0.92)
                    : Colors.tealAccent.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isSold
                    ? "Sold Out"
                    : isActive
                    ? "Available"
                    : "Available",
                style: TextStyle(
                  color: isSold ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final bool active = selectedImageIndex == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 7,
                    width: active ? 24 : 7,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.tealAccent
                          : Colors.white.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sellerAndStatusSection({required Map<String, dynamic> product}) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.tealAccent.withOpacity(0.12),
            border: Border.all(color: Colors.tealAccent.withOpacity(0.25)),
          ),
          child: const Icon(Icons.person, color: Colors.tealAccent, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Listed by",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11.5,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                product["user_name"]?.toString().trim().isNotEmpty == true
                    ? product["user_name"].toString()
                    : "Seller",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.tealAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.tealAccent.withOpacity(0.25)),
          ),
          child: Row(
            children: const [
              Icon(
                Icons.verified_user_outlined,
                color: Colors.tealAccent,
                size: 15,
              ),
              SizedBox(width: 5),
              Text(
                "Used Sale",
                style: TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _titleAndPriceSection({
    required Map<String, dynamic> product,
    required bool hasDiscount,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product["title"] ?? "",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasDiscount) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    "₹${product['price'].toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                "₹${product['final_price'].toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                  height: 1,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      "Save ₹${product['discount'].toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.white38, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Price set by seller. Please verify item condition before purchase.",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11.5,
                    fontFamily: 'Poppins',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _usedProductTrustStrip({required Map<String, dynamic> product}) {
    return Row(
      children: [
        Expanded(
          child: _miniFeatureCard(
            icon: Icons.recycling,
            title: "Pre-owned",
            value: "Used item",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniFeatureCard(
            icon: Icons.assignment_return,
            title: "Return",
            value: "${product["return_policy_days"]?.toString() ?? "0"} days",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniFeatureCard(
            icon: Icons.local_shipping,
            title: "Delivery",
            value: "₹${product["shipment_charge"]?.toString() ?? "0.00"}",
          ),
        ),
      ],
    );
  }

  Widget _miniFeatureCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.tealAccent, size: 22),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10.5,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _productOverviewText({required String description}) {
    const TextStyle descriptionStyle = TextStyle(
      color: Colors.white70,
      fontSize: 14.5,
      height: 1.65,
      fontFamily: 'Poppins',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final TextPainter textPainter = TextPainter(
          text: TextSpan(text: description, style: descriptionStyle),
          maxLines: 5,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final bool isMoreThanFiveLines = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Text(
                description,
                maxLines: productOverviewExpanded ? null : 5,
                overflow: productOverviewExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: descriptionStyle,
              ),
            ),

            if (isMoreThanFiveLines) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    productOverviewExpanded = !productOverviewExpanded;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      productOverviewExpanded ? "See less" : "See more",
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      productOverviewExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.tealAccent,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.052),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: Colors.tealAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.tealAccent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Colors.white.withOpacity(0.08)),
    );
  }

  Widget _checkoutPriceDetailsCard() {
  if (priceDetailsLoading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14,
            width: 130,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  if (usedProductPriceDetails == null) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: const Text(
        "Price details unavailable",
        style: TextStyle(
          color: Colors.white60,
          fontSize: 13,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  final data = usedProductPriceDetails!;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.055),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Price Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),

        const SizedBox(height: 14),

        _checkoutPriceRow(
          label: "Product Price",
          value: "₹${data["price"]?.toString() ?? "0.00"}",
        ),

        _checkoutPriceRow(
          label: "Discount (${data["discount_percentage"]?.toString() ?? "0"}%)",
          value: "- ₹${data["discount_amount"]?.toString() ?? "0.00"}",
          valueColor: Colors.greenAccent,
        ),

        _checkoutPriceRow(
          label: "Subtotal",
          value: "₹${data["total"]?.toString() ?? "0.00"}",
        ),

        // _checkoutPriceRow(
        //   label: "Product Fee",
        //   value: "₹${data["product_percentage"]?.toString() ?? "0.00"}",
        // ),

        _checkoutPriceRow(
          label: "Platform Fee",
          value: "₹${data["platform_fee"]?.toString() ?? "0.00"}",
        ),

        _checkoutPriceRow(
          label: "Convenience Fee",
          value: "₹${data["convenience_fee"]?.toString() ?? "0.00"}",
        ),

        _checkoutPriceRow(
          label: "Shipment Charge",
          value: "₹${data["shipment_charge"]?.toString() ?? "0.00"}",
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(
            height: 1,
            color: Colors.white.withOpacity(0.12),
          ),
        ),

        Row(
          children: [
            const Expanded(
              child: Text(
                "Final Payable",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Text(
              "₹${data["final_payable"]?.toString() ?? "0.00"}",
              style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _checkoutPriceRow({
  required String label,
  required String value,
  Color? valueColor,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    ),
  );
}

  Widget _buyerSafetyCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.tealAccent.withOpacity(0.13),
            Colors.white.withOpacity(0.045),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.28),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.security,
              color: Colors.tealAccent,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Buyer Safety Tip",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Check product images, confirm seller details, and verify item condition before finalizing the deal.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.55,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActionBar({required bool isSold}) {
  return Container(
    padding: EdgeInsets.fromLTRB(
      16,
      12,
      16,
      MediaQuery.of(context).padding.bottom + 12,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF080808),
      border: Border(
        top: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 22,
          offset: const Offset(0, -8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.13)),
          ),
          child: IconButton(
            onPressed: isSold
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Message seller functionality"),
                        backgroundColor: Colors.tealAccent,
                      ),
                    );
                  },
            icon: Icon(
              Icons.chat_bubble_outline,
              color: isSold ? Colors.white38 : Colors.white,
              size: 22,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isSold
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Contact seller functionality"),
                          backgroundColor: Colors.tealAccent,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSold
                    ? Colors.grey.shade800
                    : Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade800,
                disabledForegroundColor: Colors.white54,
                side: BorderSide(color: Colors.white.withOpacity(0.18)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: Text(
                isSold ? "Sold Out" : "Contact",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isSold ? null : _openCheckoutBottomSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSold ? Colors.grey.shade700 : Colors.tealAccent,
                foregroundColor: isSold ? Colors.white54 : Colors.black,
                disabledBackgroundColor: Colors.grey.shade800,
                disabledForegroundColor: Colors.white54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: Text(
                isSold ? "Sold Out" : "Buy Now",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

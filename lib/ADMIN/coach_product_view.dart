import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/add_product.dart';
import 'package:my_skates/ADMIN/cart_view.dart';
import 'package:my_skates/ADMIN/product_big%20_view.dart';
import 'package:my_skates/ADMIN/products_by_user.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/update_product.dart';
import 'package:my_skates/ADMIN/wishlist.dart';
import 'package:my_skates/COACH/coach_homepage.dart';
import 'package:my_skates/bottomnavigation.dart';
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

class UserApprovedProducts extends StatefulWidget {
  const UserApprovedProducts({super.key});

  @override
  State<UserApprovedProducts> createState() => _UserApprovedProductsState();
}

class _UserApprovedProductsState extends State<UserApprovedProducts> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> _allProducts = [];
  bool pageLoading = true;
  bool productsLoading = false;
  int? selectedCategoryId;
  String selectedCategoryName = "";
  String? _selectedPriceRange;
  bool _isPriceFilterActive = false;

  bool _animatePage = false;

  final List<Map<String, String>> statusTabs = [
    {"label": "Approved", "value": "approved"},
    {"label": "Pending", "value": "pending"},
    {"label": "Disapproved", "value": "disapproved"},
  ];

  final List<Map<String, dynamic>> priceRanges = [
    {'label': 'Rs. 499 and Below', 'min': 0, 'max': 499},
    {'label': 'Rs. 500 and Below', 'min': 0, 'max': 500},
    {'label': 'Rs. 500 to Rs. 999', 'min': 500, 'max': 999},
    {'label': 'Rs. 1000 to Rs. 1499', 'min': 1000, 'max': 1499},
    {'label': 'Rs. 1500 to Rs. 1999', 'min': 1500, 'max': 1999},
    {'label': 'Rs. 2000 to Rs. 2999', 'min': 2000, 'max': 2999},
    {'label': 'Rs. 2999 and above', 'min': 2999, 'max': double.infinity},
  ];

  @override
  void initState() {
    super.initState();
    loadInitialData();

    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _animatePage = true;
      });
    });
  }

  Future<void> loadInitialData() async {
    await Future.wait([getbanner(), getProductCategories()]);
    setState(() {
      pageLoading = false;
    });
  }

  Future<void> refreshAllData() async {
    await getbanner();
    await getProductCategories();

    if (selectedCategoryId != null) {
      await getProductsByCategory(selectedCategoryId!);
    }
  }

  Future<void> delete(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    var response = await http.delete(
      Uri.parse("$api/api/myskates/products/update/${id}/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Product Deleted"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete Failed"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> addwishlist(int id, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    final userId = prefs.getInt("id");

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login expired. Please login again.")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$api/api/myskates/products/$id/wishlist/'),
        headers: {'Authorization': 'Bearer $token'},
        body: {"user": userId.toString(), "product": id.toString()},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final String message = decoded['message'] ?? "Added to wishlist";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2F2B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.tealAccent.withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.tealAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        setState(() {
          for (var product in products) {
            if (product['id'] == id) {
              product['is_wishlisted'] = true;
              break;
            }
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2A230F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.6)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Failed to add wishlist",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2A230F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.6)),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Failed to add wishlist",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<Map<String, dynamic>> banner = [];

  Future<void> getbanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var response = await http.get(
        Uri.parse('$api/api/myskates/product/banner/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> statelist = [];
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed;

        for (var productData in productsData) {
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

  List<Map<String, dynamic>> categories = [];

  Future<void> getProductCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      var response = await http.get(
        Uri.parse("$api/api/myskates/products/category/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> list = [];

        for (var item in parsed) {
          list.add({"id": item["id"], "name": item["name"]});
        }

        setState(() {
          categories = list;
        });

        if (categories.isNotEmpty) {
          selectedCategoryId = categories.first['id'];
          selectedCategoryName = categories.first['name'];
          await getProductsByCategory(selectedCategoryId!);
        }
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> getProductsByCategory(int categoryId) async {
    setState(() {
      productsLoading = true;
      _selectedPriceRange = null;
      _isPriceFilterActive = false;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final response = await http.get(
        Uri.parse('$api/api/myskates/products/by/category/$categoryId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> dataList = jsonDecode(response.body);

        products = dataList.map<Map<String, dynamic>>((c) {
          // Handle price conversion safely
          var price = c['base_price'];
          String priceString = "0";

          if (price != null) {
            if (price is int) {
              priceString = price.toString();
            } else if (price is double) {
              priceString = price.toString();
            } else if (price is String) {
              priceString = price;
            }
          }

          return {
            'id': c['id'],
            'title': c['title'] ?? "",
            'image': c['image'] != null ? '$api${c['image']}' : "",
            'category_name': c['category_name'] ?? "",
            'price': priceString,
            'is_wishlisted': c['is_in_wishlist'] ?? false,
          };
        }).toList();

        _allProducts = List.from(products);
      }
    } catch (e) {
      print("Category fetch error: $e");
    }

    setState(() {
      productsLoading = false;
    });
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade800),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Price Range List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: priceRanges.length,
                      itemBuilder: (context, index) {
                        final range = priceRanges[index];
                        final isSelected =
                            _selectedPriceRange == range['label'];

                        return ListTile(
                          leading: Radio<String>(
                            value: range['label'],
                            groupValue: _selectedPriceRange,
                            onChanged: (value) {
                              setState(() {
                                this.setState(() {
                                  _selectedPriceRange = value;
                                });
                              });
                            },
                            activeColor: Colors.tealAccent,
                          ),
                          title: Text(
                            range['label'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.tealAccent
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              this.setState(() {
                                _selectedPriceRange = range['label'];
                              });
                            });
                          },
                        );
                      },
                    ),
                  ),

                  // Apply Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearPriceFilter,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _applyPriceFilter(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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

  void _applyPriceFilter(BuildContext context) {
    if (_selectedPriceRange == null) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isPriceFilterActive = true;
    });

    _filterProductsByPrice();
    Navigator.pop(context);
  }

  void _clearPriceFilter() {
    setState(() {
      _selectedPriceRange = null;
      _isPriceFilterActive = false;
    });

    // Reload original products
    if (selectedCategoryId != null) {
      getProductsByCategory(selectedCategoryId!);
    }
  }

  void _filterProductsByPrice() {
    if (selectedCategoryId == null || _selectedPriceRange == null) return;

    setState(() {
      productsLoading = true;
    });

    // Find the selected price range
    final selectedRange = priceRanges.firstWhere(
      (range) => range['label'] == _selectedPriceRange,
    );

    // Convert min and max to double safely
    double minPrice = 0.0;
    double maxPrice = double.infinity;

    var minValue = selectedRange['min'];
    if (minValue is int) {
      minPrice = minValue.toDouble();
    } else if (minValue is double) {
      minPrice = minValue;
    }

    var maxValue = selectedRange['max'];
    if (maxValue is int) {
      maxPrice = maxValue.toDouble();
    } else if (maxValue is double) {
      maxPrice = maxValue;
    }

    // Filter products based on price range
    List<Map<String, dynamic>> filteredProducts = _allProducts.where((product) {
      // Parse price safely to double
      double price = 0.0;
      var priceValue = product['price'];

      if (priceValue is String) {
        price = double.tryParse(priceValue) ?? 0.0;
      } else if (priceValue is int) {
        price = priceValue.toDouble();
      } else if (priceValue is double) {
        price = priceValue;
      }

      if (maxPrice == double.infinity) {
        return price >= minPrice;
      } else {
        return price >= minPrice && price <= maxPrice;
      }
    }).toList();

    setState(() {
      products = filteredProducts;
      productsLoading = false;
    });
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
                                            _handleUpdateProduct();
                                          },
                                          icon: const Icon(
                                            Icons.favorite_border,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 4),

                                        IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              slideRightToLeftRoute(cart()),
                                            );
                                          },
                                          icon: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              const Icon(
                                                Icons.shopping_cart_outlined,
                                                color: Colors.white,
                                                size: 26,
                                              ),
                                              Positioned(
                                                right: -2,
                                                top: -2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.redAccent,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Text(
                                                    "2",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
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
                                        child: const Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              SizedBox(width: 10),
                                              Icon(
                                                Icons.search,
                                                color: Colors.white54,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                "Search",
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white54,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Price Filter Button with Badge
                                    GestureDetector(
                                      onTap: _showPriceFilter,
                                      child: Container(
                                        height: 40,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          border: Border.all(
                                            color: _isPriceFilterActive
                                                ? Colors.tealAccent
                                                : Colors.white24,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Text(
                                              "Price",
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.filter_list,
                                              color: _isPriceFilterActive
                                                  ? Colors.tealAccent
                                                  : Colors.white,
                                              size: 18,
                                            ),
                                            if (_isPriceFilterActive) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  3,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.tealAccent,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.black,
                                                  size: 10,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Products Button
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          slideRightToLeftRoute(
                                            ProductsByUser(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 40,
                                        width: 90,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.25),
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
                                                      loadingBuilder:
                                                          (
                                                            context,
                                                            child,
                                                            progress,
                                                          ) {
                                                            if (progress ==
                                                                null)
                                                              return child;
                                                            return Container(
                                                              color: Colors
                                                                  .grey
                                                                  .shade900,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
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

                                Text(
                                  selectedCategoryName.isEmpty
                                      ? "Products"
                                      : "$selectedCategoryName Products",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                categories.isEmpty
                                    ? _categorySkeleton()
                                    : SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: categories.map((cat) {
                                            final bool isSelected =
                                                selectedCategoryId == cat['id'];
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedCategoryId =
                                                      cat['id'];
                                                  selectedCategoryName =
                                                      cat['name'];
                                                });
                                                getProductsByCategory(
                                                  cat['id'],
                                                );
                                              },
                                              child: AnimatedContainer(
                                                duration: Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves.easeInOut,
                                                margin: const EdgeInsets.only(
                                                  right: 10,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.tealAccent
                                                      : Colors.black
                                                            .withOpacity(0.25),
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  border: Border.all(
                                                    color: Colors.white24,
                                                  ),
                                                ),
                                                child: Text(
                                                  cat['name'],
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: isSelected
                                                        ? Colors.black
                                                        : Colors.white,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),

                                const SizedBox(height: 20),

                                if (_isPriceFilterActive &&
                                    _selectedPriceRange != null)
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.tealAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.tealAccent.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.attach_money,
                                              color: Colors.tealAccent,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _selectedPriceRange!,
                                              style: const TextStyle(
                                                color: Colors.tealAccent,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: _clearPriceFilter,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.tealAccent
                                                  .withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.tealAccent,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                if (productsLoading)
                                  _productGridSkeleton()
                                else if (products.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 40,
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.inventory_2_outlined,
                                            color: Colors.white54,
                                            size: 60,
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            "No products found",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: products.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisExtent: 250,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                    itemBuilder: (context, index) {
                                      final p = products[index];

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
    final bool isWishlisted = p['is_wishlisted'] == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          slideRightToLeftRoute(big_view(productId: p['id'])),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.20),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Hero(
                    tag: "product_${p['id']}",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        p['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      await addwishlist(p['id'], context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedScale(
                        scale: isWishlisted ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted
                              ? Colors.tealAccent
                              : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                p['title'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                p['category_name'],
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                "₹${p['price']}",
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUpdateProduct() {
    Navigator.push(context, slideRightToLeftRoute(Wishlist()));
  }

  Widget _productGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 250,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
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
                  color: Colors.grey.shade900,
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
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _categorySkeleton() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(5, (index) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(30),
            ),
          );
        }),
      ),
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

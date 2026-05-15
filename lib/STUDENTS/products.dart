import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/cart_count_notifier.dart';
import 'package:my_skates/ADMIN/cart_view.dart';
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/ADMIN/product_big%20_view.dart';
import 'package:my_skates/ADMIN/products_by_user.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/wishlist.dart';
import 'package:my_skates/COACH/coach_homepage.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/bottomnavigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

class UserProducts extends StatefulWidget {
  const UserProducts({super.key});

  @override
  State<UserProducts> createState() => _UserProductssState();
}

class _UserProductssState extends State<UserProducts> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> banner = [];
  List<Map<String, dynamic>> categories = [];

  bool pageLoading = true;
  bool productsLoading = false;
  bool _animatePage = false;

  int? selectedCategoryId;
  String selectedCategoryName = "";
  String _userType = "";

  String? _selectedPriceRange;
  bool _isPriceFilterActive = false;
  final ScrollController _scrollController = ScrollController();

  bool isAllCategorySelected = true;
  String? allProductsNextUrl;
  bool paginationLoading = false;
  Timer? _searchDebounce;
  String currentSearchQuery = "";

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

    _getUserType();
    loadInitialData();
    CartCountNotifier.refreshCartCount();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

   if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300 &&
    isAllCategorySelected &&
    !_isPriceFilterActive &&
    currentSearchQuery.trim().isEmpty &&
    allProductsNextUrl != null &&
    !paginationLoading &&
    !productsLoading) {
  getAllApprovedProducts(loadMore: true);
}
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _animatePage = true;
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userType = (prefs.getString("user_type") ?? "").toLowerCase().trim();
    });
  }

  Future<void> loadInitialData() async {
    await Future.wait([getbanner(), getProductCategories()]);

    await getAllApprovedProducts();

    if (!mounted) return;
    setState(() {
      pageLoading = false;
    });
  }

  Future<void> refreshAllData() async {
    await getbanner();
    await getProductCategories();

    if (isAllCategorySelected) {
      await getAllApprovedProducts();
    } else if (selectedCategoryId != null) {
      await getProductsByCategory(selectedCategoryId!);
    }
  }

  String _buildImageUrl(dynamic imagePath) {
    if (imagePath == null || imagePath.toString().trim().isEmpty) {
      return "";
    }

    final String image = imagePath.toString().trim();

    if (image.startsWith("http://") || image.startsWith("https://")) {
      return image;
    }

    if (image.startsWith("/")) {
      return "$api$image";
    }

    return "$api/$image";
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  bool _isOfferActive(dynamic offer) {
    if (offer == null || offer is! Map) return false;

    final dynamic activeValue = offer["is_active"];

    return activeValue == true ||
        activeValue.toString().toLowerCase() == "true" ||
        activeValue.toString() == "1";
  }

  String _formatOfferText(String title) {
    return title
        .toUpperCase()
        .replaceAll('BUY ', 'B')
        .replaceAll(' GET ', 'G')
        .replaceAll(' FREE', 'FREE')
        .replaceAll(' ', '');
  }

  Future<void> getbanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse('$api/api/myskates/banner/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final List<Map<String, dynamic>> list = [];

        for (var item in parsed) {
          list.add({
            'id': item['id'],
            'title': item['title'] ?? "",
            'image': _buildImageUrl(item['image']),
          });
        }

        if (!mounted) return;
        setState(() {
          banner = list;
        });
      }
    } catch (e) {
      debugPrint("Banner fetch error: $e");
    }
  }

  Future<void> getProductCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final response = await http.get(
        Uri.parse("$api/api/myskates/products/category/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("Categories status: ${response.statusCode}");
      debugPrint("Categories response: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final List<Map<String, dynamic>> list = [];

        list.add({"id": null, "name": "All"});

        for (var item in parsed) {
          list.add({"id": item["id"], "name": item["name"] ?? ""});
        }

        if (!mounted) return;

        setState(() {
          categories = list;
          selectedCategoryId = null;
          selectedCategoryName = "All";
          isAllCategorySelected = true;
        });
      }
    } catch (e) {
      debugPrint("Category fetch error: $e");
    }
  }

  Map<String, dynamic> _mapProductData(dynamic c) {
    final double basePrice = _toDouble(c['base_price']);
    final double price = _toDouble(c['price']);
    final double discountedPrice = _toDouble(c['discounted_price']);
    final double discount = _toDouble(c['discount']);

    double finalDiscountedPrice = discountedPrice;

    if (finalDiscountedPrice <= 0) {
      if (price > 0) {
        finalDiscountedPrice = price;
      } else {
        finalDiscountedPrice = basePrice;
      }
    }

    return {
      'id': c['id'],
      'title': c['title'] ?? "",
      'image': _buildImageUrl(c['image']),
      'category_name': c['category_name'] ?? "",
      'description': c['description'] ?? "",
      'approval_status': c['approval_status'] ?? "",
      'base_price': basePrice.toString(),
      'price': price.toString(),
      'discounted_price': finalDiscountedPrice.toString(),
      'discount': discount.toString(),
      'is_wishlisted': c['is_in_wishlist'] ?? c['is_wishlisted'] ?? false,
      'offer_details': c['offer_details'],
      'created_at': c['created_at'],
    };
  }

  Future<void> getAllApprovedProducts({bool loadMore = false}) async {
    if (loadMore) {
      if (allProductsNextUrl == null || paginationLoading) return;

      setState(() {
        paginationLoading = true;
      });
    } else {
      setState(() {
        productsLoading = true;
        paginationLoading = false;
        allProductsNextUrl = null;
        _selectedPriceRange = null;
        _isPriceFilterActive = false;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      Uri uri;

      if (loadMore && allProductsNextUrl != null) {
        uri = Uri.parse(allProductsNextUrl!);
      } else {
        uri = Uri.parse('$api/api/myskates/all/approved/products/view/');

        final Map<String, String> params = {};

        if (currentSearchQuery.trim().isNotEmpty) {
          params["search"] = currentSearchQuery.trim();
        }

        if (params.isNotEmpty) {
          uri = uri.replace(queryParameters: params);
        }
      }

      debugPrint("ALL PRODUCTS API: $uri");

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("ALL PRODUCTS STATUS: ${response.statusCode}");
      debugPrint("ALL PRODUCTS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        String? nextUrl;
        List<dynamic> dataList = [];

        if (decoded is Map && decoded["results"] is Map) {
          nextUrl = decoded["next"]?.toString();

          final results = decoded["results"];
          if (results["data"] is List) {
            dataList = results["data"];
          }
        } else if (decoded is Map && decoded["data"] is List) {
          nextUrl = decoded["next"]?.toString();
          dataList = decoded["data"];
        }

        final mappedProducts = dataList
            .map<Map<String, dynamic>>((c) => _mapProductData(c))
            .toList();

        if (!mounted) return;

        setState(() {
          allProductsNextUrl = nextUrl;

          if (loadMore) {
            products.addAll(mappedProducts);
            _allProducts.addAll(mappedProducts);
          } else {
            products = mappedProducts;
            _allProducts = List.from(mappedProducts);
          }
        });
      }
    } catch (e) {
      debugPrint("All approved products fetch error: $e");
    }

    if (!mounted) return;
    setState(() {
      productsLoading = false;
      paginationLoading = false;
    });
  }

  Future<void> getProductsByCategory(int categoryId) async {
    if (!mounted) return;

    setState(() {
      productsLoading = true;
      paginationLoading = false;
      allProductsNextUrl = null;
      _selectedPriceRange = null;
      _isPriceFilterActive = false;
      searchController.clear();
      currentSearchQuery = "";
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

      debugPrint('Category Response status: ${response.statusCode}');
      debugPrint('Category Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> dataList = jsonDecode(response.body);

        final List<Map<String, dynamic>> list = dataList
            .map<Map<String, dynamic>>((c) {
              return _mapProductData(c);
            })
            .toList();

        if (!mounted) return;

        setState(() {
          products = list;
          _allProducts = List.from(list);
        });
      }
    } catch (e) {
      debugPrint("Products by category fetch error: $e");
    }

    if (!mounted) return;
    setState(() {
      productsLoading = false;
    });
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

      debugPrint('Wishlist status: ${response.statusCode}');
      debugPrint('Wishlist response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final String message = decoded['message'] ?? "Wishlist updated";

        ScaffoldMessenger.of(context).showSnackBar(
          _customSnackBar(
            icon: Icons.favorite,
            color: Colors.tealAccent,
            background: const Color(0xFF0F2F2B),
            message: message,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          _customSnackBar(
            icon: Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
            background: const Color(0xFF2A230F),
            message: "Failed to update wishlist",
          ),
        );
      }
    } catch (e) {
      debugPrint("Wishlist error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        _customSnackBar(
          icon: Icons.warning_amber_rounded,
          color: Colors.orangeAccent,
          background: const Color(0xFF2A230F),
          message: "Failed to update wishlist",
        ),
      );
    }
  }

  SnackBar _customSnackBar({
    required IconData icon,
    required Color color,
    required Color background,
    required String message,
  }) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
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
    );
  }

  void _searchProducts(String query) {
    currentSearchQuery = query.trim();

    if (isAllCategorySelected) {
      _searchDebounce?.cancel();

      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        getAllApprovedProducts();
      });

      return;
    }

    if (query.trim().isEmpty) {
      setState(() {
        products = List.from(_allProducts);
      });
      return;
    }

    final String search = query.toLowerCase().trim();

    final results = _allProducts.where((product) {
      final title = product['title'].toString().toLowerCase();
      final category = product['category_name'].toString().toLowerCase();
      return title.contains(search) || category.contains(search);
    }).toList();

    setState(() {
      products = results;
    });
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.70,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            fontFamily: 'Poppins',
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
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
                            activeColor: Colors.tealAccent,
                            onChanged: (value) {
                              modalSetState(() {
                                _selectedPriceRange = value;
                              });
                              setState(() {
                                _selectedPriceRange = value;
                              });
                            },
                          ),
                          title: Text(
                            range['label'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.tealAccent
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          onTap: () {
                            modalSetState(() {
                              _selectedPriceRange = range['label'];
                            });
                            setState(() {
                              _selectedPriceRange = range['label'];
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _clearPriceFilter();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 15),
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
                              padding: const EdgeInsets.symmetric(vertical: 15),
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

  final selectedRange = priceRanges.firstWhere(
    (range) => range['label'] == _selectedPriceRange,
  );

  final double minPrice = _toDouble(selectedRange['min']);

  final double maxPrice = selectedRange['max'] == double.infinity
      ? double.infinity
      : _toDouble(selectedRange['max']);

  final List<Map<String, dynamic>> sourceList = List.from(_allProducts);

  final filteredProducts = sourceList.where((product) {
    double finalPrice = _toDouble(product['discounted_price']);

    if (finalPrice <= 0) {
      finalPrice = _toDouble(product['price']);
    }

    if (finalPrice <= 0) {
      finalPrice = _toDouble(product['base_price']);
    }

    if (maxPrice == double.infinity) {
      return finalPrice >= minPrice;
    }

    return finalPrice >= minPrice && finalPrice <= maxPrice;
  }).toList();

  setState(() {
    _isPriceFilterActive = true;
    products = filteredProducts;

    // Important: stop All category pagination while local price filter is active
    if (isAllCategorySelected) {
      allProductsNextUrl = null;
      paginationLoading = false;
    }
  });

  Navigator.pop(context);
}

  void _clearPriceFilter() {
    setState(() {
      _selectedPriceRange = null;
      _isPriceFilterActive = false;
    });

    if (isAllCategorySelected) {
      getAllApprovedProducts();
    } else {
      setState(() {
        products = List.from(_allProducts);
      });
    }
  }

  Future<void> _handleUpdateProduct() async {
    await Navigator.push(context, slideRightToLeftRoute(const Wishlist()));

    if (isAllCategorySelected) {
      await getAllApprovedProducts();
    } else if (selectedCategoryId != null) {
      await getProductsByCategory(selectedCategoryId!);
    }
  }

  Widget _offerBadge(Map<String, dynamic> p) {
    final offer = p['offer_details'];

    if (!_isOfferActive(offer)) {
      return const SizedBox.shrink();
    }

    final String title = (offer['title'] ?? '').toString().trim();

    if (title.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipPath(
      clipper: _ExactOfferRibbonClipper(),
      child: Container(
        height: 22,
        width: 92,
        padding: const EdgeInsets.fromLTRB(7, 0, 16, 0),
        alignment: Alignment.centerLeft,
        color: const Color.fromARGB(255, 55, 210, 194),
        child: Text(
          _formatOfferText(title),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            fontFamily: 'Poppins',
            height: 1,
            letterSpacing: -0.45,
          ),
        ),
      ),
    );
  }

  Widget _productPriceSection(Map<String, dynamic> p) {
    final double basePrice = _toDouble(p['base_price']);
    final double price = _toDouble(p['price']);
    final double discountPercent = _toDouble(p['discount']);

    double discountedPrice = _toDouble(p['discounted_price']);

    if (discountedPrice <= 0) {
      discountedPrice = price > 0 ? price : basePrice;
    }

    final bool hasDiscount =
        discountPercent > 0 && basePrice > 0 && discountedPrice < basePrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "₹${discountedPrice.toStringAsFixed(2)}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.tealAccent,
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
            fontFamily: 'Poppins',
            letterSpacing: 0.2,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  "₹${basePrice.toStringAsFixed(2)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.white.withOpacity(0.55),
                    decorationThickness: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.35),
                  ),
                ),
                child: Text(
                  "${discountPercent.toStringAsFixed(discountPercent.truncateToDouble() == discountPercent ? 0 : 1)}% OFF",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Poppins',
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    final bool isWishlisted = p['is_wishlisted'] == true;
    final double discountPercent = _toDouble(p['discount']);
    final bool hasDiscount = discountPercent > 0;
    final bool hasOffer = _isOfferActive(p['offer_details']);

    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 400),
      transitionType: ContainerTransitionType.fadeThrough,
      openElevation: 0,
      closedElevation: 0,
      closedColor: Colors.transparent,
      openColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      openBuilder: (context, _) {
        return big_view(productId: p['id']);
      },
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: openContainer,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 168,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF111111),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: p['image'].toString().isEmpty
                            ? const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.white38,
                                  size: 34,
                                ),
                              )
                            : Image.network(
                                p['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) {
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.white38,
                                      size: 34,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),

                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.05),
                                Colors.transparent,
                                Colors.black.withOpacity(0.50),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (hasOffer)
                      Positioned(top: 10, left: 0, child: _offerBadge(p)),

                    if (hasDiscount)
                      Positioned(
                        top: hasOffer ? 38 : 10,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${discountPercent.toStringAsFixed(discountPercent.truncateToDouble() == discountPercent ? 0 : 1)}%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                  height: 1,
                                ),
                              ),
                              const Text(
                                "OFF",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Poppins',
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          await addwishlist(p['id'], context);

                          setState(() {
                            p['is_wishlisted'] = !(p['is_wishlisted'] == true);

                            for (var item in _allProducts) {
                              if (item['id'] == p['id']) {
                                item['is_wishlisted'] = p['is_wishlisted'];
                              }
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                          child: Icon(
                            isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isWishlisted
                                ? Colors.tealAccent
                                : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 8,
                      bottom: 8,
                      right: 8,
                      child: Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F2F2B),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.tealAccent.withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                p['category_name'].toString().toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['title'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 7),

                        _productPriceSection(p),

                        const Spacer(),

                        Row(
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              color: Colors.white.withOpacity(0.48),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "View product",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
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
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade900,
      highlightColor: Colors.grey.shade800,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _categorySkeleton() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, _) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade900,
            highlightColor: Colors.grey.shade800,
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _productGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 295,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, _) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade900,
          highlightColor: Colors.grey.shade800,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
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
        backgroundColor: Colors.black,
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
                      controller: _scrollController,
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
                                          onPressed: _handleUpdateProduct,
                                          icon: const Icon(
                                            Icons.favorite_border,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              slideRightToLeftRoute(
                                                const cart(),
                                              ),
                                            );
                                            CartCountNotifier.refreshCartCount();
                                          },
                                          icon: ValueListenableBuilder<int>(
                                            valueListenable:
                                                CartCountNotifier.cartCount,
                                            builder: (context, count, _) {
                                              return Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .shopping_cart_outlined,
                                                    color: Colors.white,
                                                    size: 26,
                                                  ),
                                                  if (count > 0)
                                                    Positioned(
                                                      right: -2,
                                                      top: -2,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4,
                                                            ),
                                                        decoration:
                                                            const BoxDecoration(
                                                              color: Colors
                                                                  .redAccent,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                        child: Text(
                                                          "$count",
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
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
                                            fontFamily: 'Poppins',
                                          ),
                                          decoration: const InputDecoration(
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color: Colors.white54,
                                              size: 20,
                                            ),
                                            hintText: "Search",
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
                                        onTap: _showPriceFilter,
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
                                              color: _isPriceFilterActive
                                                  ? Colors.tealAccent
                                                  : Colors.white24,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                              const SizedBox(width: 6),
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
                                                  decoration:
                                                      const BoxDecoration(
                                                        color:
                                                            Colors.tealAccent,
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
                                    ),
                                    if (_userType != "student") ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: GestureDetector(
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
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(30),
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
                                                          ) {
                                                            return Container(
                                                              color:
                                                                  Colors.black,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: const Icon(
                                                                Icons
                                                                    .broken_image,
                                                                color: Colors
                                                                    .white54,
                                                                size: 40,
                                                              ),
                                                            );
                                                          },
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
                                    fontWeight: FontWeight.w500,
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
                                                isAllCategorySelected
                                                ? cat['id'] == null
                                                : selectedCategoryId ==
                                                      cat['id'];

                                            return GestureDetector(
                                              onTap: () {
                                                final bool selectedAll =
                                                    cat['id'] == null;

                                                setState(() {
                                                  selectedCategoryId =
                                                      cat['id'];
                                                  selectedCategoryName =
                                                      cat['name'];
                                                  isAllCategorySelected =
                                                      selectedAll;
                                                  searchController.clear();
                                                  currentSearchQuery = "";
                                                  _selectedPriceRange = null;
                                                  _isPriceFilterActive = false;
                                                });

                                                if (selectedAll) {
                                                  getAllApprovedProducts();
                                                } else {
                                                  getProductsByCategory(
                                                    cat['id'],
                                                  );
                                                }
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
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
                                                  cat['name'].toString(),
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
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
                                    margin: const EdgeInsets.only(bottom: 12),
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
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Poppins',
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
                                        ],
                                      ),
                                    ),
                                  )
                                else ...[
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: products.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisExtent: 295,
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

                                  if (paginationLoading)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.tealAccent,
                                        ),
                                      ),
                                    ),
                                ],

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
}

class _ExactOfferRibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - 10, size.height / 2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

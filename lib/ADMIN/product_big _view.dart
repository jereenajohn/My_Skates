import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/cart_view.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/wishlist.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/cart_count_notifier.dart';

class Review {
  final int id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isVerified;
  final String approvalStatus;
  final int userId;
  final int variantId;
  final String? userImage;

  Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isVerified = false,
    required this.approvalStatus,
    required this.userId,
    required this.variantId,
    this.userImage,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    String firstName = json['user_first_name'] ?? '';
    String lastName = json['user_last_name'] ?? '';
    String fullName = '$firstName $lastName'.trim();
    if (fullName.isEmpty) {
      fullName = json['user_name'] ?? 'Anonymous';
    }

    return Review(
      id: json['id'] ?? 0,
      userName: fullName,
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['review'] ?? json['comment'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isVerified: json['is_verified'] ?? false,
      approvalStatus: json['approval_status'] ?? 'pending',
      userId: json['user'] ?? 0,
      variantId: json['variant'] ?? 0,
      userImage: json['user_image'],
    );
  }
}

class big_view extends StatefulWidget {
  final int productId;
  const big_view({super.key, required this.productId});

  @override
  State<big_view> createState() => _big_viewState();
}

class _big_viewState extends State<big_view> with TickerProviderStateMixin {
  bool loading = true;
  Map<String, dynamic>? product;
  int? selectedVariantId;
  Map<String, dynamic>? selectedVariant;
  List<Map<String, dynamic>> similarProducts = [];
  bool similarProductsLoading = false;

  List<Review> allReviews = [];
  List<Review> approvedReviews = [];

  // Review variables
  List<Review> reviews = [];
  bool reviewsLoading = false;
  double averageRating = 0;
  int totalReviews = 0;
  bool isInWishlist = false;
  final ScrollController _scrollController = ScrollController();
  bool _isDescriptionExpanded = false;
  // Animation variables
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  OverlayEntry? _overlayEntry;
  bool _isAnimating = false;
  final GlobalKey _variantImageKey = GlobalKey();
  final GlobalKey _cartIconKey = GlobalKey();

  // bool _isCoach = false;
  // bool _isAdmin = false;

  // int? _currentUserId;
  // String _currentUserType = '';
  // int? _productOwnerId;
  // String _productOwnerType = '';
  // bool _canApproveReviews = false;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _offsetAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(1.5, -1.5)).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    // Call API methods
    getproductDetails();
    fetchProductReviews();
    CartCountNotifier.refreshCartCount();
    print("Product ID in big view: ${widget.productId}");
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  String _formatOfferText(String title) {
    return title
        .toUpperCase()
        .replaceAll('BUY ', 'B')
        .replaceAll(' GET ', 'G')
        .replaceAll(' FREE', 'FREE')
        .replaceAll(' ', '');
  }

  Map<String, dynamic>? _getActiveOfferFromProductItem(
    Map<String, dynamic> item,
  ) {
    final offers = item["offer_details"];

    if (offers == null) {
      return null;
    }

    // Case 1: API returns offer_details as object/map
    if (offers is Map) {
      final Map<String, dynamic> offerMap = Map<String, dynamic>.from(offers);

      final dynamic activeValue = offerMap["is_active"];

      final bool isActive =
          activeValue == true ||
          activeValue.toString().toLowerCase() == "true" ||
          activeValue.toString() == "1";

      if (isActive) {
        return offerMap;
      }

      return null;
    }

    // Case 2: API returns offer_details as list
    if (offers is List && offers.isNotEmpty) {
      for (final offer in offers) {
        if (offer is Map) {
          final Map<String, dynamic> offerMap = Map<String, dynamic>.from(
            offer,
          );

          final dynamic activeValue = offerMap["is_active"];

          final bool isActive =
              activeValue == true ||
              activeValue.toString().toLowerCase() == "true" ||
              activeValue.toString() == "1";

          if (isActive) {
            return offerMap;
          }
        }
      }
    }

    return null;
  }

  String _getOfferTitleFromProductItem(Map<String, dynamic> item) {
    final offer = _getActiveOfferFromProductItem(item);

    if (offer == null) return "";

    final title = offer["title"]?.toString().trim() ?? "";
    final message = offer["message"]?.toString().trim() ?? "";

    if (title.isNotEmpty && title.toLowerCase() != "null") return title;
    if (message.isNotEmpty && message.toLowerCase() != "null") return message;

    return "";
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _getVariantOfferTitle(Map<String, dynamic> variant) {
    final offers = product?["offer_details"];

    if (offers == null) return "";

    final int productId = _toInt(product?["id"]);
    final int variantId = _toInt(variant["id"]);

    final List<Map<String, dynamic>> activeOffers = [];

    if (offers is Map) {
      activeOffers.add(Map<String, dynamic>.from(offers));
    } else if (offers is List) {
      for (final offer in offers) {
        if (offer is Map) {
          activeOffers.add(Map<String, dynamic>.from(offer));
        }
      }
    }

    for (final offer in activeOffers) {
      final dynamic activeValue = offer["is_active"];

      final bool isActive =
          activeValue == true ||
          activeValue.toString().toLowerCase() == "true" ||
          activeValue.toString() == "1";

      if (!isActive) continue;

      final List eligibleProductIds = offer["eligible_product_ids"] ?? [];
      final List eligibleVariantIds = offer["eligible_variant_ids"] ?? [];

      final bool isProductEligible = eligibleProductIds
          .map((e) => _toInt(e))
          .contains(productId);

      final bool isVariantEligible = eligibleVariantIds
          .map((e) => _toInt(e))
          .contains(variantId);

      if (isProductEligible || isVariantEligible) {
        final String title = offer["title"]?.toString().trim() ?? "";
        final String message = offer["message"]?.toString().trim() ?? "";

        if (title.isNotEmpty && title.toLowerCase() != "null") {
          return title;
        }

        if (message.isNotEmpty && message.toLowerCase() != "null") {
          return message;
        }
      }
    }

    return "";
  }

  Map<String, dynamic>? _getActiveOffer() {
    final offers = product?["offer_details"];

    debugPrint("PRODUCT OFFER DETAILS: $offers");

    if (offers == null) {
      return null;
    }

    // Case 1: offer_details is object/map
    if (offers is Map) {
      final Map<String, dynamic> offerMap = Map<String, dynamic>.from(offers);

      final dynamic activeValue = offerMap["is_active"];

      final bool isActive =
          activeValue == true ||
          activeValue.toString().toLowerCase() == "true" ||
          activeValue.toString() == "1";

      if (isActive) {
        return offerMap;
      }

      return null;
    }

    // Case 2: offer_details is list
    if (offers is List && offers.isNotEmpty) {
      for (final offer in offers) {
        if (offer is Map) {
          final Map<String, dynamic> offerMap = Map<String, dynamic>.from(
            offer,
          );

          final dynamic activeValue = offerMap["is_active"];

          final bool isActive =
              activeValue == true ||
              activeValue.toString().toLowerCase() == "true" ||
              activeValue.toString() == "1";

          if (isActive) {
            return offerMap;
          }
        }
      }
    }

    return null;
  }

  String _getOfferTitle() {
    final offer = _getActiveOffer();

    if (offer == null) return "";

    final title = offer["title"]?.toString().trim() ?? "";
    final message = offer["message"]?.toString().trim() ?? "";

    debugPrint("ACTIVE OFFER TITLE: $title");
    debugPrint("ACTIVE OFFER MESSAGE: $message");

    if (title.isNotEmpty && title.toLowerCase() != "null") return title;
    if (message.isNotEmpty && message.toLowerCase() != "null") return message;

    return "";
  }

  bool _hasActiveOffer() {
    return _getOfferTitle().isNotEmpty;
  }

  Widget _compactOfferRibbonBadgeFromTitle(String title) {
    final String cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipPath(
      clipper: _ExactOfferRibbonClipper(),
      child: Container(
        height: 24,
        width: 92,
        padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
        alignment: Alignment.centerLeft,
        color: const Color.fromARGB(255, 55, 210, 194),
        child: Text(
          _formatOfferText(cleanTitle),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontFamily: 'Poppins',
            height: 1,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _offerRibbonBadgeFromTitle(String title) {
    final String cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipPath(
      clipper: _ExactOfferRibbonClipper(),
      child: Container(
        height: 30,
        width: 128,
        padding: const EdgeInsets.fromLTRB(10, 0, 22, 0),
        alignment: Alignment.centerLeft,
        color: const Color.fromARGB(255, 55, 210, 194),
        child: Text(
          _formatOfferText(cleanTitle),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: 'Poppins',
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  void _showFloatingAnimation(Offset startPosition, String imageUrl) {
    _removeOverlay();
    RenderBox? cartBox =
        _cartIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (cartBox == null) return;

    Offset cartPosition = cartBox.localToGlobal(Offset.zero);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            double progress = _animationController.value;

            double currentX =
                startPosition.dx +
                (cartPosition.dx - startPosition.dx + 20) * progress;
            double currentY =
                startPosition.dy +
                (cartPosition.dy - startPosition.dy - 10) * progress;

            double arcOffset = sin(progress * pi) * 50;
            currentY -= arcOffset;
            return Positioned(
              left: currentX - 30,
              top: currentY - 30,
              child: Transform.scale(
                scale: 1.0 + (0.2 * sin(progress * pi)),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.tealAccent.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);

    _animationController.forward().then((_) {
      _removeOverlay();
      _animationController.reset();
      _isAnimating = false;

      _animateCartIcon();
    });
  }

  void _animateCartIcon() {}

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

  Future<void> fetchSimilarProducts(int categoryId) async {
    try {
      print("FETCH SIMILAR PRODUCTS STARTED FOR CATEGORY: $categoryId");

      if (!mounted) return;

      setState(() {
        similarProductsLoading = true;
        similarProducts = [];
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        print("Similar products token is null");

        if (!mounted) return;
        setState(() {
          similarProductsLoading = false;
        });
        return;
      }

      final url = "$api/api/myskates/products/by/category/$categoryId/";
      print("Similar products URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      print("Similar products status: ${response.statusCode}");
      print("Similar products raw response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> rawProducts = [];

        if (decoded is List) {
          rawProducts = decoded;
        } else if (decoded is Map && decoded["data"] is List) {
          rawProducts = decoded["data"];
        } else if (decoded is Map && decoded["results"] is List) {
          rawProducts = decoded["results"];
        }

        print("RAW SIMILAR PRODUCTS COUNT: ${rawProducts.length}");

        final List<Map<String, dynamic>> fetchedProducts = rawProducts
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) {
              final int? itemId = int.tryParse(item["id"].toString());
              final String approvalStatus =
                  item["approval_status"]?.toString().toLowerCase() ?? "";

              return itemId != null &&
                  itemId != widget.productId &&
                  approvalStatus == "approved";
            })
            .toList();

        print("CURRENT PRODUCT ID: ${widget.productId}");
        print("FILTERED SIMILAR PRODUCTS COUNT: ${fetchedProducts.length}");
        print("FILTERED SIMILAR PRODUCTS DATA: $fetchedProducts");

        if (!mounted) return;

        setState(() {
          similarProducts = fetchedProducts;
          similarProductsLoading = false;
        });
      } else {
        print("Similar products API failed: ${response.statusCode}");

        if (!mounted) return;
        setState(() {
          similarProductsLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching similar products: $e");

      if (!mounted) return;

      setState(() {
        similarProductsLoading = false;
      });
    }
  }

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    final text = value.toString().trim();
    return text.isNotEmpty && text.toLowerCase() != "null";
  }

  bool _hasProductDescription(String description) {
    return _hasValue(description);
  }

  bool _hasReviews() {
    return approvedReviews.isNotEmpty;
  }

  bool _hasSimilarProducts() {
    return similarProducts.isNotEmpty;
  }

  Future<void> fetchProductReviews() async {
    setState(() {
      reviewsLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse('$api/api/myskates/products/${widget.productId}/ratings/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Reviews API Status: ${response.statusCode}');
      print('Reviews API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Review> fetchedReviews = [];

        if (data is List) {
          fetchedReviews = data.map((r) => Review.fromJson(r)).toList();
        } else if (data['success'] == true && data['data'] != null) {
          fetchedReviews = (data['data'] as List)
              .map((r) => Review.fromJson(r))
              .toList();
        }

        final approved = fetchedReviews
            .where((r) => r.approvalStatus == 'approved')
            .toList();

        if (approved.isNotEmpty) {
          double total = 0;
          for (var review in approved) {
            total += review.rating;
          }
          averageRating = total / approved.length;
          totalReviews = approved.length;
        } else {
          averageRating = 0;
          totalReviews = 0;
        }

        setState(() {
          allReviews = fetchedReviews;
          approvedReviews = approved;
          reviewsLoading = false;
          print("Approved reviews: ${approvedReviews.length}");
        });
      } else {
        setState(() {
          reviewsLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      setState(() {
        reviewsLoading = false;
      });
    }
  }

  int _getPendingReviewCount() {
    return allReviews.where((r) => r.approvalStatus == 'pending').length;
  }

  Future<void> addToCart(int variantId) async {
    if (_isAnimating) return;

    if (selectedVariant == null) {
      _showSnackBar(
        icon: Icons.info_outline,
        color: Colors.orangeAccent,
        background: const Color(0xFF2A230F),
        message: "Please select a variant",
      );
      return;
    }

    final int stock =
        int.tryParse(
          (selectedVariant!["stock"] ?? selectedVariant!["quantity"] ?? "0")
              .toString(),
        ) ??
        0;

    if (stock <= 0) {
      _showSnackBar(
        icon: Icons.remove_shopping_cart_outlined,
        color: Colors.redAccent,
        background: const Color(0xFF2A0F0F),
        message: "Selected variant is out of stock",
      );
      return;
    }

    RenderBox? renderBox =
        _variantImageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      debugPrint("⚠️ Variant image key not founddd");
      await _callAddToCartAPI(variantId);
      return;
    }

    Offset position = renderBox.localToGlobal(Offset.zero);

    String imageUrl = selectedVariant?["images"]?.isNotEmpty == true
        ? selectedVariant!["images"][0]["image"]
        : product!["image"];

    _isAnimating = true;

    _showFloatingAnimation(position, imageUrl);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final response = await http.post(
        Uri.parse('$api/api/myskates/cart/item/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"variant_id": variantId, "quantity": 1}),
      );

      debugPrint('Add to cart response status: ${response.statusCode}');
      debugPrint('Add to cart response body: ${response.body}');

      final decoded = jsonDecode(response.body);
      final String message = decoded["message"] ?? "Unable to add to cart";

      if (response.statusCode == 200 || response.statusCode == 201) {
        await CartCountNotifier.refreshCartCount();
        Future.delayed(const Duration(milliseconds: 800), () {
          _showSnackBar(
            icon: Icons.shopping_cart,
            color: Colors.tealAccent,
            background: const Color(0xFF0F2F2B),
            message: message,
          );
        });
      } else {
        _isAnimating = false;
        _animationController.stop();
        _removeOverlay();
        _showSnackBar(
          icon: Icons.warning_amber_rounded,
          color: Colors.orangeAccent,
          background: const Color(0xFF2A230F),
          message: message,
        );
      }
    } catch (e) {
      _isAnimating = false;
      _animationController.stop();
      _removeOverlay();
      debugPrint("Add to cart error: $e");
    }
  }

  Future<void> _callAddToCartAPI(int variantId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final response = await http.post(
        Uri.parse('$api/api/myskates/cart/item/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"variant_id": variantId, "quantity": 1}),
      );

      final decoded = jsonDecode(response.body);
      final message = decoded["message"] ?? "Added to cart";

      if (response.statusCode == 200 || response.statusCode == 201) {
        await CartCountNotifier.refreshCartCount();
      }

      _showSnackBar(
        icon: Icons.shopping_cart,
        color: Colors.tealAccent,
        background: const Color(0xFF0F2F2B),
        message: message,
      );
    } catch (e) {
      debugPrint("Add to cart error: $e");
    }
  }

  List<String> getSelectedVariantAttributes() {
    if (selectedVariant == null || selectedVariant!["attributes"] == null) {
      return [];
    }

    List<String> values = [];

    for (var attr in selectedVariant!["attributes"]) {
      for (var v in attr["values"]) {
        values.add("${attr["name"]}: ${v["name"]}");
      }
    }

    return values;
  }

  void _showSnackBar({
    required IconData icon,
    required Color color,
    required Color background,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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
      ),
    );
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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
      print('Error: $e');
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

  Future<void> getproductDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        print("Product details token is null");
        if (!mounted) return;
        setState(() => loading = false);
        return;
      }

      final res = await http.get(
        Uri.parse("$api/api/myskates/products/full/${widget.productId}/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("Product details status: ${res.statusCode}");
      print("Product details response: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        final Map<String, dynamic> productData = Map<String, dynamic>.from(
          decoded["data"],
        );

        final int? categoryId = int.tryParse(
          productData["category"]?.toString() ?? "",
        );

        print("CATEGORY ID FROM PRODUCT DETAILS: $categoryId");
        print("resss ${res.body}");

        if (!mounted) return;

        setState(() {
          product = productData;
          isInWishlist = product!["is_in_wishlist"] == true;

          if ((product!["variants"] ?? []).isNotEmpty) {
            selectedVariant = product!["variants"][0];
            selectedVariantId = selectedVariant!["id"];
          }

          loading = false;
        });

        if (categoryId != null) {
          await fetchSimilarProducts(categoryId);
        } else {
          print("Category id is null. Similar products API not called.");
        }
      } else {
        if (!mounted) return;
        setState(() => loading = false);
      }
    } catch (e) {
      print("Product details error: $e");

      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  List get variants => product?["variants"] ?? [];

  void _handleUpdateProduct() {
    Navigator.push(context, slideRightToLeftRoute(Wishlist()));
  }

  List<String> getSelectedVariantValuesOnly() {
    if (selectedVariant == null || selectedVariant!["attributes"] == null) {
      return [];
    }

    List<String> values = [];

    for (var attr in selectedVariant!["attributes"]) {
      for (var v in attr["values"]) {
        values.add(v["name"]);
      }
    }

    return values;
  }

  Widget _buildSimilarProductsSection() {
    if (similarProductsLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          height: 245,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, __) {
              return SkeletonBox(
                height: 245,
                width: 160,
                borderRadius: BorderRadius.circular(18),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemCount: 4,
          ),
        ),
      );
    }

    if (similarProducts.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  "SIMILAR PRODUCTS",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: Colors.greenAccent.withOpacity(0.18),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 255,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: similarProducts.length,
              itemBuilder: (context, index) {
                final item = similarProducts[index];

                final String imageUrl = _buildImageUrl(item["image"]);
                final String title = item["title"]?.toString() ?? "";
                final String categoryName =
                    item["category_name"]?.toString() ?? "";
                final double price =
                    double.tryParse(item["price"]?.toString() ?? "0") ?? 0.0;
                final double discountedPrice =
                    double.tryParse(
                      item["discounted_price"]?.toString() ?? "0",
                    ) ??
                    0.0;
                final double discount =
                    double.tryParse(item["discount"]?.toString() ?? "0") ?? 0.0;
                final bool wishlisted = item["is_in_wishlist"] == true;
                final String similarOfferTitle = _getOfferTitleFromProductItem(
                  item,
                );
                final bool hasSimilarOffer = similarOfferTitle.isNotEmpty;

                return GestureDetector(
                  onTap: () async {
                    final int? nextProductId = int.tryParse(
                      item["id"].toString(),
                    );

                    if (nextProductId == null) return;

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => big_view(productId: nextProductId),
                      ),
                    );

                    CartCountNotifier.refreshCartCount();
                  },
                  child: Container(
                    width: 165,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 10,
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
                                top: Radius.circular(18),
                              ),
                              child: Container(
                                height: 135,
                                width: double.infinity,
                                color: Colors.black,
                                child: imageUrl.isEmpty
                                    ? const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.white38,
                                        size: 34,
                                      )
                                    : Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.broken_image,
                                                color: Colors.white38,
                                                size: 34,
                                              );
                                            },
                                      ),
                              ),
                            ),

                            // DISCOUNT BADGE (TOP LEFT)
                            if (discount > 0)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${discount.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'OFF',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (hasSimilarOffer)
                              Positioned(
                                top: discount > 0 ? 48 : 8,
                                left: 8,
                                child: _compactOfferRibbonBadgeFromTitle(
                                  similarOfferTitle,
                                ),
                              ),

                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () async {
                                  final int productId =
                                      int.tryParse(item["id"].toString()) ?? 0;
                                  if (productId == 0) return;

                                  await addwishlist(productId, context);
                                  setState(() {
                                    item['is_in_wishlist'] =
                                        !(item['is_in_wishlist'] == true);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Icon(
                                    wishlisted
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: wishlisted
                                        ? Colors.tealAccent
                                        : Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F2F2B),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.greenAccent.withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  categoryName.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  height: 1.3,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Price section with discount
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Original price with strikethrough
                                  Text(
                                    "₹${price.toStringAsFixed(0)}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.redAccent,
                                      decorationThickness: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Discounted price
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "₹${discountedPrice.toStringAsFixed(0)}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Discount badge
                                      if (discount > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.redAccent
                                                  .withOpacity(0.4),
                                            ),
                                          ),
                                          child: Text(
                                            "${discount.toStringAsFixed(0)}% OFF",
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.visibility_outlined,
                                    color: Colors.white54,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "View product",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.62),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _doesDescriptionOverflow(String text, double maxWidth, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 5,
      textDirection: TextDirection.ltr,
      ellipsis: '...',
    );

    textPainter.layout(maxWidth: maxWidth);
    return textPainter.didExceedMaxLines;
  }

  Widget _buildProductDescription(String description) {
    const descriptionStyle = TextStyle(
      color: Colors.white70,
      fontSize: 14,
      height: 1.6,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isOverflowing = _doesDescriptionOverflow(
          description,
          constraints.maxWidth,
          descriptionStyle,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: descriptionStyle,
              maxLines: _isDescriptionExpanded ? null : 5,
              overflow: _isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
            if (isOverflowing)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isDescriptionExpanded = !_isDescriptionExpanded;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.greenAccent,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _isDescriptionExpanded ? 'See less' : 'See more',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 50),
          const SizedBox(height: 12),
          const Text(
            "Something went wrong",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {
                loading = true;
              });
              getproductDetails();
              fetchProductReviews();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(String imageUrl) {
    final TransformationController transformationController =
        TransformationController();

    bool isZoomed = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                children: [
                  SizedBox.expand(
                    child: GestureDetector(
                      onDoubleTap: () {
                        if (isZoomed) {
                          transformationController.value = Matrix4.identity();
                          setDialogState(() {
                            isZoomed = false;
                          });
                        } else {
                          transformationController.value = Matrix4.identity()
                            ..scale(2.5);
                          setDialogState(() {
                            isZoomed = true;
                          });
                        }
                      },
                      child: InteractiveViewer(
                        transformationController: transformationController,
                        minScale: 1.0,
                        maxScale: 4.0,
                        panEnabled: isZoomed,
                        boundaryMargin: const EdgeInsets.all(200),
                        constrained: true,
                        onInteractionUpdate: (_) {
                          final scale = transformationController.value
                              .getMaxScaleOnAxis();
                          if (scale > 1.01 && !isZoomed) {
                            setDialogState(() {
                              isZoomed = true;
                            });
                          } else if (scale <= 1.01 && isZoomed) {
                            setDialogState(() {
                              isZoomed = false;
                            });
                          }
                        },
                        onInteractionEnd: (_) {
                          final scale = transformationController.value
                              .getMaxScaleOnAxis();
                          setDialogState(() {
                            isZoomed = scale > 1.01;
                          });
                        },
                        child: Center(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 60,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
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

  void _showAllReviewsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Reviews ($totalReviews)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: approvedReviews.length,
                  itemBuilder: (context, index) {
                    return ReviewCard(review: approvedReviews[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget buildTopIconButton({
      required IconData icon,
      required VoidCallback onTap,
      Widget? badge,
      Key? key,
    }) {
      return GestureDetector(
        key: key,
        onTap: onTap,
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              if (badge != null) badge,
            ],
          ),
        ),
      );
    }

    Widget buildPanel({required Widget child, EdgeInsetsGeometry? padding}) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF101312),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      );
    }

    Widget buildInfoChip({
      required IconData icon,
      required String title,
      required String value,
      Color color = Colors.tealAccent,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.48),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildScrollableHeader() {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 12,
          16,
          12,
        ),
        child: Row(
          children: [
            buildTopIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Product Details",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Poppins',
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    loading || product == null
                        ? "Loading product information"
                        : "View product information",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.52),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            buildTopIconButton(
              icon: Icons.favorite_border_rounded,
              onTap: _handleUpdateProduct,
            ),
            const SizedBox(width: 10),
            ValueListenableBuilder<int>(
              valueListenable: CartCountNotifier.cartCount,
              builder: (context, count, _) {
                return buildTopIconButton(
                  key: _cartIconKey,
                  icon: Icons.shopping_bag_outlined,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const cart()),
                    );
                    CartCountNotifier.refreshCartCount();
                  },
                  badge: count > 0
                      ? Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 17,
                              minHeight: 17,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "$count",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
          ],
        ),
      );
    }

    VoidCallback addToCartAction() {
      return () {
        if (variants.isEmpty) {
          _showSnackBar(
            icon: Icons.info_outline,
            color: Colors.orangeAccent,
            background: const Color(0xFF2A230F),
            message: "This product has no variants available",
          );
          return;
        }

        if (selectedVariantId == null || selectedVariant == null) {
          _showSnackBar(
            icon: Icons.info_outline,
            color: Colors.orangeAccent,
            background: const Color(0xFF2A230F),
            message: "Please select a variant",
          );
          return;
        }

        final int stock =
            int.tryParse(
              (selectedVariant!["stock"] ?? selectedVariant!["quantity"] ?? "0")
                  .toString(),
            ) ??
            0;

        if (stock <= 0) {
          _showSnackBar(
            icon: Icons.remove_shopping_cart_outlined,
            color: Colors.redAccent,
            background: const Color(0xFF2A0F0F),
            message: "Selected variant is out of stock",
          );
          return;
        }

        addToCart(selectedVariantId!);
      };
    }

    return Scaffold(
      backgroundColor: const Color(0xFF030706),
      extendBodyBehindAppBar: false,
      bottomNavigationBar: loading || product == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF050706),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.65),
                      blurRadius: 22,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Selected Price",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.48),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "₹${_getDiscountedPrice().toStringAsFixed(2)}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(58),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: addToCartAction(),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 21),
                        label: const Text(
                          "Add to Cart",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00332F), Color(0xFF020403), Color(0xFF000000)],
            stops: [0.0, 0.34, 1.0],
          ),
        ),
        child: loading
            ? _buildSkeleton()
            : product == null
            ? _buildErrorWidget()
            : SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                child: Builder(
                  builder: (context) {
                    final rawDisplayImage =
                        (selectedVariant?["images"] != null &&
                            selectedVariant!["images"].isNotEmpty)
                        ? selectedVariant!["images"][0]["image"]
                        : product!["image"];

                    final displayImage = _buildImageUrl(rawDisplayImage);

                    final variantValues = getSelectedVariantValuesOnly();

                    final displayTitle =
                        selectedVariant != null && variantValues.isNotEmpty
                        ? "${product!["title"]} (${variantValues.join(" / ")})"
                        : product!["title"]?.toString() ?? "";

                    final displayDescription =
                        selectedVariant?["description"]?.toString().trim() ??
                        product!["description"]?.toString().trim() ??
                        "";

                    final seller =
                        selectedVariant?["seller_name"]?.toString().trim() ??
                        product!["seller_name"]?.toString().trim() ??
                        "";

                    final double originalPrice = _getOriginalPrice();
                    final double discountedPrice = _getDiscountedPrice();
                    final double savedAmount = originalPrice - discountedPrice;
                    final bool hasDiscount =
                        _getDiscount() > 0 && savedAmount > 0;

                    final String offerTitle = _getOfferTitle();
                    final bool hasActiveOffer = offerTitle.isNotEmpty;

                    debugPrint("UI OFFER TITLE: $offerTitle");
                    debugPrint("UI HAS ACTIVE OFFER: $hasActiveOffer");
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildScrollableHeader(),

                        const SizedBox(height: 4),

                        // ================= PRODUCT IMAGE =================
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                          height: 430,
                          decoration: BoxDecoration(
                            color: const Color(0xFF101312),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.36),
                                blurRadius: 22,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Hero(
                                    tag:
                                        "product_${widget.productId}_$displayImage",
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: GestureDetector(
                                        key: ValueKey(displayImage),
                                        onTap: () =>
                                            _openImageViewer(displayImage),
                                        child: displayImage.isEmpty
                                            ? Container(
                                                color: const Color(0xFF111111),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    color: Colors.white38,
                                                    size: 48,
                                                  ),
                                                ),
                                              )
                                            : Image.network(
                                                displayImage,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        color: const Color(
                                                          0xFF111111,
                                                        ),
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            color:
                                                                Colors.white54,
                                                            size: 48,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                              ),
                                      ),
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
                                            Colors.black.withOpacity(0.05),
                                            Colors.black.withOpacity(0.04),
                                            Colors.black.withOpacity(0.64),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (hasDiscount)
                                  Positioned(
                                    top: 16,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.redAccent.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        "${_getDiscountPercentage()}% OFF",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ),

                                if (hasActiveOffer)
                                  Positioned(
                                    top: hasDiscount ? 56 : 18,
                                    left: 16,
                                    child: _offerRibbonBadgeFromTitle(
                                      offerTitle,
                                    ),
                                  ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          await addwishlist(
                                            product!["id"],
                                            context,
                                          );
                                          setState(() {
                                            isInWishlist = !isInWishlist;
                                            product!["is_in_wishlist"] =
                                                isInWishlist;
                                          });
                                        },
                                        child: Container(
                                          height: 44,
                                          width: 44,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.58,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.12,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            isInWishlist
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            color: isInWishlist
                                                ? Colors.tealAccent
                                                : Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          height: 44,
                                          width: 44,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.58,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.12,
                                              ),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.ios_share_rounded,
                                            color: Colors.white,
                                            size: 21,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: 18,
                                  right: 18,
                                  bottom: 18,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Tap image to zoom",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.58,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ================= PRODUCT INFO CARD =================
                        // ================= PRODUCT INFO CARD =================
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF111C1A), Color(0xFF090D0C)],
                            ),
                            border: Border.all(color: Colors.white10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.32),
                                blurRadius: 22,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  18,
                                  0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          height: 1.22,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'Poppins',
                                          letterSpacing: -0.35,
                                        ),
                                      ),
                                    ),
                                    if (hasDiscount) ...[
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(
                                            0.16,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: Colors.redAccent.withOpacity(
                                              0.42,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          "${_getDiscountPercentage()}% OFF",
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'Poppins',
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              if (seller.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.045),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.075),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 28,
                                          width: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.tealAccent
                                                .withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.storefront_rounded,
                                            color: Colors.tealAccent,
                                            size: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            "Sold by $seller",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.68,
                                              ),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              if (hasActiveOffer) ...[
                                const SizedBox(height: 14),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orangeAccent.withOpacity(0.22),
                                          Colors.amberAccent.withOpacity(0.12),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.orangeAccent.withOpacity(
                                          0.42,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 34,
                                          width: 34,
                                          decoration: BoxDecoration(
                                            color: Colors.orangeAccent
                                                .withOpacity(0.18),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.card_giftcard_rounded,
                                            color: Colors.orangeAccent,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Active Offer",
                                                style: TextStyle(
                                                  color: Colors.orangeAccent,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                offerTitle,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                  fontFamily: 'Poppins',
                                                  height: 1.25,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 18),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.28),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: Colors.tealAccent.withOpacity(
                                        0.18,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Special Price",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.48),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "₹${discountedPrice.toStringAsFixed(2)}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.tealAccent,
                                                fontSize: 34,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -1.0,
                                              ),
                                            ),
                                          ),
                                          if (hasDiscount) ...[
                                            const SizedBox(width: 10),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: Text(
                                                "₹${originalPrice.toStringAsFixed(2)}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.42),
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Poppins',
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  decorationColor: Colors.white
                                                      .withOpacity(0.5),
                                                  decorationThickness: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (hasDiscount) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              height: 30,
                                              width: 30,
                                              decoration: BoxDecoration(
                                                color: Colors.greenAccent
                                                    .withOpacity(0.13),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.savings_outlined,
                                                color: Colors.greenAccent,
                                                size: 17,
                                              ),
                                            ),
                                            const SizedBox(width: 9),
                                            Expanded(
                                              child: Text(
                                                "You save ₹${savedAmount.toStringAsFixed(2)} on this product",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.greenAccent,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w800,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  0,
                                  18,
                                  18,
                                ),
                                child: Row(
                                  children: [
                                    if (totalReviews > 0)
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 11,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amberAccent
                                                .withOpacity(0.10),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: Colors.amberAccent
                                                  .withOpacity(0.28),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                color: Colors.amberAccent,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 7),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${averageRating.toStringAsFixed(1)} Rating",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color:
                                                            Colors.amberAccent,
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      "$totalReviews reviews",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.48),
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    if (totalReviews > 0)
                                      const SizedBox(width: 10),

                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 11,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.tealAccent.withOpacity(
                                            0.10,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: Colors.tealAccent
                                                .withOpacity(0.28),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.verified_user_outlined,
                                              color: Colors.tealAccent,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 7),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Quality",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors.tealAccent,
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "Assured",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.48),
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    if (_getShipmentCharge() != null) ...[
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 11,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.tealAccent
                                                .withOpacity(0.10),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: Colors.tealAccent
                                                  .withOpacity(0.28),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.local_shipping_outlined,
                                                color: Colors.tealAccent,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 7),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      "Delivery",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color:
                                                            Colors.tealAccent,
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _isFreeShipping()
                                                          ? "Free"
                                                          : "₹${_getShipmentCharge()!.toStringAsFixed(2)}",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.48),
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ================= VARIANTS =================
                        if (variants.isNotEmpty) ...[
                          _buildSectionHeader(
                            "Select Variant",
                            subtitle: "Pick your preferred size, color or SKU",
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 214,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: variants.length,
                              itemBuilder: (context, index) {
                                final variant = variants[index];

                                final int stock =
                                    int.tryParse(
                                      (variant["stock"] ??
                                              variant["quantity"] ??
                                              "0")
                                          .toString(),
                                    ) ??
                                    0;
                                final bool isOutOfStock = stock <= 0;
                                final bool isSelected =
                                    selectedVariantId == variant["id"];

                                final List<String> values = [];
                                if (variant["attributes"] != null) {
                                  for (var attr in variant["attributes"]) {
                                    for (var v in attr["values"]) {
                                      values.add(v["name"]);
                                    }
                                  }
                                }

                                final rawVariantImage =
                                    (variant["images"] != null &&
                                        variant["images"].isNotEmpty)
                                    ? variant["images"][0]["image"]
                                    : product!["image"];
                                final String imageUrl = _buildImageUrl(
                                  rawVariantImage,
                                );
                                final String variantOfferTitle =
                                    _getVariantOfferTitle(
                                      Map<String, dynamic>.from(variant),
                                    );

                                final bool hasVariantOffer =
                                    variantOfferTitle.isNotEmpty &&
                                    !isOutOfStock;

                                return GestureDetector(
                                  onTap: isOutOfStock
                                      ? null
                                      : () {
                                          setState(() {
                                            selectedVariantId = variant["id"];
                                            selectedVariant = variant;
                                            _isDescriptionExpanded = false;
                                          });

                                          Future.delayed(
                                            const Duration(milliseconds: 50),
                                            () {
                                              _scrollController.animateTo(
                                                0,
                                                duration: const Duration(
                                                  milliseconds: 220,
                                                ),
                                                curve: Curves.easeInOut,
                                              );
                                            },
                                          );
                                        },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    key: isSelected ? _variantImageKey : null,
                                    width: 158,
                                    margin: const EdgeInsets.only(right: 14),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF102B27)
                                          : const Color(0xFF101312),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: isOutOfStock
                                            ? Colors.white.withOpacity(0.08)
                                            : isSelected
                                            ? Colors.tealAccent
                                            : Colors.white.withOpacity(0.10),
                                        width: isSelected ? 1.4 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.tealAccent
                                                    .withOpacity(0.12),
                                                blurRadius: 16,
                                                offset: const Offset(0, 8),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    height: 98,
                                                    width: double.infinity,
                                                    color: Colors.black,
                                                    child: imageUrl.isEmpty
                                                        ? const Icon(
                                                            Icons
                                                                .image_not_supported_outlined,
                                                            color:
                                                                Colors.white38,
                                                          )
                                                        : Image.network(
                                                            imageUrl,
                                                            fit: BoxFit.cover,
                                                            color: isOutOfStock
                                                                ? Colors.grey
                                                                      .withOpacity(
                                                                        0.60,
                                                                      )
                                                                : null,
                                                            colorBlendMode:
                                                                isOutOfStock
                                                                ? BlendMode
                                                                      .saturation
                                                                : null,
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return const Icon(
                                                                    Icons
                                                                        .broken_image,
                                                                    color: Colors
                                                                        .white38,
                                                                  );
                                                                },
                                                          ),
                                                  ),

                                                  if (hasVariantOffer)
                                                    Positioned(
                                                      top: 8,
                                                      left: 0,
                                                      child: Transform.scale(
                                                        scale: 0.72,
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child:
                                                            _compactOfferRibbonBadgeFromTitle(
                                                              variantOfferTitle,
                                                            ),
                                                      ),
                                                    ),
                                                  if (isOutOfStock)
                                                    Positioned.fill(
                                                      child: Container(
                                                        color: Colors.black
                                                            .withOpacity(0.55),
                                                        alignment:
                                                            Alignment.center,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .redAccent,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                          child: const Text(
                                                            "OUT",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              variant["sku"]?.toString() ?? "",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isOutOfStock
                                                    ? Colors.white38
                                                    : Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'Poppins',
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              values.isEmpty
                                                  ? "Default variant"
                                                  : values.join(" / "),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isOutOfStock
                                                    ? Colors.white30
                                                    : Colors.white60,
                                                fontSize: 10.5,
                                                height: 1.25,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),

                                            const Spacer(),
                                            Text(
                                              "₹${variant["price"] ?? product!["base_price"]}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isOutOfStock
                                                    ? Colors.white38
                                                    : Colors.tealAccent,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              height: 24,
                                              width: 24,
                                              decoration: const BoxDecoration(
                                                color: Colors.tealAccent,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.black,
                                                size: 15,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],

                        // ================= DESCRIPTION =================
                        if (_hasProductDescription(displayDescription)) ...[
                          _buildSectionHeader("Product Description"),
                          const SizedBox(height: 12),
                          buildPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProductDescription(displayDescription),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],

                        _buildSimilarProductsSection(),

                        const SizedBox(height: 16),

                        // ================= USER REVIEWS =================
                        if (!reviewsLoading && _hasReviews()) ...[
                          _buildSectionHeader("Customer Reviews"),
                          const SizedBox(height: 12),
                          buildPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RatingSummary(
                                  averageRating: averageRating,
                                  totalReviews: totalReviews,
                                  onViewAllPressed: () =>
                                      _showAllReviewsDialog(),
                                ),
                                const SizedBox(height: 16),
                                ...approvedReviews
                                    .take(3)
                                    .map(
                                      (review) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: ReviewCard(review: review),
                                      ),
                                    ),
                                if (approvedReviews.length > 3)
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: () => _showAllReviewsDialog(),
                                      icon: const Icon(
                                        Icons.rate_review_outlined,
                                        size: 16,
                                      ),
                                      label: Text(
                                        "View all ${approvedReviews.length} reviews",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.tealAccent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  // Helper methods for price calculations
  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  double _getOriginalPrice() {
    if (selectedVariant != null) {
      return _toDouble(selectedVariant!['price']);
    }
    return _toDouble(product?['base_price']);
  }

  double _getDiscountedPrice() {
    if (selectedVariant != null &&
        selectedVariant!['discounted_price'] != null) {
      return _toDouble(selectedVariant!['discounted_price']);
    }

    final original = _getOriginalPrice();
    final discountPercent = _getDiscount();

    if (discountPercent > 0) {
      return original - ((original * discountPercent) / 100);
    }

    return original;
  }

  double _getDiscount() {
    if (selectedVariant != null) {
      return _toDouble(selectedVariant!['discount']);
    }
    return 0;
  }

  String _getDiscountPercentage() {
    final discount = _getDiscount();
    return discount.toStringAsFixed(
      discount.truncateToDouble() == discount ? 0 : 1,
    );
  }

  double? _getShipmentCharge() {
    if (product == null) return null;
    return _toDouble(product!['shipment_charge']);
  }

  bool _isFreeShipping() {
    final charge = _getShipmentCharge();
    return charge != null && charge <= 0;
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE SKELETON
          const SkeletonBox(
            height: 360,
            width: double.infinity,
            borderRadius: BorderRadius.zero,
          ),

          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SkeletonBox(
                height: 80,
                width: double.infinity,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 22, width: 220),
                SizedBox(height: 12),
                SkeletonBox(height: 14, width: double.infinity),
                SizedBox(height: 8),
                SkeletonBox(height: 14, width: double.infinity),
                SizedBox(height: 8),
                SkeletonBox(height: 14, width: 260),
                SizedBox(height: 30),

                SkeletonBox(height: 14, width: 160),
                SizedBox(height: 16),
              ],
            ),
          ),

          // VARIANT SKELETON
          SizedBox(
            height: 190,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, __) =>
                  const SkeletonBox(height: 190, width: 150),
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemCount: 3,
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    required this.height,
    required this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: borderRadius,
      ),
    );
  }
}

// Review Card Widget
class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    if (review.approvalStatus != 'approved') return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                  if (review.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: Colors.greenAccent,
                    ),
                  ],
                ],
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating.round()
                        ? Icons.star
                        : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(review.createdAt),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          if (review.comment.isNotEmpty)
            Text(
              review.comment,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
                fontFamily: 'Poppins',
              ),
            )
          else
            const Text(
              'No written review',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// Rating Summary Widget
class RatingSummary extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final VoidCallback onViewAllPressed;

  const RatingSummary({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < averageRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          TextButton.icon(
            onPressed: onViewAllPressed,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('View All'),
            style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
          ),
        ],
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
    path.lineTo(size.width - 9, size.height / 2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

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

  List<Review> allReviews = [];
  List<Review> approvedReviews = [];

  // Review variables
  List<Review> reviews = [];
  bool reviewsLoading = false;
  double averageRating = 0;
  int totalReviews = 0;
  bool isInWishlist = false;
  final ScrollController _scrollController = ScrollController();
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
        final json = jsonDecode(res.body);

        print("resss ${res.body}");

        setState(() {
          product = json["data"];
          isInWishlist = product!["is_in_wishlist"] == true;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
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
                  Center(
                    child: GestureDetector(
                      onDoubleTap: () {
                        if (isZoomed) {
                          transformationController.value = Matrix4.identity();
                          setDialogState(() {
                            isZoomed = false;
                          });
                        } else {
                          transformationController.value = Matrix4.identity()
                            ..scale(2.0);
                          setDialogState(() {
                            isZoomed = true;
                          });
                        }
                      },
                      child: InteractiveViewer(
                        transformationController: transformationController,
                        minScale: 1.0,
                        maxScale: 4.0,
                        panEnabled: true,
                        onInteractionUpdate: (_) {
                          final scale = transformationController.value
                              .getMaxScaleOnAxis();
                          setDialogState(() {
                            isZoomed = scale > 1.01;
                          });
                        },
                        onInteractionEnd: (_) {
                          final scale = transformationController.value
                              .getMaxScaleOnAxis();
                          setDialogState(() {
                            isZoomed = scale > 1.01;
                          });
                        },
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      // APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),

        actions: [
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

              Container(
                key: _cartIconKey,
                child: IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const cart()),
                    );
                    CartCountNotifier.refreshCartCount();
                  },
                  icon: ValueListenableBuilder<int>(
                    valueListenable: CartCountNotifier.cartCount,
                    builder: (context, count, _) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                          if (count > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  "$count",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),
            ],
          ),
        ],
      ),

      // BOTTOM CTA
      bottomNavigationBar: loading || product == null
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              color: Colors.black,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
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
                        (selectedVariant!["stock"] ??
                                selectedVariant!["quantity"] ??
                                "0")
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
                },

                child: const Text(
                  "ADD TO CART",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00312D), Color(0xFF000000)],
            stops: [0.0, 0.35],
          ),
        ),
        child: loading
            ? _buildSkeleton()
            : product == null
            ? _buildErrorWidget()
            : SingleChildScrollView(
                controller: _scrollController,
                child: Builder(
                  builder: (context) {
                    final displayImage =
                        (selectedVariant?["images"] != null &&
                            selectedVariant!["images"].isNotEmpty)
                        ? selectedVariant!["images"][0]["image"]
                        : product!["image"];

                    print("DISPLAY IMAGE URLLLLLLLL: $displayImage");

                    final displayPrice =
                        selectedVariant?["price"] ?? product!["base_price"];

                    final variantValues = getSelectedVariantValuesOnly();

                    final displayTitle =
                        selectedVariant != null && variantValues.isNotEmpty
                        ? "${product!["title"]} (${variantValues.join(" / ")})"
                        : product!["title"];

                    final displayDescription =
                        selectedVariant?["description"] ??
                        product!["description"];

                    print("imageeeeeeeeeee: $displayImage");

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ================= PRODUCT IMAGE =================
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(1),
                            child: Container(
                              color: Colors.black,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Hero(
                                      tag:
                                          "product_${widget.productId}_${displayImage}",
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: Container(
                                          key: ValueKey(displayImage),
                                          color: Colors.black,
                                          alignment: Alignment.center,
                                          child: GestureDetector(
                                            onTap: () =>
                                                _openImageViewer(displayImage),
                                            child: Image.network(
                                              displayImage,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.black,
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
                                    ),
                                  ),

                                  // RIGHT ICONS
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            await addwishlist(
                                              product!['id'],
                                              context,
                                            );
                                            setState(() {
                                              isInWishlist = !isInWishlist;
                                              product!['is_in_wishlist'] =
                                                  isInWishlist;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.6,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isInWishlist
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isInWishlist
                                                  ? Colors.tealAccent
                                                  : Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        GestureDetector(
                                          onTap: () {},
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.6,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.share,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ================= PRICE CARD =================
                        Transform.translate(
                          offset: const Offset(0, -30),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.greenAccent.withOpacity(.4),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "₹$displayPrice",
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 22,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                totalReviews > 0
                                    ? Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.greenAccent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            averageRating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            ' ($totalReviews)',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'No ratings',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),

                        // const SizedBox(height: 20),

                        // ================= TITLE =================
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            displayTitle.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ================= VARIANTS =================
                        if (variants.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Text(
                              "AVAILABLE VARIANTS",
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            height: 190,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: variants.length,
                              itemBuilder: (context, index) {
                                final variant = variants[index];

                                final List<String> values = [];
                                if (variant["attributes"] != null) {
                                  for (var attr in variant["attributes"]) {
                                    for (var v in attr["values"]) {
                                      values.add(v["name"]);
                                    }
                                  }
                                }

                                final String imageUrl =
                                    (variant["images"] != null &&
                                        variant["images"].isNotEmpty)
                                    ? variant["images"][0]["image"]
                                    : product!["image"];

                                print("VARIANT IMAGE URL: $imageUrl");

                                final bool isSelected =
                                    selectedVariantId == variant["id"];

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedVariantId = variant["id"];
                                      selectedVariant = variant;
                                    });

                                    Future.delayed(
                                      const Duration(milliseconds: 50),
                                      () {
                                        _scrollController.animateTo(
                                          0,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    key: selectedVariantId == variant["id"]
                                        ? _variantImageKey
                                        : null,
                                    width: 150,
                                    margin: const EdgeInsets.only(right: 14),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF0F2F2B)
                                          : const Color(0xFF121212),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.tealAccent
                                            : Colors.greenAccent.withOpacity(
                                                .3,
                                              ),
                                        width: isSelected ? 2 : .5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // IMAGE
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            height: 90,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        // SKU
                                        Text(
                                          variant["sku"] ?? "",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        // VALUES
                                        Expanded(
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: values.map((v) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(.3),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.greenAccent
                                                        .withOpacity(.4),
                                                  ),
                                                ),
                                                child: Text(
                                                  v,
                                                  style: const TextStyle(
                                                    color: Colors.greenAccent,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
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

                        SizedBox(height: 20),

                        // ================= DESCRIPTION =================
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(
                                color: Colors.greenAccent.withOpacity(.2),
                              ),

                              const SizedBox(height: 10),

                              const Text(
                                "PRODUCT DETAILS",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                displayDescription,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        SizedBox(height: 10),
                        // ================= USER REVIEWS =================
                        // Replace the Reviews section in the build method (around line 950) with this:

                        // ================= USER REVIEWS =================
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Divider(
                                color: Colors.greenAccent.withOpacity(.2),
                              ),
                              const SizedBox(height: 10),

                              // Reviews Header with conditional pending badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "CUSTOMER REVIEWS",
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),

                                  // Show pending badge ONLY for coaches and admins
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Admin/Coach Review Management Card

                              // Reviews Content
                              if (approvedReviews.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.reviews_outlined,
                                          size: 48,
                                          color: Colors.white24,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "No reviews yet",
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else ...[
                                // Rating Summary
                                RatingSummary(
                                  averageRating: averageRating,
                                  totalReviews: totalReviews,
                                  onViewAllPressed: () =>
                                      _showAllReviewsDialog(),
                                ),

                                const SizedBox(height: 14),

                                // Reviews List
                                if (reviewsLoading)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: [
                                      ...approvedReviews
                                          .take(3)
                                          .map(
                                            (review) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: ReviewCard(review: review),
                                            ),
                                          )
                                          .toList(),

                                      if (approvedReviews.length > 3)
                                        Center(
                                          child: TextButton(
                                            onPressed: () =>
                                                _showAllReviewsDialog(),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.greenAccent,
                                            ),
                                            child: Text(
                                              'View all ${approvedReviews.length} reviews',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
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

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/Viewall_product_Review.dart';
import 'package:my_skates/ADMIN/cart_view.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/wishlist.dart';
import 'package:my_skates/COACH/product_review_page.dart';
import 'package:my_skates/COACH/product_review_approval_page.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

  // Review variables
  List<Review> allReviews = [];
  List<Review> approvedReviews = [];
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

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    getproductDetails();
    fetchProductReviews();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt("id");
    final userType = prefs.getString("user_type");

    setState(() {
      _isCoach = userType == 'coach' || userType == 'admin';
      print("User is coach/admin: $_isCoach");
    });
  }

  @override
  void dispose() {
    super.dispose();
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

        // Filter only approved reviews for display
        final approved = fetchedReviews
            .where((r) => r.approvalStatus == 'approved')
            .toList();

        // Calculate average rating from approved reviews only
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

  Future<void> addToCart(int variantId) async {
    if (_isAnimating) return;

    RenderBox? renderBox =
        _variantImageKey.currentContext?.findRenderObject() as RenderBox?;
if (renderBox == null) {
  debugPrint("⚠️ Variant image key not found");

  // still call API without animation
  await _callAddToCartAPI(variantId);
  return;
}
    Offset position = renderBox.localToGlobal(Offset.zero);

    String imageUrl = selectedVariant?["images"]?.isNotEmpty == true
        ? selectedVariant!["images"][0]["image"]
        : product!["image"];

    _isAnimating = true;

    _showFloatingAnimation(position, imageUrl);

  Future<void> addToCart(int variantId) async {
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
        Future.delayed(const Duration(milliseconds: 800), () {
          _showSnackBar(
            icon: Icons.shopping_cart,
            color: Colors.tealAccent,
            background: const Color(0xFF0F2F2B),
            message: message,
          );
        });
      } else {
        _showSnackBar(
          icon: Icons.warning_amber_rounded,
          color: Colors.orangeAccent,
          background: const Color(0xFF2A230F),
          message: message,
        );
      }
    } catch (e) {
      debugPrint("Add to cart error: $e");

      // _showSnackBar(
      //   icon: Icons.error_outline,
      //   color: Colors.redAccent,
      //   background: const Color(0xFF2A0F0F),
      //   // message: "Something went wrong. Please try again.",
      // );
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
      body: jsonEncode({
        "variant_id": variantId,
        "quantity": 1,
      }),
    );

    final decoded = jsonDecode(response.body);
    final message = decoded["message"] ?? "Added to cart";

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
      print("$api/api/myskates/products/full/${widget.productId}/");
      final res = await http.get(
        Uri.parse("$api/api/myskates/products/full/${widget.productId}/"),
        headers: {"Authorization": "Bearer $token"},
      );
      print(res.body);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          product = json["data"];
          isInWishlist = product!["is_in_wishlist"] == true;
          loading = false;
        });
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  List get variants => product?["variants"] ?? [];

  void _handleUpdateProduct() {
    Navigator.push(context, slideRightToLeftRoute(Wishlist()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // APP BAR
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(color: Colors.white),

        actions: [
          // Row(
          //   children: [
          //     // Review Approval Button for Coaches
          //     if (_isCoach && _getPendingReviewCount() > 0)
          //       Stack(
          //         children: [
          //           IconButton(
          //             onPressed: () {
          //               Navigator.push(
          //                 context,
          //                 MaterialPageRoute(
          //                   builder: (_) => ProductReviewApprovalPage(
          //                     productId: widget.productId,
          //                     productName: product?["title"] ?? "Product",
          //                   ),
          //                 ),
          //               ).then((_) => fetchProductReviews());
          //             },
          //             icon: const Icon(
          //               Icons.reviews,
          //               color: Colors.white,
          //               size: 26,
          //             ),
          //           ),
          //           Positioned(
          //             right: 4,
          //             top: 4,
          //             child: Container(
          //               padding: const EdgeInsets.all(4),
          //               decoration: const BoxDecoration(
          //                 color: Colors.orange,
          //                 shape: BoxShape.circle,
          //               ),
          //               child: Text(
          //                 _getPendingReviewCount().toString(),
          //                 style: const TextStyle(
          //                   color: Colors.white,
          //                   fontSize: 10,
          //                   fontWeight: FontWeight.bold,
          //                 ),
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),

          //     IconButton(
          //       onPressed: () {
          //         _handleUpdateProduct();
          //       },
          //       icon: const Icon(
          //         Icons.favorite_border,
          //         color: Colors.white,
          //         size: 26,
          //       ),
          //     ),

          //     const SizedBox(width: 4),

          //     // Cart Icon
          //     Container(
          //       child: IconButton(
          //         onPressed: () {
          //           Navigator.push(
          //             context,
          //             MaterialPageRoute(builder: (context) => const cart()),
          //           );
          //         },
          //         icon: Stack(
          //           clipBehavior: Clip.none,
          //           children: [
          //             const Icon(
          //               Icons.shopping_cart_outlined,
          //               color: Colors.white,
          //               size: 26,
          //             ),

          //             // CART BADGE
          //             Positioned(
          //               right: -2,
          //               top: -2,
          //               child: Container(
          //                 padding: const EdgeInsets.all(4),
          //                 decoration: const BoxDecoration(
          //                   color: Colors.redAccent,
          //                   shape: BoxShape.circle,
          //                 ),
          //                 child: const Text(
          //                   "2",
          //                   style: TextStyle(
          //                     color: Colors.white,
          //                     fontSize: 10,
          //                     fontWeight: FontWeight.bold,
          //                   ),
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),

          //     const SizedBox(width: 12),
          //   ],
          // ),
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
                  if (selectedVariantId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        content: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A230F),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.orangeAccent.withOpacity(0.6),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orangeAccent,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Please select a variant",
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
            : SingleChildScrollView(
                controller: _scrollController,
                child: Builder(
                  builder: (context) {
                    // ✅ SAFE VARIABLES (product is guaranteed here)

                    final displayImage =
                        (selectedVariant?["images"] != null &&
                            selectedVariant!["images"].isNotEmpty)
                        ? selectedVariant!["images"][0]["image"]
                        : product!["image"];

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
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            top: 16,
                            right: 16,
                            child: Column(
                              children: [
                                // WISHLIST ICON
                                GestureDetector(
                                  onTap: () async {
                                    await addwishlist(product!['id'], context);

                                    setState(() {
                                      isInWishlist = !isInWishlist;
                                      product!['is_in_wishlist'] = isInWishlist;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
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

                                // SHARE ICON
                                GestureDetector(
                                  onTap: () {
                                    // TODO: add share logic later
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
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

                    // PRICE CARD
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
                              "₹${product!["base_price"]}",
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 22,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Dynamic rating display
                            if (totalReviews > 0)
                              GestureDetector(
                                onTap: () {
                                  // Scroll to reviews section
                                },
                                child: Row(
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
                                ),
                              )
                            else
                              const Text(
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

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TITLE
                          Text(
                            product!["title"],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          Divider(color: Colors.greenAccent.withOpacity(.2)),

                          const SizedBox(height: 16),

                          // DESCRIPTION
                          const Text(
                            "PRODUCT DETAILS",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            product!["description"],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // VARIANTS (HORIZONTAL)
                          if (variants.isNotEmpty) ...[
                            const Text(
                              "AVAILABLE VARIANTS",
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),

                            SizedBox(
                              height: 190,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: variants.length,
                                itemBuilder: (context, index) {
                                  final variant = variants[index];

                                  // Collect attribute values as text
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

                                  final bool isSelected =
                                      selectedVariantId == variant["id"];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedVariantId = variant["id"];
                                        selectedVariant = variant;
                                      });
                                    },
                                    child: Container(
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
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Colors.tealAccent
                                                      .withOpacity(.25),
                                                  blurRadius: 10,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : [],
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
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      height: 90,
                                                      color: Colors.grey[900],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.white54,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),

                                          const SizedBox(height: 10),

                                          // SKU / NAME
                                          Text(
                                            variant["sku"] ?? "",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),

                                          const SizedBox(height: 6),

                                          // VALUES (Size / Colour etc.)
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: values.map((v) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(.3),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Colors.greenAccent
                                                        .withOpacity(.4),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle,
                                                      size: 12,
                                                      color: Colors.greenAccent,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      v,
                                                      style: const TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color:
                                                            Colors.greenAccent,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),

                          /// USER REVIEWS SECTION
                          const Text(
                            "CUSTOMER REVIEWS",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
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
                            ),

                          // Pending Summary for Coaches
                          if (_isCoach && _getPendingReviewCount() > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.pending_actions, color: Colors.orange, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${_getPendingReviewCount()} Pending Review${_getPendingReviewCount() > 1 ? 's' : ''}",
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductReviewApprovalPage(
                                            productId: widget.productId,
                                            productName: product!["title"] ?? "Product",
                                          ),
                                        ),
                                      ).then((_) => fetchProductReviews());
                                    },
                                    child: const Text(
                                      "Manage",
                                      style: TextStyle(color: Color(0xFF00AFA5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (approvedReviews.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.reviews_outlined,
                                      size: 48,
                                      color: Colors.white24,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "No reviews yet",
                                      style: TextStyle(color: Colors.white54, fontSize: 16),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Be the first to review this product",
                                      style: TextStyle(color: Colors.white38, fontSize: 12),
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
                            ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        SizedBox(height: 10),
                        // ================= USER REVIEWS =================
                        if (!reviewsLoading && reviews.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "USER REVIEWS",
                                  style: TextStyle(
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
                                        (review) => ReviewCard(review: review),
                                      )
                                      .toList(),

                                const SizedBox(height: 14),

                                // ⭐ HORIZONTAL LIST
                                SizedBox(
                                  height: 140,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: reviews.length > 4
                                        ? 4
                                        : reviews.length,
                                    itemBuilder: (context, index) {
                                      final review = reviews[index];

                                      return Container(
                                        width: 260,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: ReviewCard(review: review),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // 👉 SHOW ARROW IF MORE THAN 4 REVIEWS
                                if (reviews.length > 4)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                Viewall_Product_Review(
                                                  productId: widget.productId,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF111111),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.greenAccent
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              "View All",
                                              style: TextStyle(
                                                color: Colors.greenAccent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 14,
                                              color: Colors.greenAccent,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
      ),
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
    // Only show approved reviews
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
                  // User Avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: review.userImage != null
                        ? NetworkImage(review.userImage!)
                        : const AssetImage("lib/assets/placeholder.png")
                            as ImageProvider,
                  ),
                  const SizedBox(width: 8),
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

  const RatingSummary({
    super.key,
    required this.averageRating,
    required this.totalReviews,
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (index) {
                        double fullStarThreshold = index + 0.75;
                        double halfStarThreshold = index + 0.25;

                        if (averageRating >= fullStarThreshold) {
                          return const Icon(
                            Icons.star,
                            color: Colors.greenAccent,
                            size: 16,
                          );
                        } else if (averageRating >= halfStarThreshold) {
                          return const Icon(
                            Icons.star_half,
                            color: Colors.greenAccent,
                            size: 16,
                          );
                        } else {
                          return const Icon(
                            Icons.star_border,
                            color: Colors.greenAccent,
                            size: 16,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
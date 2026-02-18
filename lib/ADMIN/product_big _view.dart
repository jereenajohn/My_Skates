import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/cart_view.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/wishlist.dart';
import 'package:my_skates/COACH/product_review_page';
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

  Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isVerified = false,
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
    );
  }
}

class big_view extends StatefulWidget {
  final int productId;
  const big_view({super.key, required this.productId});

  @override
  State<big_view> createState() => _big_viewState();
}

class _big_viewState extends State<big_view> {
  bool loading = true;
  Map<String, dynamic>? product;
  int? selectedVariantId;
  Map<String, dynamic>? selectedVariant;

  // Review variables
  List<Review> reviews = [];
  bool reviewsLoading = false;
  double averageRating = 0;
  int totalReviews = 0;
  bool isInWishlist = false;

  @override
  void initState() {
    super.initState();
    getproductDetails();
    fetchProductReviews();
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
          fetchedReviews = (data as List)
              .map((r) => Review.fromJson(r))
              .toList();
        } else if (data['success'] == true && data['data'] != null) {
          fetchedReviews = (data['data'] as List)
              .map((r) => Review.fromJson(r))
              .toList();
        }

        // Calculate average rating
        if (fetchedReviews.isNotEmpty) {
          double total = 0;
          for (var review in fetchedReviews) {
            total += review.rating;
          }
          averageRating = total / fetchedReviews.length;
          totalReviews = fetchedReviews.length;
        }

        setState(() {
          reviews = fetchedReviews;
          reviewsLoading = false;

          print("reviewss...${reviews}");
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
        _showSnackBar(
          icon: Icons.shopping_cart,
          color: Colors.tealAccent,
          background: const Color(0xFF0F2F2B),
          message: message,
        );
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

      _showSnackBar(
        icon: Icons.error_outline,
        color: Colors.redAccent,
        background: const Color(0xFF2A0F0F),
        message: "Something went wrong. Please try again.",
      );
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
                    MaterialPageRoute(builder: (context) => const cart()),
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

                    // CART BADGE
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          "2",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PRODUCT IMAGE
                    AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          // PRODUCT IMAGE
                          Positioned.fill(
                            child: Hero(
                              tag: "product_${widget.productId}",
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  product!["image"],
                                  fit: BoxFit.cover,
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
                              Row(
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
                          // Only show USER REVIEWS section if there are reviews
                          if (totalReviews > 0) ...[
                            /// USER REVIEWS SECTION
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "USER REVIEWS",
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  '$totalReviews reviews',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Rating Summary
                            RatingSummary(
                              averageRating: averageRating,
                              totalReviews: totalReviews,
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
                                  ...reviews
                                      .take(3)
                                      .map(
                                        (review) => ReviewCard(review: review),
                                      )
                                      .toList(),

                                  if (reviews.length > 3)
                                    Center(
                                      child: TextButton(
                                        onPressed: () {
                                        },
                                        child: Text(
                                          'View all ${reviews.length} reviews',
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                            const SizedBox(height: 20),
                          ],

                          const SizedBox(height: 20),

                          // Write Review Button
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductReviewPage(
                                    productId: widget.productId,
                                    productTitle: product!["title"],
                                    productImage: product!["image"],
                                    variantId: selectedVariantId ?? 0,
                                    variantImage:
                                        selectedVariant?["images"]
                                                ?.isNotEmpty ==
                                            true
                                        ? selectedVariant!["images"][0]["image"]
                                        : product!["image"],
                                    variantLabel:
                                        selectedVariant?["sku"] ?? "Default",
                                  ),
                                ),
                              );

                              // Refresh reviews after returning
                              if (result != null) {
                                fetchProductReviews();
                              }
                            },
                            icon: const Icon(Icons.edit, color: Colors.black),
                            label: const Text(
                              'Write a Review',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              minimumSize: const Size(double.infinity, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
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

// Review Card Widget - Dynamic from API
class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with User Name and Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User Name with Verified Badge (if verified)
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

              // Star Rating - Dynamic from API
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

          // Date - Dynamic from API
          Text(
            _formatDate(review.createdAt),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 10),

          // Review Text - Dynamic from API
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
                      (index) => Icon(
                        index < averageRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.greenAccent,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalReviews reviews',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {
              // Navigate to all reviews page (you can add this later)
            },
            icon: const Icon(Icons.arrow_forward, color: Colors.greenAccent),
            label: const Text(
              'View All',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }
}

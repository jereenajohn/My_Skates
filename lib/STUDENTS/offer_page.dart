import 'dart:convert';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/product_big%20_view.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class OfferProductsPage extends StatefulWidget {
  final String initialOfferName;

  const OfferProductsPage({
    super.key,
    required this.initialOfferName,
  });

  @override
  State<OfferProductsPage> createState() => _OfferProductsPageState();
}

class _OfferProductsPageState extends State<OfferProductsPage> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> offerProducts = [];

  String offerName = "";
  String? nextUrl;

  bool pageLoading = true;
  bool paginationLoading = false;

  @override
  void initState() {
    super.initState();

    offerName = widget.initialOfferName;

    getOfferProducts();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          nextUrl != null &&
          !paginationLoading &&
          !pageLoading) {
        getOfferProducts(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> getOfferProducts({bool loadMore = false}) async {
    if (loadMore) {
      if (nextUrl == null || paginationLoading) return;

      if (!mounted) return;
      setState(() {
        paginationLoading = true;
      });
    } else {
      if (!mounted) return;
      setState(() {
        pageLoading = true;
        paginationLoading = false;
        nextUrl = null;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final Uri uri = loadMore && nextUrl != null
          ? Uri.parse(nextUrl!)
          : Uri.parse('$api/api/myskates/approved/offer/products/view/');

      debugPrint("OFFER PAGE API: $uri");

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("OFFER PAGE STATUS: ${response.statusCode}");
      debugPrint("OFFER PAGE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        String? apiNextUrl;
        String apiOfferName = offerName;
        List<dynamic> dataList = [];

        if (decoded is Map && decoded["results"] is Map) {
          apiNextUrl = decoded["next"]?.toString();

          final results = decoded["results"];

          apiOfferName = (results["offer_name"] ?? apiOfferName).toString();

          if (results["data"] is List) {
            dataList = results["data"];
          }
        } else if (decoded is Map && decoded["data"] is List) {
          apiNextUrl = decoded["next"]?.toString();
          apiOfferName = (decoded["offer_name"] ?? apiOfferName).toString();

          if (decoded["data"] is List) {
            dataList = decoded["data"];
          }
        }

        final mappedProducts = dataList
            .map<Map<String, dynamic>>((item) => _mapProductData(item))
            .toList();

        if (!mounted) return;

        setState(() {
          offerName = apiOfferName;
          nextUrl = apiNextUrl;

          if (loadMore) {
            offerProducts.addAll(mappedProducts);
          } else {
            offerProducts = mappedProducts;
          }
        });
      }
    } catch (e) {
      debugPrint("Offer products page fetch error: $e");
    }

    if (!mounted) return;

    setState(() {
      pageLoading = false;
      paginationLoading = false;
    });
  }

  Future<void> addwishlist(int id, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    final userId = prefs.getInt("id");

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login expired. Please login again."),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$api/api/myskates/products/$id/wishlist/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          "user": userId.toString(),
          "product": id.toString(),
        },
      );

      debugPrint("OFFER WISHLIST STATUS: ${response.statusCode}");
      debugPrint("OFFER WISHLIST BODY: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final String message = decoded['message'] ?? "Wishlist updated";

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
                color: const Color(0xFF0F2F2B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.tealAccent.withOpacity(0.6),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Colors.tealAccent,
                  ),
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
          ),
        );
      } else {
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
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orangeAccent,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Failed to update wishlist",
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
          ),
        );
      }
    } catch (e) {
      debugPrint("Offer wishlist error: $e");

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
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Failed to update wishlist",
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
        ),
      );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.35),
                  ),
                ),
                child: Text(
                  "${discountPercent.toStringAsFixed(discountPercent.truncateToDouble() == discountPercent ? 0 : 1)}% OFF",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Poppins',
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
                      Positioned(
                        top: 10,
                        left: 0,
                        child: _offerBadge(p),
                      ),
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

                          if (!mounted) return;

                          setState(() {
                            p['is_wishlisted'] = !(p['is_wishlisted'] == true);
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

  Widget _gridSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 295,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) {
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
    final String title =
        offerName.trim().isEmpty ? "Offer Products" : offerName.trim();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00312D),
        elevation: 0,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00312D),
              Color(0xFF000000),
            ],
            stops: [
              0.0,
              0.35,
            ],
          ),
        ),
        child: pageLoading
            ? _gridSkeleton()
            : RefreshIndicator(
                color: Colors.tealAccent,
                backgroundColor: Colors.black,
                onRefresh: () => getOfferProducts(),
                child: offerProducts.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 180),
                          Icon(
                            Icons.local_offer_outlined,
                            color: Colors.white54,
                            size: 64,
                          ),
                          SizedBox(height: 14),
                          Center(
                            child: Text(
                              "No offer products found",
                              style: TextStyle(
                                color: Colors.white70,
                                fontFamily: 'Poppins',
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: offerProducts.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 295,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemBuilder: (context, index) {
                                return _productCard(offerProducts[index]);
                              },
                            ),
                            if (paginationLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 18),
                                child: CircularProgressIndicator(
                                  color: Colors.tealAccent,
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
      ),
    );
  }
}

class _ExactOfferRibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double notchWidth = 10;

    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - notchWidth, size.height / 2)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
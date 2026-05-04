import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsedProductBigView extends StatefulWidget {
  final int productId;
  const UsedProductBigView({super.key, required this.productId});

  @override
  State<UsedProductBigView> createState() => _UsedProductBigViewState();
}

class _UsedProductBigViewState extends State<UsedProductBigView> {
  bool loading = true;
  Map<String, dynamic>? product;

  @override
  void initState() {
    super.initState();
    getUsedProductDetails();
  }

  Future<void> getUsedProductDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() => loading = false);
        return;
      }

      final res = await http.get(
        Uri.parse("$api/api/myskates/used/products/update/${widget.productId}/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("USED PRODUCT DETAILS STATUS: ${res.statusCode}");
      print("USED PRODUCT DETAILS BODY: ${res.body}");

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final data = json["data"];

        final double price =
            double.tryParse(data["price"]?.toString() ?? "0") ?? 0;
        final double discount =
            double.tryParse(data["discount"]?.toString() ?? "0") ?? 0;

        setState(() {
          product = {
            "id": data["id"],
            "title": data["title"] ?? "",
            "category": data["category"],
            "category_name": data["category_name"] ?? "",
            "user": data["user"],
            "user_name": data["user_name"] ?? "",
            "image": data["image"] != null ? "$api${data["image"]}" : "",
            "description": data["description"] ?? "",
            "price": price,
            "discount": discount,
            "final_price": discount > 0 ? (price - discount) : price,
            "status": (data["status"] ?? "").toString().toLowerCase(),
            "created_at": data["created_at"] ?? "",
          };
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      print("USED PRODUCT DETAILS ERROR: $e");
      setState(() => loading = false);
    }
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
              getUsedProductDetails();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
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
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return isoDate;
    }
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(
            height: 360,
            width: double.infinity,
            borderRadius: BorderRadius.zero,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 12, width: 80),
                const SizedBox(height: 12),
                const SkeletonBox(height: 28, width: double.infinity),
                const SizedBox(height: 8),
                const SkeletonBox(height: 28, width: 260),
                const SizedBox(height: 20),
                const SkeletonBox(height: 40, width: 200),
                const SizedBox(height: 30),
                const SkeletonBox(height: 100, width: double.infinity),
                const SizedBox(height: 20),
                const SkeletonBox(height: 80, width: double.infinity),
                const SizedBox(height: 20),
                const SkeletonBox(height: 100, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSold = product?["status"] == "sold";

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ],
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
                : Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Section with better styling
                            _buildImageSection(),

                            // Status Badge
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSold
                                      ? Colors.redAccent.withOpacity(0.15)
                                      : Colors.greenAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSold
                                        ? Colors.redAccent.withOpacity(0.5)
                                        : Colors.greenAccent.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  isSold ? "SOLD OUT" : "IN STOCK",
                                  style: TextStyle(
                                    color: isSold
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Title Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product!["title"] ?? "",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Category
                                  Text(
                                    product!["category_name"] ?? "-",
                                    style: TextStyle(
                                      color: Colors.greenAccent.withOpacity(0.8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Price Section
                            _buildPriceSection(),

                            const SizedBox(height: 28),

                            // Seller Information Card
                            _buildSellerCard(),

                            const SizedBox(height: 20),

                            // Product Description Section
                            _buildDescriptionSection(),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                      // Action Buttons at Bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildActionButtons(isSold),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      color: Colors.black26,
      child: GestureDetector(
        onTap: () => _openImageViewer(product!["image"]),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Colors.black38,
                child: Image.network(
                  product!["image"],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black26,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.zoom_in,
                      color: Colors.greenAccent.withOpacity(0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "TAP TO ZOOM",
                      style: TextStyle(
                        color: Colors.greenAccent.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product!["discount"] > 0) ...[
            Text(
              "₹${product!["price"].toStringAsFixed(0)}",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
                decoration: TextDecoration.lineThrough,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "₹${product!["final_price"].toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 32,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${((product!["discount"] / product!["price"]) * 100).toStringAsFixed(0)}% OFF",
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              "₹${product!["price"].toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 32,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSellerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.greenAccent.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.greenAccent.withOpacity(0.7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Sold by",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        product!["user_name"] ?? "-",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    "View",
                    style: TextStyle(
                      color: Colors.greenAccent.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About this product",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            (product!["description"] ?? "").toString().isEmpty
                ? "No description available"
                : product!["description"],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.greenAccent.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.greenAccent.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Posted on ${_formatDate(product!["created_at"] ?? "")}",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isSold) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border(
          top: BorderSide(
            color: Colors.greenAccent.withOpacity(0.2),
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.3),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.message_outlined,
                  color: Colors.white70,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isSold ? Colors.grey[700] : Colors.greenAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  isSold ? "SOLD OUT" : "ADD TO CART",
                  style: TextStyle(
                    color: isSold ? Colors.white54 : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
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
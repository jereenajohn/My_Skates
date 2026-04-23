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
                SkeletonBox(height: 14, width: 120),
                SizedBox(height: 20),
                SkeletonBox(height: 14, width: double.infinity),
                SizedBox(height: 8),
                SkeletonBox(height: 14, width: double.infinity),
                SizedBox(height: 8),
                SkeletonBox(height: 14, width: 260),
                SizedBox(height: 30),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            color: Colors.black,
                            child: GestureDetector(
                              onTap: () => _openImageViewer(product!["image"]),
                              child: Image.network(
                                product!["image"],
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.black,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

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
                                product!["discount"] > 0
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "₹${product!["price"].toStringAsFixed(0)}",
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 13,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "₹${product!["final_price"].toStringAsFixed(0)}",
                                            style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 22,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        "₹${product!["price"].toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 22,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSold
                                        ? Colors.redAccent.withOpacity(0.2)
                                        : Colors.greenAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSold
                                          ? Colors.redAccent.withOpacity(0.5)
                                          : Colors.greenAccent.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    isSold ? "Sold" : "Active",
                                    style: TextStyle(
                                      color: isSold
                                          ? Colors.redAccent
                                          : Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            (product!["title"] ?? "").toString().toUpperCase(),
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

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _infoChip(
                                label: "Category",
                                value: product!["category_name"] ?? "-",
                              ),
                              _infoChip(
                                label: "Seller",
                                value: product!["user_name"] ?? "-",
                              ),
                              _infoChip(
                                label: "Posted",
                                value: _formatDate(product!["created_at"] ?? ""),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(color: Colors.greenAccent.withOpacity(.2)),
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
                                (product!["description"] ?? "").toString().isEmpty
                                    ? "No description available"
                                    : product!["description"],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _infoChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.25)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:shimmer/shimmer.dart';

class DisapprovedProducts extends StatefulWidget {
  const DisapprovedProducts({super.key});

  @override
  State<DisapprovedProducts> createState() => _DisapprovedProductsState();
}

class _DisapprovedProductsState extends State<DisapprovedProducts> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  bool isRefreshing = false;
  Map<int, bool> expandedProducts = {};

  int currentPage = 1;
  int totalCount = 0;
  String? nextPageUrl;
  String? previousPageUrl;
  bool isPageLoading = false;
  final int pageSize = 10;

  @override
  void initState() {
    super.initState();
    getproduct("disapproved");
  }

  Future<void> getproduct(String status, {int page = 1}) async {
    try {
      setState(() {
        if (page == 1) {
          isLoading = true;
        } else {
          isPageLoading = true;
        }
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() {
          isLoading = false;
          isPageLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$api/api/myskates/products/status/view/$status/?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("PRODUCT STATUS: ${response.statusCode}");
      print("PRODUCT BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        totalCount = decoded['count'] ?? 0;
        nextPageUrl = decoded['next'];
        previousPageUrl = decoded['previous'];
        currentPage = page;

        final List<dynamic> parsed = decoded['results']?['data'] ?? [];

        Map<int, Map<String, dynamic>> productMap = {};

        for (final item in parsed) {
          if (item.containsKey('title') &&
              item['title'] != null &&
              item['title'].toString().isNotEmpty &&
              item.containsKey('variants')) {
            int productId = item['id'];

            List<Map<String, dynamic>> processedVariants = [];

            if (item['variants'] != null && item['variants'].isNotEmpty) {
              for (var variant in item['variants']) {
                String variantImage = "";

                if (variant['images'] != null && variant['images'].isNotEmpty) {
                  String imagePath = variant['images'][0]['image'] ?? "";

                  if (imagePath.startsWith('http://') ||
                      imagePath.startsWith('https://')) {
                    variantImage = imagePath;
                  } else {
                    variantImage = '$api$imagePath';
                  }
                }

                processedVariants.add({
                  'id': variant['id'],
                  'sku': variant['sku'] ?? "",
                  'price': variant['price']?.toString() ?? "0",
                  'discount': variant['discount']?.toString() ?? "0",
                  'stock': variant['stock'] ?? 0,
                  'category_name':
                      variant['category_name'] ?? item['category_name'] ?? "",
                  'image': variantImage,
                  'approval_status': variant['approval_status'] ?? status,
                  'description': variant['description'] ?? "",
                  'is_active': variant['is_active'] ?? true,
                });
              }
            }

            String mainImage = "";

            if (item['image'] != null && item['image'].toString().isNotEmpty) {
              String imagePath = item['image'];

              if (imagePath.startsWith('http://') ||
                  imagePath.startsWith('https://')) {
                mainImage = imagePath;
              } else {
                mainImage = '$api$imagePath';
              }
            }

            productMap[productId] = {
              'id': item['id'],
              'title': item['title'] ?? "",
              'image': mainImage,
              'category_name': item['category_name'] ?? "",
              'price': item['base_price']?.toString() ?? "0",
              'description': item['description'] ?? "",
              'user': item['user']?.toString() ?? "",
              'variants': processedVariants,
              'created_at': item['created_at'] ?? "",
              'approval_status': item['approval_status'] ?? status,
            };
          }
        }

        products = productMap.values.toList();

        for (var product in products) {
          List variants = product['variants'];
          variants.sort((a, b) => (a['sku'] ?? '').compareTo(b['sku'] ?? ''));
        }
      }

      setState(() {
        isLoading = false;
        isRefreshing = false;
        isPageLoading = false;
      });
    } catch (e) {
      print("Error fetching products: $e");

      setState(() {
        isLoading = false;
        isRefreshing = false;
        isPageLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => isRefreshing = true);
    await getproduct("disapproved", page: 1);
  }

  void _showProductDetailDialog(Map<String, dynamic> product) {
    final List variants = product['variants'] ?? [];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with image
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      image: product['image'].isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product['image']),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey[800],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "DISAPPROVED",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00CFC5).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              product['category_name'],
                              style: const TextStyle(
                                color: Color(0xFF00CFC5),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Price
                          Row(
                            children: [
                              const Icon(
                                Icons.currency_rupee,
                                color: Colors.white70,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product['price'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Description
                          if (product['description'].isNotEmpty) ...[
                            const Text(
                              "Description",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                product['description'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Product ID
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.tag,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Product ID: ${product['id']}",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Variants Section
                          if (variants.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24, height: 24),
                            Row(
                              children: [
                                const Icon(
                                  Icons.swap_horiz,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Variants (${variants.length})",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...variants
                                .map(
                                  (variant) => Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            variant['approval_status'] ==
                                                'disapproved'
                                            ? Colors.red.withOpacity(0.3)
                                            : Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                variant['sku'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    variant['is_active'] == true
                                                    ? Colors.green.withOpacity(
                                                        0.2,
                                                      )
                                                    : Colors.red.withOpacity(
                                                        0.2,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                variant['is_active'] == true
                                                    ? 'Active'
                                                    : 'Inactive',
                                                style: TextStyle(
                                                  color:
                                                      variant['is_active'] ==
                                                          true
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Price",
                                                    style: TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "₹${variant['price']}",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (variant['discount'] != "0" &&
                                                variant['discount'] != "0.00")
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      "Discount",
                                                      style: TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      "${variant['discount']}% OFF",
                                                      style: const TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Stock",
                                                    style: TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    variant['stock'].toString(),
                                                    style: TextStyle(
                                                      color:
                                                          (variant['stock']
                                                                  as int) <
                                                              10
                                                          ? Colors.orange
                                                          : Colors.white,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                variant['approval_status'] ==
                                                    'disapproved'
                                                ? Colors.red.withOpacity(0.2)
                                                : Colors.orange.withOpacity(
                                                    0.2,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                variant['approval_status'] ==
                                                        'disapproved'
                                                    ? Icons.block
                                                    : Icons.pending,
                                                color:
                                                    variant['approval_status'] ==
                                                        'disapproved'
                                                    ? Colors.red
                                                    : Colors.orange,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                variant['approval_status']
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color:
                                                      variant['approval_status'] ==
                                                          'disapproved'
                                                      ? Colors.red
                                                      : Colors.orange,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              updateVariantStatus(
                                                variant['id'],
                                                "approved",
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.check_circle_outline,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              "Approve Variant",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF00CFC5,
                                              ),
                                              foregroundColor: Colors.black,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 11,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ],

                          const SizedBox(height: 16),

                          // Close Button
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "Close",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    updateMainProductStatus(
                                      product['id'],
                                      "approved",
                                    );
                                  },
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF00CFC5),
                                          Color(0xFF00A89F),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "Approve",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
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
          ),
        );
      },
    );
  }

  Future<void> updateVariantStatus(int variantId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Authentication token missing"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse("$api/api/myskates/products/variant/approval/$variantId/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"approval_status": status}),
      );

      print("VARIANT STATUS UPDATE ID: $variantId");
      print("VARIANT STATUS UPDATE TO: $status");
      print("VARIANT STATUS UPDATE CODE: ${response.statusCode}");
      print("VARIANT STATUS UPDATE BODY: ${response.body}");

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == "approved"
                  ? "Variant approved successfully"
                  : "Variant disapproved successfully",
            ),
            backgroundColor: status == "approved"
                ? Colors.green
                : Colors.orange,
          ),
        );

        await getproduct("disapproved", page: currentPage);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update variant: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("VARIANT STATUS UPDATE ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating variant: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPaginationControls(String status) {
    final int totalPages = totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: previousPageUrl == null || isPageLoading
                ? null
                : () {
                    getproduct(status, page: currentPage - 1);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.10),
              disabledBackgroundColor: Colors.white.withOpacity(0.04),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: Colors.white,
            ),
            label: const Text("Prev", style: TextStyle(color: Colors.white)),
          ),

          isPageLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00CFC5),
                  ),
                )
              : Text(
                  "Page $currentPage of $totalPages",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

          ElevatedButton.icon(
            onPressed: nextPageUrl == null || isPageLoading
                ? null
                : () {
                    getproduct(status, page: currentPage + 1);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00CFC5),
              disabledBackgroundColor: Colors.white.withOpacity(0.04),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.white,
            ),
            label: const Text("Next", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassProductCard(Map<String, dynamic> product) {
    final List variants = product['variants'] ?? [];
    final bool isExpanded = expandedProducts[product['id']] ?? false;

    return GestureDetector(
      onTap: () => _showProductDetailDialog(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade900,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: product['image'].isNotEmpty
                              ? Image.network(
                                  product['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey.shade800,
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                              : const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "DISAPPROVED",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.category_outlined,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    product['category_name'],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.currency_rupee,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "₹${product['price']}",
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (variants.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "${variants.length} variants",
                                      style: const TextStyle(
                                        color: Colors.tealAccent,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (product['description'].isNotEmpty)
                              Text(
                                product['description'],
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                  if (variants.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            expandedProducts[product['id']] = !isExpanded;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.tealAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.tealAccent,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isExpanded
                                    ? "Hide variants"
                                    : "Show ${variants.length} variants",
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (isExpanded && variants.isNotEmpty) ...[
                    const Divider(color: Colors.white24, height: 16),
                    ...variants.map((variant) => _buildVariantCard(variant)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantCard(Map<String, dynamic> variant) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8, left: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: variant['approval_status'] == 'disapproved'
              ? Colors.red.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: (variant['image'] != null && variant['image'].isNotEmpty)
                  ? Image.network(
                      variant['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image, color: Colors.grey[600]),
                    )
                  : Icon(Icons.image, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant['sku'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "₹${variant['price']}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: variant['approval_status'] == 'disapproved'
                  ? Colors.red.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  variant['approval_status'] == 'disapproved'
                      ? Icons.block
                      : Icons.pending,
                  color: variant['approval_status'] == 'disapproved'
                      ? Colors.red
                      : Colors.orange,
                  size: 10,
                ),
                const SizedBox(width: 4),
                Text(
                  variant['approval_status'].toUpperCase(),
                  style: TextStyle(
                    color: variant['approval_status'] == 'disapproved'
                        ? Colors.red
                        : Colors.orange,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updateMainProductStatus(int id, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Authentication token missing"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse("$api/api/myskates/products/approval/$id/"),
        headers: {"Authorization": "Bearer $token"},
        body: {"approval_status": status},
      );

      print("MAIN PRODUCT STATUS UPDATE ID: $id");
      print("MAIN PRODUCT STATUS UPDATE TO: $status");
      print("MAIN PRODUCT STATUS UPDATE CODE: ${response.statusCode}");
      print("MAIN PRODUCT STATUS UPDATE BODY: ${response.body}");

      if (response.statusCode == 200) {
        if (!mounted) return;

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == "approved"
                  ? "Product approved successfully"
                  : "Product disapproved successfully",
            ),
            backgroundColor: status == "approved"
                ? Colors.green
                : Colors.orange,
          ),
        );

        await getproduct("disapproved", page: currentPage);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to update product status: ${response.statusCode}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("MAIN PRODUCT STATUS UPDATE ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating product status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFF1A2B2A),
              highlightColor: const Color(0xFF2F4F4D),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 14,
                              width: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 12,
                              width: 180,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 26,
                      width: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: isLoading
          ? _buildShimmerList()
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.tealAccent,
              backgroundColor: Colors.black,
              strokeWidth: 3.0,
              displacement: 40.0,
              child: products.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 16),
                              Text(
                                "No disapproved products",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(10),
                      itemCount: products.length + 1,
                      itemBuilder: (context, index) {
                        if (index == products.length) {
                          return _buildPaginationControls("disapproved");
                        }

                        final product = products[index];
                        return _buildGlassProductCard(product);
                      },
                    ),
            ),
    );
  }
}

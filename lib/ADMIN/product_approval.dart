import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart';

class Approveproduct extends StatefulWidget {
  const Approveproduct({super.key});

  @override
  State<Approveproduct> createState() => _ApproveproductState();
}

class _ApproveproductState extends State<Approveproduct> {
  List<Map<String, dynamic>> coach = [];
  bool isLoading = true;
  bool isRefreshing = false;
  Map<int, bool> expandedProducts = {};
  Set<int> approvedMainProducts = {};

  int currentPage = 1;
  int totalCount = 0;
  String? nextPageUrl;
  String? previousPageUrl;
  bool isPageLoading = false;
  final int pageSize = 10;

  @override
  void initState() {
    super.initState();
    getproduct("pending");
  }

  Future<String> getAddressFromLatLng(String? lat, String? lng) async {
    if (lat == null || lng == null || lat.isEmpty || lng.isEmpty) {
      return "";
    }

    try {
      double latitude = double.parse(lat);
      double longitude = double.parse(lng);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark p = placemarks.first;
        return "${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.country ?? ''}";
      }
    } catch (e) {
      print("Reverse geocode error: $e");
    }
    return "";
  }

  Future<void> updateMainProductStatus(int id, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      var response = await http.patch(
        Uri.parse("$api/api/myskates/products/approval/$id/"),
        headers: {"Authorization": "Bearer $token"},
        body: {"approval_status": status},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Product ${status == 'approved' ? 'approved' : 'rejected'} successfully",
            ),
            backgroundColor: status == 'approved'
                ? Colors.green
                : Colors.orange,
          ),
        );
        if (status == 'approved') {
          setState(() {
            approvedMainProducts.add(id);
          });
        } else {
          setState(() {
            approvedMainProducts.remove(id);
          });
        }
        Navigator.pop(context);
        getproduct("pending", page: currentPage);
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error updating product status"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

Future<bool> updateVariantStatus(int variantId, String status) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  if (token == null) {
    print("TOKEN MISSING");
    return false;
  }

  try {
    final response = await http.patch(
      Uri.parse("$api/api/myskates/products/variant/approval/$variantId/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "approval_status": status,
      }),
    );

    print("VARIANT APPROVAL ID: $variantId");
    print("VARIANT APPROVAL STATUS CODE: ${response.statusCode}");
    print("VARIANT APPROVAL BODY: ${response.body}");

    return response.statusCode == 200;
  } catch (e) {
    print("VARIANT APPROVAL ERROR: $e");
    return false;
  }
}
Future<void> submitFinalApproval(
  BuildContext productDialogContext,
  List<Map<String, dynamic>> variants,
) async {
  if (variants.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select at least one variant"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext confirmDialogContext) {
      bool isSubmitting = false;

      return StatefulBuilder(
        builder: (BuildContext confirmStateContext, StateSetter setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              "Confirm Final Approval",
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Please review before final submission:",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),

                  ...variants.map((variant) {
                    final bool isAccepted = variant['isAccepted'] == true;
                    final String status =
                        variant['status']?.toString() ?? 'pending';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            isAccepted ? Icons.check_circle : Icons.cancel,
                            color: isAccepted ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  variant['sku']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "Status: ${status.toUpperCase()}",
                                  style: TextStyle(
                                    color: status == 'approved'
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  const Text(
                    "Do you want to proceed?",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(confirmDialogContext),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() {
                          isSubmitting = true;
                        });

                        int successCount = 0;
                        int failedCount = 0;

                        for (final variant in variants) {
                          final int variantId = variant['id'];
                          final String status = variant['status'];

                          final bool success = await updateVariantStatus(
                            variantId,
                            status,
                          );

                          if (success) {
                            successCount++;
                          } else {
                            failedCount++;
                          }
                        }

                        if (!mounted) return;

                        Navigator.pop(confirmDialogContext);

                        if (failedCount == 0) {
                          Navigator.pop(productDialogContext);
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              failedCount == 0
                                  ? "All $successCount variants processed successfully"
                                  : "$successCount variants processed, $failedCount failed",
                            ),
                            backgroundColor:
                                failedCount == 0 ? Colors.green : Colors.orange,
                          ),
                        );

                        await getproduct("pending", page: currentPage);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Confirm"),
              ),
            ],
          );
        },
      );
    },
  );
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

        coach = productMap.values.toList();

        for (var product in coach) {
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
    await getproduct("pending", page: 1);
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
            icon: const Icon(Icons.chevron_left_rounded, size: 18,color: Colors.white,),
            label: const Text("Prev",style: TextStyle(color: Colors.white)),
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
            icon: const Icon(Icons.chevron_right_rounded, size: 18,color: Colors.white,),
            label: const Text("Next",style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProductDetailDialog(Map<String, dynamic> product) {
    final List variants = product['variants'] ?? [];
    final bool isProductApproved = product['approval_status'] == 'approved';

    // Track variant selections
    Map<int, Map<String, dynamic>> variantSelections = {};

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext productDialogContext) {
  return StatefulBuilder(
    builder: (BuildContext dialogStateContext, StateSetter setDialogState) {
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
                                      color:
                                          product['approval_status'] ==
                                              'pending'
                                          ? Colors.orange.withOpacity(0.8)
                                          : Colors.green.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      product['approval_status'].toUpperCase(),
                                      style: const TextStyle(
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
                                  color: const Color(
                                    0xFF00CFC5,
                                  ).withOpacity(0.2),
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
                                Text(
                                  product['description'],
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Variants Section (only if product is approved)
                              if (isProductApproved && variants.isNotEmpty) ...[
                                const Divider(
                                  color: Colors.white24,
                                  height: 24,
                                ),
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
                                ...variants.map((variant) {
                                  final isVariantProcessed =
                                      variant['approval_status'] != 'pending';
                                  final currentStatus =
                                      variantSelections[variant['id']]?['status'] ??
                                      variant['approval_status'];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: currentStatus == 'approved'
                                            ? Colors.green.withOpacity(0.5)
                                            : (currentStatus == 'disapproved'
                                                  ? Colors.red.withOpacity(0.5)
                                                  : Colors.white.withOpacity(
                                                      0.1,
                                                    )),
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
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    variant['sku'],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Column(
                                                    children: [
                                                      Text(
                                                        "₹${variant['price']}",
                                                        style: const TextStyle(
                                                          color:
                                                              Colors.tealAccent,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      if (variant['discount'] !=
                                                              "0" &&
                                                          variant['discount'] !=
                                                              "0.00") ...[
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.green
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            "${variant['discount']}% OFF",
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .green,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .inventory_2_outlined,
                                                        color:
                                                            (variant['stock']
                                                                    as int) <
                                                                10
                                                            ? Colors.orange
                                                            : Colors.green,
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "Stock: ${variant['stock']}",
                                                        style: TextStyle(
                                                          color:
                                                              (variant['stock']
                                                                      as int) <
                                                                  10
                                                              ? Colors.orange
                                                              : Colors.white54,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (!isVariantProcessed)
                                              Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      setDialogState(() {
                                                        variantSelections[variant['id']] =
                                                            {
                                                              'id':
                                                                  variant['id'],
                                                              'sku':
                                                                  variant['sku'],
                                                              'status':
                                                                  'disapproved',
                                                              'isAccepted':
                                                                  false,
                                                            };
                                                      });
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            currentStatus ==
                                                                'disapproved'
                                                            ? Colors.red
                                                            : Colors.grey[800],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        "Reject",
                                                        style: TextStyle(
                                                          color:
                                                              currentStatus ==
                                                                  'disapproved'
                                                              ? Colors.white
                                                              : Colors.white70,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  GestureDetector(
                                                    onTap: () {
                                                      setDialogState(() {
                                                        variantSelections[variant['id']] =
                                                            {
                                                              'id':
                                                                  variant['id'],
                                                              'sku':
                                                                  variant['sku'],
                                                              'status':
                                                                  'approved',
                                                              'isAccepted':
                                                                  true,
                                                            };
                                                      });
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            currentStatus ==
                                                                'approved'
                                                            ? const LinearGradient(
                                                                colors: [
                                                                  Colors.green,
                                                                  Color(
                                                                    0xFF00A89F,
                                                                  ),
                                                                ],
                                                              )
                                                            : const LinearGradient(
                                                                colors: [
                                                                  Color(
                                                                    0xFF00CFC5,
                                                                  ),
                                                                  Color(
                                                                    0xFF00A89F,
                                                                  ),
                                                                ],
                                                              ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        "Accept",
                                                        style: TextStyle(
                                                          color:
                                                              currentStatus ==
                                                                  'approved'
                                                              ? Colors.white
                                                              : Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      variant['approval_status'] ==
                                                          'approved'
                                                      ? Colors.green
                                                            .withOpacity(0.2)
                                                      : Colors.red.withOpacity(
                                                          0.2,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  variant['approval_status']
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color:
                                                        variant['approval_status'] ==
                                                            'approved'
                                                        ? Colors.green
                                                        : Colors.red,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                const SizedBox(height: 16),

                                // Submit button for variants
                                if (variantSelections.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      final selectedVariants = variantSelections
                                          .values
                                          .toList();
                                     submitFinalApproval(productDialogContext, selectedVariants);
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
                                          "Submit Variant Approvals",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],

                              const SizedBox(height: 24),

                              // Action Buttons for Main Product (only if not already approved/rejected)
                              if (product['approval_status'] == 'pending')
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          updateMainProductStatus(
                                            product['id'],
                                            "disapproved",
                                          );
                                        },
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[800],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "Reject Product",
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
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF00CFC5),
                                                Color(0xFF00A89F),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "Accept Product",
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
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        product['approval_status'] == 'approved'
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Product ${product['approval_status'].toUpperCase()}",
                                      style: TextStyle(
                                        color:
                                            product['approval_status'] ==
                                                'approved'
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
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
      },
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
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: product['image'].isNotEmpty
                            ? NetworkImage(product['image'])
                            : const AssetImage("lib/assets/img.jpg")
                                  as ImageProvider,
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
                                // Container(
                                //   padding: const EdgeInsets.symmetric(
                                //     horizontal: 8,
                                //     vertical: 4,
                                //   ),
                                //   decoration: BoxDecoration(
                                //     color:
                                //         product['approval_status'] == 'pending'
                                //         ? Colors.orange.withOpacity(0.2)
                                //         : Colors.green.withOpacity(0.2),
                                //     borderRadius: BorderRadius.circular(12),
                                //   ),
                                //   child: Text(
                                //     product['approval_status'].toUpperCase(),
                                //     style: TextStyle(
                                //       color:
                                //           product['approval_status'] ==
                                //               'pending'
                                //           ? Colors.orange
                                //           : Colors.green,
                                //       fontSize: 10,
                                //       fontWeight: FontWeight.w500,
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product['category_name'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  "₹${product['price']}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                  if (variants.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
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
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  expandedProducts[product['id']] = !isExpanded;
                                });
                              },
                              child: Text(
                                isExpanded
                                    ? "Hide variants"
                                    : "Show ${variants.length} variants",
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (isExpanded && variants.isNotEmpty) ...[
                    const Divider(color: Colors.white24, height: 16),
                    ...variants.map(
                      (variant) => _buildVariantCard(product, variant),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantCard(
    Map<String, dynamic> product,
    Map<String, dynamic> variant,
  ) {
    final bool isProductApproved = product['approval_status'] == 'approved';
    final bool isVariantPending = variant['approval_status'] == 'pending';

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8, left: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: variant['approval_status'] == 'approved'
              ? Colors.green.withOpacity(0.3)
              : (variant['approval_status'] == 'disapproved'
                    ? Colors.red.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1)),
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
                    color: Colors.tealAccent,
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
              color: variant['approval_status'] == 'pending'
                  ? Colors.orange.withOpacity(0.2)
                  : (variant['approval_status'] == 'approved'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              variant['approval_status'].toUpperCase(),
              style: TextStyle(
                color: variant['approval_status'] == 'pending'
                    ? Colors.orange
                    : (variant['approval_status'] == 'approved'
                          ? Colors.green
                          : Colors.red),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
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
                              height: 12,
                              width: 80,
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
                  Row(
                    children: [
                      const SizedBox(width: 25),
                      Expanded(
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
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
              child: coach.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.white54,
                                size: 60,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No pending products",
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
                      itemCount: coach.length + 1,
                      itemBuilder: (context, index) {
                        if (index == coach.length) {
                          return _buildPaginationControls("pending");
                        }

                        final product = coach[index];
                        return _buildGlassProductCard(product);
                      },
                    ),
            ),
    );
  }
}

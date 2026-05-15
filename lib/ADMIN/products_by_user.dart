import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/add_product.dart';
import 'package:my_skates/ADMIN/add_product_variant.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/update_product.dart';
import 'package:my_skates/bottomnavigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class ProductsByUser extends StatefulWidget {
  const ProductsByUser({super.key});

  @override
  State<ProductsByUser> createState() => _ProductsByUserState();
}

class _ProductsByUserState extends State<ProductsByUser> {
  List<Map<String, dynamic>> products = [];
  bool pageLoading = true;
  bool productsLoading = false;
  String selectedStatus = "approved";

  final List<Map<String, String>> statusTabs = [
    {"label": "Approved", "value": "approved"},
    {"label": "Pending", "value": "pending"},
    {"label": "Rejected", "value": "disapproved"},
  ];

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await getbanner();
    await getproduct(selectedStatus);
    setState(() {
      pageLoading = false;
    });
    print("Initial data loaded.$pageLoading");
  }

  Future<void> delete(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    var response = await http.delete(
      Uri.parse("$api/api/myskates/products/update/$id/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    print("DELETE RESPONSE STATUS: ${response.statusCode}");
    print("DELETE RESPONSE BODY: ${response.body}");
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Product Deleted"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete Failed"), backgroundColor: Colors.red),
      );
    }
  }

  List<Map<String, dynamic>> banner = [];

  Future<void> getbanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var response = await http.get(
        Uri.parse('$api/api/myskates/banner/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> statelist = [];
      print("response.bodyyyyyyyyyyyyyyyyy:${response.body}");
      print(response.statusCode);
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed;

        for (var productData in productsData) {
          String imageUrl = "$api${productData['image']}";
          statelist.add({
            'id': productData['id'],
            'title': productData['title'],
            'image': imageUrl,
          });
        }
        setState(() {
          banner = statelist;
          print("statelistttttttttttttttttttt:$banner");
        });
      }
    } catch (error) {}
  }

  Future<void> getproduct(String status) async {
    setState(() {
      productsLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    final userId = prefs.getInt("id");
    print("USER ID IN PRODUCT STATUS:::::::::::::::::::::; $userId");
    final response = await http.get(
      Uri.parse('$api/api/myskates/products/status/$userId/user/$status/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("PRODUCT STATUS: ${response.statusCode}");
    print("PRODUCT BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // IMPORTANT: The response has a 'data' field containing the products list
      final List list = decoded['data'] ?? [];

      print("PRODUCTS COUNT: ${list.length}");

      products = list.map<Map<String, dynamic>>((c) {
        // Extract variants - make sure we're getting them correctly
        final variants = (c['variants'] as List? ?? [])
            .where((v) => v['approval_status'] == status)
            .toList();

        print("Product: ${c['title']}, Variants count: ${variants.length}");

        return {
          'id': c['id'],
          'title': c['title'] ?? "",
          'image': c['image'] != null ? '$api${c['image']}' : "",
          'category_name': c['category_name'] ?? "",
          'discount': c['discount']?.toString() ?? "0",
          'price': c['base_price']?.toString() ?? "0",
          'variants': variants.map((v) {
            // Extract attribute values names if available
            List<String> attributeNames = [];
            if (v['attribute_values'] != null &&
                v['attribute_values'] is List) {
              // You might need to fetch attribute names from another API
              // For now, just use the IDs
              attributeNames = (v['attribute_values'] as List)
                  .map((attr) => attr.toString())
                  .toList();
            }

            return {
              'id': v['id'],
              'sku': v['sku'] ?? "",
              'price': v['price']?.toString() ?? "0",
              'discount': v['discount']?.toString() ?? "0",
              'stock': v['stock'] ?? 0,
              'approval_status': v['approval_status'] ?? "pending",
              'attribute_values': attributeNames,
              'images': v['images'] ?? [],
            };
          }).toList(),
          'variants_count': variants.length,
        };
      }).toList();

      print("MAPPED PRODUCTS: ${products.length}");
      for (var p in products) {
        print("Product: ${p['title']}, Variants: ${p['variants_count']}");
      }
    } else {
      products = [];
    }

    setState(() {
      productsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        searchBarSkeleton(),
                        const SizedBox(height: 20),
                        statusTabsSkeleton(),
                        const SizedBox(height: 20),
                        productGridSkeleton(),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            height: 50,
                            width: 68,
                            decoration: BoxDecoration(),
                            child: Image.asset(
                              "lib/assets/myskates.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  border: Border.all(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 10),
                                      Text(
                                        "Search",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  slideRightToLeftRoute(AddProduct()),
                                );
                              },
                              child: Container(
                                height: 40,
                                width: 110,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Add product",
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
                          ],
                        ),
                        const SizedBox(height: 18),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: statusTabs.map((tab) {
                              final bool isSelected =
                                  selectedStatus == tab["value"];

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedStatus = tab["value"]!;
                                  });
                                  getproduct(selectedStatus);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.tealAccent
                                        : Colors.black.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    tab["label"]!,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
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
                        if (productsLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: productGridSkeleton(),
                          )
                        else if (products.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(
                                "No $selectedStatus products found",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  // Remove fixed mainAxisExtent or make it larger
                                  childAspectRatio:
                                      0.65, // Use aspect ratio instead
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemBuilder: (context, index) {
                              final p = products[index];
                              final hasVariants =
                                  (p['variants_count'] ?? 0) > 0;

                              // return Dismissible(
                              //   key: ValueKey(p['id']),
                              //   direction: DismissDirection.horizontal,
                              //   confirmDismiss: (direction) async {
                              //     if (direction ==
                              //         DismissDirection.endToStart) {
                              //       addvariant(p);
                              //       return false;
                              //     }
                              //     return false;
                              //   },
                              //   background: const SizedBox.shrink(),
                              //   secondaryBackground: Container(
                              //     alignment: Alignment.centerRight,
                              //     padding: const EdgeInsets.only(right: 20),
                              //     decoration: BoxDecoration(
                              //       color: const Color.fromARGB(
                              //         255,
                              //         82,
                              //         255,
                              //         203,
                              //       ).withOpacity(0.9),
                              //       borderRadius: BorderRadius.circular(18),
                              //     ),
                              //     child: const Column(
                              //       mainAxisAlignment: MainAxisAlignment.center,
                              //       children: [
                              //         Icon(
                              //           Icons.chevron_left,
                              //           color: Colors.white,
                              //           size: 24,
                              //         ),
                              //         Text(
                              //           "Add Variant",
                              //           style: TextStyle(
                              //             color: Colors.white,
                              //             fontSize: 12,
                              //             fontWeight: FontWeight.w600,
                              //             fontFamily: 'Poppins',
                              //           ),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              //   child: _productCard(p, hasVariants),
                              // );

                              return Dismissible(
                                key: ValueKey(
                                  "product_${p['id']}_$selectedStatus",
                                ),
                                direction: DismissDirection.horizontal,

                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    addvariant(p);
                                    return false;
                                  }

                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    updateProduct(p);
                                    return false;
                                  }

                                  return false;
                                },

                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.edit_note_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Update",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                secondaryBackground: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      82,
                                      255,
                                      203,
                                    ).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Add Variant",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                child: _productCard(p, hasVariants),
                              );
                            },
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _productCard(Map<String, dynamic> p, bool hasVariants) {
    final variants = p['variants'] as List? ?? [];
    final variantsCount = p['variants_count'] ?? 0;

    print(
      "Building card for: ${p['title']}, Has variants: $hasVariants, Variants count: ${variants.length}",
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Image
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: p['image'] != null && p['image'].toString().isNotEmpty
                      ? Image.network(
                          p['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                ),
              ),
              // Variant count badge on image (optional)
              if (hasVariants)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.color_lens,
                          size: 10,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "$variantsCount",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Slide left hint
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left,
                        size: 14,
                        color: Colors.tealAccent,
                      ),
                      Text(
                        "Slide left",
                        style: TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 10,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Product Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              p['title'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              p['category_name'],
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontFamily: 'Poppins',
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Price and Variants Count in same row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Text(
                  "₹${p['price']}",
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (hasVariants) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$variantsCount variant${variantsCount > 1 ? 's' : ''}",
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // // Variants Section - Only show if there are variants
          // if (hasVariants && variants.isNotEmpty) ...[
          //   const SizedBox(height: 6),
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 6),
          //     child: Container(
          //       padding: const EdgeInsets.all(6),
          //       decoration: BoxDecoration(
          //         color: Colors.white.withOpacity(0.05),
          //         borderRadius: BorderRadius.circular(8),
          //         border: Border.all(color: Colors.white12),
          //       ),
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Row(
          //             children: [
          //               const Icon(
          //                 Icons.color_lens,
          //                 size: 12,
          //                 color: Colors.tealAccent,
          //               ),
          //               const SizedBox(width: 4),
          //               Text(
          //                 "${variants.length} Variant${variants.length > 1 ? 's' : ''}",
          //                 style: const TextStyle(
          //                   color: Colors.white70,
          //                   fontSize: 11,
          //                   fontWeight: FontWeight.w500,
          //                   fontFamily: 'Poppins',
          //                 ),
          //               ),
          //             ],
          //           ),
          //           const SizedBox(height: 6),
          //           // Show variant preview (max 2)
          //           ...variants.take(2).map((variant) {
          //             return Padding(
          //               padding: const EdgeInsets.only(bottom: 4),
          //               child: Row(
          //                 children: [
          //                   Container(
          //                     width: 8,
          //                     height: 8,
          //                     decoration: BoxDecoration(
          //                       color: _getStatusColor(
          //                         variant['approval_status'],
          //                       ),
          //                       shape: BoxShape.circle,
          //                     ),
          //                   ),
          //                   const SizedBox(width: 6),
          //                   Expanded(
          //                     child: Text(
          //                       variant['sku'] ?? "Variant",
          //                       style: const TextStyle(
          //                         color: Colors.white60,
          //                         fontSize: 10,
          //                         fontFamily: 'Poppins',
          //                       ),
          //                       maxLines: 1,
          //                       overflow: TextOverflow.ellipsis,
          //                     ),
          //                   ),
          //                   Text(
          //                     "₹${variant['price']}",
          //                     style: const TextStyle(
          //                       color: Colors.tealAccent,
          //                       fontSize: 10,
          //                       fontWeight: FontWeight.w500,
          //                       fontFamily: 'Poppins',
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             );
          //           }),
          //           if (variants.length > 2)
          //             Padding(
          //               padding: const EdgeInsets.only(top: 2),
          //               child: Text(
          //                 "+${variants.length - 2} more",
          //                 style: const TextStyle(
          //                   color: Colors.white54,
          //                   fontSize: 9,
          //                   fontFamily: 'Poppins',
          //                 ),
          //               ),
          //             ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'disapproved':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void addvariant(Map<String, dynamic> product) {
    print("Add variant ${product['id']}");
    Navigator.push(
      context,
      slideRightToLeftRoute(variant(productId: product['id'])),
    );
  }

  void updateProduct(Map<String, dynamic> product) async {
  print("Update product ${product['id']}");

  final result = await Navigator.push(
    context,
    _slideLeftToRightRoute(
      UpdateProduct(productId: product['id']),
    ),
  );

  if (result == true || mounted) {
    await getproduct(selectedStatus);
  }
}

Route _slideLeftToRightRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(-1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      final tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

  Widget bannerSkeleton() {
    return Skeleton(height: 160, radius: 14);
  }

  Widget searchBarSkeleton() {
    return Row(
      children: [
        Expanded(child: Skeleton(height: 40, radius: 30)),
        const SizedBox(width: 10),
        Skeleton(height: 40, width: 110, radius: 30),
      ],
    );
  }

  Widget statusTabsSkeleton() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Skeleton(height: 36, width: 90, radius: 30),
          ),
        ),
      ),
    );
  }

  Widget productGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 320,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(height: 150, radius: 18),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Skeleton(height: 14, width: 120),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Skeleton(height: 12, width: 80),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Skeleton(height: 14, width: 60),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Skeleton(height: 40, width: double.infinity),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Skeleton extends StatelessWidget {
  final double height;
  final double width;
  final double radius;

  const Skeleton({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
      ),
    );
  }
}

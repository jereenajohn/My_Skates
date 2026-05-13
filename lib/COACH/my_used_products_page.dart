import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/COACH/add_used_product_page.dart';
import 'package:my_skates/COACH/update_used_product_page.dart';
import 'package:my_skates/COACH/used_product_big_view.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class MyUsedProductsPage extends StatefulWidget {
  const MyUsedProductsPage({super.key});

  @override
  State<MyUsedProductsPage> createState() => _MyUsedProductsPageState();
}

class _MyUsedProductsPageState extends State<MyUsedProductsPage> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> myProducts = [];
  List<Map<String, dynamic>> allMyProducts = [];

  bool isLoading = true;
  bool _animatePage = false;

  @override
  void initState() {
    super.initState();
    fetchMyUsedProducts();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _animatePage = true;
        });
      }
    });
  }

  Future<void> fetchMyUsedProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse("$api/api/myskates/my/used/products/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("MY USED PRODUCTS STATUS: ${response.statusCode}");
      print("MY USED PRODUCTS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded["data"] ?? [];

        final productsList = data.map<Map<String, dynamic>>((item) {
          final price = double.tryParse(item["price"]?.toString() ?? "0") ?? 0;
          final discount =
              double.tryParse(item["discount"]?.toString() ?? "0") ?? 0;

          // ✅ Correct image handling
          // API response gives images as a list:
          // "images": [
          //   {
          //     "id": 4,
          //     "image": "http://.../media/used_products/image.jpg"
          //   }
          // ]
          final List images = item["images"] ?? [];

          String firstImage = "";

          if (images.isNotEmpty) {
            firstImage = images.first["image"]?.toString() ?? "";
          }

          return {
            "id": item["id"],
            "title": item["title"] ?? "",
            "category": item["category"],
            "category_name": item["category_name"] ?? "",
            "user_name": item["user_name"] ?? "",
            "description": item["description"] ?? "",

            // ✅ First image for grid card
            // Do not add $api because API already gives full image URL
            "image": firstImage,

            // ✅ All images saved for big view / slider if needed
            "images": images,

            "price": price,
            "discount": discount,
            "final_price": discount > 0 ? price - discount : price,
            "status": (item["status"] ?? "").toString().toLowerCase(),
            "created_at": item["created_at"] ?? "",
            "return_policy_days": item["return_policy_days"] ?? 0,
            "shipment_charge": item["shipment_charge"] ?? "0.00",
            "payment_methods": item["payment_methods"] ?? [],
            "attribute": item["attribute"],
            "attribute_value": item["attribute_value"],
            "user": item["user"],
          };
        }).toList();

        setState(() {
          myProducts = productsList;
          allMyProducts = List.from(productsList);
        });
      } else {
        setState(() {
          myProducts = [];
          allMyProducts = [];
        });
      }
    } catch (e) {
      print("MY USED PRODUCTS ERROR: $e");
      setState(() {
        myProducts = [];
        allMyProducts = [];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> deleteUsedProduct(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final response = await http.delete(
      Uri.parse("$api/api/myskates/used/products/update/$id/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("DELETE USED PRODUCT STATUS: ${response.statusCode}");
    print("DELETE USED PRODUCT BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Used product deleted"),
          backgroundColor: Colors.green,
        ),
      );
      await fetchMyUsedProducts();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Delete failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleUpdateUsedProduct(Map<String, dynamic> product) async {
    final result = await Navigator.push(
      context,
      slideRightToLeftRoute(UpdateUsedProductPage(productId: product['id'])),
    );

    if (result == true) {
      await fetchMyUsedProducts();
    }
  }

  Future<bool> _confirmDeleteUsedProduct(
    BuildContext context,
    Map<String, dynamic> product,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1C1C1C),
            title: const Text(
              "Delete Product",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Are you sure you want to delete \"${product['title']}\"?",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _searchProducts(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        myProducts = List.from(allMyProducts);
      });
      return;
    }

    final q = query.toLowerCase();

    final filtered = allMyProducts.where((product) {
      final title = product["title"].toString().toLowerCase();
      final category = product["category_name"].toString().toLowerCase();
      final desc = product["description"].toString().toLowerCase();
      final status = product["status"].toString().toLowerCase();

      return title.contains(q) ||
          category.contains(q) ||
          desc.contains(q) ||
          status.contains(q);
    }).toList();

    setState(() {
      myProducts = filtered;
    });
  }

  Future<void> _goToAddUsedProduct() async {
    final result = await Navigator.push(
      context,
      slideRightToLeftRoute(const AddUsedProductPage()),
    );

    if (result == true) {
      await fetchMyUsedProducts();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
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
          child: RefreshIndicator(
            onRefresh: fetchMyUsedProducts,
            color: Colors.tealAccent,
            backgroundColor: Colors.black,
            displacement: 40,
            edgeOffset: 10,
            strokeWidth: 3,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: _animatePage ? 1 : 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 600),
                  offset: _animatePage ? Offset.zero : const Offset(0, 0.05),
                  curve: Curves.easeOutCubic,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              height: 50,
                              width: 68,
                              child: Image.asset(
                                "lib/assets/myskates.png",
                                fit: BoxFit.cover,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
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
                                child: TextField(
                                  controller: searchController,
                                  onChanged: _searchProducts,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.white54,
                                      size: 20,
                                    ),
                                    hintText: "Search my used products",
                                    hintStyle: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _goToAddUsedProduct,
                              child: Container(
                                height: 40,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Add Product",
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

                        const Text(
                          "My Used Products",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (isLoading)
                          _productGridSkeleton()
                        else if (myProducts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                children: const [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.white54,
                                    size: 60,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "No products found",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: myProducts.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 285,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemBuilder: (context, index) {
                              final p = myProducts[index];

                              return TweenAnimationBuilder<double>(
                                duration: Duration(
                                  milliseconds: 400 + (index * 80),
                                ),
                                tween: Tween<double>(begin: 0, end: 1),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 30 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Dismissible(
                                  key: ValueKey(p['id']),
                                  direction: DismissDirection.horizontal,
                                  confirmDismiss: (direction) async {
                                    if (direction ==
                                        DismissDirection.startToEnd) {
                                      await _handleUpdateUsedProduct(p);
                                      return false;
                                    }

                                    if (direction ==
                                        DismissDirection.endToStart) {
                                      final shouldDelete =
                                          await _confirmDeleteUsedProduct(
                                            context,
                                            p,
                                          );
                                      if (shouldDelete) {
                                        await deleteUsedProduct(p['id']);
                                      }
                                      return false;
                                    }

                                    return false;
                                  },
                                  background: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.tealAccent.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.black),
                                        SizedBox(width: 8),
                                        Text(
                                          "Update",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
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
                                      color: Colors.redAccent.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Delete",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.delete, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                  child: _productCard(p),
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    final bool isSold = p['status'] == "sold";
    
    final bool hasDiscount = (p['discount'] ?? 0) > 0;

    // ✅ Safe image URL
    final String imageUrl = p['image']?.toString() ?? "";

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
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
                  top: Radius.circular(20),
                ),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
    
                            return const ColoredBox(
                              color: Colors.white10,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.tealAccent,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Colors.white10,
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : const ColoredBox(
                          color: Colors.white10,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSold
                        ? Colors.redAccent.withOpacity(0.85)
                        : Colors.tealAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isSold ? "Sold" : "Active",
                    style: TextStyle(
                      color: isSold ? Colors.white : Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                p['title'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              p['category_name'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11.5,
                fontFamily: 'Poppins',
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              p['description']?.toString().isNotEmpty == true
                  ? p['description']
                  : "No description",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11.5,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: hasDiscount
                ? Row(
                    children: [
                      Text(
                        "₹${p['price'].toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11.5,
                          decoration: TextDecoration.lineThrough,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "₹${p['final_price'].toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    "₹${p['price'].toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _productGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 285,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF001A18),
          highlightColor: const Color(0xFF00AFA5).withOpacity(0.25),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    height: 14,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(6),
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
}

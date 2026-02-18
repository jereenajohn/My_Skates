import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class approvedProducts extends StatefulWidget {
  const approvedProducts({super.key});

  @override
  State<approvedProducts> createState() => _approvedProductsState();
}

class _approvedProductsState extends State<approvedProducts> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    getproduct("approved");
  }

  Future<void> getproduct(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('$api/api/myskates/products/status/view/$status/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("PRODUCT STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // ✅ SAFETY CHECK
        final List<dynamic> parsed = decoded['data'] ?? [];

        List<Map<String, dynamic>> tempProducts = [];

        for (final c in parsed) {
          tempProducts.add({
            'id': c['id'],
            'title': c['title'] ?? "",
            'image': c['image'] != null ? '$api${c['image']}' : "",
            'category_name': c['category_name'] ?? "",
            'price': c['base_price']?.toString() ?? "0",
            'description': c['description'] ?? "",
            'user': c['user']?.toString() ?? "",
            'variants': c['variants'] ?? [],
          });
        }

        setState(() {
          products = tempProducts;
          isLoading = false;
          isRefreshing = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    } catch (e) {
      print("Error fetching approved products: $e");
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => isRefreshing = true);
    await getproduct("approved");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
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
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.white54,
                                size: 60,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No approved products",
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
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(92, 35, 35, 35),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.grey.shade800),
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // PRODUCT IMAGE
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade900,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: p['image'].isNotEmpty
                                          ? Image.network(
                                              p['image'],
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) =>
                                                      Container(
                                                color: Colors.grey.shade800,
                                                child: const Icon(
                                                  Icons.image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.image,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // PRODUCT DETAILS
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // TITLE
                                        Text(
                                          p['title'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 6),

                                        // CATEGORY
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.category_outlined,
                                              color: Colors.grey,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              p['category_name'],
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        // PRICE
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.currency_rupee,
                                              color: Colors.tealAccent,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "₹${p['price']}",
                                              style: const TextStyle(
                                                color: Colors.tealAccent,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        // DESCRIPTION (Optional)
                                        if (p['description'].isNotEmpty)
                                          Text(
                                            p['description'],
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
                                ],
                              ),
                              
                              // Variants count badge (if any)
                              if (p['variants'] != null && 
                                  p['variants'].isNotEmpty)
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
                                    child: Text(
                                      "${p['variants'].length} variant(s)",
                                      style: const TextStyle(
                                        color: Colors.tealAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
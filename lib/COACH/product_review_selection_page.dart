// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:my_skates/COACH/product_review_approval_page.dart';
// import 'package:my_skates/ADMIN/slideRightRoute.dart';
// import 'package:my_skates/api.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;

// class ProductReviewSelectionPage extends StatefulWidget {
//   const ProductReviewSelectionPage({super.key});

//   @override
//   State<ProductReviewSelectionPage> createState() => _ProductReviewSelectionPageState();
// }

// class _ProductReviewSelectionPageState extends State<ProductReviewSelectionPage> {
//   List<Map<String, dynamic>> _products = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchProductsWithPendingReviews();
//   }

//   Future<void> _fetchProductsWithPendingReviews() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("access");

//       if (token == null) return;

//       // Fetch all products
//       final productsResponse = await http.get(
//         Uri.parse("$api/api/myskates/products/"),
//         headers: {"Authorization": "Bearer $token"},
//       );

//       if (productsResponse.statusCode == 200) {
//         final productsData = jsonDecode(productsResponse.body);
//         List products = productsData['data'] ?? productsData;
        
//         List<Map<String, dynamic>> productsWithPending = [];

//         // For each product, check pending reviews count
//         for (var product in products) {
//           final reviewResponse = await http.get(
//             Uri.parse("$api/api/myskates/products/${product['id']}/ratings/"),
//             headers: {"Authorization": "Bearer $token"},
//           );

//           if (reviewResponse.statusCode == 200) {
//             final jsonResponse = jsonDecode(reviewResponse.body);
            
//             List<dynamic> reviews;
//             if (jsonResponse is List) {
//               reviews = jsonResponse;
//             } else if (jsonResponse is Map && jsonResponse['data'] != null) {
//               reviews = jsonResponse['data'] as List;
//             } else {
//               reviews = [];
//             }
            
//             final pendingCount = reviews.where((r) => r['approval_status'] == 'pending').length;

//             if (pendingCount > 0) {
//               productsWithPending.add({
//                 'id': product['id'],
//                 'name': product['title'] ?? 'Product',
//                 'image': product['image'] ?? '',
//                 'pending_count': pendingCount,
//               });
//             }
//           }
//         }

//         setState(() {
//           _products = productsWithPending;
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print("Error fetching products: $e");
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           "Select Product",
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _fetchProductsWithPendingReviews,
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Color(0xFF00332D), Colors.black],
//           ),
//         ),
//         child: _isLoading
//             ? const Center(child: CircularProgressIndicator(color: Colors.teal))
//             : _products.isEmpty
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(
//                           Icons.check_circle_outline,
//                           size: 64,
//                           color: Colors.white24,
//                         ),
//                         const SizedBox(height: 16),
//                         const Text(
//                           "No pending reviews",
//                           style: TextStyle(color: Colors.white54, fontSize: 16),
//                         ),
//                         const SizedBox(height: 8),
//                         const Text(
//                           "All product reviews have been processed",
//                           style: TextStyle(color: Colors.white38, fontSize: 14),
//                         ),
//                       ],
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.all(16),
//                     itemCount: _products.length,
//                     itemBuilder: (context, index) {
//                       final product = _products[index];
//                       return _buildProductCard(product);
//                     },
//                   ),
//       ),
//     );
//   }

//   Widget _buildProductCard(Map<String, dynamic> product) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           slideRightToLeftRoute(
//             ProductReviewApprovalPage(
//               productId: product['id'],
//               productName: product['name'],
//             ),
//           ),
//         ).then((_) {
//           // Refresh the list when coming back
//           _fetchProductsWithPendingReviews();
//         });
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white12,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.teal.withOpacity(0.3)),
//         ),
//         child: Row(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.network(
//                 product['image'],
//                 width: 60,
//                 height: 60,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) {
//                   return Container(
//                     width: 60,
//                     height: 60,
//                     color: Colors.grey[800],
//                     child: const Icon(Icons.image, color: Colors.white54),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     product['name'],
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.orange.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       "${product['pending_count']} pending ${product['pending_count'] == 1 ? 'review' : 'reviews'}",
//                       style: const TextStyle(
//                         color: Colors.orange,
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
//           ],
//         ),
//       ),
//     );
//   }
// }
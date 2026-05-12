// import 'dart:convert';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:my_skates/api.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shimmer/shimmer.dart';

// class approvedProducts extends StatefulWidget {
//   const approvedProducts({super.key});

//   @override
//   State<approvedProducts> createState() => _approvedProductsState();
// }

// class _approvedProductsState extends State<approvedProducts> {
//   List<Map<String, dynamic>> products = [];
//   bool isLoading = true;
//   bool isRefreshing = false;
//   bool isPageLoading = false;

//   Map<int, bool> expandedProducts = {};

//   int currentPage = 1;
//   int totalCount = 0;
//   String? nextPageUrl;
//   String? previousPageUrl;
//   final int pageSize = 10;

//   @override
//   void initState() {
//     super.initState();
//     getproduct("approved");
//   }

//   Future<void> getproduct(String status, {int page = 1}) async {
//     try {
//       setState(() {
//         if (page == 1) {
//           isLoading = true;
//         } else {
//           isPageLoading = true;
//         }
//       });

//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("access");

//       if (token == null) {
//         setState(() {
//           isLoading = false;
//           isPageLoading = false;
//           isRefreshing = false;
//         });
//         return;
//       }

//       final response = await http.get(
//         Uri.parse('$api/api/myskates/products/status/view/$status/?page=$page'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print("APPROVED PRODUCTS STATUS: ${response.statusCode}");
//       print("APPROVED PRODUCTS BODY: ${response.body}");

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);

//         totalCount = decoded['count'] ?? 0;
//         nextPageUrl = decoded['next'];
//         previousPageUrl = decoded['previous'];
//         currentPage = page;

//         final List<dynamic> parsed = decoded['results']?['data'] ?? [];

//         Map<int, Map<String, dynamic>> productMap = {};

//         for (final item in parsed) {
//           if (item.containsKey('title') &&
//               item['title'] != null &&
//               item['title'].toString().isNotEmpty &&
//               item.containsKey('variants')) {
//             final int productId = item['id'];

//             List<Map<String, dynamic>> processedVariants = [];

//             if (item['variants'] != null && item['variants'].isNotEmpty) {
//               for (final variant in item['variants']) {
//                 String variantImage = "";

//                 if (variant['images'] != null && variant['images'].isNotEmpty) {
//                   String imagePath = variant['images'][0]['image'] ?? "";

//                   if (imagePath.startsWith('http://') ||
//                       imagePath.startsWith('https://')) {
//                     variantImage = imagePath;
//                   } else {
//                     variantImage = '$api$imagePath';
//                   }
//                 }

//                 processedVariants.add({
//                   'id': variant['id'],
//                   'sku': variant['sku'] ?? "",
//                   'price': variant['price']?.toString() ?? "0",
//                   'discount': variant['discount']?.toString() ?? "0",
//                   'stock': variant['stock'] ?? 0,
//                   'category_name':
//                       variant['category_name'] ?? item['category_name'] ?? "",
//                   'image': variantImage,
//                   'approval_status':
//                       variant['approval_status']?.toString() ?? 'pending',
//                   'description': variant['description'] ?? "",
//                   'is_active': variant['is_active'] ?? true,
//                 });
//               }
//             }

//             String mainImage = "";

//             if (item['image'] != null && item['image'].toString().isNotEmpty) {
//               String imagePath = item['image'];

//               if (imagePath.startsWith('http://') ||
//                   imagePath.startsWith('https://')) {
//                 mainImage = imagePath;
//               } else {
//                 mainImage = '$api$imagePath';
//               }
//             }

//             productMap[productId] = {
//               'id': item['id'],
//               'title': item['title'] ?? "",
//               'image': mainImage,
//               'category_name': item['category_name'] ?? "",
//               'price': item['base_price']?.toString() ?? "0",
//               'description': item['description'] ?? "",
//               'user': item['user']?.toString() ?? "",
//               'variants': processedVariants,
//               'created_at': item['created_at'] ?? "",
//               'approval_status': item['approval_status']?.toString() ?? status,
//             };
//           }
//         }

//         products = productMap.values.toList();

//         for (final product in products) {
//           final List variants = product['variants'];
//           variants.sort((a, b) => (a['sku'] ?? '').compareTo(b['sku'] ?? ''));
//         }
//       }

//       setState(() {
//         isLoading = false;
//         isRefreshing = false;
//         isPageLoading = false;
//       });
//     } catch (e) {
//       print("ERROR FETCHING APPROVED PRODUCTS: $e");

//       setState(() {
//         isLoading = false;
//         isRefreshing = false;
//         isPageLoading = false;
//       });
//     }
//   }

//   Future<void> _refreshData() async {
//     setState(() {
//       isRefreshing = true;
//     });

//     await getproduct("approved", page: 1);
//   }

//   Future<void> updateMainProductStatus(int id, String status) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("access");

//     if (token == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Authentication token missing"),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     try {
//       final response = await http.patch(
//         Uri.parse("$api/api/myskates/products/approval/$id/"),
//         headers: {
//           "Authorization": "Bearer $token",
//         },
//         body: {
//           "approval_status": status,
//         },
//       );

//       print("MAIN PRODUCT STATUS UPDATE ID: $id");
//       print("MAIN PRODUCT STATUS UPDATE TO: $status");
//       print("MAIN PRODUCT STATUS UPDATE CODE: ${response.statusCode}");
//       print("MAIN PRODUCT STATUS UPDATE BODY: ${response.body}");

//       if (response.statusCode == 200) {
//         if (!mounted) return;

//         Navigator.pop(context);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               status == "approved"
//                   ? "Product approved successfully"
//                   : "Product disapproved successfully",
//             ),
//             backgroundColor: status == "approved" ? Colors.green : Colors.orange,
//           ),
//         );

//         await getproduct("approved", page: currentPage);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "Failed to update product status: ${response.statusCode}",
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       print("MAIN PRODUCT STATUS UPDATE ERROR: $e");

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error updating product status: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Widget _buildPaginationControls(String status) {
//     final int totalPages = totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

//     return Container(
//       margin: const EdgeInsets.only(top: 12, bottom: 20),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.06),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white.withOpacity(0.10)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           ElevatedButton.icon(
//             onPressed: previousPageUrl == null || isPageLoading
//                 ? null
//                 : () {
//                     getproduct(status, page: currentPage - 1);
//                   },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.white.withOpacity(0.10),
//               disabledBackgroundColor: Colors.white.withOpacity(0.04),
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             icon: const Icon(
//               Icons.chevron_left_rounded,
//               size: 18,
//               color: Colors.white,
//             ),
//             label: const Text(
//               "Prev",
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//           isPageLoading
//               ? const SizedBox(
//                   height: 22,
//                   width: 22,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Color(0xFF00CFC5),
//                   ),
//                 )
//               : Text(
//                   "Page $currentPage of $totalPages",
//                   style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//           ElevatedButton.icon(
//             onPressed: nextPageUrl == null || isPageLoading
//                 ? null
//                 : () {
//                     getproduct(status, page: currentPage + 1);
//                   },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF00CFC5),
//               disabledBackgroundColor: Colors.white.withOpacity(0.04),
//               foregroundColor: Colors.black,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             icon: const Icon(
//               Icons.chevron_right_rounded,
//               size: 18,
//               color: Colors.white,
//             ),
//             label: const Text(
//               "Next",
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showProductDetailDialog(Map<String, dynamic> product) {
//     final List variants = product['variants'] ?? [];

//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (BuildContext dialogContext) {
//         return BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//           child: Dialog(
//             backgroundColor: Colors.transparent,
//             insetPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 24,
//             ),
//             child: Container(
//               constraints: BoxConstraints(
//                 maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
//               ),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1A1A),
//                 borderRadius: BorderRadius.circular(24),
//                 border: Border.all(color: Colors.white.withOpacity(0.1)),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.3),
//                     blurRadius: 20,
//                     offset: const Offset(0, 8),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     height: 200,
//                     decoration: BoxDecoration(
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(24),
//                         topRight: Radius.circular(24),
//                       ),
//                       image: product['image'].toString().isNotEmpty
//                           ? DecorationImage(
//                               image: NetworkImage(product['image']),
//                               fit: BoxFit.cover,
//                             )
//                           : null,
//                       color: Colors.grey[800],
//                     ),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(24),
//                           topRight: Radius.circular(24),
//                         ),
//                         gradient: LinearGradient(
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                           colors: [
//                             Colors.transparent,
//                             Colors.black.withOpacity(0.7),
//                           ],
//                         ),
//                       ),
//                       child: Align(
//                         alignment: Alignment.bottomLeft,
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.green.withOpacity(0.8),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: const Text(
//                                   "APPROVED",
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 product['title'],
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Flexible(
//                     child: SingleChildScrollView(
//                       padding: const EdgeInsets.all(20),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF00CFC5).withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Text(
//                               product['category_name'],
//                               style: const TextStyle(
//                                 color: Color(0xFF00CFC5),
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               const Icon(
//                                 Icons.currency_rupee,
//                                 color: Colors.white70,
//                                 size: 20,
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 product['price'],
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 28,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           if (product['description'].toString().isNotEmpty) ...[
//                             const Text(
//                               "Description",
//                               style: TextStyle(
//                                 color: Colors.white70,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.05),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: Colors.white.withOpacity(0.1),
//                                 ),
//                               ),
//                               child: Text(
//                                 product['description'],
//                                 style: const TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 14,
//                                   height: 1.5,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                           ],
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 8,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.05),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: Colors.white.withOpacity(0.1),
//                               ),
//                             ),
//                             child: Row(
//                               children: [
//                                 const Icon(
//                                   Icons.tag,
//                                   color: Colors.white54,
//                                   size: 16,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   "Product ID: ${product['id']}",
//                                   style: const TextStyle(
//                                     color: Colors.white54,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           if (variants.isNotEmpty) ...[
//                             const SizedBox(height: 16),
//                             const Divider(color: Colors.white24, height: 24),
//                             Row(
//                               children: [
//                                 const Icon(
//                                   Icons.swap_horiz,
//                                   color: Colors.white70,
//                                   size: 20,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   "Variants (${variants.length})",
//                                   style: const TextStyle(
//                                     color: Colors.white70,
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 12),
//                             ...variants.map((variant) {
//                               return _buildDialogVariantCard(variant);
//                             }).toList(),
//                             const SizedBox(height: 8),
//                             Container(
//                               width: double.infinity,
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.orange.withOpacity(0.12),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: Colors.orange.withOpacity(0.35),
//                                 ),
//                               ),
//                               child: const Row(
//                                 children: [
//                                   Icon(
//                                     Icons.info_outline,
//                                     color: Colors.orange,
//                                     size: 20,
//                                   ),
//                                   SizedBox(width: 10),
//                                   Expanded(
//                                     child: Text(
//                                       "To change variant status, first disapprove the main product. Then open it from Disapproved Products screen.",
//                                       style: TextStyle(
//                                         color: Colors.white70,
//                                         fontSize: 12,
//                                         height: 1.35,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                           const SizedBox(height: 18),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: GestureDetector(
//                                   onTap: () => Navigator.pop(dialogContext),
//                                   child: Container(
//                                     height: 48,
//                                     decoration: BoxDecoration(
//                                       color: Colors.grey[800],
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: const Center(
//                                       child: Text(
//                                         "Close",
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: GestureDetector(
//                                   onTap: () {
//                                     updateMainProductStatus(
//                                       product['id'],
//                                       "disapproved",
//                                     );
//                                   },
//                                   child: Container(
//                                     height: 48,
//                                     decoration: BoxDecoration(
//                                       color: Colors.red.withOpacity(0.85),
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: const Center(
//                                       child: Text(
//                                         "Disapprove Product",
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDialogVariantCard(Map<String, dynamic> variant) {
//     final String approvalStatus =
//         variant['approval_status']?.toString() ?? 'pending';

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: approvalStatus == 'approved'
//               ? Colors.green.withOpacity(0.3)
//               : approvalStatus == 'disapproved'
//                   ? Colors.red.withOpacity(0.3)
//                   : Colors.white.withOpacity(0.1),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               if (variant['image'] != null &&
//                   variant['image'].toString().isNotEmpty) ...[
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(10),
//                   child: Image.network(
//                     variant['image'],
//                     width: 48,
//                     height: 48,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         width: 48,
//                         height: 48,
//                         color: Colors.grey[800],
//                         child: const Icon(
//                           Icons.image,
//                           color: Colors.grey,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//               ],
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       variant['sku']?.toString() ?? '',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       "₹${variant['price']}",
//                       style: const TextStyle(
//                         color: Colors.tealAccent,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               _buildVariantStatusChip(approvalStatus),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Row(
//             children: [
//               _buildVariantInfoBox(
//                 title: "Stock",
//                 value: variant['stock'].toString(),
//               ),
//               const SizedBox(width: 8),
//               _buildVariantInfoBox(
//                 title: "Discount",
//                 value: "${variant['discount']}%",
//               ),
//               const SizedBox(width: 8),
//               _buildVariantInfoBox(
//                 title: "Active",
//                 value: variant['is_active'] == true ? "Yes" : "No",
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildVariantInfoBox({
//     required String title,
//     required String value,
//   }) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.04),
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: Colors.white.withOpacity(0.08),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 color: Colors.white54,
//                 fontSize: 10,
//               ),
//             ),
//             const SizedBox(height: 3),
//             Text(
//               value,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildVariantStatusChip(String status) {
//     Color bgColor;
//     Color textColor;
//     IconData icon;

//     if (status == 'approved') {
//       bgColor = Colors.green.withOpacity(0.2);
//       textColor = Colors.green;
//       icon = Icons.check_circle;
//     } else if (status == 'disapproved') {
//       bgColor = Colors.red.withOpacity(0.2);
//       textColor = Colors.red;
//       icon = Icons.cancel;
//     } else {
//       bgColor = Colors.orange.withOpacity(0.2);
//       textColor = Colors.orange;
//       icon = Icons.pending;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(9),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             color: textColor,
//             size: 12,
//           ),
//           const SizedBox(width: 4),
//           Text(
//             status.toUpperCase(),
//             style: TextStyle(
//               color: textColor,
//               fontSize: 9,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGlassProductCard(Map<String, dynamic> product) {
//     final List variants = product['variants'] ?? [];
//     final bool isExpanded = expandedProducts[product['id']] ?? false;

//     return GestureDetector(
//       onTap: () => _showProductDetailDialog(product),
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 15),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(22),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.06),
//                 borderRadius: BorderRadius.circular(22),
//                 border: Border.all(color: Colors.white.withOpacity(0.10)),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.20),
//                     blurRadius: 14,
//                     offset: const Offset(0, 6),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         width: 70,
//                         height: 70,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12),
//                           color: Colors.grey.shade900,
//                         ),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(12),
//                           child: product['image'].toString().isNotEmpty
//                               ? Image.network(
//                                   product['image'],
//                                   fit: BoxFit.cover,
//                                   errorBuilder: (context, error, stackTrace) {
//                                     return Container(
//                                       color: Colors.grey.shade800,
//                                       child: const Icon(
//                                         Icons.image,
//                                         color: Colors.grey,
//                                       ),
//                                     );
//                                   },
//                                 )
//                               : const Icon(
//                                   Icons.image,
//                                   color: Colors.grey,
//                                 ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     product['title'],
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8,
//                                     vertical: 4,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.green.withOpacity(0.2),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: const Text(
//                                     "APPROVED",
//                                     style: TextStyle(
//                                       color: Colors.green,
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 6),
//                             Row(
//                               children: [
//                                 const Icon(
//                                   Icons.category_outlined,
//                                   color: Colors.grey,
//                                   size: 16,
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Expanded(
//                                   child: Text(
//                                     product['category_name'],
//                                     style: const TextStyle(
//                                       color: Colors.grey,
//                                       fontSize: 13,
//                                     ),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 4),
//                             Row(
//                               children: [
//                                 const Icon(
//                                   Icons.currency_rupee,
//                                   color: Colors.tealAccent,
//                                   size: 16,
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Expanded(
//                                   child: Text(
//                                     "₹${product['price']}",
//                                     style: const TextStyle(
//                                       color: Colors.tealAccent,
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                                 if (variants.isNotEmpty) ...[
//                                   const SizedBox(width: 8),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 6,
//                                       vertical: 2,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: Colors.teal.withOpacity(0.2),
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: Text(
//                                       "${variants.length} variants",
//                                       style: const TextStyle(
//                                         color: Colors.tealAccent,
//                                         fontSize: 10,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ],
//                             ),
//                             const SizedBox(height: 4),
//                             if (product['description']
//                                 .toString()
//                                 .isNotEmpty)
//                               Text(
//                                 product['description'],
//                                 style: const TextStyle(
//                                   color: Colors.white54,
//                                   fontSize: 12,
//                                 ),
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                           ],
//                         ),
//                       ),
//                       const Icon(
//                         Icons.chevron_right,
//                         color: Colors.white54,
//                       ),
//                     ],
//                   ),
//                   if (variants.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 8),
//                       child: GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             expandedProducts[product['id']] = !isExpanded;
//                           });
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.teal.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                               color: Colors.tealAccent.withOpacity(0.3),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 isExpanded
//                                     ? Icons.expand_less
//                                     : Icons.expand_more,
//                                 color: Colors.tealAccent,
//                                 size: 14,
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 isExpanded
//                                     ? "Hide variants"
//                                     : "Show ${variants.length} variants",
//                                 style: const TextStyle(
//                                   color: Colors.tealAccent,
//                                   fontSize: 11,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   if (isExpanded && variants.isNotEmpty) ...[
//                     const Divider(color: Colors.white24, height: 16),
//                     ...variants.map((variant) => _buildVariantCard(variant)),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildVariantCard(Map<String, dynamic> variant) {
//     final String status = variant['approval_status']?.toString() ?? 'pending';

//     return Container(
//       margin: const EdgeInsets.only(top: 8, bottom: 8, left: 10),
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: status == 'approved'
//               ? Colors.green.withOpacity(0.3)
//               : status == 'disapproved'
//                   ? Colors.red.withOpacity(0.3)
//                   : Colors.white.withOpacity(0.1),
//         ),
//       ),
//       child: Row(
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: Colors.grey[800],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: variant['image'] != null &&
//                       variant['image'].toString().isNotEmpty
//                   ? Image.network(
//                       variant['image'],
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return Icon(
//                           Icons.image,
//                           color: Colors.grey[600],
//                         );
//                       },
//                     )
//                   : Icon(
//                       Icons.image,
//                       color: Colors.grey[600],
//                     ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   variant['sku']?.toString() ?? '',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   "₹${variant['price']}",
//                   style: const TextStyle(
//                     color: Colors.tealAccent,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _buildVariantStatusChip(status),
//         ],
//       ),
//     );
//   }

//   Widget _buildShimmerCard() {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 15),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(22),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.06),
//               borderRadius: BorderRadius.circular(22),
//               border: Border.all(color: Colors.white.withOpacity(0.10)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.20),
//                   blurRadius: 14,
//                   offset: const Offset(0, 6),
//                 ),
//               ],
//             ),
//             child: Shimmer.fromColors(
//               baseColor: const Color(0xFF1A2B2A),
//               highlightColor: const Color(0xFF2F4F4D),
//               child: Column(
//                 children: [
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         width: 70,
//                         height: 70,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Container(
//                               height: 16,
//                               width: double.infinity,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Container(
//                               height: 12,
//                               width: 120,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Container(
//                               height: 14,
//                               width: 90,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Container(
//                               height: 12,
//                               width: double.infinity,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                             ),
//                             const SizedBox(height: 6),
//                             Container(
//                               height: 12,
//                               width: 180,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: Container(
//                       height: 26,
//                       width: 100,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildShimmerList() {
//     return ListView.builder(
//       physics: const AlwaysScrollableScrollPhysics(),
//       padding: const EdgeInsets.all(10),
//       itemCount: 6,
//       itemBuilder: (context, index) => _buildShimmerCard(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.transparent,
//       child: isLoading
//           ? _buildShimmerList()
//           : RefreshIndicator(
//               onRefresh: _refreshData,
//               color: Colors.tealAccent,
//               backgroundColor: Colors.black,
//               strokeWidth: 3.0,
//               displacement: 40.0,
//               child: products.isEmpty
//                   ? SingleChildScrollView(
//                       physics: const AlwaysScrollableScrollPhysics(),
//                       child: SizedBox(
//                         height: MediaQuery.of(context).size.height * 0.8,
//                         child: const Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.inventory_2_outlined,
//                                 color: Colors.white54,
//                                 size: 60,
//                               ),
//                               SizedBox(height: 16),
//                               Text(
//                                 "No approved products",
//                                 style: TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     )
//                   : ListView.builder(
//                       physics: const AlwaysScrollableScrollPhysics(),
//                       padding: const EdgeInsets.all(10),
//                       itemCount: products.length + 1,
//                       itemBuilder: (context, index) {
//                         if (index == products.length) {
//                           return _buildPaginationControls("approved");
//                         }

//                         final product = products[index];
//                         return _buildGlassProductCard(product);
//                       },
//                     ),
//             ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class approvedProducts extends StatefulWidget {
  const approvedProducts({super.key});

  @override
  State<approvedProducts> createState() => _approvedProductsState();
}

class _approvedProductsState extends State<approvedProducts> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  bool isRefreshing = false;
  bool isPageLoading = false;

  Map<int, bool> expandedProducts = {};

  int currentPage = 1;
  int totalCount = 0;
  String? nextPageUrl;
  String? previousPageUrl;
  final int pageSize = 10;

  @override
  void initState() {
    super.initState();
    getproduct("approved");
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
          isRefreshing = false;
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

      print("APPROVED PRODUCTS STATUS: ${response.statusCode}");
      print("APPROVED PRODUCTS BODY: ${response.body}");

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
            final int productId = item['id'];

            List<Map<String, dynamic>> processedVariants = [];

            if (item['variants'] != null && item['variants'].isNotEmpty) {
              for (final variant in item['variants']) {
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
                  'approval_status':
                      variant['approval_status']?.toString() ?? 'pending',
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
              'approval_status': item['approval_status']?.toString() ?? status,
            };
          }
        }

        products = productMap.values.toList();

        for (final product in products) {
          final List variants = product['variants'];
          variants.sort((a, b) => (a['sku'] ?? '').compareTo(b['sku'] ?? ''));
        }
      }

      setState(() {
        isLoading = false;
        isRefreshing = false;
        isPageLoading = false;
      });
    } catch (e) {
      print("ERROR FETCHING APPROVED PRODUCTS: $e");

      setState(() {
        isLoading = false;
        isRefreshing = false;
        isPageLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isRefreshing = true;
    });

    await getproduct("approved", page: 1);
  }

  // Update main product status - when disapproved, all variants get disapproved automatically
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
      late final Uri uri;
      Object? requestBody;

      if (status == "approved") {
        // NEW API: approve product and all variants
        uri = Uri.parse("$api/api/myskates/products/$id/approve/all/");
        requestBody = null;
      } else {
        // Keep old API for disapprove unless backend gives a separate disapprove/all API
        uri = Uri.parse("$api/api/myskates/products/approval/$id/");
        requestBody = jsonEncode({"approval_status": status});
      }

      final response = await http.patch(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: requestBody,
      );

      print("MAIN PRODUCT STATUS UPDATE ID: $id");
      print("MAIN PRODUCT STATUS UPDATE TO: $status");
      print("MAIN PRODUCT STATUS UPDATE URL: $uri");
      print("MAIN PRODUCT STATUS UPDATE CODE: ${response.statusCode}");
      print("MAIN PRODUCT STATUS UPDATE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 202) {
        if (!mounted) return;

        Map<String, dynamic>? decoded;
        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map<String, dynamic>) {
            decoded = parsed;
          }
        } catch (_) {
          decoded = null;
        }

        final String message =
            decoded?["message"]?.toString() ??
            (status == "approved"
                ? "Product and all variants approved successfully"
                : "Product and all variants disapproved successfully");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: status == "approved"
                ? Colors.green
                : Colors.orange,
          ),
        );

        await getproduct("approved", page: currentPage);
      } else {
        if (!mounted) return;

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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating product status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NEW: Update individual variant status
  Future<void> updateVariantStatus(
    int productId,
    int variantId,
    String status,
  ) async {
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

        // Refresh the current page to show updated status
        await getproduct("approved", page: currentPage);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to update variant status: ${response.statusCode}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("VARIANT STATUS UPDATE ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating variant status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NEW: Show confirmation dialog for variant disapproval
  void _showVariantDisapprovalDialog(
    Map<String, dynamic> product,
    Map<String, dynamic> variant,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            "Disapprove Variant",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Are you sure you want to disapprove this variant?",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SKU: ${variant['sku']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Price: ₹${variant['price']}",
                      style: const TextStyle(color: Colors.tealAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "⚠️ Only this variant will be disapproved. Other variants will remain approved.",
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                updateVariantStatus(
                  product['id'],
                  variant['id'],
                  "disapproved",
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Disapprove"),
            ),
          ],
        );
      },
    );
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

  void _showProductDetailDialog(Map<String, dynamic> product) {
    final List variants = product['variants'] ?? [];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
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
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
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
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      image: product['image'].toString().isNotEmpty
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
                                  color: Colors.green.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "APPROVED",
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
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          if (product['description'].toString().isNotEmpty) ...[
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
                            ...variants.map((variant) {
                              return _buildDialogVariantCard(product, variant);
                            }).toList(),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(dialogContext),
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
                                    Navigator.pop(dialogContext);
                                    _showMainProductDisapprovalDialog(product);
                                  },
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "Disapprove Product & All Variants",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
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

  // NEW: Show confirmation dialog for main product disapproval
  void _showMainProductDisapprovalDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            "Disapprove Product",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Are you sure you want to disapprove '${product['title']}'?",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "⚠️ This will disapprove the main product AND ALL its variants. This action cannot be undone easily.",
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                updateMainProductStatus(product['id'], "disapproved");
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Disapprove All"),
            ),
          ],
        );
      },
    );
  }

  // UPDATED: Dialog variant card with disapprove button for each variant
  Widget _buildDialogVariantCard(
    Map<String, dynamic> product,
    Map<String, dynamic> variant,
  ) {
    final String approvalStatus =
        variant['approval_status']?.toString() ?? 'pending';

    // Only show disapprove button for approved variants
    final bool canDisapprove = approvalStatus == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: approvalStatus == 'approved'
              ? Colors.green.withOpacity(0.3)
              : approvalStatus == 'disapproved'
              ? Colors.red.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (variant['image'] != null &&
                  variant['image'].toString().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    variant['image'],
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[800],
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant['sku']?.toString() ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${variant['price']}",
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildVariantStatusChip(approvalStatus),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildVariantInfoBox(
                title: "Stock",
                value: variant['stock'].toString(),
              ),
              const SizedBox(width: 8),
              _buildVariantInfoBox(
                title: "Discount",
                value: "${variant['discount']}%",
              ),
              const SizedBox(width: 8),
              _buildVariantInfoBox(
                title: "Active",
                value: variant['is_active'] == true ? "Yes" : "No",
              ),
            ],
          ),
          if (canDisapprove) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close dialog first
                _showVariantDisapprovalDialog(product, variant);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Text(
                    "Disapprove This Variant Only",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ] else if (approvalStatus == 'disapproved') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  "Variant Disapproved",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantInfoBox({required String title, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantStatusChip(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    if (status == 'approved') {
      bgColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green;
      icon = Icons.check_circle;
    } else if (status == 'disapproved') {
      bgColor = Colors.red.withOpacity(0.2);
      textColor = Colors.red;
      icon = Icons.cancel;
    } else {
      bgColor = Colors.orange.withOpacity(0.2);
      textColor = Colors.orange;
      icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 12),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Variant card in main list with disapprove button
  Widget _buildVariantCard(
    Map<String, dynamic> product,
    Map<String, dynamic> variant,
  ) {
    final String status = variant['approval_status']?.toString() ?? 'pending';
    final bool canDisapprove = status == 'approved';

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8, left: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'approved'
              ? Colors.green.withOpacity(0.3)
              : status == 'disapproved'
              ? Colors.red.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
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
                  child:
                      variant['image'] != null &&
                          variant['image'].toString().isNotEmpty
                      ? Image.network(
                          variant['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image, color: Colors.grey[600]);
                          },
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
                      variant['sku']?.toString() ?? '',
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
              _buildVariantStatusChip(status),
            ],
          ),
          if (canDisapprove) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showVariantDisapprovalDialog(product, variant),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Text(
                    "Disapprove Variant",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ] else if (status == 'disapproved') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  "Disapproved",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // UPDATED: Glass product card with expanded variants showing disapprove buttons
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
                          child: product['image'].toString().isNotEmpty
                              ? Image.network(
                                  product['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
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
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "APPROVED",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
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
                                  color: Colors.tealAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "₹${product['price']}",
                                    style: const TextStyle(
                                      color: Colors.tealAccent,
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
                            if (product['description'].toString().isNotEmpty)
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
                      width: 100,
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
                              Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.white54,
                                size: 60,
                              ),
                              SizedBox(height: 16),
                              Text(
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
                      itemCount: products.length + 1,
                      itemBuilder: (context, index) {
                        if (index == products.length) {
                          return _buildPaginationControls("approved");
                        }

                        final product = products[index];
                        return _buildGlassProductCard(product);
                      },
                    ),
            ),
    );
  }
}

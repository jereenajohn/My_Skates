// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:ui';
// import 'package:my_skates/api.dart';

// // lib/models/review_model.dart
// class ReviewModel {
//   final int id;
//   final String productName;
//   final String userFirstName;
//   final String userLastName;
//   final String? userProfile;
//   final int rating;
//   final String review;
//   final String approvalStatus;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final int product;
//   final int user;

//   ReviewModel({
//     required this.id,
//     required this.productName,
//     required this.userFirstName,
//     required this.userLastName,
//     this.userProfile,
//     required this.rating,
//     required this.review,
//     required this.approvalStatus,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.product,
//     required this.user,
//   });

//   factory ReviewModel.fromJson(Map<String, dynamic> json) {
//     return ReviewModel(
//       id: json['id'],
//       productName: json['product_name'],
//       userFirstName: json['user_first_name'],
//       userLastName: json['user_last_name'],
//       userProfile: json['user_profile'],
//       rating: json['rating'],
//       review: json['review'],
//       approvalStatus: json['approval_status'],
//       createdAt: DateTime.parse(json['created_at']),
//       updatedAt: DateTime.parse(json['updated_at']),
//       product: json['product'],
//       user: json['user'],
//     );
//   }
// }

// class AdminProductReview extends StatefulWidget {
//   final int productId;
//   final String productTitle;
//   final String? productImage;
//   final int variantId;
//   final String? variantImage;
//   final String variantLabel;

//   const AdminProductReview({
//     super.key,
//     required this.productId,
//     required this.productTitle,
//     this.productImage,
//     required this.variantId,
//     this.variantImage,
//     required this.variantLabel,
//   });

//   @override
//   State<AdminProductReview> createState() => _AdminProductReviewState();
// }

// class _AdminProductReviewState extends State<AdminProductReview> {
//   double _selectedRating = 0;
//   final TextEditingController _reviewController = TextEditingController();
//   bool _isSubmitted = false;
//   bool _isLoading = false;

//   Future<void> _fetchProductReviews() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("access");

//       final response = await http.get(
//         Uri.parse('$api/api/myskates/products/${widget.productId}/ratings/'),
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         print('Existing reviews: $data');
//       }
//     } catch (e) {
//       print('Error fetching reviews: $e');
//     }
//   }

//   Future<void> _submitReview() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("access");

//       if (token == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Please login to submit a review'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         setState(() {
//           _isLoading = false;
//         });
//         return;
//       }

//       final url = '$api/api/myskates/products/${widget.productId}/ratings/';

//       Map<String, dynamic> reviewData = {
//         'rating': _selectedRating,
//         'review': _reviewController.text.trim(),
//         'variant': widget.variantId,
//       };

//       print('Submitting to URL: $url');
//       print('Review data: $reviewData');

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode(reviewData),
//       );

//       print('Review API Status: ${response.statusCode}');
//       print('Review API Response: ${response.body}');

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         setState(() {
//           _isSubmitted = true;
//           _isLoading = false;
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Review submitted successfully!'),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );

//         await Future.delayed(const Duration(seconds: 1));
//         if (mounted) Navigator.pop(context, true);
//       } else {
//         setState(() {
//           _isLoading = false;
//         });

//         String errorMessage = 'Failed to submit review';
//         try {
//           final errorData = json.decode(response.body);
//           if (errorData['message'] != null) {
//             errorMessage = errorData['message'];
//           } else if (errorData['error'] != null) {
//             errorMessage = errorData['error'];
//           } else if (errorData['detail'] != null) {
//             errorMessage = errorData['detail'];
//           }
//         } catch (e) {}

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
//         );
//       }
//     } catch (e) {
//       print('Error submitting review: $e');
//       setState(() {
//         _isLoading = false;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Widget _glassWrap({required Widget child, EdgeInsets? padding}) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//         child: Container(
//           padding: padding,
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.06),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: Colors.white.withOpacity(0.10)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.20),
//                 blurRadius: 14,
//                 offset: const Offset(0, 6),
//               ),
//             ],
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }

//   Widget _buildProductImage() {
//     final imagePath = widget.variantImage ?? widget.productImage;

//     if (imagePath == null || imagePath.isEmpty) {
//       return Container(
//         color: Colors.white.withOpacity(0.04),
//         child: const Icon(
//           Icons.image_not_supported,
//           color: Colors.white38,
//           size: 34,
//         ),
//       );
//     }

//     return Image.network(
//       '$api$imagePath',
//       fit: BoxFit.cover,
//       errorBuilder: (_, __, ___) => Container(
//         color: Colors.white.withOpacity(0.04),
//         child: const Icon(
//           Icons.image_not_supported,
//           color: Colors.white38,
//           size: 34,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFF001F1D),
//               Color(0xFF003A36),
//               Colors.black,
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.white),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       const SizedBox(width: 6),
//                       const Expanded(
//                         child: Text(
//                           'Write a Review',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 18),

//                 _glassWrap(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(14),
//                         child: SizedBox(
//                           width: 84,
//                           height: 84,
//                           child: _buildProductImage(),
//                         ),
//                       ),
//                       const SizedBox(width: 14),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               widget.productTitle,
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             if (widget.variantLabel.isNotEmpty) ...[
//                               const SizedBox(height: 8),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 10,
//                                   vertical: 5,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.tealAccent.withOpacity(0.16),
//                                   borderRadius: BorderRadius.circular(10),
//                                   border: Border.all(
//                                     color: Colors.tealAccent.withOpacity(0.25),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   widget.variantLabel,
//                                   style: const TextStyle(
//                                     color: Colors.tealAccent,
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 if (_isSubmitted)
//                   Container(
//                     margin: const EdgeInsets.only(bottom: 24),
//                     child: _glassWrap(
//                       padding: const EdgeInsets.all(16),
//                       child: Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: const BoxDecoration(
//                               color: Colors.green,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                               Icons.check,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           const Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Thank you for your review!',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   'Your feedback helps us improve',
//                                   style: TextStyle(
//                                     color: Colors.white70,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                 _glassWrap(
//                   padding: const EdgeInsets.all(18),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Rate this product',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),

//                       const SizedBox(height: 16),

//                       Center(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: List.generate(5, (index) {
//                             return GestureDetector(
//                               onTap: (_isSubmitted || _isLoading)
//                                   ? null
//                                   : () {
//                                       setState(() {
//                                         _selectedRating = index + 1.0;
//                                       });
//                                     },
//                               child: Container(
//                                 padding: const EdgeInsets.all(4),
//                                 child: Icon(
//                                   index < _selectedRating
//                                       ? Icons.star
//                                       : Icons.star_border,
//                                   color: Colors.amber,
//                                   size: 40,
//                                 ),
//                               ),
//                             );
//                           }),
//                         ),
//                       ),

//                       const SizedBox(height: 24),

//                       const Text(
//                         'Write your review',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),

//                       const SizedBox(height: 12),

//                       TextField(
//                         controller: _reviewController,
//                         maxLines: 5,
//                         enabled: !_isSubmitted && !_isLoading,
//                         style: const TextStyle(color: Colors.white),
//                         decoration: InputDecoration(
//                           hintText: 'Share your experience about this product...',
//                           hintStyle: const TextStyle(color: Colors.white38),
//                           filled: true,
//                           fillColor: Colors.white.withOpacity(0.05),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: BorderSide.none,
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: BorderSide(
//                               color: Colors.white.withOpacity(0.08),
//                             ),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: BorderSide(
//                               color: Colors.tealAccent.withOpacity(0.35),
//                             ),
//                           ),
//                           contentPadding: const EdgeInsets.all(16),
//                         ),
//                       ),

//                       const SizedBox(height: 24),

//                       if (!_isSubmitted)
//                         SizedBox(
//                           width: double.infinity,
//                           height: 50,
//                           child: ElevatedButton(
//                             onPressed: _isLoading
//                                 ? null
//                                 : () {
//                                     if (_selectedRating == 0) {
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(
//                                           content: Text('Please select a rating'),
//                                           backgroundColor: Colors.red,
//                                         ),
//                                       );
//                                       return;
//                                     }

//                                     if (_reviewController.text.trim().isEmpty) {
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(
//                                           content: Text('Please write a review'),
//                                           backgroundColor: Colors.red,
//                                         ),
//                                       );
//                                       return;
//                                     }

//                                     _submitReview();
//                                   },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.tealAccent,
//                               foregroundColor: Colors.black,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             child: _isLoading
//                                 ? const SizedBox(
//                                     height: 20,
//                                     width: 20,
//                                     child: CircularProgressIndicator(
//                                       color: Colors.black,
//                                       strokeWidth: 2,
//                                     ),
//                                   )
//                                 : const Text(
//                                     'Submit Review',
//                                     style: TextStyle(
//                                       color: Colors.black,
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                           ),
//                         )
//                       else
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.05),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.08),
//                             ),
//                           ),
//                           child: const Column(
//                             children: [
//                               Icon(
//                                 Icons.check_circle,
//                                 color: Colors.green,
//                                 size: 48,
//                               ),
//                               SizedBox(height: 8),
//                               Text(
//                                 'You have already reviewed this product',
//                                 style: TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 14,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ],
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _reviewController.dispose();
//     super.dispose();
//   }
// }
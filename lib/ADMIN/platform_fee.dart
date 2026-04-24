// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:ui';
// import 'package:my_skates/api.dart';
// import 'package:shimmer/shimmer.dart';

// class AdminPlatformFeePage extends StatefulWidget {
//   const AdminPlatformFeePage({super.key});

//   @override
//   State<AdminPlatformFeePage> createState() => _AdminPlatformFeePageState();
// }

// class _AdminPlatformFeePageState extends State<AdminPlatformFeePage>
//     with SingleTickerProviderStateMixin {
//   // ── Platform Fee ────────────────────────────────────────────────────────────
//   final TextEditingController _feeController = TextEditingController();
//   final FocusNode _feeFocusNode = FocusNode();

//   String? _currentFee;
//   int? _currentFeeId;
//   bool _isFeeLoading = true;
//   bool _isFeeSaving = false;
//   String? _feeError;
//   bool _isFeeEditing = false;

//   // ── Product Percentage ──────────────────────────────────────────────────────
//   final TextEditingController _percentageController = TextEditingController();
//   final FocusNode _percentageFocusNode = FocusNode();

//   String? _currentPercentage;
//   int? _currentPercentageId;
//   bool _isPercentageLoading = true;
//   bool _isPercentageSaving = false;
//   String? _percentageError;
//   bool _isPercentageEditing = false;

//   late AnimationController _animController;
//   late Animation<double> _fadeAnim;
//   late Animation<Offset> _slideAnim;

//   @override
//   void initState() {
//     super.initState();

//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
//     _slideAnim = Tween<Offset>(
//       begin: const Offset(0, 0.08),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

//     _fetchPlatformFee();
//     _fetchProductPercentage();
//   }

//   @override
//   void dispose() {
//     _feeController.dispose();
//     _feeFocusNode.dispose();
//     _percentageController.dispose();
//     _percentageFocusNode.dispose();
//     _animController.dispose();
//     super.dispose();
//   }

//   // ── Fetch Platform Fee ──────────────────────────────────────────────────────
//   Future<void> _fetchPlatformFee() async {
//     setState(() {
//       _isFeeLoading = true;
//       _feeError = null;
//     });

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("access");

//       if (token == null) {
//         setState(() {
//           _feeError = 'Authentication token missing';
//           _isFeeLoading = false;
//         });
//         return;
//       }

//       final response = await http.get(
//         Uri.parse('$api/api/myskates/platform/fee/view/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       print("PLATFORM FEE GET STATUS: ${response.statusCode}");
//       print("PLATFORM FEE GET RESPONSE: ${response.body}");

//       if (response.statusCode == 200) {
//         final jsonData = jsonDecode(response.body);

//         final dynamic rawData = jsonData['data'];
//         final Map<String, dynamic> payload =
//             rawData is List && rawData.isNotEmpty
//                 ? Map<String, dynamic>.from(rawData[0])
//                 : rawData is Map
//                     ? Map<String, dynamic>.from(rawData)
//                     : {};

//         _currentFeeId = payload['id'] as int?;

//         final dynamic rawFee = payload['platform_fee'];
//         final double fee = rawFee is num
//             ? rawFee.toDouble()
//             : double.tryParse(rawFee?.toString() ?? '0') ?? 0.0;

//         setState(() {
//           _currentFee = fee.toStringAsFixed(2);
//           _feeController.text = _currentFee!;
//           _isFeeLoading = false;
//         });
//         _animController.forward(from: 0);
//       } else {
//         setState(() {
//           _feeError = 'Failed to load platform fee: ${response.statusCode}';
//           _isFeeLoading = false;
//         });
//       }
//     } catch (e) {
//       print("Error fetching platform fee: $e");
//       setState(() {
//         _feeError = e.toString();
//         _isFeeLoading = false;
//       });
//     }
//   }

//   // ── Fetch Product Percentage ────────────────────────────────────────────────
//   Future<void> _fetchProductPercentage() async {
//     setState(() {
//       _isPercentageLoading = true;
//       _percentageError = null;
//     });

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("access");

//       if (token == null) {
//         setState(() {
//           _percentageError = 'Authentication token missing';
//           _isPercentageLoading = false;
//         });
//         return;
//       }

//       final response = await http.get(
//         Uri.parse('$api/api/myskates/product/percentage/view/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       print("PRODUCT PERCENTAGE GET STATUS: ${response.statusCode}");
//       print("PRODUCT PERCENTAGE GET RESPONSE: ${response.body}");

//       if (response.statusCode == 200) {
//         final jsonData = jsonDecode(response.body);

//         final dynamic rawData = jsonData['data'];
//         final Map<String, dynamic> payload =
//             rawData is List && rawData.isNotEmpty
//                 ? Map<String, dynamic>.from(rawData[0])
//                 : rawData is Map
//                     ? Map<String, dynamic>.from(rawData)
//                     : {};

//         _currentPercentageId = payload['id'] as int?;

//         final dynamic rawPercentage = payload['product_percentage'];
//         final double percentage = rawPercentage is num
//             ? rawPercentage.toDouble()
//             : double.tryParse(rawPercentage?.toString() ?? '0') ?? 0.0;

//         setState(() {
//           _currentPercentage = percentage.toStringAsFixed(2);
//           _percentageController.text = _currentPercentage!;
//           _isPercentageLoading = false;
//         });
//       } else {
//         setState(() {
//           _percentageError =
//               'Failed to load product percentage: ${response.statusCode}';
//           _isPercentageLoading = false;
//         });
//       }
//     } catch (e) {
//       print("Error fetching product percentage: $e");
//       setState(() {
//         _percentageError = e.toString();
//         _isPercentageLoading = false;
//       });
//     }
//   }

//   // ── Update Platform Fee ─────────────────────────────────────────────────────
//   Future<void> _updatePlatformFee() async {
//     final input = _feeController.text.trim();

//     if (input.isEmpty) {
//       _showSnackBar('Please enter a platform fee amount', isError: true);
//       return;
//     }

//     final parsed = double.tryParse(input);
//     if (parsed == null || parsed < 0) {
//       _showSnackBar('Enter a valid non-negative number', isError: true);
//       return;
//     }

//     if (_currentFeeId == null) {
//       _showSnackBar('Unable to update: Fee record ID not found', isError: true);
//       return;
//     }

//     setState(() => _isFeeSaving = true);
//     _feeFocusNode.unfocus();

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("access");

//       if (token == null) {
//         _showSnackBar('Authentication token missing', isError: true);
//         setState(() => _isFeeSaving = false);
//         return;
//       }

//       final response = await http.put(
//         Uri.parse('$api/api/myskates/platform/fee/update/${_currentFeeId}/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({'platform_fee': parsed}),
//       );

//       print("PLATFORM FEE PUT STATUS: ${response.statusCode}");
//       print("PLATFORM FEE PUT RESPONSE: ${response.body}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         setState(() {
//           _isFeeSaving = false;
//           _isFeeEditing = false;
//         });
//         await _fetchPlatformFee();
//         _showSnackBar('Platform fee updated successfully');
//       } else {
//         setState(() => _isFeeSaving = false);

//         String errorMessage = 'Failed to update: ${response.statusCode}';
//         try {
//           final errorData = jsonDecode(response.body);
//           if (errorData['message'] != null) {
//             errorMessage = errorData['message'];
//           } else if (errorData['error'] != null) {
//             errorMessage = errorData['error'];
//           }
//         } catch (e) {
//           // use default message
//         }

//         _showSnackBar(errorMessage, isError: true);
//       }
//     } catch (e) {
//       print("Error updating platform fee: $e");
//       setState(() => _isFeeSaving = false);
//       _showSnackBar('Error: $e', isError: true);
//     }
//   }

//   // ── Update Product Percentage ───────────────────────────────────────────────
//   Future<void> _updateProductPercentage() async {
//     final input = _percentageController.text.trim();

//     if (input.isEmpty) {
//       _showSnackBar('Please enter a product percentage', isError: true);
//       return;
//     }

//     final parsed = double.tryParse(input);
//     if (parsed == null || parsed < 0) {
//       _showSnackBar('Enter a valid non-negative number', isError: true);
//       return;
//     }

//     if (parsed > 100) {
//       _showSnackBar('Percentage cannot exceed 100%', isError: true);
//       return;
//     }

//     if (_currentPercentageId == null) {
//       _showSnackBar('Unable to update: Percentage record ID not found',
//           isError: true);
//       return;
//     }

//     setState(() => _isPercentageSaving = true);
//     _percentageFocusNode.unfocus();

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("access");

//       if (token == null) {
//         _showSnackBar('Authentication token missing', isError: true);
//         setState(() => _isPercentageSaving = false);
//         return;
//       }

//       final response = await http.put(
//         Uri.parse(
//             '$api/api/myskates/product/percentage/update/${_currentPercentageId}/'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({'product_percentage': parsed}),
//       );

//       print("PRODUCT PERCENTAGE PUT STATUS: ${response.statusCode}");
//       print("PRODUCT PERCENTAGE PUT RESPONSE: ${response.body}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         setState(() {
//           _isPercentageSaving = false;
//           _isPercentageEditing = false;
//         });
//         await _fetchProductPercentage();
//         _showSnackBar('Product percentage updated successfully');
//       } else {
//         setState(() => _isPercentageSaving = false);

//         String errorMessage = 'Failed to update: ${response.statusCode}';
//         try {
//           final errorData = jsonDecode(response.body);
//           if (errorData['message'] != null) {
//             errorMessage = errorData['message'];
//           } else if (errorData['error'] != null) {
//             errorMessage = errorData['error'];
//           }
//         } catch (e) {
//           // use default message
//         }

//         _showSnackBar(errorMessage, isError: true);
//       }
//     } catch (e) {
//       print("Error updating product percentage: $e");
//       setState(() => _isPercentageSaving = false);
//       _showSnackBar('Error: $e', isError: true);
//     }
//   }

//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               isError ? Icons.error_outline : Icons.check_circle_outline,
//               color: isError ? Colors.white : Colors.black,
//               size: 18,
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 message,
//                 style: TextStyle(
//                   color: isError ? Colors.white : Colors.black,
//                   fontSize: 13,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: isError ? Colors.red.shade700 : Colors.tealAccent,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
//       ),
//     );
//   }

//   // ─── UI helpers ─────────────────────────────────────────────────────────────
//   Widget _glassWrap({required Widget child, EdgeInsets? padding}) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//         child: Container(
//           padding: padding,
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.06),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: Colors.white.withOpacity(0.10)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.22),
//                 blurRadius: 18,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }

//   Widget _buildShimmerBlock() {
//     return Column(
//       children: [
//         _glassWrap(
//           padding: const EdgeInsets.all(28),
//           child: Column(
//             children: [
//               Container(
//                 width: 120,
//                 height: 14,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Container(
//                 width: 160,
//                 height: 52,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 20),
//         _glassWrap(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 140,
//                 height: 14,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Container(
//                 height: 56,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Container(
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildShimmer() {
//     return Shimmer.fromColors(
//       baseColor: const Color(0xFF1A2B2A),
//       highlightColor: const Color(0xFF2F4F4D),
//       child: Column(
//         children: [
//           _buildShimmerBlock(),
//           const SizedBox(height: 32),
//           _buildShimmerBlock(),
//         ],
//       ),
//     );
//   }

//   // ── Platform Fee Section ────────────────────────────────────────────────────
//   Widget _buildFeeCurrentCard() {
//     return _glassWrap(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: Colors.tealAccent.withOpacity(0.15),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.account_balance_wallet_outlined,
//                   color: Colors.tealAccent,
//                   size: 18,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               const Text(
//                 'Current Platform Fee',
//                 style: TextStyle(
//                   color: Colors.white54,
//                   fontSize: 13,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 18),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
//             decoration: BoxDecoration(
//               color: Colors.tealAccent.withOpacity(0.08),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: Colors.tealAccent.withOpacity(0.25),
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Padding(
//                   padding: EdgeInsets.only(top: 4),
//                   child: Text(
//                     '₹',
//                     style: TextStyle(
//                       color: Colors.tealAccent,
//                       fontSize: 22,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   _currentFee != null
//                       ? double.tryParse(_currentFee!)?.toStringAsFixed(2) ??
//                           _currentFee!
//                       : '—',
//                   style: const TextStyle(
//                     color: Colors.tealAccent,
//                     fontSize: 42,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: -1,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             'Applied to every order at checkout',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.28),
//               fontSize: 11,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFeeEditCard() {
//     return _glassWrap(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 30,
//                 height: 30,
//                 decoration: BoxDecoration(
//                   color: Colors.tealAccent.withOpacity(0.15),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.edit_outlined,
//                   color: Colors.tealAccent,
//                   size: 15,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               const Text(
//                 'Update Platform Fee',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 15,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Padding(
//             padding: const EdgeInsets.only(left: 40),
//             child: Text(
//               'Enter the new fee amount in ₹',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.35),
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           // Input field
//           ClipRRect(
//             borderRadius: BorderRadius.circular(14),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//               child: TextField(
//                 controller: _feeController,
//                 focusNode: _feeFocusNode,
//                 keyboardType:
//                     const TextInputType.numberWithOptions(decimal: true),
//                 inputFormatters: [
//                   FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
//                 ],
//                 onTap: () => setState(() => _isFeeEditing = true),
//                 onChanged: (_) => setState(() => _isFeeEditing = true),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 decoration: InputDecoration(
//                   filled: true,
//                   fillColor: Colors.white.withOpacity(0.06),
//                   hintText: '0.00',
//                   hintStyle: TextStyle(
//                     color: Colors.white.withOpacity(0.25),
//                     fontSize: 18,
//                   ),
//                   prefixIcon: Container(
//                     width: 52,
//                     alignment: Alignment.center,
//                     child: const Text(
//                       '₹',
//                       style: TextStyle(
//                         color: Colors.tealAccent,
//                         fontSize: 20,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                   suffixIcon: _feeController.text.isNotEmpty
//                       ? IconButton(
//                           icon: Icon(
//                             Icons.close_rounded,
//                             color: Colors.white.withOpacity(0.3),
//                             size: 18,
//                           ),
//                           onPressed: () {
//                             _feeController.clear();
//                             setState(() => _isFeeEditing = true);
//                           },
//                         )
//                       : null,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide:
//                         BorderSide(color: Colors.white.withOpacity(0.1)),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide:
//                         BorderSide(color: Colors.white.withOpacity(0.1)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide:
//                         const BorderSide(color: Colors.tealAccent, width: 1.5),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 16, vertical: 16),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           // Save button
//           SizedBox(
//             width: double.infinity,
//             height: 52,
//             child: ElevatedButton(
//               onPressed: _isFeeSaving ? null : _updatePlatformFee,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.tealAccent,
//                 disabledBackgroundColor: Colors.tealAccent.withOpacity(0.4),
//                 foregroundColor: Colors.black,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 elevation: 0,
//               ),
//               child: _isFeeSaving
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         color: Colors.black54,
//                         strokeWidth: 2.5,
//                       ),
//                     )
//                   : const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.save_rounded, size: 18),
//                         SizedBox(width: 8),
//                         Text(
//                           'Update Platform Fee',
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 0.3,
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//           // Cancel / reset
//           if (_isFeeEditing &&
//               _currentFee != null &&
//               _feeController.text != _currentFee)
//             Padding(
//               padding: const EdgeInsets.only(top: 10),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 44,
//                 child: TextButton(
//                   onPressed: () {
//                     _feeController.text = _currentFee!;
//                     _feeFocusNode.unfocus();
//                     setState(() => _isFeeEditing = false);
//                   },
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.white38,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                       side: BorderSide(color: Colors.white.withOpacity(0.08)),
//                     ),
//                   ),
//                   child: const Text(
//                     'Reset to current value',
//                     style: TextStyle(fontSize: 13),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // ── Product Percentage Section ──────────────────────────────────────────────
//   Widget _buildPercentageCurrentCard() {
//     return _glassWrap(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: Colors.orangeAccent.withOpacity(0.15),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.percent_rounded,
//                   color: Colors.orangeAccent,
//                   size: 18,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               const Text(
//                 'Current Product Percentage',
//                 style: TextStyle(
//                   color: Colors.white54,
//                   fontSize: 13,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 18),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
//             decoration: BoxDecoration(
//               color: Colors.orangeAccent.withOpacity(0.08),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: Colors.orangeAccent.withOpacity(0.25),
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _currentPercentage != null
//                       ? double.tryParse(_currentPercentage!)
//                               ?.toStringAsFixed(2) ??
//                           _currentPercentage!
//                       : '—',
//                   style: const TextStyle(
//                     color: Colors.orangeAccent,
//                     fontSize: 42,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: -1,
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 const Padding(
//                   padding: EdgeInsets.only(top: 4),
//                   child: Text(
//                     '%',
//                     style: TextStyle(
//                       color: Colors.orangeAccent,
//                       fontSize: 22,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             'Applied as a percentage on product pricing',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.28),
//               fontSize: 11,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPercentageEditCard() {
//     return _glassWrap(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 30,
//                 height: 30,
//                 decoration: BoxDecoration(
//                   color: Colors.orangeAccent.withOpacity(0.15),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.edit_outlined,
//                   color: Colors.orangeAccent,
//                   size: 15,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               const Text(
//                 'Update Product Percentage',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 15,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Padding(
//             padding: const EdgeInsets.only(left: 40),
//             child: Text(
//               'Enter the new percentage value (0–100)',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.35),
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           // Input field
//           ClipRRect(
//             borderRadius: BorderRadius.circular(14),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//               child: TextField(
//                 controller: _percentageController,
//                 focusNode: _percentageFocusNode,
//                 keyboardType:
//                     const TextInputType.numberWithOptions(decimal: true),
//                 inputFormatters: [
//                   FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
//                 ],
//                 onTap: () => setState(() => _isPercentageEditing = true),
//                 onChanged: (_) => setState(() => _isPercentageEditing = true),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 decoration: InputDecoration(
//                   filled: true,
//                   fillColor: Colors.white.withOpacity(0.06),
//                   hintText: '0.00',
//                   hintStyle: TextStyle(
//                     color: Colors.white.withOpacity(0.25),
//                     fontSize: 18,
//                   ),
//                   suffixIcon: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       if (_percentageController.text.isNotEmpty)
//                         IconButton(
//                           icon: Icon(
//                             Icons.close_rounded,
//                             color: Colors.white.withOpacity(0.3),
//                             size: 18,
//                           ),
//                           onPressed: () {
//                             _percentageController.clear();
//                             setState(() => _isPercentageEditing = true);
//                           },
//                         ),
//                       Container(
//                         width: 48,
//                         alignment: Alignment.center,
//                         child: const Text(
//                           '%',
//                           style: TextStyle(
//                             color: Colors.orangeAccent,
//                             fontSize: 20,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide:
//                         BorderSide(color: Colors.white.withOpacity(0.1)),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide:
//                         BorderSide(color: Colors.white.withOpacity(0.1)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide: const BorderSide(
//                         color: Colors.orangeAccent, width: 1.5),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 16, vertical: 16),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           // Save button
//           SizedBox(
//             width: double.infinity,
//             height: 52,
//             child: ElevatedButton(
//               onPressed:
//                   _isPercentageSaving ? null : _updateProductPercentage,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orangeAccent,
//                 disabledBackgroundColor: Colors.orangeAccent.withOpacity(0.4),
//                 foregroundColor: Colors.black,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 elevation: 0,
//               ),
//               child: _isPercentageSaving
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         color: Colors.black54,
//                         strokeWidth: 2.5,
//                       ),
//                     )
//                   : const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.save_rounded, size: 18),
//                         SizedBox(width: 8),
//                         Text(
//                           'Update Product Percentage',
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 0.3,
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//           // Cancel / reset
//           if (_isPercentageEditing &&
//               _currentPercentage != null &&
//               _percentageController.text != _currentPercentage)
//             Padding(
//               padding: const EdgeInsets.only(top: 10),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 44,
//                 child: TextButton(
//                   onPressed: () {
//                     _percentageController.text = _currentPercentage!;
//                     _percentageFocusNode.unfocus();
//                     setState(() => _isPercentageEditing = false);
//                   },
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.white38,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                       side: BorderSide(color: Colors.white.withOpacity(0.08)),
//                     ),
//                   ),
//                   child: const Text(
//                     'Reset to current value',
//                     style: TextStyle(fontSize: 13),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDivider(String label) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Expanded(
//               child: Divider(color: Colors.white.withOpacity(0.08), height: 1)),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Text(
//               label,
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.25),
//                 fontSize: 11,
//                 letterSpacing: 1,
//               ),
//             ),
//           ),
//           Expanded(
//               child: Divider(color: Colors.white.withOpacity(0.08), height: 1)),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoNote(String message, Color accentColor) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: accentColor.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: accentColor.withOpacity(0.12),
//           width: 0.5,
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(Icons.info_outline_rounded, color: accentColor, size: 16),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               message,
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.4),
//                 fontSize: 12,
//                 height: 1.5,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool anyLoading = _isFeeLoading || _isPercentageLoading;

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF001F1D), Color(0xFF003A36), Colors.black],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // ── App Bar ────────────────────────────────────────────────────
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back, color: Colors.white),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                     const SizedBox(width: 4),
//                     const Expanded(
//                       child: Text(
//                         'Platform Fee & Percentage',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     if (!anyLoading)
//                       IconButton(
//                         icon: const Icon(
//                           Icons.refresh_rounded,
//                           color: Colors.tealAccent,
//                           size: 22,
//                         ),
//                         onPressed: () {
//                           _fetchPlatformFee();
//                           _fetchProductPercentage();
//                         },
//                         tooltip: 'Refresh',
//                       ),
//                   ],
//                 ),
//               ),

//               // ── Body ───────────────────────────────────────────────────────
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
//                   child: anyLoading
//                       ? _buildShimmer()
//                       : FadeTransition(
//                           opacity: _fadeAnim,
//                           child: SlideTransition(
//                             position: _slideAnim,
//                             child: Column(
//                               children: [
//                                 // ── Platform Fee Section ──────────────────
//                                 _buildDivider('PLATFORM FEE'),
//                                 const SizedBox(height: 12),

//                                 if (_feeError != null)
//                                   _buildSectionError(
//                                       _feeError!, _fetchPlatformFee)
//                                 else ...[
//                                   _buildFeeCurrentCard(),
//                                   const SizedBox(height: 20),
//                                   _buildFeeEditCard(),
//                                   const SizedBox(height: 12),
//                                   _buildInfoNote(
//                                     'The platform fee is added on top of the order total during checkout. Changes take effect immediately on all new orders.',
//                                     Colors.tealAccent,
//                                   ),
//                                 ],

//                                 const SizedBox(height: 32),

//                                 // ── Product Percentage Section ────────────
//                                 _buildDivider('PRODUCT PERCENTAGE'),
//                                 const SizedBox(height: 12),

//                                 if (_percentageError != null)
//                                   _buildSectionError(
//                                       _percentageError!, _fetchProductPercentage)
//                                 else ...[
//                                   _buildPercentageCurrentCard(),
//                                   const SizedBox(height: 20),
//                                   _buildPercentageEditCard(),
//                                   const SizedBox(height: 12),
//                                   _buildInfoNote(
//                                     'The product percentage is applied to product pricing calculations. Must be between 0% and 100%. Changes take effect immediately.',
//                                     Colors.orangeAccent,
//                                   ),
//                                 ],
//                               ],
//                             ),
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionError(String error, VoidCallback onRetry) {
//     return _glassWrap(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.error_outline, color: Colors.red, size: 40),
//           const SizedBox(height: 12),
//           Text(
//             error,
//             style: const TextStyle(color: Colors.red, fontSize: 13),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton.icon(
//             onPressed: onRetry,
//             icon: const Icon(Icons.refresh_rounded, size: 16),
//             label: const Text('Try Again'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.tealAccent,
//               foregroundColor: Colors.black,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:my_skates/api.dart';
import 'package:shimmer/shimmer.dart';

class AdminPlatformFeePage extends StatefulWidget {
  const AdminPlatformFeePage({super.key});

  @override
  State<AdminPlatformFeePage> createState() => _AdminPlatformFeePageState();
}

class _AdminPlatformFeePageState extends State<AdminPlatformFeePage>
    with SingleTickerProviderStateMixin {
  // ── Platform Fee ─────────────────────────────────────────────────────────────
  final TextEditingController _feeController = TextEditingController();
  final FocusNode _feeFocusNode = FocusNode();
  String? _currentFee;
  int? _currentFeeId;
  bool _isFeeLoading = true;
  bool _isFeeSaving = false;
  String? _feeError;
  bool _isFeeEditing = false;

  // ── Product Percentage ────────────────────────────────────────────────────────
  final TextEditingController _percentageController = TextEditingController();
  final FocusNode _percentageFocusNode = FocusNode();
  String? _currentPercentage;
  int? _currentPercentageId;
  bool _isPercentageLoading = true;
  bool _isPercentageSaving = false;
  String? _percentageError;
  bool _isPercentageEditing = false;

  // ── Convenience Fee ───────────────────────────────────────────────────────────
  final TextEditingController _convenienceController = TextEditingController();
  final FocusNode _convenienceFocusNode = FocusNode();
  String? _currentConvenienceFee;
  int? _currentConvenienceFeeId;
  bool _isConvenienceLoading = true;
  bool _isConvenienceSaving = false;
  String? _convenienceError;
  bool _isConvenienceEditing = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fetchPlatformFee();
    _fetchProductPercentage();
    _fetchConvenienceFee();
  }

  @override
  void dispose() {
    _feeController.dispose();
    _feeFocusNode.dispose();
    _percentageController.dispose();
    _percentageFocusNode.dispose();
    _convenienceController.dispose();
    _convenienceFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FETCH METHODS
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _fetchPlatformFee() async {
    setState(() {
      _isFeeLoading = true;
      _feeError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        setState(() {
          _feeError = 'Authentication token missing';
          _isFeeLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('$api/api/myskates/platform/fee/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("PLATFORM FEE GET STATUS: ${response.statusCode}");
      print("PLATFORM FEE GET RESPONSE: ${response.body}");
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final dynamic rawData = jsonData['data'];
        final Map<String, dynamic> payload =
            rawData is List && rawData.isNotEmpty
            ? Map<String, dynamic>.from(rawData[0])
            : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : {};
        _currentFeeId = payload['id'] as int?;
        final dynamic rawFee = payload['platform_fee'];
        final double fee = rawFee is num
            ? rawFee.toDouble()
            : double.tryParse(rawFee?.toString() ?? '0') ?? 0.0;
        setState(() {
          _currentFee = fee.toStringAsFixed(2);
          _feeController.text = _currentFee!;
          _isFeeLoading = false;
        });
        _animController.forward(from: 0);
      } else {
        setState(() {
          _feeError = 'Failed to load platform fee: ${response.statusCode}';
          _isFeeLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching platform fee: $e");
      setState(() {
        _feeError = e.toString();
        _isFeeLoading = false;
      });
    }
  }

  Future<void> _fetchProductPercentage() async {
    setState(() {
      _isPercentageLoading = true;
      _percentageError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        setState(() {
          _percentageError = 'Authentication token missing';
          _isPercentageLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('$api/api/myskates/product/percentage/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("PRODUCT PERCENTAGE GET STATUS: ${response.statusCode}");
      print("PRODUCT PERCENTAGE GET RESPONSE: ${response.body}");
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final dynamic rawData = jsonData['data'];
        final Map<String, dynamic> payload =
            rawData is List && rawData.isNotEmpty
            ? Map<String, dynamic>.from(rawData[0])
            : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : {};
        _currentPercentageId = payload['id'] as int?;
        final dynamic rawPercentage = payload['product_percentage'];
        final double percentage = rawPercentage is num
            ? rawPercentage.toDouble()
            : double.tryParse(rawPercentage?.toString() ?? '0') ?? 0.0;
        setState(() {
          _currentPercentage = percentage.toStringAsFixed(2);
          _percentageController.text = _currentPercentage!;
          _isPercentageLoading = false;
        });
      } else {
        setState(() {
          _percentageError =
              'Failed to load product percentage: ${response.statusCode}';
          _isPercentageLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching product percentage: $e");
      setState(() {
        _percentageError = e.toString();
        _isPercentageLoading = false;
      });
    }
  }

  Future<void> _fetchConvenienceFee() async {
    setState(() {
      _isConvenienceLoading = true;
      _convenienceError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        setState(() {
          _convenienceError = 'Authentication token missing';
          _isConvenienceLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('$api/api/myskates/convenience/fee/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("CONVENIENCE FEE GET STATUS: ${response.statusCode}");
      print("CONVENIENCE FEE GET RESPONSE: ${response.body}");
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final dynamic rawData = jsonData['data'];
        final Map<String, dynamic> payload =
            rawData is List && rawData.isNotEmpty
            ? Map<String, dynamic>.from(rawData[0])
            : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : {};
        _currentConvenienceFeeId = payload['id'] as int?;
        final dynamic rawFee = payload['convenience_fee'];
        final double fee = rawFee is num
            ? rawFee.toDouble()
            : double.tryParse(rawFee?.toString() ?? '0') ?? 0.0;
        setState(() {
          _currentConvenienceFee = fee.toStringAsFixed(2);
          _convenienceController.text = _currentConvenienceFee!;
          _isConvenienceLoading = false;
        });
      } else {
        setState(() {
          _convenienceError =
              'Failed to load convenience fee: ${response.statusCode}';
          _isConvenienceLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching convenience fee: $e");
      setState(() {
        _convenienceError = e.toString();
        _isConvenienceLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UPDATE METHODS
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _updatePlatformFee() async {
    final input = _feeController.text.trim();
    if (input.isEmpty) {
      _showSnackBar('Please enter a platform fee amount', isError: true);
      return;
    }
    final parsed = double.tryParse(input);
    if (parsed == null || parsed < 0) {
      _showSnackBar('Enter a valid non-negative number', isError: true);
      return;
    }
    if (_currentFeeId == null) {
      _showSnackBar('Unable to update: Fee record ID not found', isError: true);
      return;
    }
    setState(() => _isFeeSaving = true);
    _feeFocusNode.unfocus();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        _showSnackBar('Authentication token missing', isError: true);
        setState(() => _isFeeSaving = false);
        return;
      }
      final response = await http.put(
        Uri.parse('$api/api/myskates/platform/fee/update/${_currentFeeId}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'platform_fee': parsed}),
      );
      print("PLATFORM FEE PUT STATUS: ${response.statusCode}");
      print("PLATFORM FEE PUT RESPONSE: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isFeeSaving = false;
          _isFeeEditing = false;
        });
        await _fetchPlatformFee();
        _showSnackBar('Platform fee updated successfully');
      } else {
        setState(() => _isFeeSaving = false);
        String errorMessage = 'Failed to update: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (_) {}
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      print("Error updating platform fee: $e");
      setState(() => _isFeeSaving = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _updateProductPercentage() async {
    final input = _percentageController.text.trim();
    if (input.isEmpty) {
      _showSnackBar('Please enter a product percentage', isError: true);
      return;
    }
    final parsed = double.tryParse(input);
    if (parsed == null || parsed < 0) {
      _showSnackBar('Enter a valid non-negative number', isError: true);
      return;
    }
    if (parsed > 100) {
      _showSnackBar('Percentage cannot exceed 100%', isError: true);
      return;
    }
    if (_currentPercentageId == null) {
      _showSnackBar(
        'Unable to update: Percentage record ID not found',
        isError: true,
      );
      return;
    }
    setState(() => _isPercentageSaving = true);
    _percentageFocusNode.unfocus();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        _showSnackBar('Authentication token missing', isError: true);
        setState(() => _isPercentageSaving = false);
        return;
      }
      final response = await http.put(
        Uri.parse(
          '$api/api/myskates/product/percentage/update/${_currentPercentageId}/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'product_percentage': parsed}),
      );
      print("PRODUCT PERCENTAGE PUT STATUS: ${response.statusCode}");
      print("PRODUCT PERCENTAGE PUT RESPONSE: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isPercentageSaving = false;
          _isPercentageEditing = false;
        });
        await _fetchProductPercentage();
        _showSnackBar('Product percentage updated successfully');
      } else {
        setState(() => _isPercentageSaving = false);
        String errorMessage = 'Failed to update: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (_) {}
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      print("Error updating product percentage: $e");
      setState(() => _isPercentageSaving = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _updateConvenienceFee() async {
    final input = _convenienceController.text.trim();
    if (input.isEmpty) {
      _showSnackBar('Please enter a convenience fee amount', isError: true);
      return;
    }
    final parsed = double.tryParse(input);
    if (parsed == null || parsed < 0) {
      _showSnackBar('Enter a valid non-negative number', isError: true);
      return;
    }
    if (_currentConvenienceFeeId == null) {
      _showSnackBar(
        'Unable to update: Convenience fee record ID not found',
        isError: true,
      );
      return;
    }
    setState(() => _isConvenienceSaving = true);
    _convenienceFocusNode.unfocus();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      if (token == null) {
        _showSnackBar('Authentication token missing', isError: true);
        setState(() => _isConvenienceSaving = false);
        return;
      }
      final response = await http.put(
        Uri.parse(
          '$api/api/myskates/convenience/fee/update/${_currentConvenienceFeeId}/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'convenience_fee': parsed}),
      );
      print("CONVENIENCE FEE PUT STATUS: ${response.statusCode}");
      print("CONVENIENCE FEE PUT RESPONSE: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isConvenienceSaving = false;
          _isConvenienceEditing = false;
        });
        await _fetchConvenienceFee();
        _showSnackBar('Convenience fee updated successfully');
      } else {
        setState(() => _isConvenienceSaving = false);
        String errorMessage = 'Failed to update: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (_) {}
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      print("Error updating convenience fee: $e");
      setState(() => _isConvenienceSaving = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SNACK BAR
  // ─────────────────────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.white : Colors.black,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? Colors.white : Colors.black,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.tealAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _glassWrap({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildShimmerBlock() {
    return Column(
      children: [
        _glassWrap(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 160,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _glassWrap(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A2B2A),
      highlightColor: const Color(0xFF2F4F4D),
      child: Column(
        children: [
          _buildShimmerBlock(),
          const SizedBox(height: 32),
          _buildShimmerBlock(),
          const SizedBox(height: 32),
          _buildShimmerBlock(),
        ],
      ),
    );
  }

  Widget _buildDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.white.withOpacity(0.08), height: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.white.withOpacity(0.08), height: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote(String message, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.12), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: accentColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionError(String error, VoidCallback onRetry) {
    return _glassWrap(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // GENERIC SECTION CARDS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildCurrentCard({
    required String label,
    required String? value,
    required Color accent,
    required IconData icon,
    required String subLabel,
    bool isPercentage = false,
  }) {
    final displayValue = value != null
        ? double.tryParse(value)?.toStringAsFixed(2) ?? value
        : '—';

    return _glassWrap(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.25), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: isPercentage
                  ? [
                      Text(
                        displayValue,
                        style: TextStyle(
                          color: accent,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '%',
                          style: TextStyle(
                            color: accent,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ]
                  : [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '₹',
                          style: TextStyle(
                            color: accent,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayValue,
                        style: TextStyle(
                          color: accent,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.28),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditCard({
    required String title,
    required String inputHint,
    required Color accent,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isSaving,
    required bool isEditing,
    required String? currentValue,
    required VoidCallback onSave,
    required VoidCallback onReset,
    required VoidCallback onTapOrChange,
    required String buttonLabel,
    bool isPercentage = false,
  }) {
    return _glassWrap(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_outlined, color: accent, size: 15),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              inputHint,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Input field
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onTap: onTapOrChange,
                onChanged: (_) => onTapOrChange(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 18,
                  ),
                  prefixIcon: isPercentage
                      ? null
                      : Container(
                          width: 52,
                          alignment: Alignment.center,
                          child: Text(
                            '₹',
                            style: TextStyle(
                              color: accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  suffixIcon: isPercentage
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (controller.text.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 18,
                                ),
                                onPressed: () {
                                  controller.clear();
                                  onTapOrChange();
                                },
                              ),
                            Container(
                              width: 48,
                              alignment: Alignment.center,
                              child: Text(
                                '%',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        )
                      : controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withOpacity(0.3),
                            size: 18,
                          ),
                          onPressed: () {
                            controller.clear();
                            onTapOrChange();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                disabledBackgroundColor: accent.withOpacity(0.4),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black54,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          buttonLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Reset button
          if (isEditing &&
              currentValue != null &&
              controller.text != currentValue)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: onReset,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  child: const Text(
                    'Reset to current value',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool anyLoading =
        _isFeeLoading || _isPercentageLoading || _isConvenienceLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F1D), Color(0xFF003A36), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Fees & Percentage',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!anyLoading)
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.tealAccent,
                          size: 22,
                        ),
                        onPressed: () {
                          _fetchPlatformFee();
                          _fetchProductPercentage();
                          _fetchConvenienceFee();
                        },
                        tooltip: 'Refresh all',
                      ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: anyLoading
                      ? _buildShimmer()
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Column(
                              children: [
                                // ── Platform Fee ─────────────────────────
                                _buildDivider('PLATFORM FEE'),
                                const SizedBox(height: 12),
                                if (_feeError != null)
                                  _buildSectionError(
                                    _feeError!,
                                    _fetchPlatformFee,
                                  )
                                else ...[
                                  _buildCurrentCard(
                                    label: 'Current Platform Fee',
                                    value: _currentFee,
                                    accent: Colors.tealAccent,
                                    icon: Icons.account_balance_wallet_outlined,
                                    subLabel:
                                        'Applied to every order at checkout',
                                  ),
                                  const SizedBox(height: 20),
                                  _buildEditCard(
                                    title: 'Update Platform Fee',
                                    inputHint: 'Enter the new fee amount in ₹',
                                    accent: Colors.tealAccent,
                                    controller: _feeController,
                                    focusNode: _feeFocusNode,
                                    isSaving: _isFeeSaving,
                                    isEditing: _isFeeEditing,
                                    currentValue: _currentFee,
                                    onSave: _updatePlatformFee,
                                    onReset: () {
                                      _feeController.text = _currentFee!;
                                      _feeFocusNode.unfocus();
                                      setState(() => _isFeeEditing = false);
                                    },
                                    onTapOrChange: () =>
                                        setState(() => _isFeeEditing = true),
                                    buttonLabel: 'Update Platform Fee',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoNote(
                                    'The platform fee is added on top of the order total during checkout. Changes take effect immediately on all new orders.',
                                    Colors.tealAccent,
                                  ),
                                ],

                                const SizedBox(height: 32),

                                // ── Product Percentage ────────────────────
                                _buildDivider('PRODUCT PERCENTAGE'),
                                const SizedBox(height: 12),
                                if (_percentageError != null)
                                  _buildSectionError(
                                    _percentageError!,
                                    _fetchProductPercentage,
                                  )
                                else ...[
                                  _buildCurrentCard(
                                    label: 'Current Product Percentage',
                                    value: _currentPercentage,
                                    accent: Colors.tealAccent,
                                    icon: Icons.percent_rounded,
                                    subLabel:
                                        'Applied as a percentage on product pricing',
                                    isPercentage: true,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildEditCard(
                                    title: 'Update Product Percentage',
                                    inputHint:
                                        'Enter the new percentage value (0–100)',
                                    accent: Colors.tealAccent,
                                    controller: _percentageController,
                                    focusNode: _percentageFocusNode,
                                    isSaving: _isPercentageSaving,
                                    isEditing: _isPercentageEditing,
                                    currentValue: _currentPercentage,
                                    onSave: _updateProductPercentage,
                                    onReset: () {
                                      _percentageController.text =
                                          _currentPercentage!;
                                      _percentageFocusNode.unfocus();
                                      setState(
                                        () => _isPercentageEditing = false,
                                      );
                                    },
                                    onTapOrChange: () => setState(
                                      () => _isPercentageEditing = true,
                                    ),
                                    buttonLabel: 'Update Product Percentage',
                                    isPercentage: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoNote(
                                    'The product percentage is applied to product pricing calculations. Must be between 0% and 100%. Changes take effect immediately.',
                                    Colors.tealAccent,
                                  ),
                                ],

                                const SizedBox(height: 32),

                                // ── Convenience Fee ───────────────────────
                                _buildDivider('CONVENIENCE FEE'),
                                const SizedBox(height: 12),
                                if (_convenienceError != null)
                                  _buildSectionError(
                                    _convenienceError!,
                                    _fetchConvenienceFee,
                                  )
                                else ...[
                                  _buildCurrentCard(
                                    label: 'Current Convenience Fee',
                                    value: _currentConvenienceFee,
                                    accent: Colors.tealAccent,
                                    icon: Icons.local_offer_outlined,
                                    subLabel:
                                        'Charged as a convenience fee per order',
                                  ),
                                  const SizedBox(height: 20),
                                  _buildEditCard(
                                    title: 'Update Convenience Fee',
                                    inputHint: 'Enter the new fee amount in ₹',
                                    accent: Colors.tealAccent,
                                    controller: _convenienceController,
                                    focusNode: _convenienceFocusNode,
                                    isSaving: _isConvenienceSaving,
                                    isEditing: _isConvenienceEditing,
                                    currentValue: _currentConvenienceFee,
                                    onSave: _updateConvenienceFee,
                                    onReset: () {
                                      _convenienceController.text =
                                          _currentConvenienceFee!;
                                      _convenienceFocusNode.unfocus();
                                      setState(
                                        () => _isConvenienceEditing = false,
                                      );
                                    },
                                    onTapOrChange: () => setState(
                                      () => _isConvenienceEditing = true,
                                    ),
                                    buttonLabel: 'Update Convenience Fee',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoNote(
                                    'The convenience fee is charged per order as a service charge. Changes take effect immediately on all new orders.',
                                    Colors.tealAccent,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

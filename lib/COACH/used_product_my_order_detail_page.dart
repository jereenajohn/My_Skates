import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_skates/api.dart';

class UsedProductOrderDetailItem {
  final int id;
  final int productId;
  final String title;
  final String description;
  final String? image;
  final String price;
  final String discount;
  final String shipmentCharge;
  final String? attributeName;
  final String? attributeValue;
  final int quantity;

  UsedProductOrderDetailItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.description,
    this.image,
    required this.price,
    required this.discount,
    required this.shipmentCharge,
    this.attributeName,
    this.attributeValue,
    required this.quantity,
  });

  factory UsedProductOrderDetailItem.fromJson(Map<String, dynamic> json) {
    return UsedProductOrderDetailItem(
      id: json['id'] ?? json['item_id'] ?? json['order_item_id'] ?? 0,
      productId: json['product_id'] ?? json['product'] ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString(),
      price: json['price']?.toString() ?? '0',
      discount: json['discount']?.toString() ?? '0',
      shipmentCharge: json['shipment_charge']?.toString() ?? '0',
      attributeName: json['attribute_name']?.toString(),
      attributeValue: json['attribute_value']?.toString(),
      quantity: json['quantity'] ?? 0,
    );
  }

  double get priceValue => double.tryParse(price) ?? 0;
  double get discountValue => double.tryParse(discount) ?? 0;

  double get discountedPrice {
    return priceValue - ((priceValue * discountValue) / 100);
  }
}

class UsedProductOrderDetailModel {
  final int id;
  final String orderNo;
  final String status;
  final String paymentMethod;
  final String? razorpayPaymentRef;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final String? note;

  final String subtotal;
  final String discountTotal;
  final String total;
  final String platformFee;
  final String convenienceFee;
  final String shipmentCharge;
  final String productPercentage;
  final String finalPayable;

  final DateTime createdAt;
  final List<UsedProductOrderDetailItem> items;

  UsedProductOrderDetailModel({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.paymentMethod,
    this.razorpayPaymentRef,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    this.note,
    required this.subtotal,
    required this.discountTotal,
    required this.total,
    required this.platformFee,
    required this.convenienceFee,
    required this.shipmentCharge,
    required this.productPercentage,
    required this.finalPayable,
    required this.createdAt,
    required this.items,
  });

  factory UsedProductOrderDetailModel.fromJson(Map<String, dynamic> json) {
    final itemList = json['items'] as List? ?? [];

    // ✅ New API has pricing object.
    // ✅ Fallback to root also added for old API support.
    final pricing = json['pricing'] as Map<String, dynamic>? ?? json;

    return UsedProductOrderDetailModel(
      id: json['id'] ?? 0,
      orderNo: json['order_no']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      razorpayPaymentRef: json['razorpay_payment_ref']?.toString(),
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      addressLine1: json['address_line1']?.toString() ?? '',
      addressLine2: json['address_line2']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      note: json['note']?.toString(),

      subtotal: pricing['subtotal']?.toString() ?? '0',
      discountTotal: pricing['discount_total']?.toString() ?? '0',
      total: pricing['total']?.toString() ?? '0',
      platformFee: pricing['platform_fee']?.toString() ?? '0',
      convenienceFee: pricing['convenience_fee']?.toString() ?? '0',
      shipmentCharge: pricing['shipment_charge']?.toString() ?? '0',
      productPercentage: pricing['product_percentage']?.toString() ?? '0',
      finalPayable: pricing['final_payable']?.toString() ?? '0',

      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      items: itemList
          .map((e) => UsedProductOrderDetailItem.fromJson(e))
          .toList(),
    );
  }
}

class UsedProductOrderDetailPage extends StatefulWidget {
  final int orderId;

  const UsedProductOrderDetailPage({super.key, required this.orderId});

  @override
  State<UsedProductOrderDetailPage> createState() =>
      _UsedProductOrderDetailPageState();
}

class _UsedProductOrderDetailPageState
    extends State<UsedProductOrderDetailPage> {
  UsedProductOrderDetailModel? order;
  bool isLoading = true;
  String? error;
  final TextEditingController _usedReturnReasonController =
      TextEditingController();

  bool _usedReturnAlreadyRequested = false;
  String? _usedReturnStatus;

  bool _isSubmittingUsedReturn = false;
  UsedProductOrderDetailItem? _selectedUsedReturnItem;
  String? _selectedUsedReturnReasonType;
  String? _usedReturnErrorMessage;

  final List<Map<String, String>> _usedReturnReasonTypeOptions = [
    {'value': 'defective', 'label': 'Defective Product'},
    {'value': 'wrong_item', 'label': 'Wrong Item Delivered'},
    {'value': 'no_longer_needed', 'label': 'No Longer Needed'},
    {'value': 'damaged', 'label': 'Damaged Product'},
    {'value': 'size_issue', 'label': 'Size Issue'},
    {'value': 'other', 'label': 'Other'},
  ];

  bool get _canRequestUsedReturn {
    final status = order?.status.trim().toUpperCase() ?? '';
    return status == 'DELIVERED';
  }

  String _getUsedReturnReasonLabel(String value) {
    final match = _usedReturnReasonTypeOptions
        .where((option) => option['value'] == value)
        .toList();

    if (match.isEmpty) return value;
    return match.first['label'] ?? value;
  }

  @override
  void dispose() {
    _usedReturnReasonController.dispose();
    super.dispose();
  }

  void _resetUsedReturnForm() {
    _selectedUsedReturnItem = order != null && order!.items.isNotEmpty
        ? order!.items.first
        : null;
    _selectedUsedReturnReasonType = null;
    _usedReturnReasonController.clear();
    _usedReturnErrorMessage = null;
    _isSubmittingUsedReturn = false;
  }

  Future<void> _submitUsedProductReturnRequest(
    StateSetter bottomSheetSetState,
  ) async {
    if (order == null) return;

    if (_selectedUsedReturnItem == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }

    if (_selectedUsedReturnItem!.id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order item id missing from API response'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedUsedReturnReasonType == null ||
        _selectedUsedReturnReasonType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select reason type')),
      );
      return;
    }

    final customReason = _usedReturnReasonController.text.trim();

    if (_selectedUsedReturnReasonType == 'other' && customReason.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter reason')));
      return;
    }

    bottomSheetSetState(() {
      _isSubmittingUsedReturn = true;
      _usedReturnErrorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        bottomSheetSetState(() {
          _isSubmittingUsedReturn = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token missing')),
        );
        return;
      }

      final Map<String, dynamic> requestBody = {
        'invoice': order!.id,
        'item': _selectedUsedReturnItem!.id,
        'remark': 'return',
        'reason_type': _selectedUsedReturnReasonType,
        'reason': _selectedUsedReturnReasonType == 'other'
            ? customReason
            : _getUsedReturnReasonLabel(_selectedUsedReturnReasonType!),
      };

      final response = await http.post(
        Uri.parse('$api/api/myskates/msk/used/product/refund/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print("USED PRODUCT RETURN API STATUS: ${response.statusCode}");
      print("USED PRODUCT RETURN REQUEST BODY: ${jsonEncode(requestBody)}");
      print("USED PRODUCT RETURN RESPONSE: ${response.body}");

      Map<String, dynamic>? decoded;

      try {
        final dynamic parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        }
      } catch (_) {
        decoded = null;
      }

      final bool apiStatus = decoded?['status'] == true;

      final String responseMessage =
          decoded?['message']?.toString() ??
          decoded?['error']?.toString() ??
          decoded?['detail']?.toString() ??
          'Something went wrong';

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (apiStatus || decoded?['status'] == null)) {
        if (!mounted) return;

        setState(() {
          _usedReturnAlreadyRequested = true;
          _usedReturnStatus =
              decoded?['data']?['status']?.toString() ?? 'pending';
        });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseMessage.isNotEmpty
                  ? responseMessage
                  : 'Return request submitted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        await fetchOrderDetail();
      } else {
        if (!mounted) return;

        bottomSheetSetState(() {
          _usedReturnErrorMessage = responseMessage;
        });
      }
    } catch (e) {
      print("ERROR SUBMITTING USED PRODUCT RETURN: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        bottomSheetSetState(() {
          _isSubmittingUsedReturn = false;
        });
      }
    }
  }

  Future<void> _showUsedProductReturnBottomSheet() async {
    if (order == null || order!.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available in this order')),
      );
      return;
    }

    if (!_canRequestUsedReturn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return is available only for delivered used products'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _resetUsedReturnForm();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, bottomSheetSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF101010),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.tealAccent.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.assignment_return_outlined,
                              color: Colors.tealAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Return Request',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Submit return request for used product',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _isSubmittingUsedReturn
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Choose Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<UsedProductOrderDetailItem>(
                            value: _selectedUsedReturnItem,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF161616),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white70,
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: _isSubmittingUsedReturn
                                ? null
                                : (UsedProductOrderDetailItem? value) {
                                    bottomSheetSetState(() {
                                      _selectedUsedReturnItem = value;
                                    });
                                  },
                            items: order!.items.map((item) {
                              return DropdownMenuItem<
                                UsedProductOrderDetailItem
                              >(
                                value: item,
                                child: Text(
                                  item.title.isEmpty
                                      ? 'Used Product'
                                      : item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Request Type',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.tealAccent.withOpacity(0.25),
                          ),
                        ),
                        child: const Text(
                          'Return',
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Reason Type',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedUsedReturnReasonType,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF161616),
                            hint: const Text(
                              'Select reason type',
                              style: TextStyle(color: Colors.white54),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white70,
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: _isSubmittingUsedReturn
                                ? null
                                : (String? value) {
                                    bottomSheetSetState(() {
                                      _selectedUsedReturnReasonType = value;
                                      if (value != 'other') {
                                        _usedReturnReasonController.clear();
                                      }
                                    });
                                  },
                            items: _usedReturnReasonTypeOptions.map((option) {
                              return DropdownMenuItem<String>(
                                value: option['value'],
                                child: Text(
                                  option['label'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      if (_selectedUsedReturnReasonType == 'other') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Reason',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usedReturnReasonController,
                          enabled: !_isSubmittingUsedReturn,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Type your reason',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.07),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Colors.tealAccent,
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (_usedReturnErrorMessage != null &&
                          _usedReturnErrorMessage!.trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _usedReturnErrorMessage!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmittingUsedReturn
                              ? null
                              : () => _submitUsedProductReturnRequest(
                                  bottomSheetSetState,
                                ),
                          icon: _isSubmittingUsedReturn
                              ? const SizedBox.shrink()
                              : const Icon(Icons.assignment_return_outlined),
                          label: _isSubmittingUsedReturn
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Text(
                                  'Submit Return Request',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            disabledBackgroundColor: Colors.tealAccent
                                .withOpacity(0.35),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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

  Widget _buildUsedProductReturnButton() {
    if (!_canRequestUsedReturn) {
      return const SizedBox.shrink();
    }

    if (_usedReturnAlreadyRequested) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              color: Colors.orangeAccent,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _usedReturnStatus != null && _usedReturnStatus!.isNotEmpty
                    ? 'Return request already submitted. Status: $_usedReturnStatus'
                    : 'Return request already submitted',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      child: ElevatedButton.icon(
        onPressed: _showUsedProductReturnBottomSheet,
        icon: const Icon(Icons.assignment_return_outlined, size: 20),
        label: const Text(
          'Return Product',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.tealAccent,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchOrderDetail();
  }

  Future<void> fetchOrderDetail() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() {
          error = 'Authentication token missing';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
          '$api/api/myskates/used/product/my/orders/detail/view/${widget.orderId}/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("USED PRODUCT ORDER DETAIL STATUS: ${response.statusCode}");
      print("USED PRODUCT ORDER DETAIL BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? decoded;

        bool returnAlreadyRequested = false;
        String? returnStatus;

        final refunds = data['refunds'];

        if (refunds is List && refunds.isNotEmpty) {
          final returnRefund = refunds.where((refund) {
            if (refund is! Map) return false;
            return refund['remark']?.toString() == 'return';
          }).toList();

          if (returnRefund.isNotEmpty) {
            returnAlreadyRequested = true;
            returnStatus = returnRefund.first['status']?.toString();
          }
        }

        setState(() {
          order = UsedProductOrderDetailModel.fromJson(data);
          _usedReturnAlreadyRequested = returnAlreadyRequested;
          _usedReturnStatus = returnStatus;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load order detail: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print("USED PRODUCT ORDER DETAIL ERROR: $e");
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return Colors.orange;
      case 'PAID':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _glassWrap({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildImage(String? image) {
    if (image != null && image.isNotEmpty) {
      final imageUrl = image.startsWith('http') ? image : '$api$image';

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.image_not_supported,
          color: Colors.white38,
          size: 30,
        ),
      );
    }

    return const Icon(
      Icons.image_not_supported,
      color: Colors.white38,
      size: 30,
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _smallChip(
    IconData icon,
    String text, {
    Color color = Colors.white70,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.trim().isEmpty || value == 'null') {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pricingRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    final amount = double.tryParse(value) ?? 0;

    return Padding(
      padding: EdgeInsets.only(bottom: isTotal ? 0 : 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? Colors.white : Colors.white70,
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${isDiscount ? '- ' : ''}₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isTotal
                  ? Colors.tealAccent
                  : isDiscount
                  ? Colors.redAccent
                  : Colors.white,
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UsedProductOrderDetailModel? orderData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Used Order Detail',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (orderData != null) _statusBadge(orderData.status),
        ],
      ),
    );
  }

  Widget _buildItemCard(UsedProductOrderDetailItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 0.8,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImage(item.image),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isEmpty ? 'Used Product' : item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _smallChip(
                      Icons.shopping_bag_outlined,
                      'Qty ${item.quantity}',
                    ),
                    if ((item.attributeName ?? '').isNotEmpty &&
                        (item.attributeValue ?? '').isNotEmpty)
                      _smallChip(
                        Icons.tune_rounded,
                        '${item.attributeName}: ${item.attributeValue}',
                      ),
                    if (item.discountValue > 0)
                      _smallChip(
                        Icons.local_offer_outlined,
                        '${item.discount}% OFF',
                        color: Colors.orangeAccent,
                      ),
                    if ((double.tryParse(item.shipmentCharge) ?? 0) > 0)
                      _smallChip(
                        Icons.local_shipping_outlined,
                        'Shipping ₹${item.shipmentCharge}',
                        color: Colors.blueAccent,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (item.discountValue > 0) ...[
                      Text(
                        '₹${item.priceValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '₹${item.discountedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTopCard(UsedProductOrderDetailModel orderData) {
    return _glassWrap(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${orderData.orderNo}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(orderData.createdAt),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallChip(
                Icons.payments_outlined,
                orderData.paymentMethod,
                color: Colors.tealAccent,
              ),
              if ((orderData.razorpayPaymentRef ?? '').isNotEmpty)
                _smallChip(
                  Icons.receipt_long_rounded,
                  'Payment Ref Available',
                  color: Colors.greenAccent,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(UsedProductOrderDetailModel orderData) {
    return _glassWrap(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ...orderData.items.map(_buildItemCard).toList(),
        ],
      ),
    );
  }

  Widget _buildAddressCard(UsedProductOrderDetailModel orderData) {
    return _glassWrap(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Address',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _infoRow('Name', orderData.fullName),
          _infoRow('Phone', orderData.phone),
          _infoRow('Address', orderData.addressLine1),
          _infoRow('Landmark', orderData.addressLine2),
          _infoRow('City', orderData.city),
          _infoRow('State', orderData.state),
          _infoRow('Pincode', orderData.pincode),
          _infoRow('Country', orderData.country),
          _infoRow('Note', orderData.note),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(UsedProductOrderDetailModel orderData) {
    return _glassWrap(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _pricingRow('Subtotal', orderData.subtotal),

          _pricingRow('Discount', orderData.discountTotal, isDiscount: true),

          _pricingRow('Total', orderData.total),

          if ((double.tryParse(orderData.platformFee) ?? 0) > 0)
            _pricingRow('Platform Fee', orderData.platformFee),

          if ((double.tryParse(orderData.convenienceFee) ?? 0) > 0)
            _pricingRow('Convenience Fee', orderData.convenienceFee),

          _pricingRow('Shipment Charge', orderData.shipmentCharge),

          // if ((double.tryParse(orderData.productPercentage) ?? 0) > 0)
          //   _pricingRow('Product Percentage', orderData.productPercentage),
          const Divider(color: Colors.white24, height: 24),

          _pricingRow('Final Payable', orderData.finalPayable, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildHeader(null),
        const SizedBox(height: 90),
        const Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildHeader(null),
        const SizedBox(height: 80),
        _glassWrap(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                error ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchOrderDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadedView() {
    final orderData = order!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildHeader(orderData),
        const SizedBox(height: 14),
        _buildOrderTopCard(orderData),
        const SizedBox(height: 14),
        _buildItemsCard(orderData),

        const SizedBox(height: 14),
        _buildAddressCard(orderData),
        const SizedBox(height: 14),
        _buildPaymentSummaryCard(orderData),
        const SizedBox(height: 24),

        _buildUsedProductReturnButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (isLoading) {
      child = _buildLoadingView();
    } else if (error != null) {
      child = _buildErrorView();
    } else {
      child = _buildLoadedView();
    }

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
          child: RefreshIndicator(
            onRefresh: fetchOrderDetail,
            color: Colors.tealAccent,
            backgroundColor: Colors.black,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
  }
}

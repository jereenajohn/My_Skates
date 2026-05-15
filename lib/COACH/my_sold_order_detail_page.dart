import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_skates/api.dart';

class SellerOrderDetailPage extends StatefulWidget {
  final int orderId;

  const SellerOrderDetailPage({super.key, required this.orderId});

  @override
  State<SellerOrderDetailPage> createState() => _SellerOrderDetailPageState();
}

class _SellerOrderDetailPageState extends State<SellerOrderDetailPage> {
  bool isLoading = true;
  String? error;
  SellerOrderDetail? order;

  final List<Map<String, String>> statusOptions = [
    {"value": "PLACED", "label": "Placed"},
    {"value": "PAID", "label": "Paid"},
    {"value": "SHIPPED", "label": "Shipped"},
    {"value": "DELIVERED", "label": "Delivered"},
    {"value": "CANCELLED", "label": "Cancelled"},
  ];

  @override
  void initState() {
    super.initState();
    fetchSellerOrderDetail();
  }

  Future<void> fetchSellerOrderDetail() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() {
          error = "Authentication token missing";
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$api/api/myskates/seller/orders/update/${widget.orderId}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("SELLER ORDER DETAIL STATUS: ${response.statusCode}");
      print("SELLER ORDER DETAIL BODY: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final data = jsonResponse['data'];

        setState(() {
          order = SellerOrderDetail.fromJson(data);
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Failed to load seller order detail: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> updateOrderItemStatus(
    int itemId,
    String newStatus,
    int index,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token missing')),
        );
        return;
      }

      final response = await http.patch(
        Uri.parse('$api/api/myskates/order/item/status/update/$itemId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': newStatus}),
      );

      print("UPDATE ITEM STATUS API STATUS: ${response.statusCode}");
      print("UPDATE ITEM STATUS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          order?.items[index].status = newStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Item status updated to $newStatus',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
            backgroundColor: Colors.tealAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${response.statusCode}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print("Error updating status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showStatusBottomSheet(SellerOrderItem item, int itemIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D2B28).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Update Order Item Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Product: ${item.productTitle}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  ...statusOptions.map((option) {
                    final isSelected = item.status == option['value'];
                    final statusColor = _getStatusColor(option['value']!);
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        if (!isSelected) {
                          updateOrderItemStatus(
                            item.id,
                            option['value']!,
                            itemIndex,
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? statusColor.withOpacity(0.18)
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? statusColor.withOpacity(0.6)
                                : Colors.white.withOpacity(0.08),
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: statusColor.withOpacity(0.5),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : [],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                option['label']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? statusColor
                                      : Colors.white70,
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: statusColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  double _amount(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  String _money(dynamic value) {
    return '₹${_amount(value).toStringAsFixed(2)}';
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$api$path';
  }

  Widget _glassWrap({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(14),
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

  Widget _priceRow(
    String title,
    dynamic value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
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

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.tealAccent, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(SellerOrderItem item) {
    final image = item.variantImage?.isNotEmpty == true
        ? item.variantImage
        : item.productImage;

    if (image == null || image.isEmpty) {
      return const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white38,
        size: 28,
      );
    }

    return Image.network(
      _imageUrl(image),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) {
        return const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white38,
          size: 28,
        );
      },
    );
  }

  Widget _buildOrderItemCard(SellerOrderItem item, int index) {
    return _glassWrap(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: _buildProductImage(item),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _chip(
                          Icons.shopping_bag_outlined,
                          'Qty ${item.quantity}',
                        ),
                        if (item.productUserType.isNotEmpty)
                          _chip(Icons.storefront_rounded, item.productUserType),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(item.itemTotal),
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showStatusBottomSheet(item, index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(item.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getStatusColor(item.status).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.status,
                            style: TextStyle(
                              color: _getStatusColor(item.status),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit,
                            color: _getStatusColor(item.status),
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.tealAccent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.tealAccent, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SellerOrderDetail order) {
    return _glassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Order Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              // Container(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 12,
              //     vertical: 7,
              //   ),
              //   decoration: BoxDecoration(
              //     color: _getStatusColor(order.status).withOpacity(0.18),
              //     borderRadius: BorderRadius.circular(20),
              //     border: Border.all(
              //       color: _getStatusColor(order.status).withOpacity(0.45),
              //     ),
              //   ),
              //   child: Text(
              //     order.status,
              //     style: TextStyle(
              //       color: _getStatusColor(order.status),
              //       fontSize: 12,
              //       fontWeight: FontWeight.w700,
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Order #${order.orderNo}',
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.10), height: 1),
          const SizedBox(height: 12),
          _infoRow('Payment', order.paymentMethod),
          _infoRow('Customer', order.fullName),
          _infoRow('Phone', order.phone),
        ],
      ),
    );
  }

  Widget _buildAddressCard(SellerOrderDetail order) {
    final address = [
      order.addressLine1,
      order.addressLine2,
      order.city,
      order.state,
      order.pincode,
      order.country,
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');

    return _glassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Delivery Address', Icons.location_on_outlined),
          const SizedBox(height: 14),
          Text(
            address.isEmpty ? 'No address found' : address,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSummaryCard(SellerSummary summary) {
    return _glassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Seller Payment Summary',
            Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 14),
          _priceRow('Product Total', "₹${summary.sellerDiscountedTotal}"),
          _priceRow(
            'Percentage (${summary.productPercentage}%)',
            "-₹${summary.sellerPercentageTotal}",
            valueColor: Colors.redAccent,
          ),
          _priceRow('Shipping Total', "₹${summary.sellerShippingTotal}"),
          const Divider(color: Colors.white24, height: 24),
          _priceRow(
            'Seller Payable Total',
            "₹${summary.sellerPayableTotal}",
            valueColor: Colors.greenAccent,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _glassWrap(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 46,
              ),
              const SizedBox(height: 14),
              Text(
                error ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: fetchSellerOrderDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.tealAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = order;

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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'My Sold Order Detail',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: fetchSellerOrderDetail,
                      icon: const Icon(Icons.refresh, color: Colors.tealAccent),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? _buildLoadingView()
                    : error != null
                    ? _buildErrorView()
                    : data == null
                    ? _buildErrorView()
                    : RefreshIndicator(
                        color: Colors.tealAccent,
                        backgroundColor: Colors.black,
                        onRefresh: fetchSellerOrderDetail,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildAddressCard(data),
                            const SizedBox(height: 14),
                            _buildHeader(data),
                            const SizedBox(height: 14),
                            _sectionTitle(
                              'Sold Products',
                              Icons.inventory_2_outlined,
                            ),
                            const SizedBox(height: 12),
                            ...data.items.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildOrderItemCard(
                                  entry.value,
                                  entry.key,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (data.summary != null) ...[
                              _buildSellerSummaryCard(data.summary!),
                              const SizedBox(height: 14),
                            ],
                          ],
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

class SellerOrderDetail {
  final int id;
  final List<SellerOrderItem> items;
  final String orderNo;
  final String status;
  final String paymentMethod;
  final String? paymentRef;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final String? note;
  final DateTime createdAt;
  final SellerSummary? summary;

  SellerOrderDetail({
    required this.id,
    required this.items,
    required this.orderNo,
    required this.status,
    required this.paymentMethod,
    this.paymentRef,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    this.note,
    required this.createdAt,
    this.summary,
  });

  factory SellerOrderDetail.fromJson(Map<String, dynamic> json) {
    final itemList = json['items'] as List? ?? [];

    return SellerOrderDetail(
      id: json['id'] ?? 0,
      items: itemList.map((e) => SellerOrderItem.fromJson(e)).toList(),
      orderNo: json['order_no']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentRef: json['payment_ref']?.toString(),
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      addressLine1: json['address_line1']?.toString() ?? '',
      addressLine2: json['address_line2']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      note: json['note']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      summary: json['summary'] == null
          ? null
          : SellerSummary.fromJson(json['summary']),
    );
  }
}

class SellerOrderItem {
  final int id;
  final int product;
  final String productTitle;
  final String? productImage;
  final int variantId;
  final String? variantImage;
  final String variantPrice;
  final String variantDiscount;
  final String productShippingCharge;
  final String discountedPrice;
  final int quantity;
  final String coachName;
  final String coachPhone;
  final String productUserType;
  final String itemTotal;
  final String percentageAmount;
  final String sellerPayable;
  String status; // Made mutable

  SellerOrderItem({
    required this.id,
    required this.product,
    required this.productTitle,
    this.productImage,
    required this.variantId,
    this.variantImage,
    required this.variantPrice,
    required this.variantDiscount,
    required this.productShippingCharge,
    required this.discountedPrice,
    required this.quantity,
    required this.coachName,
    required this.coachPhone,
    required this.productUserType,
    required this.itemTotal,
    required this.percentageAmount,
    required this.sellerPayable,
    required this.status,
  });

  factory SellerOrderItem.fromJson(Map<String, dynamic> json) {
    return SellerOrderItem(
      id: json['id'] ?? 0,
      product: json['product'] ?? 0,
      productTitle: json['product_title']?.toString() ?? '',
      productImage: json['product_image']?.toString(),
      variantId: json['variant_id'] ?? json['variant'] ?? 0,
      variantImage: json['variant_image']?.toString(),
      variantPrice: json['variant_price']?.toString() ?? '0',
      variantDiscount: json['variant_discount']?.toString() ?? '0',
      productShippingCharge: json['product_shipping_charge']?.toString() ?? '0',
      discountedPrice: json['discounted_price']?.toString() ?? '0',
      quantity: json['quantity'] ?? 0,
      coachName: json['coach_name']?.toString() ?? '',
      coachPhone: json['coach_phone']?.toString() ?? '',
      productUserType: json['product_user_type']?.toString() ?? '',
      itemTotal: json['item_total']?.toString() ?? '0',
      percentageAmount: json['percentage_amount']?.toString() ?? '0',
      sellerPayable: json['seller_payable']?.toString() ?? '0',
      status: json['status']?.toString() ?? 'PLACED',
    );
  }
}

class SellerSummary {
  final String productPercentage;
  final String sellerTotal;
  final String sellerDiscountedTotal;
  final String sellerPercentageTotal;
  final String sellerShippingTotal;
  final String sellerPayableTotal;

  SellerSummary({
    required this.productPercentage,
    required this.sellerTotal,
    required this.sellerDiscountedTotal,
    required this.sellerPercentageTotal,
    required this.sellerShippingTotal,
    required this.sellerPayableTotal,
  });

  factory SellerSummary.fromJson(Map<String, dynamic> json) {
    return SellerSummary(
      productPercentage: json['product_percentage']?.toString() ?? '0',
      sellerTotal: json['seller_total']?.toString() ?? '0',
      sellerDiscountedTotal: json['seller_discounted_total']?.toString() ?? '0',
      sellerPercentageTotal: json['seller_percentage_total']?.toString() ?? '0',
      sellerShippingTotal: json['seller_shipping_total']?.toString() ?? '0',
      sellerPayableTotal: json['seller_payable_total']?.toString() ?? '0',
    );
  }
}

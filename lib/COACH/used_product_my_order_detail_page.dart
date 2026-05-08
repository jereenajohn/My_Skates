import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_skates/api.dart';

class UsedProductOrderDetailItem {
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
      productId: json['product_id'] ?? 0,
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

        setState(() {
          order = UsedProductOrderDetailModel.fromJson(data);
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

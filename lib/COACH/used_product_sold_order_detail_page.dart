import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_skates/api.dart';

class UsedProductSoldOrderDetailItem {
  final int id;
  final int productId;
  final String? image;
  final String title;
  final String description;
  final String price;
  final String discount;
  final String discountPercent;
  final String discountAmount;
  final String shipmentCharge;
  final String productTotal;
  final String productPercentage;
  final String percentageAmount;
  final String sellerPayable;
  final String? attributeName;
  final String? attributeValue;
  final int quantity;
  final DateTime createdAt;

  UsedProductSoldOrderDetailItem({
    required this.id,
    required this.productId,
    this.image,
    required this.title,
    required this.description,
    required this.price,
    required this.discount,
    required this.discountPercent,
    required this.discountAmount,
    required this.shipmentCharge,
    required this.productTotal,
    required this.productPercentage,
    required this.percentageAmount,
    required this.sellerPayable,
    this.attributeName,
    this.attributeValue,
    required this.quantity,
    required this.createdAt,
  });

  factory UsedProductSoldOrderDetailItem.fromJson(Map<String, dynamic> json) {
    return UsedProductSoldOrderDetailItem(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      image: json['image']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      discount: json['discount']?.toString() ?? '0',
      discountPercent:
          json['discount_percent']?.toString() ??
          json['discount']?.toString() ??
          '0',
      discountAmount: json['discount_amount']?.toString() ?? '0',
      shipmentCharge: json['shipment_charge']?.toString() ?? '0',
      productTotal: json['product_total']?.toString() ?? '0',
      productPercentage: json['product_percentage']?.toString() ?? '0',
      percentageAmount: json['percentage_amount']?.toString() ?? '0',
      sellerPayable: json['seller_payable']?.toString() ?? '0',
      attributeName: json['attribute_name']?.toString(),
      attributeValue: json['attribute_value']?.toString(),
      quantity: json['quantity'] ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class UsedProductSoldOrderDetailModel {
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
  final String subtotal;
  final String discountTotal;
  final String total;
  final String platformFee;
  final String convenienceFee;
  final String shipmentCharge;
  final String finalPayable;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<UsedProductSoldOrderDetailItem> items;

  UsedProductSoldOrderDetailModel({
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
    required this.subtotal,
    required this.discountTotal,
    required this.total,
    required this.platformFee,
    required this.convenienceFee,
    required this.shipmentCharge,
    required this.finalPayable,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory UsedProductSoldOrderDetailModel.fromJson(Map<String, dynamic> json) {
    final itemList = json['items'] as List? ?? [];

    return UsedProductSoldOrderDetailModel(
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
      subtotal: json['subtotal']?.toString() ?? '0',
      discountTotal: json['discount_total']?.toString() ?? '0',
      total: json['total']?.toString() ?? '0',
      platformFee: json['platform_fee']?.toString() ?? '0',
      convenienceFee: json['convenience_fee']?.toString() ?? '0',
      shipmentCharge: json['shipment_charge']?.toString() ?? '0',
      finalPayable: json['final_payable']?.toString() ?? '0',
      note: json['note']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      items: itemList
          .map((e) => UsedProductSoldOrderDetailItem.fromJson(e))
          .toList(),
    );
  }

  String get sellerProductTotal {
    double sum = 0;
    for (final item in items) {
      sum += double.tryParse(item.productTotal) ?? 0;
    }
    return sum.toStringAsFixed(2);
  }

  String get sellerPercentageTotal {
    double sum = 0;
    for (final item in items) {
      sum += double.tryParse(item.percentageAmount) ?? 0;
    }
    return sum.toStringAsFixed(2);
  }

  String get sellerShippingTotal {
    double sum = 0;
    for (final item in items) {
      sum += double.tryParse(item.shipmentCharge) ?? 0;
    }
    return sum.toStringAsFixed(2);
  }

  String get sellerPayableTotal {
    double sum = 0;
    for (final item in items) {
      sum += double.tryParse(item.sellerPayable) ?? 0;
    }
    return sum.toStringAsFixed(2);
  }

  String get productPercentage {
    if (items.isEmpty) return '0';
    return items.first.productPercentage;
  }
}

class UsedProductSoldOrderDetailPage extends StatefulWidget {
  final int orderId;

  const UsedProductSoldOrderDetailPage({super.key, required this.orderId});

  @override
  State<UsedProductSoldOrderDetailPage> createState() =>
      _UsedProductSoldOrderDetailPageState();
}

class _UsedProductSoldOrderDetailPageState
    extends State<UsedProductSoldOrderDetailPage> {
  UsedProductSoldOrderDetailModel? order;
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
          '$api/api/myskates/used/product/sold/orders/detail/view/${widget.orderId}/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("USED PRODUCT SOLD DETAIL STATUS: ${response.statusCode}");
      print("USED PRODUCT SOLD DETAIL BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? decoded;

        setState(() {
          order = UsedProductSoldOrderDetailModel.fromJson(data);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load sold order detail: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print("USED PRODUCT SOLD DETAIL ERROR: $e");
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

  Widget _statusBadge(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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

  Widget _infoRow(String title, String? value) {
    if (value == null || value.trim().isEmpty || value == 'null') {
      return const SizedBox.shrink();
    }

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

  Widget _priceRow(
    String title,
    dynamic value, {
    Color? valueColor,
    bool isBold = false,
    bool isMinus = false,
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
            '${isMinus ? '- ' : ''}${_money(value)}',
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

  Widget _buildProductImage(UsedProductSoldOrderDetailItem item) {
    if (item.image == null || item.image!.isEmpty) {
      return const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white38,
        size: 28,
      );
    }

    return Image.network(
      _imageUrl(item.image),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) {
        return const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white38,
          size: 28,
        );
      },
    );
  }

  Widget _buildHeader(UsedProductSoldOrderDetailModel orderData) {
    return _glassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Used Product Sold Detail',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _statusBadge(orderData.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Order #${orderData.orderNo}',
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(orderData.createdAt),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.10), height: 1),
          const SizedBox(height: 12),
          _infoRow('Payment', orderData.paymentMethod),
          _infoRow('Payment Ref', orderData.razorpayPaymentRef),
          _infoRow('Buyer', orderData.fullName),
          _infoRow('Phone', orderData.phone),
          _infoRow('Note', orderData.note),
        ],
      ),
    );
  }

  Widget _buildAddressCard(UsedProductSoldOrderDetailModel orderData) {
    final address = [
      orderData.addressLine1,
      orderData.addressLine2,
      orderData.city,
      orderData.state,
      orderData.pincode,
      orderData.country,
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');

    return _glassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Buyer Delivery Address', Icons.location_on_outlined),
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

  Widget _buildOrderItemCard(UsedProductSoldOrderDetailItem item) {
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
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _chip(
                          Icons.shopping_bag_outlined,
                          'Qty ${item.quantity}',
                        ),
                        if ((item.attributeName ?? '').isNotEmpty &&
                            (item.attributeValue ?? '').isNotEmpty)
                          _chip(
                            Icons.tune_rounded,
                            '${item.attributeName}: ${item.attributeValue}',
                          ),
                        if (_amount(item.discountPercent) > 0)
                          _chip(
                            Icons.local_offer_outlined,
                            '${item.discountPercent}% OFF',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _money(item.productTotal),
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.10), height: 1),
          const SizedBox(height: 10),
          // _priceRow('Product Price', item.price),
          // if (_amount(item.discountAmount) > 0)
          // _priceRow(
          //   'Discount Amount',
          //   item.discountAmount,
          //   valueColor: Colors.redAccent,
          //   isMinus: true,
          // ),
          _priceRow(
            'Product Total',
            item.productTotal,
            valueColor: Colors.tealAccent,
          ),
          _priceRow(
            'Percentage (${item.productPercentage}%)',
            item.percentageAmount,
            valueColor: Colors.redAccent,
          ),
          _priceRow(
            'Shipping Charge',
            item.shipmentCharge,
            valueColor: Colors.tealAccent,
          ),
          const Divider(color: Colors.white24, height: 22),
          _priceRow(
            'Seller Payable',
            item.sellerPayable,
            valueColor: Colors.tealAccent,
            isBold: true,
          ),
        ],
      ),
    );
  }

  // Widget _buildSellerSummaryCard(UsedProductSoldOrderDetailModel orderData) {
  //   return _glassWrap(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _sectionTitle(
  //           'Seller Payment Summary',
  //           Icons.account_balance_wallet_outlined,
  //         ),
  //         const SizedBox(height: 14),
  //         _priceRow('Product Total', orderData.sellerProductTotal),
  //         _priceRow(
  //           'Percentage (${orderData.productPercentage}%)',
  //           orderData.sellerPercentageTotal,
  //         ),
  //         _priceRow('Shipping Total', orderData.sellerShippingTotal),
  //         const Divider(color: Colors.white24, height: 24),
  //         _priceRow(
  //           'Seller Payable Total',
  //           orderData.sellerPayableTotal,
  //           valueColor: Colors.greenAccent,
  //           isBold: true,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildCustomerPaymentSummaryCard(
    UsedProductSoldOrderDetailModel orderData,
  ) {
    return _glassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Customer Payment Summary',
            Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 14),
          _priceRow('Subtotal', orderData.subtotal),
          if (_amount(orderData.discountTotal) > 0)
            _priceRow(
              'Discount',
              orderData.discountTotal,
              valueColor: Colors.redAccent,
              isMinus: true,
            ),
          _priceRow('Total', orderData.total),
          if (_amount(orderData.platformFee) > 0)
            _priceRow('Platform Fee', orderData.platformFee),
          if (_amount(orderData.convenienceFee) > 0)
            _priceRow('Convenience Fee', orderData.convenienceFee),
          _priceRow('Shipment Charge', orderData.shipmentCharge),
          const Divider(color: Colors.white24, height: 24),
          _priceRow(
            'Final Payable',
            orderData.finalPayable,
            valueColor: Colors.tealAccent,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.tealAccent),
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
      ),
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
                      onPressed: fetchOrderDetail,
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
                        onRefresh: fetchOrderDetail,
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
                            ...data.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildOrderItemCard(item),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // _buildSellerSummaryCard(data),
                            // const SizedBox(height: 14),
                            // _buildCustomerPaymentSummaryCard(data),
                            // const SizedBox(height: 24),
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

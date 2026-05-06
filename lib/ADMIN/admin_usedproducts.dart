import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:my_skates/api.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class UsedOrderItem {
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

  UsedOrderItem({
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

  factory UsedOrderItem.fromJson(Map<String, dynamic> json) {
    return UsedOrderItem(
      productId: json['product_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      price: json['price']?.toString() ?? '0',
      discount: json['discount']?.toString() ?? '0',
      shipmentCharge: json['shipment_charge']?.toString() ?? '0',
      attributeName: json['attribute_name'],
      attributeValue: json['attribute_value'],
      quantity: json['quantity'] ?? 1,
    );
  }

  double get discountedPrice {
    final p = double.tryParse(price) ?? 0;
    final d = double.tryParse(discount) ?? 0;
    // discount field appears to be a percentage
    if (d > 0 && d <= 100) return p - (p * d / 100);
    return p - d;
  }
}

class UsedOrder {
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
  final String shipmentCharge;
  final String finalPayable;
  final DateTime createdAt;
  final List<UsedOrderItem> items;

  UsedOrder({
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
    required this.shipmentCharge,
    required this.finalPayable,
    required this.createdAt,
    required this.items,
  });

  factory UsedOrder.fromJson(Map<String, dynamic> json) {
    final itemList = json['items'] as List? ?? [];
    return UsedOrder(
      id: json['id'] ?? 0,
      orderNo: json['order_no'] ?? '',
      status: json['status'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      razorpayPaymentRef: json['razorpay_payment_ref'],
      fullName: json['full_name'] ?? '',
      phone: json['phone']?.toString() ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode']?.toString() ?? '',
      country: json['country'] ?? '',
      subtotal: json['subtotal']?.toString() ?? '0',
      discountTotal: json['discount_total']?.toString() ?? '0',
      total: json['total']?.toString() ?? '0',
      shipmentCharge: json['shipment_charge']?.toString() ?? '0',
      finalPayable: json['final_payable']?.toString() ?? '0',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      items: itemList.map((e) => UsedOrderItem.fromJson(e)).toList(),
    );
  }
}

// ─── List Page ────────────────────────────────────────────────────────────────

class UsedProductOrdersPage extends StatefulWidget {
  const UsedProductOrdersPage({super.key});

  @override
  State<UsedProductOrdersPage> createState() => _UsedProductOrdersPageState();
}

class _UsedProductOrdersPageState extends State<UsedProductOrdersPage> {
  List<UsedOrder> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access');

      if (token == null) {
        setState(() {
          _error = 'Authentication token missing';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$api/api/myskates/used/product/all/orders/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('USED ORDERS STATUS: ${response.statusCode}');
      print('USED ORDERS BODY: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data =
            json['data'] ?? json['results'] ?? json ?? [];
        setState(() {
          _orders = data.map((e) => UsedOrder.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load orders (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching used orders: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
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

  // ── Shimmer ──────────────────────────────────────────────────────────────

  Widget _shimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _glassWrap(
        padding: const EdgeInsets.all(14),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFF1A2B2A),
          highlightColor: const Color(0xFF2F4F4D),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 80,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 12,
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
              const SizedBox(height: 14),
              Container(height: 1, color: Colors.white),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //───────────────────  Order Card 

  Widget _orderCard(UsedOrder order) {
    final statusColor = _statusColor(order.status);
    final firstItem = order.items.isNotEmpty ? order.items.first : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UsedProductOrderDetailPage(orderId: order.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: _glassWrap(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.orderNo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Date + payment
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white38,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: order.paymentMethod == 'COD'
                          ? Colors.orange.withOpacity(0.15)
                          : Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.paymentMethod,
                      style: TextStyle(
                        color: order.paymentMethod == 'COD'
                            ? Colors.orange
                            : Colors.blueAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Items preview ────────────────────────────────────────────
              if (firstItem != null) ...[
                const Text(
                  'Items',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.take(2).map((item) => _itemRow(item)),
                if (order.items.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${order.items.length - 2} more item${order.items.length - 2 == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],

              const Divider(color: Colors.white12, height: 24),

              // ── Total row ──────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Final Payable',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${(double.tryParse(order.finalPayable) ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItemImage(UsedOrderItem item) {
    if (item.image != null && item.image!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          '$api${item.image}',
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _listImageFallback(),
        ),
      );
    }
    return _listImageFallback();
  }

  Widget _listImageFallback() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Colors.white38,
        size: 22,
      ),
    );
  }

  Widget _itemRow(UsedOrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _buildListItemImage(item),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    if (item.attributeName != null &&
                        item.attributeValue != null) ...[
                      const Text(
                        ' • ',
                        style: TextStyle(color: Colors.white24, fontSize: 11),
                      ),
                      Text(
                        '${item.attributeName}: ${item.attributeValue}',
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹${(double.tryParse(item.price) ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
            onRefresh: _fetchOrders,
            color: Colors.tealAccent,
            backgroundColor: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── App bar ──────────────────────────────────────────────
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Used Product Orders',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_isLoading && _error == null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.tealAccent.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '${_orders.length}',
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Body ─────────────────────────────────────────────────
                  Expanded(
                    child: _isLoading
                        ? ListView.builder(
                            itemCount: 5,
                            itemBuilder: (_, i) => _shimmerCard(),
                          )
                        : _error != null
                        ? _buildError()
                        : _orders.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _orders.length,
                            itemBuilder: (_, i) => _orderCard(_orders[i]),
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

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 60),
        _glassWrap(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        _glassWrap(
          padding: const EdgeInsets.all(36),
          child: const Column(
            children: [

              Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 64),
              SizedBox(height: 16),
              Text(
                'No used product orders yet',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Your used product orders will appear here',
                style: TextStyle(color: Colors.white38, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Detail Page ──────────────────────────────────────────────────────────────

class UsedProductOrderDetailPage extends StatefulWidget {
  final int orderId;

  const UsedProductOrderDetailPage({super.key, required this.orderId});

  @override
  State<UsedProductOrderDetailPage> createState() =>
      _UsedProductOrderDetailPageState();
}

class _UsedProductOrderDetailPageState
    extends State<UsedProductOrderDetailPage> {
  UsedOrder? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access');

      if (token == null) {
        setState(() {
          _error = 'Authentication token missing';
          _isLoading = false;
        });
        return;
      }

      final url =
          '$api/api/myskates/used/product/all/orders/detail/view/${widget.orderId}/';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('USED ORDER DETAIL STATUS: ${response.statusCode}');
      print('USED ORDER DETAIL BODY: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // Support both flat and wrapped responses
        final orderJson = json['data'] ?? json;
        setState(() {
          _order = UsedOrder.fromJson(orderJson);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load order detail (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching used order detail: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.tealAccent, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pricingRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isBold = false,
  }) {
    final amount = double.tryParse(value) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isBold ? Colors.white : Colors.white70,
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${isDiscount ? '- ' : ''}₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isDiscount
                  ? Colors.redAccent
                  : isBold
                  ? Colors.tealAccent
                  : Colors.white,
              fontSize: isBold ? 18 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
            onRefresh: _fetchDetail,
            color: Colors.tealAccent,
            backgroundColor: Colors.black,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── App bar ────────────────────────────────────────────
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Order Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.tealAccent,
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_isLoading)
                    _buildShimmer()
                  else if (_error != null)
                    _buildError()
                  else if (_order != null)
                    _buildContent(_order!),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(UsedOrder order) {
    final statusColor = _statusColor(order.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Order header ────────────────────────────────────────────────
        _glassWrap(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.orderNo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.tealAccent,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    order.paymentMethod == 'COD' ? Icons.money : Icons.payment,
                    color: Colors.tealAccent,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Payment: ${order.paymentMethod}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (order.razorpayPaymentRef != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '(${order.razorpayPaymentRef})',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Customer info ────────────────────────────────────────────────
        _glassWrap(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _infoRow(Icons.person_outline, 'Name', order.fullName),
              const SizedBox(height: 12),
              _infoRow(Icons.phone_outlined, 'Phone', order.phone),
              const SizedBox(height: 12),
              _infoRow(
                Icons.location_on_outlined,
                'Delivery Address',
                [
                  order.addressLine1,
                  if (order.addressLine2 != null) order.addressLine2!,
                  '${order.city}, ${order.state} - ${order.pincode}',
                  order.country,
                ].join('\n'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Items ────────────────────────────────────────────────────────
        _glassWrap(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Items',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...order.items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isLast = i == order.items.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: item.image != null && item.image!.isNotEmpty
                                ? Image.network(
                                    '$api${item.image}',
                                    width: 58,
                                    height: 58,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _detailImageFallback(),
                                  )
                                : _detailImageFallback(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.description.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _chip(
                                      'Qty: ${item.quantity}',
                                      Colors.white54,
                                    ),
                                    if (item.attributeName != null &&
                                        item.attributeValue != null)
                                      _chip(
                                        '${item.attributeName}: ${item.attributeValue}',
                                        Colors.tealAccent,
                                      ),
                                    if ((double.tryParse(item.discount) ?? 0) >
                                        0)
                                      _chip(
                                        '${item.discount}% off',
                                        Colors.greenAccent,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${(double.tryParse(item.price) ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if ((double.tryParse(item.shipmentCharge) ?? 0) >
                                  0)
                                Text(
                                  '+₹${(double.tryParse(item.shipmentCharge) ?? 0).toStringAsFixed(0)} ship',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(color: Colors.white.withOpacity(0.07), height: 1),
                  ],
                );
              }).toList(),

              const Divider(color: Colors.white24, height: 24),

              // ── Pricing breakdown ──────────────────────────────────
              _pricingRow('Subtotal', order.subtotal),
              if ((double.tryParse(order.discountTotal) ?? 0) > 0)
                _pricingRow('Discount', order.discountTotal, isDiscount: true),
              if ((double.tryParse(order.shipmentCharge) ?? 0) > 0)
                _pricingRow('Shipment Charge', order.shipmentCharge),

              const Divider(color: Colors.white12, height: 16),

              // Final payable highlight
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.tealAccent.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Final Payable',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${(double.tryParse(order.finalPayable) ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailImageFallback() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Colors.white38,
        size: 26,
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 0.7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildError() {
    return _glassWrap(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A2B2A),
      highlightColor: const Color(0xFF2F4F4D),
      child: Column(
        children: [
          _glassWrap(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 180, height: 16, color: Colors.white),
                    Container(
                      width: 80,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(width: 200, height: 12, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _glassWrap(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(width: 18, height: 18, color: Colors.white),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 50, height: 10, color: Colors.white),
                          const SizedBox(height: 6),
                          Container(
                            width: 160,
                            height: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

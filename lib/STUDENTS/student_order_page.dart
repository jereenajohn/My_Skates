import 'package:flutter/material.dart';
import 'package:my_skates/STUDENTS/student_product_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_skates/api.dart';
import 'package:intl/intl.dart';

// Order Model Classes with images
class OrderItem {
  final int id;
  final int product;
  final String productTitle;
  final String? productImage;
  final int variantId;
  final String? sku;
  final String variantLabel;
  final String? variantImage;
  final String unitPrice;
  final String unitDiscount;
  final int quantity;
  final String lineTotal;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.product,
    required this.productTitle,
    this.productImage,
    required this.variantId,
    this.sku,
    required this.variantLabel,
    this.variantImage,
    required this.unitPrice,
    required this.unitDiscount,
    required this.quantity,
    required this.lineTotal,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      product: json['product'] ?? 0,
      productTitle: json['product_title']?.toString() ?? '',
      productImage: json['product_image']?.toString(),
      variantId: json['variant_id'] ?? 0,
      sku: json['sku']?.toString(),
      variantLabel: json['variant_label']?.toString() ?? '',
      variantImage: json['variant_image']?.toString(),
      unitPrice: json['unit_price']?.toString() ?? '0',
      unitDiscount: json['unit_discount']?.toString() ?? '0',
      quantity: json['quantity'] ?? 0,
      lineTotal: json['line_total']?.toString() ?? '0',
      createdAt: DateTime.tryParse(
            json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

class Order {
  final int id;
  final List<OrderItem> items;
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
  final String subtotal;
  final String discountTotal;
  final String total;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? address;
  final int user;

  Order({
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
    required this.subtotal,
    required this.discountTotal,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    required this.user,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];

    final List<OrderItem> orderItems = itemsList
        .whereType<Map<String, dynamic>>()
        .map((i) => OrderItem.fromJson(i))
        .toList();

    return Order(
      id: json['id'] ?? 0,
      items: orderItems,
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
      subtotal: json['subtotal']?.toString() ?? '0',
      discountTotal: json['discount_total']?.toString() ?? '0',
      total: json['total']?.toString() ?? '0',
      createdAt: DateTime.tryParse(
            json['created_at']?.toString() ?? '',
          )?.toLocal() ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
            json['updated_at']?.toString() ?? '',
          )?.toLocal() ??
          DateTime.now(),
      address: json['address']?.toString(),
      user: json['user'] ?? 0,
    );
  }
}

class OrderResponse {
  final bool success;
  final int count;
  final List<Order> data;

  OrderResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    var ordersList = json['data'] as List? ?? [];
    List<Order> orders = ordersList.map((i) => Order.fromJson(i)).toList();

    return OrderResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      data: orders,
    );
  }
}

class Student_order_page extends StatefulWidget {
  const Student_order_page({super.key});

  @override
  State<Student_order_page> createState() => _Student_order_pageState();
}

class _Student_order_pageState extends State<Student_order_page> {
  List<Order> orders = [];
  bool isLoading = true;
  String? error;

  double _toDouble(String value) {
    return double.tryParse(value) ?? 0.0;
  }

  String _selectedStatusFilter = 'ALL';

  final List<Map<String, String>> statusOptions = [
    {"value": "PLACED", "label": "Placed"},
    {"value": "CONFIRMED", "label": "Confirmed"},
    {"value": "PROCESSING", "label": "Processing"},
    {"value": "SHIPPED", "label": "Shipped"},
    {"value": "DELIVERED", "label": "Delivered"},
    {"value": "CANCELLED", "label": "Cancelled"},
  ];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  List<Order> get _filteredOrders {
    if (_selectedStatusFilter == 'ALL') {
      return orders;
    }
    return orders
        .where((order) => order.status == _selectedStatusFilter)
        .toList();
  }

  Future<void> fetchOrders() async {
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
        Uri.parse('$api/api/myskates/orders/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("ORDERS API STATUS: ${response.statusCode}");
      print("ORDERS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final orderResponse = OrderResponse.fromJson(jsonResponse);

        setState(() {
          orders = orderResponse.data;
          isLoading = false;
        });

        print("Orders fetched successfully: ${orders.length} orders");
      } else {
        setState(() {
          error = 'Failed to load orders: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching orders: $e");
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _refreshOrders() async {
    await fetchOrders();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PROCESSING':
        return Colors.purple;
      case 'SHIPPED':
        return Colors.indigo;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToOrderDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderDetailPage(order: order)),
    );
  }

  Widget _buildProductImage(OrderItem item) {
    if (item.variantImage != null) {
      return Image.network(
        '$api${item.variantImage}',
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          if (item.productImage != null) {
            return Image.network(
              '$api${item.productImage}',
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.image_not_supported,
                color: Colors.white38,
                size: 20,
              ),
            );
          }
          return const Icon(
            Icons.image_not_supported,
            color: Colors.white38,
            size: 20,
          );
        },
      );
    } else if (item.productImage != null) {
      return Image.network(
        '$api${item.productImage}',
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.image_not_supported,
          color: Colors.white38,
          size: 20,
        ),
      );
    } else {
      return const Icon(
        Icons.image_not_supported,
        color: Colors.white38,
        size: 20,
      );
    }
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(order.status).withOpacity(0.35),
                  ),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.tealAccent,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Items',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...order.items.take(2).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildProductImage(item),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.variantLabel.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.variantLabel,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${item.quantity}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${'₹${_toDouble(item.lineTotal).toStringAsFixed(2)}'}',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (order.items.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 70),
              child: Text(
                '+${order.items.length - 2} more items',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${_toDouble(order.total).toStringAsFixed(2)}',
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
    );
  }

  Widget _buildFilterBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatusFilter,
          isExpanded: true,
          icon: const Icon(
            Icons.filter_list_rounded,
            color: Colors.tealAccent,
          ),
          dropdownColor: const Color(0xFF161616),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          hint: const Text(
            'Filter by Status',
            style: TextStyle(color: Colors.white54),
          ),
          onChanged: (String? newValue) {
            setState(() {
              _selectedStatusFilter = newValue!;
            });
          },
          items: [
            const DropdownMenuItem<String>(
              value: 'ALL',
              child: Row(
                children: [
                  Icon(
                    Icons.apps_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'All Orders',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            ...statusOptions.map<DropdownMenuItem<String>>(
              (Map<String, String> option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(option['value']!),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option['label']!,
                        style: TextStyle(
                          color: _getStatusColor(option['value']!),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.tealAccent.withOpacity(0.10),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "My Orders",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_filteredOrders.length} orders found',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          if (_selectedStatusFilter != 'ALL') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(_selectedStatusFilter).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Filtered: $_selectedStatusFilter',
                style: TextStyle(
                  color: _getStatusColor(_selectedStatusFilter),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001A18), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshOrders,
          color: Colors.tealAccent,
          backgroundColor: Colors.black,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  )
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchOrders,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white38,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No orders found',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Your orders will appear here',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.tealAccent,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Go Back'),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                _buildTopInfo(),
                                _buildFilterBox(),
                                ..._filteredOrders.map(
                                  (order) => GestureDetector(
                                    onTap: () => _navigateToOrderDetail(order),
                                    child: _buildOrderCard(order),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
          ),
        ),
      ),
    );
  }
}

// ==================== ORDER DETAIL PAGE ====================

class OrderDetailPage extends StatefulWidget {
  final Order order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final Map<int, List<dynamic>> _reviewsCacheByProduct = {};
  final TextEditingController _customReasonController = TextEditingController();
  bool _reviewPopupCheckedOnce = false;
  bool _isSubmittingReturnExchange = false;
  bool _isCancellingOrderItem = false;
  OrderItem? _selectedReturnItem;
  OrderItem? _selectedCancelItem;
  String? _selectedRefundRemark;
  String? _selectedReasonType;

  final List<Map<String, String>> _refundRemarkOptions = [
    {'value': 'return', 'label': 'Return'},
    {'value': 'refund', 'label': 'Refund'},
    {'value': 'exchange', 'label': 'Exchange'},
    {'value': 'cod_return', 'label': 'COD Return'},
  ];

  final List<Map<String, String>> _refundReasonTypeOptions = [
    {'value': 'defective', 'label': 'Defective Product'},
    {'value': 'wrong_item', 'label': 'Wrong Item Delivered'},
    {'value': 'no_longer_needed', 'label': 'No Longer Needed'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowReviewPopup();
    });
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _maybeShowReviewPopup() async {
    if (!mounted) return;
    if (_reviewPopupCheckedOnce) return;
    _reviewPopupCheckedOnce = true;

    final status = widget.order.status.toUpperCase();
    print("ORDER STATUS = $status");

    if (status != "DELIVERED") return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    final userId = prefs.getInt("user_id") ?? prefs.getInt("id");

    print("TOKEN EXISTS = ${token != null}");
    print("USER ID = $userId");

    if (token == null || userId == null) return;

    for (final item in widget.order.items) {
      final alreadyReviewed = await _hasUserReviewedProduct(
        token: token,
        userId: userId,
        productId: item.product,
      );

      print("ITEM ${item.productTitle} => alreadyReviewed = $alreadyReviewed");

      if (!alreadyReviewed) {
        await _showReviewPopup(item);
        break;
      }
    }
  }

  Future<bool> _hasUserReviewedProduct({
    required String token,
    required int userId,
    required int productId,
  }) async {
    try {
      List<dynamic> reviews;

      if (_reviewsCacheByProduct.containsKey(productId)) {
        reviews = _reviewsCacheByProduct[productId]!;
      } else {
        final res = await http.get(
          Uri.parse('$api/api/myskates/products/$productId/ratings/'),
          headers: {'Authorization': 'Bearer $token'},
        );

        print("RATINGS STATUS FOR PRODUCT $productId = ${res.statusCode}");
        print("RATINGS BODY FOR PRODUCT $productId = ${res.body}");

        if (res.statusCode != 200) return false;

        final decoded = jsonDecode(res.body);

        if (decoded is List) {
          reviews = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          reviews = decoded['data'];
        } else {
          reviews = [];
        }

        _reviewsCacheByProduct[productId] = reviews;
      }

      for (final r in reviews) {
        if (r is! Map) continue;

        final dynamic userField = r['user'];
        int reviewUserId = 0;

        if (userField is Map) {
          reviewUserId = userField['id'] ?? 0;
        } else {
          reviewUserId = userField ?? 0;
        }

        final int reviewProductId = r['product'] ?? productId;

        if (reviewUserId == userId && reviewProductId == productId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print("ERROR IN _hasUserReviewedProduct: $e");
      return false;
    }
  }

  Future<void> _showReviewPopup(OrderItem item) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Write a review",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Text(
            "Your order is delivered ✅\n\nPlease add a review for:\n${item.productTitle}${item.variantLabel.isNotEmpty ? '\n${item.variantLabel}' : ''}",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Later",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentProductReviewpage(
                      productId: item.product,
                      productTitle: item.productTitle,
                      productImage: item.productImage,
                      variantId: item.variantId,
                      variantLabel: item.variantLabel,
                      variantImage: item.variantImage,
                    ),
                  ),
                );

                if (result == true) {
                  _reviewsCacheByProduct.remove(item.product);
                  _reviewPopupCheckedOnce = false;
                  await Future.delayed(const Duration(milliseconds: 150));
                  await _maybeShowReviewPopup();
                }
              },
              child: const Text("Write Review"),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PROCESSING':
        return Colors.purple;
      case 'SHIPPED':
        return Colors.indigo;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRefundLabel(String value, List<Map<String, String>> options) {
    final match = options.where((option) => option['value'] == value).toList();
    if (match.isEmpty) return value;
    return match.first['label'] ?? value;
  }

  bool get _canRequestReturnExchange {
    return widget.order.status.toUpperCase() == 'DELIVERED';
  }

  bool get _canCancelOrderItem {
    return widget.order.status.toUpperCase() == 'PLACED';
  }

  void _resetCancelOrderForm() {
    _selectedCancelItem = widget.order.items.isNotEmpty ? widget.order.items.first : null;
    _isCancellingOrderItem = false;
  }

  Future<void> _submitCancelOrderItem(StateSetter bottomSheetSetState) async {
    if (_selectedCancelItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product to cancel')),
      );
      return;
    }

    bottomSheetSetState(() {
      _isCancellingOrderItem = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        bottomSheetSetState(() {
          _isCancellingOrderItem = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token missing')),
        );
        return;
      }

      final Map<String, dynamic> requestBody = {
        'order': widget.order.id,
        'order_id': widget.order.id,
        'product': _selectedCancelItem!.product,
        'product_id': _selectedCancelItem!.product,
      };

      final response = await http.post(
        Uri.parse(
          '$api/api/myskates/orders/${widget.order.id}/cancel/${_selectedCancelItem!.product}/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print("CANCEL ORDER ITEM API STATUS: ${response.statusCode}");
      print("CANCEL ORDER ITEM REQUEST BODY: ${jsonEncode(requestBody)}");
      print("CANCEL ORDER ITEM RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage = 'Failed to cancel product';

        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            errorMessage = decoded['message']?.toString() ??
                decoded['error']?.toString() ??
                decoded['detail']?.toString() ??
                errorMessage;
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print("ERROR CANCELLING ORDER ITEM: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        bottomSheetSetState(() {
          _isCancellingOrderItem = false;
        });
      }
    }
  }

  Future<void> _showCancelOrderBottomSheet() async {
    if (widget.order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available in this order')),
      );
      return;
    }

    _resetCancelOrderForm();

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
                decoration: const BoxDecoration(
                  color: Color(0xFF0E0E0E),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cancel Product',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Select the product you want to cancel',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _isCancellingOrderItem
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Product',
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
                            child: DropdownButton<OrderItem>(
                              value: _selectedCancelItem,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF161616),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white70,
                              ),
                              style: const TextStyle(color: Colors.white),
                              onChanged: _isCancellingOrderItem
                                  ? null
                                  : (OrderItem? value) {
                                      bottomSheetSetState(() {
                                        _selectedCancelItem = value;
                                      });
                                    },
                              items: widget.order.items.map((item) {
                                return DropdownMenuItem<OrderItem>(
                                  value: item,
                                  child: Text(
                                    '${item.productTitle}${item.variantLabel.isNotEmpty ? ' - ${item.variantLabel}' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.22),
                            ),
                          ),
                          child: const Text(
                            'Cancellation is allowed only while the order is in Placed status.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isCancellingOrderItem
                                ? null
                                : () => _submitCancelOrderItem(bottomSheetSetState),
                            icon: _isCancellingOrderItem
                                ? const SizedBox.shrink()
                                : const Icon(Icons.cancel_outlined),
                            label: _isCancellingOrderItem
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Text(
                                    'Cancel Selected Product',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              disabledBackgroundColor: Colors.redAccent.withOpacity(0.35),
                              foregroundColor: Colors.white,
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
              ),
            );
          },
        );
      },
    );
  }

  void _resetReturnExchangeForm() {
    _selectedReturnItem = widget.order.items.isNotEmpty ? widget.order.items.first : null;
    _selectedRefundRemark = null;
    _selectedReasonType = null;
    _customReasonController.clear();
    _isSubmittingReturnExchange = false;
  }

  Future<void> _submitReturnExchangeRequest(StateSetter bottomSheetSetState) async {
    if (_selectedReturnItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    if (_selectedRefundRemark == null || _selectedRefundRemark!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select return/exchange type')),
      );
      return;
    }

    if (_selectedReasonType == null || _selectedReasonType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select reason type')),
      );
      return;
    }

    final customReason = _customReasonController.text.trim();

    if (_selectedReasonType == 'other' && customReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter reason')),
      );
      return;
    }

    bottomSheetSetState(() {
      _isSubmittingReturnExchange = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        bottomSheetSetState(() {
          _isSubmittingReturnExchange = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token missing')),
        );
        return;
      }

      final Map<String, dynamic> requestBody = {
        'item': _selectedReturnItem!.id,
        'product': _selectedReturnItem!.product,
        'remark': _selectedRefundRemark,
        'reason_type': _selectedReasonType,
        'reason': _selectedReasonType == 'other'
            ? customReason
            : _getRefundLabel(_selectedReasonType!, _refundReasonTypeOptions),
      };

      final response = await http.post(
        Uri.parse('$api/api/myskates/msk/refund/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print("RETURN EXCHANGE API STATUS: ${response.statusCode}");
      print("RETURN EXCHANGE REQUEST BODY: ${jsonEncode(requestBody)}");
      print("RETURN EXCHANGE RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return/Exchange request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage = 'Failed to submit request';

        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            errorMessage = decoded['message']?.toString() ??
                decoded['error']?.toString() ??
                decoded['detail']?.toString() ??
                errorMessage;
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print("ERROR SUBMITTING RETURN EXCHANGE REQUEST: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        bottomSheetSetState(() {
          _isSubmittingReturnExchange = false;
        });
      }
    }
  }

  Future<void> _showReturnExchangeBottomSheet() async {
    if (widget.order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available in this order')),
      );
      return;
    }

    _resetReturnExchangeForm();

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
                                  'Return / Exchange Request',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Select product and reason to submit request',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<OrderItem>(
                            value: _selectedReturnItem,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF161616),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                            style: const TextStyle(color: Colors.white),
                            onChanged: _isSubmittingReturnExchange
                                ? null
                                : (OrderItem? value) {
                                    bottomSheetSetState(() {
                                      _selectedReturnItem = value;
                                    });
                                  },
                            items: widget.order.items.map((item) {
                              return DropdownMenuItem<OrderItem>(
                                value: item,
                                child: Text(
                                  '${item.productTitle}${item.variantLabel.isNotEmpty ? ' - ${item.variantLabel}' : ''}',
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRefundRemark,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF161616),
                            hint: const Text(
                              'Select return, refund or exchange',
                              style: TextStyle(color: Colors.white54),
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                            style: const TextStyle(color: Colors.white),
                            onChanged: _isSubmittingReturnExchange
                                ? null
                                : (String? value) {
                                    bottomSheetSetState(() {
                                      _selectedRefundRemark = value;
                                    });
                                  },
                            items: _refundRemarkOptions.map((option) {
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
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedReasonType,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF161616),
                            hint: const Text(
                              'Select reason type',
                              style: TextStyle(color: Colors.white54),
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                            style: const TextStyle(color: Colors.white),
                            onChanged: _isSubmittingReturnExchange
                                ? null
                                : (String? value) {
                                    bottomSheetSetState(() {
                                      _selectedReasonType = value;
                                      if (value != 'other') {
                                        _customReasonController.clear();
                                      }
                                    });
                                  },
                            items: _refundReasonTypeOptions.map((option) {
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
                      if (_selectedReasonType == 'other') ...[
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
                          controller: _customReasonController,
                          enabled: !_isSubmittingReturnExchange,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Type your reason',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.07),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Colors.tealAccent),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmittingReturnExchange
                              ? null
                              : () => _submitReturnExchangeRequest(bottomSheetSetState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            disabledBackgroundColor: Colors.tealAccent.withOpacity(0.35),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSubmittingReturnExchange
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Text(
                                  'Submit Request',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
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

  Widget _buildCancelOrderButton() {
    if (!_canCancelOrderItem) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      child: ElevatedButton.icon(
        onPressed: _showCancelOrderBottomSheet,
        icon: const Icon(Icons.cancel_outlined, size: 20),
        label: const Text(
          'Cancel Product',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildReturnExchangeButton() {
    if (!_canRequestReturnExchange) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      child: ElevatedButton.icon(
        onPressed: _showReturnExchangeBottomSheet,
        icon: const Icon(Icons.assignment_return_outlined, size: 20),
        label: const Text(
          'Return / Exchange',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
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

  Widget _buildProductImage(OrderItem item) {
    if (item.variantImage != null) {
      return Image.network(
        '$api${item.variantImage}',
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          if (item.productImage != null) {
            return Image.network(
              '$api${item.productImage}',
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.transparent,
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.white38,
                  size: 30,
                ),
              ),
            );
          }
          return Container(
            color: Colors.transparent,
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.white38,
              size: 30,
            ),
          );
        },
      );
    } else if (item.productImage != null) {
      return Image.network(
        '$api${item.productImage}',
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.transparent,
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.white38,
            size: 30,
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.transparent,
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.white38,
          size: 30,
        ),
      );
    }
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
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
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(
    String title,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (order.items.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () async {
                final item = order.items.first;

                final result = await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, animation, secondaryAnimation) =>
                        StudentProductReviewpage(
                      productId: item.product,
                      productTitle: item.productTitle,
                      productImage: item.productImage,
                      variantId: item.variantId,
                      variantLabel: item.variantLabel,
                      variantImage: item.variantImage,
                    ),
                    transitionsBuilder:
                        (_, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 250),
                    opaque: true,
                  ),
                );

                if (result == true) {
                  _reviewsCacheByProduct.remove(item.product);
                  _reviewPopupCheckedOnce = false;
                  await Future.delayed(const Duration(milliseconds: 150));
                  await _maybeShowReviewPopup();
                }
              },
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001A18), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGlassCard(
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
                              fontSize: 17,
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
                            color: _getStatusColor(order.status)
                                .withOpacity(0.18),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _getStatusColor(order.status)
                                  .withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            order.status,
                            style: TextStyle(
                              color: _getStatusColor(order.status),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.tealAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ordered on: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt.toLocal())}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Customer Information'),
                    const SizedBox(height: 16),
                    _infoRow(Icons.person_outline, 'Name', order.fullName),
                    const SizedBox(height: 14),
                    _infoRow(Icons.phone_outlined, 'Phone', order.phone),
                    const SizedBox(height: 14),
                    _infoRow(
                      Icons.location_on_outlined,
                      'Delivery Address',
                      '${order.addressLine1}${order.addressLine2 != null ? ', ${order.addressLine2}' : ''}\n${order.city}, ${order.state} - ${order.pincode}\n${order.country}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Payment Information'),
                    const SizedBox(height: 16),
                    _infoRow(
                      order.paymentMethod == 'COD'
                          ? Icons.money
                          : Icons.payment,
                      'Payment Method',
                      order.paymentMethod,
                    ),
                    if (order.paymentRef != null) ...[
                      const SizedBox(height: 14),
                      _infoRow(
                        Icons.receipt_outlined,
                        'Payment Reference',
                        order.paymentRef!,
                      ),
                    ],
                    if (order.note != null && order.note!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _infoRow(Icons.note_outlined, 'Order Note', order.note!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Order Items'),
                    const SizedBox(height: 16),
                    ...order.items.map(
                      (item) => InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentProductReviewpage(
                                productId: item.product,
                                productTitle: item.productTitle,
                                productImage: item.productImage,
                                variantId: item.variantId,
                                variantLabel: item.variantLabel,
                                variantImage: item.variantImage,
                              ),
                            ),
                          );

                          if (result == true) {
                            _reviewsCacheByProduct.remove(item.product);
                            _reviewPopupCheckedOnce = false;
                            await Future.delayed(
                              const Duration(milliseconds: 150),
                            );
                            await _maybeShowReviewPopup();
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.white.withOpacity(0.05),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: _buildProductImage(item),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (item.variantLabel.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.tealAccent.withOpacity(
                                            0.14,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.variantLabel,
                                          style: const TextStyle(
                                            color: Colors.tealAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Text(
                                      'Qty: ${item.quantity}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 26),
                    _priceRow(
                      'Subtotal',
                      '₹${double.parse(order.subtotal).toStringAsFixed(2)}',
                    ),
                    if (double.parse(order.discountTotal) > 0) ...[
                      const SizedBox(height: 10),
                      _priceRow(
                        'Discount',
                        '-₹${double.parse(order.discountTotal).toStringAsFixed(2)}',
                        valueColor: Colors.greenAccent,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.tealAccent.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${double.parse(order.total).toStringAsFixed(2)}',
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
              const SizedBox(height: 16),
              _buildCancelOrderButton(),
              if (_canCancelOrderItem) const SizedBox(height: 12),
              _buildReturnExchangeButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

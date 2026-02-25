import 'package:flutter/material.dart';
import 'package:my_skates/COACH/product_review_page.dart';
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
      productTitle: json['product_title'] ?? '',
      productImage: json['product_image'],
      variantId: json['variant_id'] ?? 0,
      sku: json['sku'],
      variantLabel: json['variant_label'] ?? '',
      variantImage: json['variant_image'],
      unitPrice: json['unit_price']?.toString() ?? '0',
      unitDiscount: json['unit_discount']?.toString() ?? '0',
      quantity: json['quantity'] ?? 0,
      lineTotal: json['line_total']?.toString() ?? '0',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
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
  final String final_payable;

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
    required this.final_payable,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<OrderItem> orderItems = itemsList
        .map((i) => OrderItem.fromJson(i))
        .toList();

    return Order(
      id: json['id'] ?? 0,
      items: orderItems,
      orderNo: json['order_no'] ?? '',
      status: json['status'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      paymentRef: json['payment_ref'],
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      country: json['country'] ?? '',
      note: json['note'],
      subtotal: json['subtotal']?.toString() ?? '0',
      final_payable: json['final_payable']?.toString() ?? '0',
      discountTotal: json['discount_total']?.toString() ?? '0',
      total: json['total']?.toString() ?? '0',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      address: json['address'],
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

class Myorders extends StatefulWidget {
  const Myorders({super.key});

  @override
  State<Myorders> createState() => _MyordersState();
}

class _MyordersState extends State<Myorders> {
  List<Order> orders = [];
  bool isLoading = true;
  String? error;
  
  // Status filter
  String _selectedStatusFilter = 'ALL';

  // Status options for filter dropdown
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

  // Get filtered orders based on selected status
  List<Order> get _filteredOrders {
    if (_selectedStatusFilter == 'ALL') {
      return orders;
    }
    return orders.where((order) =>
      order.status == _selectedStatusFilter
    ).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
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
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your orders will appear here',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
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
                  child: Column(
                    children: [
                      // Status Filter Dropdown
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatusFilter,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.filter_list,
                              color: Colors.tealAccent,
                            ),
                            dropdownColor: const Color(0xFF1A1A1A),
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
                                      Icons.all_inclusive,
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
                              ...statusOptions.map<DropdownMenuItem<String>>((
                                Map<String, String> option,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: option['value'],
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            option['value']!,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        option['label']!,
                                        style: TextStyle(
                                          color: _getStatusColor(
                                            option['value']!,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),

                      // Results count
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              '${_filteredOrders.length} orders found',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            if (_selectedStatusFilter != 'ALL')
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    _selectedStatusFilter,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Filtered: ${_selectedStatusFilter}',
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      _selectedStatusFilter,
                                    ),
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Orders List
                      ..._filteredOrders.map((order) => GestureDetector(
                        onTap: () => _navigateToOrderDetail(order),
                        child: _buildOrderCard(order),
                      )).toList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${order.orderNo}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getStatusColor(order.status).withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          
          // Items section
          // const Text(
          //   'Items:',
          //   style: TextStyle(
          //     color: Colors.white,
          //     fontSize: 16,
          //     fontWeight: FontWeight.w600,
          //   ),
          // ),

          const SizedBox(height: 12),
          ...order.items
              .take(2)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildProductImage(item),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Product details
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

                      // Price
                      // Text(
                      //   '₹${double.parse(item.lineTotal).toStringAsFixed(2)}',
                      //   style: const TextStyle(
                      //     color: Colors.tealAccent,
                      //     fontSize: 14,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              )
              .toList(),
          if (order.items.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 62),
              child: Text(
                '+${order.items.length -2} more items',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const Divider(color: Colors.white24, height: 15),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${double.parse(order.final_payable).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
}

// ==================== ORDER DETAIL PAGE ====================

class OrderDetailPage extends StatelessWidget {
  final Order order;

  const OrderDetailPage({super.key, required this.order});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Number and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${order.orderNo}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: _getStatusColor(
                              order.status,
                            ).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          order.status,
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Order Date
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.tealAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ordered on: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Customer Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.tealAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Name',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              order.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Phone
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        color: Colors.tealAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phone',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              order.phone,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.tealAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Delivery Address',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${order.addressLine1}${order.addressLine2 != null ? ', ${order.addressLine2}' : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${order.city}, ${order.state} - ${order.pincode}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              order.country,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  Row(
                    children: [
                      Icon(
                        order.paymentMethod == 'COD'
                            ? Icons.money
                            : Icons.payment,
                        color: Colors.tealAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Method',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              order.paymentMethod,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (order.paymentRef != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_outlined,
                          color: Colors.tealAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Reference',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                order.paymentRef!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (order.note != null && order.note!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.note_outlined,
                          color: Colors.tealAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Note',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                order.note!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order Items Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Items',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Items List
                  ...order.items
                      .map(
                        (item) => GestureDetector(
                          onTap: (){
                            Navigator.push(context,MaterialPageRoute(builder: (context)=>ProductReviewPage(
                              productId: item.product,
                              productTitle: item.productTitle,
                              productImage: item.productImage,
                              variantId: item.variantId,
                              variantLabel: item.variantLabel,
                              variantImage: item.variantImage,
                              )
                              )
                              );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _buildProductImage(item),
                                  ),
                                ),
                          
                                const SizedBox(width: 16),
                          
                                // Product Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productTitle,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (item.variantLabel.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.tealAccent.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            item.variantLabel,
                                            style: const TextStyle(
                                              color: Colors.tealAccent,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'Qty: ${item.quantity}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),

                  const Divider(color: Colors.white24, height: 24),

                  // Price Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '₹${double.parse(order.subtotal).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  if (double.parse(order.discountTotal) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Discount',
                          style: TextStyle(color: Colors.green, fontSize: 14),
                        ),
                        Text(
                          '-₹${double.parse(order.discountTotal).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${double.parse(order.final_payable).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
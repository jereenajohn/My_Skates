import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/admin_product_review.dart';
import 'package:my_skates/COACH/product_review_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:my_skates/api.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

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
  final String variantPrice;
  final String variantDiscount;
  final int quantity;
  final String lineTotal;
  final String? productUserType;
  final int? coachId;
  final String? coachName;
  final String? coachPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    required this.variantPrice,
    required this.variantDiscount,
    required this.quantity,
    required this.lineTotal,
    this.productUserType,
    this.coachId,
    this.coachName,
    this.coachPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      product: json['product'] ?? 0,
      productTitle: json['product_title'] ?? '',
      productImage: json['product_image'],
      variantId: json['variant_id'] ?? json['variant'] ?? 0,
      sku: json['sku'],
      variantLabel: json['variant_label'] ?? '',
      variantImage: json['variant_image'],
      unitPrice: json['unit_price']?.toString() ?? '0',
      unitDiscount: json['unit_discount']?.toString() ?? '0',
      variantPrice: json['variant_price']?.toString() ?? '0',
      variantDiscount: json['variant_discount']?.toString() ?? '0',
      quantity: json['quantity'] ?? 0,
      lineTotal: json['line_total']?.toString() ?? '0',
      productUserType: json['product_user_type'],
      coachId: json['coach_id'],
      coachName: json['coach_name'],
      coachPhone: json['coach_phone'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  double get displayTotal {
    final line = double.tryParse(lineTotal) ?? 0.0;
    if (line > 0) return line;

    final price = double.tryParse(variantPrice) ?? 0.0;
    final discount = double.tryParse(variantDiscount) ?? 0.0;
    return (price - discount) * quantity;
  }
}

class SellerBankDetails {
  final int id;
  final String coachName;
  final String phone;
  final String accountHolderName;
  final String bankName;
  final String branchName;
  final String accountNumber;
  final String ifscCode;
  final String upiId;

  SellerBankDetails({
    required this.id,
    required this.coachName,
    required this.phone,
    required this.accountHolderName,
    required this.bankName,
    required this.branchName,
    required this.accountNumber,
    required this.ifscCode,
    required this.upiId,
  });

  factory SellerBankDetails.fromJson(Map<String, dynamic> json) {
    return SellerBankDetails(
      id: json['id'] ?? 0,
      coachName: json['coach_name'] ?? '',
      phone: json['phone'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      branchName: json['branch_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      upiId: json['upi_id'] ?? '',
    );
  }
}

class SellerBreakdownItem {
  final int itemId;
  final String productTitle;
  final int quantity;
  final String variantPrice;
  final String variantDiscount;
  final String itemTotal;
  final String percentageAmount;
  final String sellerPayable;

  SellerBreakdownItem({
    required this.itemId,
    required this.productTitle,
    required this.quantity,
    required this.variantPrice,
    required this.variantDiscount,
    required this.itemTotal,
    required this.percentageAmount,
    required this.sellerPayable,
  });

  factory SellerBreakdownItem.fromJson(Map<String, dynamic> json) {
    return SellerBreakdownItem(
      itemId: json['item_id'] ?? 0,
      productTitle: json['product_title'] ?? '',
      quantity: json['quantity'] ?? 0,
      variantPrice: json['variant_price']?.toString() ?? '0',
      variantDiscount: json['variant_discount']?.toString() ?? '0',
      itemTotal: json['item_total']?.toString() ?? '0',
      percentageAmount: json['percentage_amount']?.toString() ?? '0',
      sellerPayable: json['seller_payable']?.toString() ?? '0',
    );
  }
}

class SellerBreakdown {
  final int coachId;
  final String coachName;
  final String coachPhone;
  final String sellerTotal;
  final String sellerPayable;
  final SellerBankDetails? bankDetails;
  final List<SellerBreakdownItem> items;

  SellerBreakdown({
    required this.coachId,
    required this.coachName,
    required this.coachPhone,
    required this.sellerTotal,
    required this.sellerPayable,
    this.bankDetails,
    required this.items,
  });

  factory SellerBreakdown.fromJson(Map<String, dynamic> json) {
    final itemList = json['items'] as List? ?? [];

    return SellerBreakdown(
      coachId: json['coach_id'] ?? 0,
      coachName: json['coach_name'] ?? '',
      coachPhone: json['coach_phone'] ?? '',
      sellerTotal: json['seller_total']?.toString() ?? '0',
      sellerPayable: json['seller_payable']?.toString() ?? '0',
      bankDetails: json['bank_details'] == null
          ? null
          : SellerBankDetails.fromJson(json['bank_details']),
      items: itemList.map((e) => SellerBreakdownItem.fromJson(e)).toList(),
    );
  }
}

class Order {
  final int id;
  final List<OrderItem> items;
  final String orderNo;
  String status;
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
  final String platformFee;
  final String convenienceFee;
  final String couponDiscount;
  final String finalPayable;
  final String? couponName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? address;
  final int user;
  final String shipmentCharge;
  final String productPercentage;
  final List<SellerBreakdown> sellerBreakdown;

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
    required this.platformFee,
    required this.convenienceFee,
    required this.couponDiscount,
    required this.finalPayable,
    this.couponName,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    required this.user,
    required this.shipmentCharge,
    required this.productPercentage,
    required this.sellerBreakdown,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<OrderItem> orderItems = itemsList
        .map((i) => OrderItem.fromJson(i))
        .toList();

    final breakdownList = json['seller_breakdown'] as List? ?? [];
    final sellerBreakdown = breakdownList
        .map((e) => SellerBreakdown.fromJson(e))
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
      discountTotal: json['discount_total']?.toString() ?? '0',
      total: json['total']?.toString() ?? '0',
      platformFee: json['platform_fee']?.toString() ?? '0',
      convenienceFee: json['convenience_fee']?.toString() ?? '0',
      couponDiscount: json['coupon_discount']?.toString() ?? '0',
      finalPayable: json['final_payable']?.toString() ?? '0',
      couponName: json['coupon_name'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      address: json['address'],
      user: json['user'] ?? 0,
      shipmentCharge: json['shipment_charge']?.toString() ?? '0',
      productPercentage: json['product_percentage']?.toString() ?? '0',
      sellerBreakdown: sellerBreakdown,
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

// Enum to track which view is selected
enum OrderViewType { allOrders, myOrders, mySoldOrders, coachProductOrders }

class Admin_order_page extends StatefulWidget {
  const Admin_order_page({super.key});

  @override
  State<Admin_order_page> createState() => _Admin_order_pageState();
}

class _Admin_order_pageState extends State<Admin_order_page> {
  List<Order> orders = [];
  bool isLoading = true;
  String? error;
  bool _isAdmin = false;

  // Only two options: All Orders and My Orders
  OrderViewType _selectedView = OrderViewType.allOrders;

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndFetchOrders();
  }

  Future<void> _loadUserRoleAndFetchOrders() async {
    final prefs = await SharedPreferences.getInstance();

    final role =
        (prefs.getString('role') ??
                prefs.getString('user_type') ??
                prefs.getString('account_type') ??
                '')
            .toLowerCase()
            .trim();

    setState(() {
      _isAdmin = role == 'admin';
    });

    await fetchOrders();
  }

  /// Returns the correct API URL based on selected view
  String get _apiUrl {
    switch (_selectedView) {
      case OrderViewType.allOrders:
        return '$api/api/myskates/all/orders/';
      case OrderViewType.myOrders:
        return '$api/api/myskates/orders/';
      case OrderViewType.mySoldOrders:
        return '$api/api/myskates/seller/orders/';
      case OrderViewType.coachProductOrders:
        return '$api/api/myskates/coach/orders/view/';
    }
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

      if (_selectedView == OrderViewType.coachProductOrders && !_isAdmin) {
        setState(() {
          orders = [];
          error = 'Only admin can view coach product orders';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(_apiUrl),
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

  final List<Map<String, String>> statusOptions = [
    {"value": "PLACED", "label": "Placed"},
    {"value": "PAID", "label": "Paid"},
    {"value": "SHIPPED", "label": "Shipped"},
    {"value": "DELIVERED", "label": "Delivered"},
    {"value": "CANCELLED", "label": "Cancelled"},
  ];

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
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
        Uri.parse('$api/api/myskates/orders/status/update/$orderId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': newStatus}),
      );

      print("UPDATE STATUS API STATUS: ${response.statusCode}");
      print("UPDATE STATUS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          final index = orders.indexWhere((o) => o.id == orderId);
          if (index != -1) {
            orders[index].status = newStatus;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Status updated to $newStatus',
                  style: TextStyle(color: Colors.black),
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

  void _showStatusBottomSheet(Order order) {
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
                  // Handle bar
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
                    'Update Order Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${order.orderNo}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  ...statusOptions.map((option) {
                    final isSelected = order.status == option['value'];
                    final statusColor = _getStatusColor(option['value']!);
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        if (!isSelected) {
                          updateOrderStatus(order.id, option['value']!);
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
                  }).toList(),
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

  void _navigateToOrderDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailPage(
          order: order,
          isCoachProductOrder:
              _selectedView == OrderViewType.coachProductOrders,
        ),
      ),
    );
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

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _glassWrap(
        padding: const EdgeInsets.all(12),
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
                    width: 90,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: 70,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 55,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 45,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    width: 70,
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

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  /// Dropdown that switches between All Orders, My Orders and My Sold Orders
  Widget _buildViewDropdown() {
    return _glassWrap(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<OrderViewType>(
          value: _selectedView,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.tealAccent),
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (OrderViewType? newValue) {
            if (newValue != null && newValue != _selectedView) {
              setState(() {
                _selectedView = newValue;
                orders = [];
              });
              fetchOrders();
            }
          },
          items: [
            DropdownMenuItem<OrderViewType>(
              value: OrderViewType.allOrders,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.list_alt_rounded,
                      color: Colors.tealAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'All Orders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            DropdownMenuItem<OrderViewType>(
              value: OrderViewType.myOrders,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.tealAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'My Orders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            DropdownMenuItem<OrderViewType>(
              value: OrderViewType.mySoldOrders,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.tealAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'My Sold Orders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            if (_isAdmin)
              DropdownMenuItem<OrderViewType>(
                value: OrderViewType.coachProductOrders,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sports_rounded,
                        color: Colors.tealAccent,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Coach Product Orders',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

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
            onRefresh: _refreshOrders,
            color: Colors.tealAccent,
            backgroundColor: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? Column(
                      children: [
                        // Header row shown during loading too
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Orders',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildViewDropdown(),
                        const SizedBox(height: 16),
                        Expanded(child: _buildShimmerList()),
                      ],
                    )
                  : error != null
                  ? Center(
                      child: _glassWrap(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Orders',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                      ),
                    )
                  : orders.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Orders',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildViewDropdown(),
                          const SizedBox(height: 40),
                          _glassWrap(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white38,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedView == OrderViewType.myOrders
                                      ? 'No orders yet'
                                      : _selectedView ==
                                            OrderViewType.mySoldOrders
                                      ? 'No sold orders yet'
                                      : _selectedView ==
                                            OrderViewType.coachProductOrders
                                      ? 'No coach product orders yet'
                                      : 'No orders found',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedView == OrderViewType.myOrders
                                      ? 'Your orders will appear here'
                                      : _selectedView ==
                                            OrderViewType.mySoldOrders
                                      ? 'Orders for your products will appear here'
                                      : _selectedView ==
                                            OrderViewType.coachProductOrders
                                      ? 'Coach product orders will appear here'
                                      : 'All orders will appear here',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Orders',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // View type dropdown (All Orders / My Orders)
                          _buildViewDropdown(),

                          const SizedBox(height: 10),

                          // Count label
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  '${orders.length} order${orders.length == 1 ? '' : 's'} found',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
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
                                    _selectedView == OrderViewType.myOrders
                                        ? 'My Orders'
                                        : _selectedView ==
                                              OrderViewType.mySoldOrders
                                        ? 'My Sold Orders'
                                        : _selectedView ==
                                              OrderViewType.coachProductOrders
                                        ? 'Coach Product Orders'
                                        : 'All Orders',
                                    style: const TextStyle(
                                      color: Colors.tealAccent,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Order cards
                          ...orders
                              .map((order) => _buildOrderCard(order))
                              .toList(),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _glassWrap(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToOrderDetail(order),
                    child: Text(
                      'Order #${order.orderNo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge — tappable in My Sold Orders only, read-only in All Orders & My Orders
                GestureDetector(
                  onTap: _selectedView == OrderViewType.mySoldOrders
                      ? () => _showStatusBottomSheet(order)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor(order.status).withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.status,
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_selectedView == OrderViewType.mySoldOrders) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.expand_more_rounded,
                            color: _getStatusColor(order.status),
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Items:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            ...order.items
                .take(2)
                .map(
                  (item) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductReviewPage(
                            productId: item.product,
                            productTitle: item.productTitle,
                            productImage: item.productImage,
                            variantId: item.variantId,
                            variantLabel: item.variantLabel,
                            variantImage: item.variantImage,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _navigateToOrderDetail(order),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildProductImage(item),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: GestureDetector(
                              onTap: () => (order),
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
                                  if (_selectedView ==
                                          OrderViewType.coachProductOrders &&
                                      item.productUserType == 'coach') ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Coach Product',
                                      style: TextStyle(
                                        color: Colors.tealAccent.withOpacity(
                                          0.9,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () => _navigateToOrderDetail(order),
                            child: Text(
                              '₹${item.displayTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.tealAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),

            if (order.items.length > 2)
              GestureDetector(
                onTap: () => _navigateToOrderDetail(order),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, left: 62),
                  child: Text(
                    '+${order.items.length - 2} more items',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            const Divider(color: Colors.white24, height: 24),

            GestureDetector(
              onTap: () => _navigateToOrderDetail(order),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${double.parse(order.total).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class OrderDetailPage extends StatefulWidget {
  final Order order; // passed from list for instant display
  final bool isCoachProductOrder;

  const OrderDetailPage({
    super.key,
    required this.order,
    this.isCoachProductOrder = false,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Order _order;
  bool _isRefreshing = false;
  String? _fetchError;
  bool _hasTriggeredReviewPopup = false;
  Map<int, bool> _reviewCheckedStatus = {};
  Map<int, ReviewModel?> _existingReviews = {}; // Store existing reviews

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    setState(() {
      _isRefreshing = true;
      _fetchError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() {
          _fetchError = 'Authentication token missing';
          _isRefreshing = false;
        });
        return;
      }

      final detailUrl = widget.isCoachProductOrder
          ? '$api/api/myskates/coach/orders/detail/view/${widget.order.id}/'
          : '$api/api/myskates/orders/${widget.order.id}/';

      final response = await http.get(
        Uri.parse(detailUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("ORDER DETAIL API STATUS: ${response.statusCode}");
      print("ORDER DETAIL RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final orderJson = jsonResponse['data'] ?? jsonResponse;
        setState(() {
          _order = Order.fromJson(orderJson);
          _isRefreshing = false;
        });

        // After order is loaded, check reviews for all items
        if (!widget.isCoachProductOrder) {
          await _checkAllReviews();
          _checkAndShowReviewPopup();
        }
      } else {
        setState(() {
          _fetchError = 'Failed to load order: ${response.statusCode}';
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print("Error fetching order detail: $e");
      setState(() {
        _fetchError = e.toString();
        _isRefreshing = false;
      });
    }
  }

  // Check all products in the order for existing reviews
  Future<void> _checkAllReviews() async {
    for (var item in _order.items) {
      if (!_reviewCheckedStatus.containsKey(item.product)) {
        final review = await _getExistingReview(item.product);
        if (review != null) {
          _existingReviews[item.product] = review;
        }
        _reviewCheckedStatus[item.product] = true;
      }
    }
    setState(() {}); // Refresh to show/hide the review icon
  }

  // Get existing review for a product
  Future<ReviewModel?> _getExistingReview(int productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt('user_id') ?? prefs.getInt('id');

      if (token == null || userId == null) return null;

      final response = await http.get(
        Uri.parse('$api/api/myskates/products/$productId/ratings/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<dynamic> reviews = [];

        if (jsonData is List) {
          reviews = jsonData;
        } else if (jsonData is Map &&
            jsonData.containsKey('data') &&
            jsonData['data'] is List) {
          reviews = jsonData['data'];
        }

        // Find review by current user
        final userReview = reviews.firstWhere(
          (review) => (review['user'] ?? 0) == userId,
          orElse: () => null,
        );

        if (userReview != null) {
          return ReviewModel.fromJson(userReview);
        }
      }
    } catch (e) {
      print("Error getting existing review: $e");
    }
    return null;
  }

  // Check if user has existing review (for popup logic)
  Future<bool> _hasUserReviewed(int productId) async {
    return _existingReviews.containsKey(productId) &&
        _existingReviews[productId] != null;
  }

  // Check if ANY product in the order has a review
  bool get _hasAnyReview {
    return _existingReviews.values.any((review) => review != null);
  }

  // Get the first product that has a review (for navigation)
  OrderItem? _getFirstReviewedProduct() {
    for (var item in _order.items) {
      if (_existingReviews.containsKey(item.product) &&
          _existingReviews[item.product] != null) {
        return item;
      }
    }
    return null;
  }

  // Check and show review popup for items without review
  Future<void> _checkAndShowReviewPopup() async {
    // Only proceed if order is delivered and popup hasn't been triggered yet
    if (_order.status.toLowerCase() == 'delivered' &&
        !_hasTriggeredReviewPopup) {
      // Check each item in the order
      for (var item in _order.items) {
        final hasReview = await _hasUserReviewed(item.product);

        // If no review found for this product, show the popup
        if (!hasReview) {
          _hasTriggeredReviewPopup = true;
          _showReviewDialog(item);
          break; // Only show one popup at a time
        }
      }
    }
  }

  // Show review dialog
  void _showReviewDialog(OrderItem item) {
    // Add a small delay to ensure the page is fully loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return ReviewDialog(
              productId: item.product,
              productTitle: item.productTitle,
              variantId: item.variantId,
              variantLabel: item.variantLabel,
              productImage: item.productImage,
              variantImage: item.variantImage,
              hasReview: false,
            );
          },
        ).then((_) {
          // Refresh reviews after dialog closes (in case user wrote a review)
          _checkAllReviews();
          setState(() {});
        });
      }
    });
  }

  // Navigate to review screen for a specific product
  void _navigateToReviewScreen(OrderItem item, {ReviewModel? existingReview}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductReviewPage(
          productId: item.product,
          productTitle: item.productTitle,
          productImage: item.productImage,
          variantId: item.variantId,
          variantLabel: item.variantLabel,
          variantImage: item.variantImage,
        ),
      ),
    ).then((_) {
      // Refresh reviews after returning
      _checkAllReviews();
      setState(() {});
    });
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

  double _amount(String value) {
    return double.tryParse(value) ?? 0.0;
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

  Widget _pricingRow(
    String label,
    String amount, {
    bool isDiscount = false,
    bool isBold = false,
  }) {
    final color = isDiscount
        ? Colors.green
        : (isBold ? Colors.white : Colors.white70);
    final prefix = isDiscount ? '-₹' : '₹';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '$prefix${_amount(amount).toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _smallAmountBox({
    required String title,
    required String value,
    required IconData icon,
    Color valueColor = Colors.tealAccent,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _normalTextRow(
    String label,
    String value, {
    Color valueColor = Colors.white,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    double valueSize = 16,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.tealAccent, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(color: Colors.white, fontSize: valueSize),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRowMultiline({
    required IconData icon,
    required String label,
    required List<String> lines,
  }) {
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
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 2),
              ...lines.map(
                (line) => Text(
                  line,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A2B2A),
      highlightColor: const Color(0xFF2F4F4D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassWrap(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 180,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: 220,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _glassWrap(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 160,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 11,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 160,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
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
          const SizedBox(height: 16),
          _glassWrap(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 15,
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
                const SizedBox(height: 20),
                Container(height: 1, color: Colors.white),
                const SizedBox(height: 16),
                ...List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the first product that has a review for the icon navigation
    final reviewedProduct = _getFirstReviewedProduct();
    final hasReview = _hasAnyReview && reviewedProduct != null;

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
            onRefresh: _fetchOrderDetail,
            color: Colors.tealAccent,
            backgroundColor: Colors.black,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Review Icon
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 6),
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
                        // Review Icon - shows only if order is delivered and has review
                        if (_order.status.toLowerCase() == 'delivered' &&
                            hasReview &&
                            reviewedProduct != null)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                _navigateToReviewScreen(
                                  reviewedProduct,
                                  existingReview:
                                      _existingReviews[reviewedProduct.product],
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.tealAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.tealAccent.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.rate_review,
                                      color: Colors.tealAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Review',
                                      style: TextStyle(
                                        color: Colors.tealAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_isRefreshing)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.tealAccent,
                              strokeWidth: 2,
                            ),
                          ),
                        if (_fetchError != null && !_isRefreshing)
                          IconButton(
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.orangeAccent,
                              size: 20,
                            ),
                            tooltip: 'Retry',
                            onPressed: _fetchOrderDetail,
                          ),
                      ],
                    ),
                  ),

                  if (_fetchError != null && !_isRefreshing) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orangeAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Could not refresh order. Showing cached data.',
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  if (_isRefreshing && _order.items.isEmpty)
                    _buildDetailShimmer()
                  else ...[
                    // Order Summary
                    _glassWrap(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Order #${_order.orderNo}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
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
                                  color: _getStatusColor(
                                    _order.status,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: _getStatusColor(
                                      _order.status,
                                    ).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _order.status,
                                  style: TextStyle(
                                    color: _getStatusColor(_order.status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.tealAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ordered on: ${DateFormat('dd MMM yyyy, hh:mm a').format(_order.createdAt)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (_order.updatedAt != _order.createdAt) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.update_rounded,
                                  color: Colors.tealAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(_order.updatedAt)}',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Customer Information
                    _glassWrap(
                      padding: const EdgeInsets.all(20),
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
                          _infoRow(
                            icon: Icons.person_outline,
                            label: 'Name',
                            value: _order.fullName,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: _order.phone,
                          ),
                          const SizedBox(height: 12),
                          _infoRowMultiline(
                            icon: Icons.location_on_outlined,
                            label: 'Delivery Address',
                            lines: [
                              '${_order.addressLine1}${_order.addressLine2 != null ? ', ${_order.addressLine2}' : ''}',
                              '${_order.city}, ${_order.state} - ${_order.pincode}',
                              _order.country,
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Information
                    _glassWrap(
                      padding: const EdgeInsets.all(20),
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
                          _infoRow(
                            icon: _order.paymentMethod == 'COD'
                                ? Icons.money
                                : Icons.payment,
                            label: 'Payment Method',
                            value: _order.paymentMethod,
                          ),
                          if (_order.paymentRef != null) ...[
                            const SizedBox(height: 12),
                            _infoRow(
                              icon: Icons.receipt_outlined,
                              label: 'Payment Reference',
                              value: _order.paymentRef!,
                              valueSize: 14,
                            ),
                          ],
                          if (_order.note != null &&
                              _order.note!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _infoRow(
                              icon: Icons.note_outlined,
                              label: 'Order Note',
                              value: _order.note!,
                              valueSize: 14,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Order Items + Pricing
                    _glassWrap(
                      padding: const EdgeInsets.all(20),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_order.items.length} item${_order.items.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          ..._order.items
                              .map(
                                (item) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: _buildProductImage(item),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.productTitle,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (item
                                                    .variantLabel
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.tealAccent
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      item.variantLabel,
                                                      style: const TextStyle(
                                                        color:
                                                            Colors.tealAccent,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Qty: ${item.quantity}',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    if (widget
                                                        .isCoachProductOrder) ...[
                                                      const SizedBox(height: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 5,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .tealAccent
                                                              .withOpacity(
                                                                0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          border: Border.all(
                                                            color: Colors
                                                                .tealAccent
                                                                .withOpacity(
                                                                  0.25,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Seller Type: ${item.productUserType ?? '-'}',
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .tealAccent,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                            if (item.coachName !=
                                                                    null &&
                                                                item
                                                                    .coachName!
                                                                    .isNotEmpty) ...[
                                                              const SizedBox(
                                                                height: 3,
                                                              ),
                                                              Text(
                                                                'Coach: ${item.coachName}',
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ],
                                                            if (item.coachPhone !=
                                                                    null &&
                                                                item
                                                                    .coachPhone!
                                                                    .isNotEmpty) ...[
                                                              const SizedBox(
                                                                height: 3,
                                                              ),
                                                              Text(
                                                                'Phone: ${item.coachPhone}',
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                    Text(
                                                      '₹${double.parse(item.lineTotal).toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        color:
                                                            Colors.tealAccent,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // Show review badge for items that have a review
                                                if (_existingReviews
                                                        .containsKey(
                                                          item.product,
                                                        ) &&
                                                    _existingReviews[item
                                                            .product] !=
                                                        null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.green
                                                              .withOpacity(0.5),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.star,
                                                            color: Colors.amber,
                                                            size: 12,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            'Reviewed (${_existingReviews[item.product]!.rating}★)',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .green,
                                                                  fontSize: 10,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),

                          const Divider(color: Colors.white24, height: 24),

                          _pricingRow('Subtotal', _order.subtotal),
                          if (double.parse(_order.discountTotal) > 0) ...[
                            const SizedBox(height: 8),
                            _pricingRow(
                              'Discount',
                              _order.discountTotal,
                              isDiscount: true,
                            ),
                          ],
                          if (double.parse(_order.platformFee) > 0) ...[
                            const SizedBox(height: 8),
                            _pricingRow('Platform Fee', _order.platformFee),
                          ],
                          if (double.parse(_order.convenienceFee) > 0) ...[
                            const SizedBox(height: 8),
                            _pricingRow(
                              'Convenience Fee',
                              _order.convenienceFee,
                            ),
                          ],
                          if (_amount(_order.shipmentCharge) > 0) ...[
                            const SizedBox(height: 8),
                            _pricingRow(
                              'Shipment Charge',
                              _order.shipmentCharge,
                            ),
                          ],
                          if (double.parse(_order.couponDiscount) > 0) ...[
                            const SizedBox(height: 8),
                            _pricingRow(
                              _order.couponName != null
                                  ? 'Coupon (${_order.couponName})'
                                  : 'Coupon Discount',
                              _order.couponDiscount,
                              isDiscount: true,
                            ),
                          ],
                          const Divider(color: Colors.white24, height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${double.parse(_order.total).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          if (double.parse(_order.finalPayable) !=
                              double.parse(_order.total)) ...[
                            const SizedBox(height: 10),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    '₹${double.parse(_order.finalPayable).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.tealAccent,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.isCoachProductOrder &&
                                _order.sellerBreakdown.isNotEmpty) ...[
                              const SizedBox(height: 16),

                              _glassWrap(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Seller Payment Summary',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    ..._order.sellerBreakdown.map((seller) {
                                      final bank = seller.bankDetails;

                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.orangeAccent
                                              .withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: Colors.orangeAccent
                                                .withOpacity(0.25),
                                            width: 0.7,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Seller Header
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orangeAccent
                                                        .withOpacity(0.15),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.storefront_rounded,
                                                    color: Colors.orangeAccent,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        seller.coachName.isEmpty
                                                            ? 'Seller'
                                                            : seller.coachName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        seller
                                                                .coachPhone
                                                                .isEmpty
                                                            ? '-'
                                                            : seller.coachPhone,
                                                        style: const TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 14),

                                            // Seller Amount Summary
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _smallAmountBox(
                                                    title: 'Seller Total',
                                                    value:
                                                        '₹${_amount(seller.sellerTotal).toStringAsFixed(2)}',
                                                    icon: Icons
                                                        .receipt_long_outlined,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: _smallAmountBox(
                                                    title: 'Seller Payable',
                                                    value:
                                                        '₹${_amount(seller.sellerPayable).toStringAsFixed(2)}',
                                                    icon:
                                                        Icons.payments_outlined,
                                                    valueColor:
                                                        Colors.orangeAccent,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 14),

                                            // Product Items
                                            const Text(
                                              'Product Details',
                                              style: TextStyle(
                                                color: Colors.tealAccent,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            const SizedBox(height: 10),

                                            ...seller.items.map((item) {
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.18),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.08),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Product title
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .inventory_2_outlined,
                                                          color:
                                                              Colors.tealAccent,
                                                          size: 17,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            item
                                                                    .productTitle
                                                                    .isEmpty
                                                                ? 'Product'
                                                                : item.productTitle,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    const SizedBox(height: 12),

                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: _smallAmountBox(
                                                            title:
                                                                'Variant Price',
                                                            value:
                                                                '₹${_amount(item.variantPrice).toStringAsFixed(2)}',
                                                            icon: Icons
                                                                .sell_outlined,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Expanded(
                                                          child: _smallAmountBox(
                                                            title:
                                                                'Variant Discount',
                                                            value:
                                                                '₹${_amount(item.variantDiscount).toStringAsFixed(2)}',
                                                            icon: Icons
                                                                .discount_outlined,
                                                            valueColor: Colors
                                                                .greenAccent,
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    const SizedBox(height: 10),

                                                    _normalTextRow(
                                                      'Quantity',
                                                      item.quantity.toString(),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    _normalTextRow(
                                                      'Item Total',
                                                      '₹${_amount(item.itemTotal).toStringAsFixed(2)}',
                                                    ),
                                                    const SizedBox(height: 6),
                                                    _normalTextRow(
                                                      'Percentage Amount (${_order.productPercentage}%)',
                                                      '₹${_amount(item.percentageAmount).toStringAsFixed(2)}',
                                                    ),
                                                    const SizedBox(height: 6),
                                                    _normalTextRow(
                                                      'Item Seller Payable',
                                                      '₹${_amount(item.sellerPayable).toStringAsFixed(2)}',
                                                      valueColor:
                                                          Colors.orangeAccent,
                                                      isBold: true,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),

                                            const SizedBox(height: 12),

                                            // Bank Details inside same seller card
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.04,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.08),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Bank Details',
                                                    style: TextStyle(
                                                      color: Colors.tealAccent,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 12),

                                                  if (bank == null)
                                                    const Text(
                                                      'No bank details available',
                                                      style: TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 13,
                                                      ),
                                                    )
                                                  else ...[
                                                    _normalTextRow(
                                                      'Account Holder',
                                                      bank
                                                              .accountHolderName
                                                              .isEmpty
                                                          ? '-'
                                                          : bank.accountHolderName,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _normalTextRow(
                                                      'Bank Name',
                                                      bank.bankName.isEmpty
                                                          ? '-'
                                                          : bank.bankName,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _normalTextRow(
                                                      'Branch',
                                                      bank.branchName.isEmpty
                                                          ? '-'
                                                          : bank.branchName,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _normalTextRow(
                                                      'Account Number',
                                                      bank.accountNumber.isEmpty
                                                          ? '-'
                                                          : bank.accountNumber,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _normalTextRow(
                                                      'IFSC Code',
                                                      bank.ifscCode.isEmpty
                                                          ? '-'
                                                          : bank.ifscCode,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _normalTextRow(
                                                      'UPI ID',
                                                      bank.upiId.isEmpty
                                                          ? '-'
                                                          : bank.upiId,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    // if (widget.isCoachProductOrder &&
                    //  _order.sellerBreakdown.any(
                    //       (e) => e.bankDetails != null,
                    //     )) ...[
                    //   const SizedBox(height: 16),

                    //   _glassWrap(
                    //     padding: const EdgeInsets.all(20),
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         const Text(
                    //           'Seller Bank Details',
                    //           style: TextStyle(
                    //             color: Colors.white,
                    //             fontSize: 16,
                    //             fontWeight: FontWeight.bold,
                    //           ),
                    //         ),
                    //         const SizedBox(height: 16),

                    //         ..._order.sellerBreakdown
                    //             .where((seller) => seller.bankDetails != null)
                    //             .map((seller) {
                    //               final bank = seller.bankDetails!;
                    //               return Container(
                    //                 margin: const EdgeInsets.only(bottom: 14),
                    //                 padding: const EdgeInsets.all(14),
                    //                 decoration: BoxDecoration(
                    //                   color: Colors.white.withOpacity(0.04),
                    //                   borderRadius: BorderRadius.circular(14),
                    //                   border: Border.all(
                    //                     color: Colors.white.withOpacity(0.08),
                    //                   ),
                    //                 ),
                    //                 child: Column(
                    //                   children: [
                    //                     _infoRow(
                    //                       icon: Icons.person_outline,
                    //                       label: 'Coach Name',
                    //                       value: bank.coachName.isEmpty
                    //                           ? '-'
                    //                           : bank.coachName,
                    //                     ),
                    //                     const SizedBox(height: 12),
                    //                     _infoRow(
                    //                       icon: Icons.phone_outlined,
                    //                       label: 'Phone',
                    //                       value: bank.phone.isEmpty
                    //                           ? '-'
                    //                           : bank.phone,
                    //                     ),
                    //                     const SizedBox(height: 12),
                    //                     _infoRow(
                    //                       icon: Icons.account_circle_outlined,
                    //                       label: 'Account Holder Name',
                    //                       value: bank.accountHolderName.isEmpty
                    //                           ? '-'
                    //                           : bank.accountHolderName,
                    //                     ),
                    //                     const SizedBox(height: 12),
                    //                     _infoRow(
                    //                       icon: Icons.account_balance_outlined,
                    //                       label: 'Bank Name',
                    //                       value: bank.bankName.isEmpty
                    //                           ? '-'
                    //                           : bank.bankName,
                    //                     ),
                    //                     const SizedBox(height: 12),
                    //                     _infoRow(
                    //                       icon: Icons.location_city_outlined,
                    //                       label: 'Branch Name',
                    //                       value: bank.branchName.isEmpty
                    //                           ? '-'
                    //                           : bank.branchName,
                    //                     ),
                    //                     const SizedBox(height: 12),
                    //                     _infoRow(
                    //                       icon: Icons.numbers_outlined,
                    //                       label: 'Account Number',
                    //                       value: bank.accountNumber.isEmpty
                    //                           ? '-'
                    //                           : bank.accountNumber,
                    //                     ),
                    //                     const SizedBox(height: 12),
                    //                     _infoRow(
                    //                       icon: Icons
                    //                           .confirmation_number_outlined,
                    //                       label: 'IFSC Code',
                    //                       value: bank.ifscCode.isEmpty
                    //                           ? '-'
                    //                           : bank.ifscCode,
                    //                     ),
                    //                     const SizedBox(height: 12),
                    //                     _infoRow(
                    //                       icon: Icons.qr_code_2_outlined,
                    //                       label: 'UPI ID',
                    //                       value: bank.upiId.isEmpty
                    //                           ? '-'
                    //                           : bank.upiId,
                    //                     ),
                    //                   ],
                    //                 ),
                    //               );
                    //             })
                    //             .toList(),
                    //       ],
                    //     ),
                    //   ),
                    // ],
                  ],

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

// Review Dialog Widget (same as before)
class ReviewDialog extends StatelessWidget {
  final int productId;
  final String productTitle;
  final int variantId;
  final String variantLabel;
  final String? productImage;
  final String? variantImage;
  final bool hasReview;

  const ReviewDialog({
    Key? key,
    required this.productId,
    required this.productTitle,
    required this.variantId,
    required this.variantLabel,
    this.productImage,
    this.variantImage,
    this.hasReview = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2B28),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasReview ? Icons.edit : Icons.star_outline,
                color: Colors.amber,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasReview ? 'Update Your Review' : 'Write a Review',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              productTitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (variantLabel.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  variantLabel,
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              hasReview
                  ? 'You have already reviewed this product. Would you like to update your review?'
                  : 'Would you like to share your experience with this product?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                    ),
                    child: const Text(
                      'Maybe Later',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductReviewPage(
                            productId: productId,
                            productTitle: productTitle,
                            productImage: productImage,
                            variantId: variantId,
                            variantLabel: variantLabel,
                            variantImage: variantImage,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      hasReview ? 'Update Review' : 'Write a Review',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// lib/models/review_model.dart
class ReviewModel {
  final int id;
  final String productName;
  final String userFirstName;
  final String userLastName;
  final String? userProfile;
  final int rating;
  final String review;
  final String approvalStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int product;
  final int user;

  ReviewModel({
    required this.id,
    required this.productName,
    required this.userFirstName,
    required this.userLastName,
    this.userProfile,
    required this.rating,
    required this.review,
    required this.approvalStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
    required this.user,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      productName: json['product_name'],
      userFirstName: json['user_first_name'],
      userLastName: json['user_last_name'],
      userProfile: json['user_profile'],
      rating: json['rating'],
      review: json['review'],
      approvalStatus: json['approval_status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      product: json['product'],
      user: json['user'],
    );
  }
}

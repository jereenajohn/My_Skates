import 'package:flutter/material.dart';
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
  final String discountprice;
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
    required this.discountprice,
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
      discountprice: json['discounted_price']?.toString() ?? '0',
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

class BoughtProductItem {
  final int id;
  final int orderId;
  final String orderNo;
  final String orderStatus;
  final DateTime orderCreatedAt;
  final int product;
  final String productTitle;
  final String? productImage;
  final String? productUserType;
  final int variantId;
  final String variantLabel;
  final String? variantImage;
  final String? sku;
  final int quantity;
  final DateTime createdAt;

  BoughtProductItem({
    required this.id,
    required this.orderId,
    required this.orderNo,
    required this.orderStatus,
    required this.orderCreatedAt,
    required this.product,
    required this.productTitle,
    this.productImage,
    this.productUserType,
    required this.variantId,
    required this.variantLabel,
    this.variantImage,
    this.sku,
    required this.quantity,
    required this.createdAt,
  });

  factory BoughtProductItem.fromJson(Map<String, dynamic> json) {
    return BoughtProductItem(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      orderNo: json['order_no'] ?? '',
      orderStatus: json['order_status'] ?? '',
      orderCreatedAt:
          DateTime.tryParse(json['order_created_at'] ?? '') ?? DateTime.now(),
      product: json['product'] ?? 0,
      productTitle: json['product_title'] ?? '',
      productImage: json['product_image'],
      productUserType: json['product_user_type'],
      variantId: json['variant_id'] ?? 0,
      variantLabel: json['variant_label'] ?? '',
      variantImage: json['variant_image'],
      sku: json['sku'],
      quantity: json['quantity'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
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
      phone: json['phone']?.toString() ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      branchName: json['branch_name'] ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      upiId: json['upi_id'] ?? '',
    );
  }
}

class SellerBreakdownItem {
  final int itemId;
  final int productId;
  final String productTitle;
  final int quantity;
  final String variantPrice;
  final String variantDiscount;
  final String itemTotal;
  final String percentageAmount;
  final String sellerPayable;
  final String? productUserType;
  final String productShippingCharge;

  SellerBreakdownItem({
    required this.itemId,
    required this.productId,
    required this.productTitle,
    required this.quantity,
    required this.variantPrice,
    required this.variantDiscount,
    required this.itemTotal,
    required this.percentageAmount,
    required this.sellerPayable,
    required this.productShippingCharge,

    this.productUserType,
  });

  factory SellerBreakdownItem.fromJson(Map<String, dynamic> json) {
    return SellerBreakdownItem(
      itemId: json['item_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productTitle: json['product_title'] ?? '',
      quantity: json['quantity'] ?? 0,
      variantPrice: json['variant_price']?.toString() ?? '0',
      variantDiscount: json['variant_discount']?.toString() ?? '0',
      itemTotal: json['item_total']?.toString() ?? '0',
      percentageAmount: json['percentage_amount']?.toString() ?? '0',
      sellerPayable: json['seller_payable']?.toString() ?? '0',
      productShippingCharge: json['product_shipping_charge']?.toString() ?? '0',

      productUserType: json['product_user_type'],
    );
  }
}

class SellerBreakdown {
  final int coachId;
  final String coachName;
  final String coachPhone;
  final String sellerPercentageTotal;
  final String sellerTotal;
  final String sellerDiscountedTotal;
  final String sellerPayable;
  final String sellershipmenttotal;
  final String sellerpayableTotal;
  final SellerBankDetails? bankDetails;
  final List<SellerBreakdownItem> items;

  SellerBreakdown({
    required this.coachId,
    required this.coachName,
    required this.coachPhone,
    required this.sellerPercentageTotal,
    required this.sellerTotal,
    required this.sellerDiscountedTotal,
    required this.sellershipmenttotal,
    required this.sellerpayableTotal,
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
      sellerPercentageTotal: json['seller_percentage_total']?.toString() ?? '0',
      sellerTotal: json['seller_total']?.toString() ?? '0',
      sellerDiscountedTotal: json['seller_discounted_total']?.toString() ?? '0',
      sellerPayable: json['seller_payable']?.toString() ?? '0',
      sellershipmenttotal: json['seller_shipping_total']?.toString() ?? '0',
      sellerpayableTotal: json['seller_payable_total']?.toString() ?? '0',
      bankDetails: json['bank_details'] == null
          ? null
          : SellerBankDetails.fromJson(json['bank_details']),
      items: itemList.map((e) => SellerBreakdownItem.fromJson(e)).toList(),
    );
  }
}

class SellerPayableBreakdown {
  final String name;
  final String userType;
  final String sellerPayableTotal;

  SellerPayableBreakdown({
    required this.name,
    required this.userType,
    required this.sellerPayableTotal,
  });

  factory SellerPayableBreakdown.fromJson(Map<String, dynamic> json) {
    return SellerPayableBreakdown(
      name: json['name'] ?? '',
      userType: json['user_type'] ?? '',
      sellerPayableTotal: json['seller_payable_total']?.toString() ?? '0',
    );
  }
}

// Also update the Order class to include summary if needed
class OrderSummary {
  final String totalPercentageAmount;
  final String total;
  final String totalSellerPayable;
  final String totalProfit;
  final String platformFee;
  final String convenienceFee;
  final String totalProductShipping;
  final String finalPayable;
  final List<SellerPayableBreakdown> sellerPayableBreakdown;

  OrderSummary({
    required this.totalPercentageAmount,
    required this.total,
    required this.totalSellerPayable,
    required this.totalProfit,
    required this.platformFee,
    required this.convenienceFee,
    required this.totalProductShipping,
    required this.finalPayable,
    required this.sellerPayableBreakdown,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final breakdownList = json['seller_payable_breakdown'] as List? ?? [];
    return OrderSummary(
      totalPercentageAmount: json['total_percentage_amount']?.toString() ?? '0',
      total: json['total']?.toString() ?? '0',
      totalSellerPayable: json['total_seller_payable']?.toString() ?? '0',
      totalProfit: json['total_profit']?.toString() ?? '0',
      platformFee: json['platform_fee']?.toString() ?? '0',
      convenienceFee: json['convenience_fee']?.toString() ?? '0',
      totalProductShipping: json['total_product_shipping']?.toString() ?? '0',
      finalPayable: json['final_payable']?.toString() ?? '0',
      sellerPayableBreakdown: breakdownList
          .map((e) => SellerPayableBreakdown.fromJson(e))
          .toList(),
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
  final String discountprice;
  final String adjustedfinalpayable;
  final String total;
  final String platformFee;
  final String convenienceFee;
  final String shipmentcharge;
  final String couponDiscount;
  final String finalPayable;
  final String? couponName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? address;
  final int user;
  final String shipmentCharge;
  final String productPercentage;
  final OrderSummary? summary;
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
    required this.discountprice,
    required this.adjustedfinalpayable,
    required this.total,
    required this.platformFee,
    required this.convenienceFee,
    required this.shipmentcharge,
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
    this.summary,
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

    // ✅ Extract pricing from nested object, fallback to root
    final pricing = json['pricing'] as Map<String, dynamic>? ?? json;

    return Order(
      id: json['id'] ?? 0,
      items: orderItems,
      orderNo: json['order_no'] ?? '',
      status: json['status'] ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
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
      // ✅ Use pricing map for all financial fields
      subtotal: pricing['subtotal']?.toString() ?? '0',
      discountTotal: pricing['discount_total']?.toString() ?? '0',
      discountprice: pricing['discounted_price']?.toString() ?? '0',
      adjustedfinalpayable:
          pricing['adjusted_final_payable']?.toString() ?? '0',
      total: pricing['total']?.toString() ?? '0',
      platformFee: pricing['platform_fee']?.toString() ?? '0',
      convenienceFee: pricing['convenience_fee']?.toString() ?? '0',
      shipmentcharge: pricing['shipment_charge']?.toString() ?? '0',
      couponDiscount: pricing['coupon_discount']?.toString() ?? '0',
      finalPayable: pricing['final_payable']?.toString() ?? '0',
      couponName: json['coupon_name'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      address: json['address'],
      user: json['user'] ?? 0,
      shipmentCharge: pricing['shipment_charge']?.toString() ?? '0',
      productPercentage: pricing['product_percentage']?.toString() ?? '0',
      summary: json['summary'] != null
          ? OrderSummary.fromJson(json['summary'])
          : null,
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
  List<BoughtProductItem> boughtProducts = [];
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
        return '$api/api/myskates/orders/bought/products/';
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

        if (_selectedView == OrderViewType.myOrders) {
          final productList = jsonResponse['data'] as List? ?? [];

          setState(() {
            boughtProducts = productList
                .map((e) => BoughtProductItem.fromJson(e))
                .toList();

            orders = [];
            isLoading = false;
          });

          print(
            "Bought products fetched successfully: ${boughtProducts.length}",
          );
        } else {
          final orderResponse = OrderResponse.fromJson(jsonResponse);

          setState(() {
            orders = orderResponse.data;
            boughtProducts = [];
            isLoading = false;
          });

          print("Orders fetched successfully: ${orders.length} orders");
        }
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

  Future<void> _navigateToBoughtProductOrderDetail(
    BoughtProductItem item,
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      );

      final response = await http.get(
        Uri.parse('$api/api/myskates/orders/${item.orderId}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print("MY ORDER DETAIL STATUS: ${response.statusCode}");
      print("MY ORDER DETAIL BODY: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final orderJson = jsonResponse['data'] ?? jsonResponse;
        final order = Order.fromJson(orderJson);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailPage(order: order)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to open order detail: ${response.statusCode}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
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
                boughtProducts = [];
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
                  : (_selectedView == OrderViewType.myOrders
                        ? boughtProducts.isEmpty
                        : orders.isEmpty)
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
                                  _selectedView == OrderViewType.myOrders
                                      ? '${boughtProducts.length} product${boughtProducts.length == 1 ? '' : 's'} found'
                                      : '${orders.length} order${orders.length == 1 ? '' : 's'} found',
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
                          if (_selectedView == OrderViewType.myOrders)
                            ...boughtProducts
                                .map((item) => _buildBoughtProductCard(item))
                                .toList()
                          else
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
                                  // if (_selectedView ==
                                  //         OrderViewType.coachProductOrders &&
                                  //     item.productUserType == 'coach') ...[
                                  //   const SizedBox(height: 3),
                                  //   Text(
                                  //     'Coach Product',
                                  //     style: TextStyle(
                                  //       color: Colors.tealAccent.withOpacity(
                                  //         0.9,
                                  //       ),
                                  //       fontSize: 11,
                                  //       fontWeight: FontWeight.w500,
                                  //     ),
                                  //   ),
                                  // ],
                                ],
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () => _navigateToOrderDetail(order),
                            child: Text(
                              '₹${item.discountprice}',
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
                    '₹${double.parse(order.finalPayable).toStringAsFixed(2)}',
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

  Widget _buildBoughtProductCard(BoughtProductItem item) {
    return GestureDetector(
      onTap: () => _navigateToBoughtProductOrderDetail(item),
      child: Container(
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
                    child: Text(
                      'Order #${item.orderNo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
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
                      color: _getStatusColor(item.orderStatus).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor(
                          item.orderStatus,
                        ).withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      item.orderStatus,
                      style: TextStyle(
                        color: _getStatusColor(item.orderStatus),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildBoughtProductImage(item),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Qty: ${item.quantity}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),

                        if (item.productUserType != null &&
                            item.productUserType!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.productUserType == 'coach'
                                ? 'Coach Product'
                                : 'Admin Product',
                            style: TextStyle(
                              color: item.productUserType == 'coach'
                                  ? Colors.tealAccent
                                  : Colors.orangeAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        const SizedBox(height: 4),

                        Text(
                          DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(item.orderCreatedAt),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(color: Colors.white24, height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tap to view details',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),

                  GestureDetector(
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.tealAccent.withOpacity(0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            color: Colors.tealAccent,
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Review',
                            style: TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildBoughtProductImage(BoughtProductItem item) {
    final imagePath = item.variantImage ?? item.productImage;

    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.network(
        '$api$imagePath',
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.image_not_supported,
          color: Colors.white38,
          size: 24,
        ),
      );
    }

    return const Icon(
      Icons.image_not_supported,
      color: Colors.white38,
      size: 24,
    );
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
        if (orderJson['seller_breakdown'] != null) {
          print("SELLER BREAKDOWN DATA: ${orderJson['seller_breakdown']}");
        }
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

  Widget _pricingRow(String label, String value, {bool isDiscount = false}) {
    final amount = double.tryParse(value) ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 12),

        SizedBox(
          width: 110,
          child: Text(
            '${isDiscount ? '- ' : ''}₹${amount.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isDiscount ? Colors.redAccent : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemCard({required OrderItem item, required bool isLast}) {
    final itemPrice = double.tryParse(item.discountprice) ?? item.displayTotal;
    final hasSellerInfo =
        widget.isCoachProductOrder &&
        ((item.productUserType ?? '').isNotEmpty ||
            (item.coachName ?? '').isNotEmpty ||
            (item.coachPhone ?? '').isNotEmpty);

    return Column(
      children: [
        Padding(
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
                child: _buildProductImage(item),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productTitle.isEmpty
                          ? 'Unnamed Product'
                          : item.productTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),

                    if (item.variantLabel.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.variantLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.tealAccent.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _smallInfoChip(
                          icon: Icons.shopping_bag_outlined,
                          text: 'Qty ${item.quantity}',
                          color: Colors.white70,
                          backgroundColor: Colors.white.withOpacity(0.06),
                          borderColor: Colors.white.withOpacity(0.10),
                        ),

                        if ((item.productUserType ?? '').isNotEmpty)
                          _smallInfoChip(
                            icon: Icons.storefront_rounded,
                            text: item.productUserType!,
                            color: Colors.tealAccent,
                            backgroundColor: Colors.tealAccent.withOpacity(
                              0.10,
                            ),
                            borderColor: Colors.tealAccent.withOpacity(0.22),
                          ),
                      ],
                    ),

                    if (hasSellerInfo) ...[
                      const SizedBox(height: 8),
                      _compactSellerDetails(item),
                    ],

                    if (_existingReviews.containsKey(item.product) &&
                        _existingReviews[item.product] != null) ...[
                      const SizedBox(height: 8),
                      _smallInfoChip(
                        icon: Icons.star_rounded,
                        text:
                            'Reviewed ${_existingReviews[item.product]!.rating}★',
                        color: Colors.greenAccent,
                        backgroundColor: Colors.greenAccent.withOpacity(0.10),
                        borderColor: Colors.greenAccent.withOpacity(0.25),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              SizedBox(
                width: 86,
                child: Text(
                  '₹${itemPrice.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (!isLast)
          Divider(
            color: Colors.white.withOpacity(0.08),
            height: 1,
            thickness: 0.8,
          ),
      ],
    );
  }

  Widget _smallInfoChip({
    required IconData icon,
    required String text,
    required Color color,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactSellerDetails(OrderItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF021F1D).withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.tealAccent.withOpacity(0.18),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          if ((item.coachName ?? '').isNotEmpty)
            _sellerMiniRow(
              icon: Icons.person_outline_rounded,
              label: 'Coach',
              value: item.coachName!,
            ),

          if ((item.coachName ?? '').isNotEmpty &&
              (item.coachPhone ?? '').isNotEmpty)
            const SizedBox(height: 5),

          if ((item.coachPhone ?? '').isNotEmpty)
            _sellerMiniRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: item.coachPhone!,
            ),
        ],
      ),
    );
  }

  Widget _sellerMiniRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.tealAccent.withOpacity(0.9)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
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
                          ..._order.items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isLast = index == _order.items.length - 1;

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // PRODUCT IMAGE
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 58,
                                          height: 58,
                                          color: Colors.white.withOpacity(0.06),
                                          child: _buildProductImage(item),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // LEFT CONTENT
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productTitle,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                height: 1.25,
                                              ),
                                            ),

                                            if (item
                                                .variantLabel
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 5),
                                              Text(
                                                item.variantLabel,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.tealAccent,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],

                                            const SizedBox(height: 8),

                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.07),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.08),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Qty: ${item.quantity}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            if (widget.isCoachProductOrder) ...[
                                              const SizedBox(height: 8),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Seller Type: ${item.productUserType ?? '-'}',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign: TextAlign.left,
                                                      style: const TextStyle(
                                                        color:
                                                            Colors.tealAccent,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),

                                                    if (item.coachName !=
                                                            null &&
                                                        item
                                                            .coachName!
                                                            .isNotEmpty) ...[
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        'Coach: ${item.coachName}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.left,
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],

                                                    if (item.coachPhone !=
                                                            null &&
                                                        item
                                                            .coachPhone!
                                                            .isNotEmpty) ...[
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        'Phone: ${item.coachPhone}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.left,
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      // RIGHT PRICE COLUMN - FIXED WIDTH TO ALIGN WITH SUBTOTAL
                                      SizedBox(
                                        width: 82,
                                        child: Text(
                                          '₹${(double.tryParse(item.discountprice) ?? 0).toStringAsFixed(2)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            color: Colors.tealAccent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (_existingReviews.containsKey(
                                      item.product,
                                    ) &&
                                    _existingReviews[item.product] != null)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 70,
                                        bottom: 8,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Reviewed (${_existingReviews[item.product]!.rating}★)',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                if (!isLast)
                                  Divider(
                                    color: Colors.white.withOpacity(0.08),
                                    height: 1,
                                  ),
                              ],
                            );
                          }).toList(),

                          const Divider(color: Colors.white24, height: 24),

                          _pricingRow('Subtotal', _order.total),
                          if (double.parse(_order.discountTotal) > 0) ...[
                            const SizedBox(height: 5),
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
                          if (double.parse(_order.shipmentcharge) > 0) ...[
                            const SizedBox(height: 8),
                            _pricingRow(
                              'Shipment Charge',
                              _order.shipmentcharge,
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
                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.payments_outlined,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Seller payment summary',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              ..._order.sellerBreakdown.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final seller = entry.value;
                                final bank = seller.bankDetails;
                                final initials = seller.coachName.isNotEmpty
                                    ? seller.coachName
                                          .trim()
                                          .split(' ')
                                          .take(2)
                                          .map((w) => w[0].toUpperCase())
                                          .join()
                                    : 'S${index + 1}';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1F1D),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ── Seller header row ──
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: Colors.tealAccent
                                                  .withOpacity(0.15),
                                              child: Text(
                                                initials,
                                                style: const TextStyle(
                                                  color: Colors.tealAccent,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    seller.coachName.isEmpty
                                                        ? 'Seller ${index + 1}'
                                                        : seller.coachName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (seller
                                                      .coachPhone
                                                      .isNotEmpty)
                                                    Text(
                                                      seller.coachPhone,
                                                      style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  'net payable',
                                                  style: TextStyle(
                                                    color: Colors.white38,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${_amount(seller.sellerpayableTotal).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Colors.greenAccent,
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const Divider(
                                        color: Colors.white10,
                                        height: 1,
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          12,
                                          14,
                                          0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'ITEMS',
                                              style: TextStyle(
                                                color: Colors.white38,
                                                fontSize: 10,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            const SizedBox(height: 8),

                                            ...seller.items.asMap().entries.map((
                                              e,
                                            ) {
                                              final isLast =
                                                  e.key ==
                                                  seller.items.length - 1;
                                              final item = e.value;
                                              return Column(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8,
                                                        ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                item.productTitle,
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 2,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                              '₹${_amount(item.itemTotal).toStringAsFixed(2)}',
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Only show Product Charge if seller is NOT admin
                                                  if (!_isSellerAdmin(
                                                    seller,
                                                  )) ...[
                                                    _receiptRow(
                                                      'Product Charge (${_order.productPercentage}%)',
                                                      '− ₹${_amount(item.percentageAmount).toStringAsFixed(2)}',
                                                      valueColor:
                                                          Colors.redAccent,
                                                    ),
                                                    const SizedBox(height: 5),
                                                  ],
                                                  // Show Shipping Charge for all sellers (including admin)
                                                  _receiptRowWithIcon(
                                                    'Shipping Charge',
                                                    '+ ₹${_amount(item.productShippingCharge).toStringAsFixed(2)}',
                                                    icon: Icons.local_shipping,
                                                    valueColor: Colors.green,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  _receiptRow(
                                                    'Seller Payable',
                                                    '₹${_amount(item.sellerPayable).toStringAsFixed(2)}',
                                                    valueColor:
                                                        Colors.redAccent,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  if (!isLast &&
                                                      !_isSellerAdmin(seller))
                                                    const Divider(
                                                      color: Colors.white10,
                                                      height: 1,
                                                    ),
                                                  if (!isLast &&
                                                      _isSellerAdmin(seller))
                                                    const Divider(
                                                      color: Colors.white10,
                                                      height: 1,
                                                    ),
                                                ],
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          4,
                                          14,
                                          14,
                                        ),
                                        child: Column(
                                          children: [
                                            const Divider(
                                              color: Colors.white10,
                                              height: 20,
                                            ),
                                            _receiptRow(
                                              'Subtotal',
                                              '₹${_amount(seller.sellerDiscountedTotal).toStringAsFixed(2)}',
                                            ),
                                            // Only show Product Charge if seller is NOT admin
                                            if (!_isSellerAdmin(seller)) ...[
                                              _receiptRow(
                                                'Product Charge (${_order.productPercentage}%)',
                                                '− ₹${_amount(seller.sellerPercentageTotal).toStringAsFixed(2)}',
                                                valueColor: Colors.redAccent,
                                              ),
                                            ],
                                            _receiptRow(
                                              'Total Shipment',
                                              '+ ₹${_amount(seller.sellershipmenttotal).toStringAsFixed(2)}',
                                              valueColor: Colors.redAccent,
                                            ),
                                            const Divider(
                                              color: Colors.white10,
                                              height: 16,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Net payable',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${_amount(seller.sellerpayableTotal).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Colors.greenAccent,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (bank != null &&
                                          _hasAnyBankDetail(bank)) ...[
                                        Container(
                                          width: double.infinity,
                                          color: Colors.white.withOpacity(0.04),
                                          padding: const EdgeInsets.fromLTRB(
                                            14,
                                            12,
                                            14,
                                            14,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'BANK DETAILS',
                                                style: TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 10,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              if (bank
                                                  .accountHolderName
                                                  .isNotEmpty)
                                                _bankRow(
                                                  'Account holder',
                                                  bank.accountHolderName,
                                                ),
                                              if (bank.bankName.isNotEmpty)
                                                _bankRow('Bank', bank.bankName),
                                              if (bank.branchName.isNotEmpty)
                                                _bankRow(
                                                  'Branch',
                                                  bank.branchName,
                                                ),
                                              if (bank.accountNumber.isNotEmpty)
                                                _bankRow(
                                                  'Account no.',
                                                  bank.accountNumber,
                                                ),
                                              if (bank.ifscCode.isNotEmpty)
                                                _bankRow('IFSC', bank.ifscCode),
                                              if (bank.upiId.isNotEmpty)
                                                _bankRow('UPI', bank.upiId),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),

                              if (_order.summary != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1F1D),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withOpacity(
                                                0.15,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.bar_chart_rounded,
                                              color: Colors.amber,
                                              size: 15,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'ORDER TOTALS',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      const Divider(
                                        color: Colors.white10,
                                        height: 1,
                                      ),
                                      const SizedBox(height: 12),

<<<<<<< HEAD
                                      // Total
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Total',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '+ ₹${_amount(_order.summary!.finalPayable).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Product Percentage collected
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Product Percentage collected',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '+ ₹${_amount(_order.summary!.totalPercentageAmount).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Total payout to sellers
=======
>>>>>>> 27d2fc914d16820ac0cf503c812f8c7a64056e6f
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Colors.redAccent,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Total payout to sellers',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            ' - ₹${_amount(_order.summary!.totalSellerPayable).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

<<<<<<< HEAD
                                      // Seller Details Section
                                      if (_order
                                          .summary!
                                          .sellerPayableBreakdown
                                          .isNotEmpty) ...[
                                        const Divider(
                                          color: Colors.white10,
                                          height: 1,
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'SELLER BREAKDOWN',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 10,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ..._order
                                            .summary!
                                            .sellerPayableBreakdown
                                            .map(
                                              (seller) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 6,
                                                          height: 6,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                seller.userType ==
                                                                    'admin'
                                                                ? Colors.orange
                                                                : Colors
                                                                      .tealAccent,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          seller.name,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white70,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                seller.userType ==
                                                                    'admin'
                                                                ? Colors.orange
                                                                      .withOpacity(
                                                                        0.2,
                                                                      )
                                                                : Colors
                                                                      .tealAccent
                                                                      .withOpacity(
                                                                        0.2,
                                                                      ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            seller.userType,
                                                            style: TextStyle(
                                                              color:
                                                                  seller.userType ==
                                                                      'admin'
                                                                  ? Colors
                                                                        .orange
                                                                  : Colors
                                                                        .tealAccent,
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      '₹${_amount(seller.sellerPayableTotal).toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        const SizedBox(height: 8),
                                        const Divider(
                                          color: Colors.white10,
                                          height: 1,
                                        ),
                                        const SizedBox(height: 12),
                                      ],

                                      // Total profit
=======
>>>>>>> 27d2fc914d16820ac0cf503c812f8c7a64056e6f
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent.withOpacity(
                                            0.07,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.greenAccent
                                                .withOpacity(0.2),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total profit',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '₹${_amount(_order.summary!.totalProfit).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.greenAccent,
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
                              ],
                            ],
                          ],
                        ],
                      ),
                    ),
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

  Widget _receiptRowWithIcon(
    String label,
    String value, {
    required IconData icon,
    required Color valueColor,
    bool isPositive = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.tealAccent, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSellerAdmin(SellerBreakdown seller) {
    if (seller.items.isEmpty) return false;

    // Check if any item in this seller's breakdown belongs to an admin
    for (var sellerItem in seller.items) {
      // Find matching order item by product title

      try {
        final matchingOrderItem = _order.items.firstWhere(
          (orderItem) => orderItem.productTitle == sellerItem.productTitle,
        );

        final userType = matchingOrderItem.productUserType?.toLowerCase() ?? '';
        print(
          "Seller: ${seller.coachName}, Product: ${sellerItem.productTitle}, UserType: $userType",
        );
        if (userType == 'admin' || userType == 'sadmin') {
          return true;
        }
      } catch (e) {
        // No matching item found, continue to next seller item
        continue;
      }
    }

    return false;
  }

  Widget _receiptRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAnyBankDetail(SellerBankDetails bank) {
    return bank.accountHolderName.isNotEmpty ||
        bank.bankName.isNotEmpty ||
        bank.branchName.isNotEmpty ||
        bank.accountNumber.isNotEmpty ||
        bank.ifscCode.isNotEmpty ||
        bank.upiId.isNotEmpty;
  }
}

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

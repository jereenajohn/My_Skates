import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/admin_orders_page.dart';
import 'package:my_skates/ADMIN/invoice_webview_page.dart';
import 'package:my_skates/STUDENTS/student_product_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_skates/api.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Order Model Classes with images
class OrderItem {
  final int id;
  final int product;
  final String productTitle;
  final String? productImage;
  final int variantId;
  final String? sku;
  final String status;
  final String variantLabel;
  final String? coachName;
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
    this.coachName,
    required this.variantId,
    this.sku,
    required this.variantLabel,
    this.variantImage,
    required this.unitPrice,
    required this.unitDiscount,
    required this.quantity,
    required this.lineTotal,
    required this.createdAt,
    required this.status,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      product: json['product'] ?? 0,
      productTitle: json['product_title']?.toString() ?? '',
      productImage: json['product_image']?.toString(),
      variantId: json['variant_id'] ?? 0,
      coachName: json['coach_name']?.toString(),
      sku: json['sku']?.toString(),
      variantLabel: json['variant_label']?.toString() ?? '',
      variantImage: json['variant_image']?.toString(),
      unitPrice: json['unit_price']?.toString() ?? '0',
      unitDiscount: json['unit_discount']?.toString() ?? '0',
      quantity: json['quantity'] ?? 0,
      lineTotal: json['line_total']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
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
  final String platformFee;
  final String convenienceFee;
  final String shipmentCharge;
  final String finalPayable;
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
    required this.platformFee,
    required this.convenienceFee,
    required this.shipmentCharge,
    required this.finalPayable,
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
      platformFee: json['platform_fee']?.toString() ?? '0',
      convenienceFee: json['convenience_fee']?.toString() ?? '0',
      shipmentCharge: json['shipment_charge']?.toString() ?? '0',
      finalPayable:
          json['final_payable']?.toString() ?? json['total']?.toString() ?? '0',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      address: json['address']?.toString(),
      user: json['user'] ?? 0,
    );
  }
}

class OrderResponse {
  final bool success;
  final int count;
  final String? next;
  final String? previous;
  final List<Order> data;

  OrderResponse({
    required this.success,
    required this.count,
    required this.next,
    required this.previous,
    required this.data,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    final dynamic resultsNode = json['results'];

    bool success = true;
    int count = 0;
    String? next = json['next']?.toString();
    String? previous = json['previous']?.toString();
    List<dynamic> ordersList = [];

    if (resultsNode is Map<String, dynamic>) {
      success = resultsNode['success'] == true;
      count = resultsNode['count'] ?? json['count'] ?? 0;
      ordersList = resultsNode['data'] as List? ?? [];
    } else {
      success = json['success'] ?? true;
      count = json['count'] ?? 0;
      ordersList = json['data'] as List? ?? [];
    }

    final List<Order> orders = ordersList
        .whereType<Map<String, dynamic>>()
        .map((item) => Order.fromJson(item))
        .toList();

    return OrderResponse(
      success: success,
      count: count,
      next: next,
      previous: previous,
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
  bool isLoadingMore = false;
  String? error;

  int _currentPage = 1;
  int _totalOrdersCount = 0;
  bool _hasNextPage = false;

  final ScrollController _ordersScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _searchText = '';
  String _selectedSortFilter = 'latest';
  DateTimeRange? _selectedDateRange;
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

    _ordersScrollController.addListener(_onOrdersScroll);
    fetchOrders(reset: true);
  }

  @override
  void dispose() {
    _ordersScrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _searchText = value.trim();
      fetchOrders(reset: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchText = '';
    fetchOrders(reset: true);
  }

  void _onOrdersScroll() {
    if (!_ordersScrollController.hasClients) return;

    final position = _ordersScrollController.position;

    if (position.pixels >= position.maxScrollExtent - 250) {
      if (_hasNextPage && !isLoadingMore && !isLoading) {
        fetchOrders();
      }
    }
  }

  Future<void> _clearDateFilter() async {
  setState(() {
    _selectedDateRange = null;
  });

  await fetchOrders(reset: true);
}

  List<Order> get _filteredOrders {
    return orders;
  }

  Future<void> fetchOrders({bool reset = false}) async {
    if (reset) {
      setState(() {
        isLoading = true;
        isLoadingMore = false;
        error = null;
        _currentPage = 1;
        _hasNextPage = false;
        orders = [];
      });
    } else {
      if (isLoadingMore || !_hasNextPage) return;

      setState(() {
        isLoadingMore = true;
        error = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() {
          error = 'Authentication token missing';
          isLoading = false;
          isLoadingMore = false;
        });
        return;
      }

      final Map<String, String> queryParams = {'page': _currentPage.toString()};

      if (_searchText.trim().isNotEmpty) {
        queryParams['search'] = _searchText.trim();
      }
      if (_selectedDateRange != null) {
        queryParams['start_date'] = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDateRange!.start);

        queryParams['end_date'] = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDateRange!.end);
      }
      if (_selectedStatusFilter != 'ALL') {
        queryParams['status'] = _selectedStatusFilter;
      }

      if (_selectedSortFilter == 'latest') {
        queryParams['ordering'] = '-created_at';
      } else if (_selectedSortFilter == 'earliest') {
        queryParams['ordering'] = 'created_at';
      }

      final uri = Uri.parse(
        '$api/api/myskates/orders/',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("ORDERS API URL: $uri");
      print("ORDERS API STATUS: ${response.statusCode}");
      print("ORDERS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final orderResponse = OrderResponse.fromJson(jsonResponse);

        setState(() {
          if (reset) {
            orders = orderResponse.data;
          } else {
            orders.addAll(orderResponse.data);
          }

          _totalOrdersCount = orderResponse.count;
          _hasNextPage =
              orderResponse.next != null && orderResponse.next!.isNotEmpty;

          if (_hasNextPage) {
            _currentPage++;
          }

          isLoading = false;
          isLoadingMore = false;
        });

        print("Orders loaded: ${orders.length} / $_totalOrdersCount");
      } else {
        setState(() {
          error = 'Failed to load orders: ${response.statusCode}';
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      print("Error fetching orders: $e");

      setState(() {
        error = e.toString();
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

 Future<void> _openDateRangePicker() async {
  final now = DateTime.now();

  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime(now.year + 2),
    initialDateRange: _selectedDateRange,
    saveText: 'Apply',
    cancelText: 'Cancel',
    builder: (context, child) {
      return Theme(
        data: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF001A18),
          dialogBackgroundColor: const Color(0xFF071412),
          canvasColor: const Color(0xFF071412),
          cardColor: const Color(0xFF071412),

          colorScheme: const ColorScheme(
            brightness: Brightness.dark,
            primary: Color(0xFF00F5D4),
            onPrimary: Colors.black,
            secondary: Color(0xFF00F5D4),
            onSecondary: Colors.black,
            error: Colors.redAccent,
            onError: Colors.white,
            surface: Color(0xFF071412),
            onSurface: Colors.white,
          ),

          textTheme: const TextTheme(
            displayLarge: TextStyle(color: Colors.white),
            displayMedium: TextStyle(color: Colors.white),
            displaySmall: TextStyle(color: Colors.white),
            headlineLarge: TextStyle(color: Colors.white),
            headlineMedium: TextStyle(color: Colors.white),
            headlineSmall: TextStyle(color: Colors.white),
            titleLarge: TextStyle(color: Colors.white),
            titleMedium: TextStyle(color: Colors.white),
            titleSmall: TextStyle(color: Colors.white),
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
            bodySmall: TextStyle(color: Colors.white),
            labelLarge: TextStyle(color: Colors.white),
            labelMedium: TextStyle(color: Colors.white),
            labelSmall: TextStyle(color: Colors.white),
          ),

          datePickerTheme: DatePickerThemeData(
            backgroundColor: const Color(0xFF071412),
            surfaceTintColor: Colors.transparent,

            headerBackgroundColor: const Color(0xFF001A18),
            headerForegroundColor: Colors.white,

            rangePickerBackgroundColor: const Color(0xFF071412),
            rangePickerHeaderBackgroundColor: const Color(0xFF001A18),
            rangePickerHeaderForegroundColor: Colors.white,

            dividerColor: Colors.white70,

            weekdayStyle: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),

            dayStyle: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),

            yearStyle: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),

            dayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.disabled)) {
                  return Colors.white54;
                }

                return Colors.white;
              },
            ),

            dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF00F5D4);
                }

                return Colors.transparent;
              },
            ),

            todayForegroundColor: WidgetStateProperty.all<Color>(
              Colors.white,
            ),

            todayBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF00F5D4);
                }

                return Colors.transparent;
              },
            ),

            todayBorder: const BorderSide(
              color: Color(0xFF00F5D4),
              width: 1.6,
            ),

            rangeSelectionBackgroundColor:
                const Color(0xFF00F5D4).withOpacity(0.28),

            rangeSelectionOverlayColor: WidgetStateProperty.all<Color?>(
              const Color(0xFF00F5D4).withOpacity(0.16),
            ),

            yearForegroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.disabled)) {
                  return Colors.white54;
                }

                return Colors.white;
              },
            ),

            yearBackgroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF00F5D4);
                }

                return Colors.transparent;
              },
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),

          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00F5D4),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          iconTheme: const IconThemeData(color: Colors.white),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );

  if (picked == null) return;

  setState(() {
    _selectedDateRange = picked;
  });

  await fetchOrders(reset: true);
}


  Future<void> _refreshOrders() async {
    await fetchOrders(reset: true);
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

  Future<void> _navigateToOrderDetail(
    Order order,
    OrderItem selectedItem,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OrderDetailPage(order: order, selectedItemId: selectedItem.id),
      ),
    );

  if (result == true) {
  await fetchOrders(reset: true);
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

  Widget _buildSearchBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.tealAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search by product name',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchController.text.trim().isNotEmpty)
            IconButton(
              onPressed: _clearSearch,
              icon: const Icon(Icons.close_rounded, color: Colors.white54),
            ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip() {
    if (_selectedDateRange == null) {
      return const SizedBox.shrink();
    }

    final start = DateFormat('dd MMM yyyy').format(_selectedDateRange!.start);
    final end = DateFormat('dd MMM yyyy').format(_selectedDateRange!.end);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.tealAccent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.date_range_rounded,
            color: Colors.tealAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$start to $end',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: _clearDateFilter,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBox() {
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
          value: _selectedSortFilter,
          isExpanded: true,
          dropdownColor: const Color(0xFF161616),
          icon: const Icon(Icons.sort_rounded, color: Colors.tealAccent),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (String? value) {
            if (value == null) return;

            setState(() {
              _selectedSortFilter = value;
            });

            fetchOrders(reset: true);
          },
          items: const [
            DropdownMenuItem<String>(
              value: 'latest',
              child: Text(
                'Latest first',
                style: TextStyle(color: Colors.white),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'earliest',
              child: Text(
                'Earliest first',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    // Return a list of widgets for each product in the order
    return Column(
      children: order.items
          .map((item) => _buildProductItemCard(order, item))
          .toList(),
    );
  }

  Widget _buildProductItemCard(Order order, OrderItem item) {
    return GestureDetector(
      onTap: () => _navigateToOrderDetail(order, item),
      child: Container(
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
                    color: _getStatusColor(item.status).withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(item.status).withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      color: _getStatusColor(item.status),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
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
              ],
            ),
          ],
        ),
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
          icon: const Icon(Icons.filter_list_rounded, color: Colors.tealAccent),
          dropdownColor: const Color(0xFF161616),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          hint: const Text(
            'Filter by Status',
            style: TextStyle(color: Colors.white54),
          ),
          onChanged: (String? newValue) {
            if (newValue == null) return;

            setState(() {
              _selectedStatusFilter = newValue;
            });

            fetchOrders(reset: true);
          },
          items: [
            const DropdownMenuItem<String>(
              value: 'ALL',
              child: Row(
                children: [
                  Icon(Icons.apps_rounded, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text('All Orders', style: TextStyle(color: Colors.white)),
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
            }).toList(),
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
            '${orders.length} of $_totalOrdersCount orders loaded',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (_selectedStatusFilter != 'ALL') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  Widget _buildFilteredOrderCard(Order order) {
    final visibleItems = _selectedStatusFilter == 'ALL'
        ? order.items
        : order.items
              .where(
                (item) => item.status.toUpperCase() == _selectedStatusFilter,
              )
              .toList();

    return Column(
      children: visibleItems
          .map((item) => _buildProductItemCard(order, item))
          .toList(),
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
        actions: [
          IconButton(
            tooltip: 'Filter by date',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
              Icon(
  Icons.calendar_month_outlined,
  color: _selectedDateRange == null
      ? Colors.white
      : const Color(0xFF00F5D4),
),
                if (_selectedDateRange != null)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.tealAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openDateRangePicker,
          ),
          const SizedBox(width: 8),
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
  child: RefreshIndicator(
    onRefresh: _refreshOrders,
    color: Colors.tealAccent,
    backgroundColor: Colors.black,
    child: isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Colors.tealAccent),
          )
        : error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.22),
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
                  Center(
                    child: ElevatedButton(
                      onPressed: () => fetchOrders(reset: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              )
            : CustomScrollView(
                controller: _ordersScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildSearchBox(),
                          _buildDateFilterChip(),
                          _buildFilterBox(),
                          // _buildSortBox(),
                          // _buildTopInfo(),
                        ],
                      ),
                    ),
                  ),

                  if (orders.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
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
                              Text(
                                _searchText.isNotEmpty ||
                                        _selectedStatusFilter != 'ALL' ||
                                        _selectedDateRange != null
                                    ? 'Try changing your search or filters'
                                    : 'Your orders will appear here',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == orders.length) {
                              return isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.tealAccent,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(height: 20);
                            }

                            return _buildFilteredOrderCard(orders[index]);
                          },
                          childCount: orders.length + 1,
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

class ExchangeVariant {
  final int id;
  final String label;
  final String? image;
  final String? productTitle;
  final String? productImage;
  final String? sku;
  final String? variantPrice;
  final String? discountedPrice;
  final String? variantDiscount;
  final String? shippingCharge;
  final String? coachName;

  ExchangeVariant({
    required this.id,
    required this.label,
    this.image,
    this.productTitle,
    this.productImage,
    this.sku,
    this.variantPrice,
    this.discountedPrice,
    this.variantDiscount,
    this.shippingCharge,
    this.coachName,
  });

  factory ExchangeVariant.fromJson(Map<String, dynamic> json) {
    final int parsedId =
        json['id'] ?? json['variant_id'] ?? json['variant'] ?? 0;

    final String parsedLabel =
        json['variant_label']?.toString().trim().isNotEmpty == true
        ? json['variant_label'].toString()
        : json['label']?.toString().trim().isNotEmpty == true
        ? json['label'].toString()
        : json['name']?.toString().trim().isNotEmpty == true
        ? json['name'].toString()
        : json['variant_name']?.toString().trim().isNotEmpty == true
        ? json['variant_name'].toString()
        : 'Variant #$parsedId';

    return ExchangeVariant(
      id: parsedId,
      label: parsedLabel,
      image: json['variant_image']?.toString() ?? json['image']?.toString(),
      productTitle: json['product_title']?.toString(),
      productImage: json['product_image']?.toString(),
      sku: json['sku']?.toString(),
      variantPrice:
          json['variant_price']?.toString() ??
          json['price']?.toString() ??
          json['product_price']?.toString(),
      discountedPrice: json['discounted_price']?.toString(),
      variantDiscount: json['variant_discount']?.toString(),
      shippingCharge:
          json['product_shipping_charge']?.toString() ??
          json['shipping_charge']?.toString(),
      coachName: json['coach_name']?.toString(),
    );
  }
}

// ==================== ORDER DETAIL PAGE ====================

class OrderDetailPage extends StatefulWidget {
  final Order order;
  final int? selectedItemId;

  const OrderDetailPage({super.key, required this.order, this.selectedItemId});

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
  List<ExchangeVariant> _exchangeVariants = [];
  ExchangeVariant? _selectedExchangeVariant;
  bool _isLoadingExchangeVariants = false;
  String? _exchangeVariantErrorMessage;
  OrderItem? _selectedCancelItem;
  String? _selectedRefundRemark;
  String? _selectedReasonType;
  String? _returnExchangeErrorMessage;
  late String _liveOrderStatus;
  bool _orderStatusChanged = false;
  final Map<int, String> _liveItemStatuses = {};

  final List<Map<String, String>> _refundRemarkOptions = [
    {'value': 'return', 'label': 'Return'},
    // {'value': 'refund', 'label': 'Refund'},
    {'value': 'exchange', 'label': 'Exchange'},
    {'value': 'cod_return', 'label': 'COD Return'},
  ];

  final List<Map<String, String>> _refundReasonTypeOptions = [
    {'value': 'defective', 'label': 'Defective Product'},
    {'value': 'wrong_item', 'label': 'Wrong Item Delivered'},
    {'value': 'no_longer_needed', 'label': 'No Longer Needed'},
    {'value': 'other', 'label': 'Other'},
  ];

  bool get _isCashOnDeliveryOrder {
    final method = widget.order.paymentMethod.trim().toUpperCase();
    return method == 'COD' ||
        method == 'CASH ON DELIVERY' ||
        method == 'CASH_ON_DELIVERY';
  }

  List<Map<String, String>> get _availableRefundRemarkOptions {
    if (_isCashOnDeliveryOrder) {
      return _refundRemarkOptions
          .where((option) => option['value'] != 'return')
          .toList();
    }

    return _refundRemarkOptions
        .where((option) => option['value'] != 'cod_return')
        .toList();
  }

  double _toDouble(String? value) {
    return double.tryParse(value ?? '0') ?? 0.0;
  }

  @override
  void initState() {
    super.initState();

    _liveOrderStatus = widget.order.status;

    for (final item in widget.order.items) {
      _liveItemStatuses[item.id] = item.status;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowReviewPopup();
    });
  }

  String _getLiveItemStatus(OrderItem item) {
    return _liveItemStatuses[item.id] ?? item.status;
  }

  OrderItem get _openedItem {
    if (widget.selectedItemId == null) {
      return widget.order.items.first;
    }

    return widget.order.items.firstWhere(
      (item) => item.id == widget.selectedItemId,
      orElse: () => widget.order.items.first,
    );
  }

  List<OrderItem> get _otherItemsInOrder {
    return widget.order.items
        .where((item) => item.id != _openedItem.id)
        .toList();
  }

  Future<void> _maybeShowReviewPopup() async {
    if (!mounted) return;
    if (_reviewPopupCheckedOnce) return;
    _reviewPopupCheckedOnce = true;

    final status = _liveOrderStatus.toUpperCase();
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

  Widget _buildOrderDetailItemCard(OrderItem item) {
    return InkWell(
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
          await Future.delayed(const Duration(milliseconds: 150));
          await _maybeShowReviewPopup();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
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
                        color: Colors.tealAccent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        _getLiveItemStatus(item),
                      ).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(
                          _getLiveItemStatus(item),
                        ).withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      _getLiveItemStatus(item),
                      style: TextStyle(
                        color: _getStatusColor(_getLiveItemStatus(item)),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (item.coachName != null &&
                      item.coachName!.trim().isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Seller: ${item.coachName}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    'Qty: ${item.quantity}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    return _getLiveItemStatus(_openedItem).toUpperCase() == 'DELIVERED';
  }

  bool get _canCancelOrderItem {
    return _getLiveItemStatus(_openedItem).toUpperCase() == 'PLACED';
  }

  void _resetCancelOrderForm() {
    _selectedCancelItem = _canCancelOrderItem ? _openedItem : null;
    _isCancellingOrderItem = false;
  }

  Future<void> _confirmAndSubmitCancelOrderItem(
    StateSetter bottomSheetSetState,
  ) async {
    if (_selectedCancelItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product to cancel')),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Confirm Cancellation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to cancel this product?\n\n${_selectedCancelItem!.productTitle}${_selectedCancelItem!.variantLabel.isNotEmpty ? '\n${_selectedCancelItem!.variantLabel}' : ''}\n\nThis action cannot be undone.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'No, Go Back',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _patchCancelOrderItemStatus(bottomSheetSetState);
    }
  }

  Future<void> _patchCancelOrderItemStatus(
    StateSetter bottomSheetSetState,
  ) async {
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

      final Map<String, dynamic> requestBody = {"status": "CANCELLED"};

      final response = await http.patch(
        Uri.parse(
          '$api/api/myskates/order/item/status/update/${_selectedCancelItem!.id}/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print("PATCH CANCEL ITEM STATUS API: ${response.statusCode}");
      print("PATCH CANCEL ITEM ID: ${_selectedCancelItem!.id}");
      print("PATCH CANCEL PRODUCT ID: ${_selectedCancelItem!.product}");
      print("PATCH CANCEL REQUEST BODY: ${jsonEncode(requestBody)}");
      print("PATCH CANCEL RESPONSE: ${response.body}");

      Map<String, dynamic>? decoded;

      try {
        final dynamic parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        }
      } catch (_) {
        decoded = null;
      }

      final String responseMessage =
          decoded?['message']?.toString() ??
          decoded?['error']?.toString() ??
          decoded?['detail']?.toString() ??
          '';

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        setState(() {
          _liveItemStatuses[_selectedCancelItem!.id] = "CANCELLED";
          _orderStatusChanged = true;
        });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseMessage.isNotEmpty
                  ? responseMessage
                  : 'Product cancelled successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseMessage.isNotEmpty
                  ? responseMessage
                  : 'Failed to cancel product',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print("PATCH CANCEL ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        bottomSheetSetState(() {
          _isCancellingOrderItem = false;
        });
      }
    }
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
            errorMessage =
                decoded['message']?.toString() ??
                decoded['error']?.toString() ??
                decoded['detail']?.toString() ??
                errorMessage;
          }
        } catch (_) {}

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      print("ERROR CANCELLING ORDER ITEM: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

    if (!_canCancelOrderItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product cannot be cancelled'),
          backgroundColor: Colors.redAccent,
        ),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                              onChanged: null,
                              items: [_openedItem].map((item) {
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
                                : () => _confirmAndSubmitCancelOrderItem(
                                    bottomSheetSetState,
                                  ),
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
                              disabledBackgroundColor: Colors.redAccent
                                  .withOpacity(0.35),
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
    _selectedReturnItem = _canRequestReturnExchange ? _openedItem : null;
    _selectedRefundRemark = null;
    _selectedReasonType = null;
    _selectedExchangeVariant = null;
    _exchangeVariants = [];
    _exchangeVariantErrorMessage = null;
    _customReasonController.clear();
    _isSubmittingReturnExchange = false;
    _isLoadingExchangeVariants = false;
    _returnExchangeErrorMessage = null;
  }

  Future<void> _fetchExchangeVariants({
    required OrderItem item,
    required StateSetter bottomSheetSetState,
  }) async {
    bottomSheetSetState(() {
      _isLoadingExchangeVariants = true;
      _exchangeVariantErrorMessage = null;
      _exchangeVariants = [];
      _selectedExchangeVariant = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        bottomSheetSetState(() {
          _isLoadingExchangeVariants = false;
          _exchangeVariantErrorMessage = 'Authentication token missing';
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
          '$api/api/myskates/products/exchange/variant/${item.product}/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("EXCHANGE VARIANT API STATUS: ${response.statusCode}");
      print("EXCHANGE VARIANT PRODUCT ID: ${item.product}");
      print("EXCHANGE VARIANT RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        List<dynamic> variantList = [];

        if (decoded is List) {
          variantList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) {
            variantList = decoded['data'];
          } else if (decoded['results'] is List) {
            variantList = decoded['results'];
          } else if (decoded['variants'] is List) {
            variantList = decoded['variants'];
          }
        }

        final variants = variantList
            .whereType<Map<String, dynamic>>()
            .map((e) => ExchangeVariant.fromJson(e))
            .where((variant) => variant.id != 0)
            .toList();

        bottomSheetSetState(() {
          _exchangeVariants = variants;
          _selectedExchangeVariant = variants.isNotEmpty
              ? variants.first
              : null;
          _isLoadingExchangeVariants = false;
          _exchangeVariantErrorMessage = variants.isEmpty
              ? 'No exchange variants available for this product'
              : null;
        });
      } else {
        String errorMessage = 'Failed to load exchange variants';

        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            errorMessage =
                decoded['message']?.toString() ??
                decoded['error']?.toString() ??
                decoded['detail']?.toString() ??
                errorMessage;
          }
        } catch (_) {}

        bottomSheetSetState(() {
          _isLoadingExchangeVariants = false;
          _exchangeVariantErrorMessage = errorMessage;
        });
      }
    } catch (e) {
      print("ERROR FETCHING EXCHANGE VARIANTS: $e");

      bottomSheetSetState(() {
        _isLoadingExchangeVariants = false;
        _exchangeVariantErrorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _submitReturnExchangeRequest(
    StateSetter bottomSheetSetState,
  ) async {
    if (_selectedReturnItem == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }

    if (_selectedRefundRemark == null || _selectedRefundRemark!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select return/exchange type')),
      );
      return;
    }
    if (_isCashOnDeliveryOrder && _selectedRefundRemark == 'return') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Return option is not available for Cash on Delivery orders',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_selectedReasonType == null || _selectedReasonType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select reason type')),
      );
      return;
    }

    if (_selectedRefundRemark == 'exchange' &&
        _selectedExchangeVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select exchange variant'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final customReason = _customReasonController.text.trim();

    if (_selectedReasonType == 'other' && customReason.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter reason')));
      return;
    }

    bottomSheetSetState(() {
      _isSubmittingReturnExchange = true;
      _returnExchangeErrorMessage = null;
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

      if (_selectedRefundRemark == 'exchange' &&
          _selectedExchangeVariant != null) {
        requestBody['exchange_variant'] = _selectedExchangeVariant!.id;
      }

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
          apiStatus) {
        if (!mounted) return;

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseMessage.isNotEmpty
                  ? responseMessage
                  : 'Return/Exchange request submitted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;

        bottomSheetSetState(() {
          _returnExchangeErrorMessage = responseMessage;
        });
      }
    } catch (e) {
      print("ERROR SUBMITTING RETURN EXCHANGE REQUEST: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        bottomSheetSetState(() {
          _isSubmittingReturnExchange = false;
        });
      }
    }
  }

  String _resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) return '';

    final trimmed = imagePath.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    return '$api$trimmed';
  }

  Widget _buildExchangeVariantImage(
    ExchangeVariant variant, {
    OrderItem? fallbackItem,
  }) {
    final String imagePath =
        variant.image ??
        variant.productImage ??
        fallbackItem?.variantImage ??
        fallbackItem?.productImage ??
        '';

    final String imageUrl = _resolveImageUrl(imagePath);

    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.white.withOpacity(0.05),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white38,
          size: 24,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.white.withOpacity(0.05),
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white38,
            size: 24,
          ),
        );
      },
    );
  }

  Widget _buildExchangeVariantDropdownItem(
    ExchangeVariant variant, {
    OrderItem? fallbackItem,
    bool compact = false,
  }) {
    final String title = variant.productTitle?.trim().isNotEmpty == true
        ? variant.productTitle!.trim()
        : fallbackItem?.productTitle ?? 'Product';

    final String priceText = variant.discountedPrice?.trim().isNotEmpty == true
        ? '₹${_toDouble(variant.discountedPrice).toStringAsFixed(2)}'
        : variant.variantPrice?.trim().isNotEmpty == true
        ? '₹${_toDouble(variant.variantPrice).toStringAsFixed(2)}'
        : '';

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 8 : 12),
          child: SizedBox(
            width: compact ? 42 : 58,
            height: compact ? 42 : 58,
            child: _buildExchangeVariantImage(
              variant,
              fallbackItem: fallbackItem,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                variant.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (variant.sku != null && variant.sku!.trim().isNotEmpty)
                      Text(
                        'SKU: ${variant.sku}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    if (priceText.isNotEmpty)
                      Text(
                        priceText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (variant.variantDiscount != null &&
                        variant.variantDiscount!.trim().isNotEmpty)
                      Text(
                        '${variant.variantDiscount}% off',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showReturnExchangeBottomSheet() async {
    if (widget.order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available in this order')),
      );
      return;
    }

    if (!_canRequestReturnExchange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Return or exchange is available only for delivered products',
          ),
          backgroundColor: Colors.redAccent,
        ),
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
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<OrderItem>(
                            value: _selectedReturnItem,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF161616),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white70,
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: null,
                            items: [_openedItem].map((item) {
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
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRefundRemark,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF161616),
                            hint: Text(
                              _isCashOnDeliveryOrder
                                  ? 'Select exchange or COD return'
                                  : 'Select return or exchange',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white70,
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: _isSubmittingReturnExchange
                                ? null
                                : (String? value) async {
                                    bottomSheetSetState(() {
                                      _selectedRefundRemark = value;
                                      _selectedExchangeVariant = null;
                                      _exchangeVariants = [];
                                      _exchangeVariantErrorMessage = null;
                                    });

                                    if (value == 'exchange' &&
                                        _selectedReturnItem != null) {
                                      await _fetchExchangeVariants(
                                        item: _selectedReturnItem!,
                                        bottomSheetSetState:
                                            bottomSheetSetState,
                                      );
                                    }
                                  },
                            items: _availableRefundRemarkOptions.map((option) {
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

                      if (_selectedRefundRemark == 'exchange') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Exchange Variant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (_isLoadingExchangeVariants)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.tealAccent,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Loading variants...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          )
                        else
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
                              child: DropdownButton<ExchangeVariant>(
                                value: _selectedExchangeVariant,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF161616),
                                hint: const Text(
                                  'Select exchange variant',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white70,
                                ),
                                style: const TextStyle(color: Colors.white),
                                onChanged:
                                    _isSubmittingReturnExchange ||
                                        _exchangeVariants.isEmpty
                                    ? null
                                    : (ExchangeVariant? value) {
                                        bottomSheetSetState(() {
                                          _selectedExchangeVariant = value;
                                        });
                                      },
                                itemHeight: 92,
                                selectedItemBuilder: (context) {
                                  return _exchangeVariants.map((variant) {
                                    return _buildExchangeVariantDropdownItem(
                                      variant,
                                      fallbackItem: _selectedReturnItem,
                                      compact: true,
                                    );
                                  }).toList();
                                },
                                items: _exchangeVariants.map((variant) {
                                  return DropdownMenuItem<ExchangeVariant>(
                                    value: variant,
                                    child: _buildExchangeVariantDropdownItem(
                                      variant,
                                      fallbackItem: _selectedReturnItem,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                        if (_exchangeVariantErrorMessage != null &&
                            _exchangeVariantErrorMessage!
                                .trim()
                                .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _exchangeVariantErrorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 10),
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
                            value: _selectedReasonType,
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
                      const SizedBox(height: 22),
                      if (_returnExchangeErrorMessage != null &&
                          _returnExchangeErrorMessage!.trim().isNotEmpty) ...[
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
                                  _returnExchangeErrorMessage!,
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
                        child: ElevatedButton(
                          onPressed: _isSubmittingReturnExchange
                              ? null
                              : () => _submitReturnExchangeRequest(
                                  bottomSheetSetState,
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            disabledBackgroundColor: Colors.tealAccent
                                .withOpacity(0.35),
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
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                style: const TextStyle(color: Colors.white54, fontSize: 12),
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
          style: const TextStyle(color: Colors.white70, fontSize: 14),
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
          onPressed: () => Navigator.pop(context, _orderStatusChanged),
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
                    _sectionTitle('Selected Item'),
                    const SizedBox(height: 16),

                    _buildOrderDetailItemCard(_openedItem),

                    if (_otherItemsInOrder.isNotEmpty) ...[
                      const Divider(color: Colors.white24, height: 30),
                      _sectionTitle('Other items in this order'),
                      const SizedBox(height: 16),
                      ..._otherItemsInOrder.map(
                        (item) => _buildOrderDetailItemCard(item),
                      ),
                    ],

                    const Divider(color: Colors.white24, height: 26),

                    _priceRow(
                      'Subtotal',
                      '₹${_toDouble(order.subtotal).toStringAsFixed(2)}',
                    ),

                    if (_toDouble(order.discountTotal) > 0) ...[
                      const SizedBox(height: 10),
                      _priceRow(
                        'Discount',
                        '-₹${_toDouble(order.discountTotal).toStringAsFixed(2)}',
                        valueColor: Colors.greenAccent,
                      ),
                    ],

                    if (_toDouble(order.platformFee) > 0) ...[
                      const SizedBox(height: 10),
                      _priceRow(
                        'Platform Fee',
                        '₹${_toDouble(order.platformFee).toStringAsFixed(2)}',
                      ),
                    ],

                    if (_toDouble(order.convenienceFee) > 0) ...[
                      const SizedBox(height: 10),
                      _priceRow(
                        'Convenience Fee',
                        '₹${_toDouble(order.convenienceFee).toStringAsFixed(2)}',
                      ),
                    ],

                    if (_toDouble(order.shipmentCharge) > 0) ...[
                      const SizedBox(height: 10),
                      _priceRow(
                        'Shipment Charge',
                        '₹${_toDouble(order.shipmentCharge).toStringAsFixed(2)}',
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
                            '₹${_toDouble(order.finalPayable).toStringAsFixed(2)}',
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
              if (_canCancelOrderItem && _canRequestReturnExchange)
                const SizedBox(height: 12),
              _buildReturnExchangeButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

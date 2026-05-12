import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/admin_orders_page.dart';
import 'package:my_skates/COACH/used_product_my_order_detail_page.dart'
    as my_used_detail;
import 'package:my_skates/COACH/used_product_sold_order_detail_page.dart';
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
}

class UsedPricing {
  final String subtotal;
  final String discountTotal;
  final String total;
  final String platformFee;
  final String convenienceFee;
  final String shipmentCharge;
  final String productPercentage;
  final String finalPayable;

  UsedPricing({
    required this.subtotal,
    required this.discountTotal,
    required this.total,
    required this.platformFee,
    required this.convenienceFee,
    required this.shipmentCharge,
    required this.productPercentage,
    required this.finalPayable,
  });

  factory UsedPricing.fromJson(Map<String, dynamic> json) {
    return UsedPricing(
      subtotal: json['subtotal']?.toString() ?? '0',
      discountTotal: json['discount_total']?.toString() ?? '0',
      total: json['total']?.toString() ?? '0',
      platformFee: json['platform_fee']?.toString() ?? '0',
      convenienceFee: json['convenience_fee']?.toString() ?? '0',
      shipmentCharge: json['shipment_charge']?.toString() ?? '0',
      productPercentage: json['product_percentage']?.toString() ?? '0',
      finalPayable: json['final_payable']?.toString() ?? '0',
    );
  }
}

class UsedSellerItem {
  final int productId;
  final String title;
  final int quantity;
  final String price;
  final String discountPercent;
  final String? productpercentage;
  final String discountAmount;
  final String shipmentCharge;
  final String productTotal;
  final String percentageAmount;
  final String sellerPayable;

  UsedSellerItem({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.price,
    required this.discountPercent,
    required this.productpercentage,
    required this.discountAmount,
    required this.shipmentCharge,
    required this.productTotal,
    required this.percentageAmount,
    required this.sellerPayable,
  });

  factory UsedSellerItem.fromJson(Map<String, dynamic> json) {
    return UsedSellerItem(
      productId: json['product_id'] ?? 0,
      title: json['title'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: json['price']?.toString() ?? '0',
      discountPercent: json['discount_percent']?.toString() ?? '0',
      productpercentage: json['product_percentage']?.toString() ?? '0',
      discountAmount: json['discount_amount']?.toString() ?? '0',
      shipmentCharge: json['shipment_charge']?.toString() ?? '0',
      productTotal: json['product_total']?.toString() ?? '0',
      percentageAmount: json['percentage_amount']?.toString() ?? '0',
      sellerPayable: json['seller_payable']?.toString() ?? '0',
    );
  }
}

class UsedSellerBankDetails {
  final String accountHolderName;
  final String bankName;
  final String branchName;
  final String accountNumber;
  final String ifscCode;
  final String upiId;

  UsedSellerBankDetails({
    required this.accountHolderName,
    required this.bankName,
    required this.branchName,
    required this.accountNumber,
    required this.ifscCode,
    required this.upiId,
  });

  factory UsedSellerBankDetails.fromJson(Map<String, dynamic> json) {
    return UsedSellerBankDetails(
      accountHolderName: json['account_holder_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      branchName: json['branch_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      upiId: json['upi_id'] ?? '',
    );
  }

  bool get hasAny =>
      accountHolderName.isNotEmpty ||
      bankName.isNotEmpty ||
      branchName.isNotEmpty ||
      accountNumber.isNotEmpty ||
      ifscCode.isNotEmpty ||
      upiId.isNotEmpty;
}

class UsedSellerBreakdown {
  final int sellerId;
  final String sellerName;
  final String sellerPhone;
  final String userType;
  final UsedSellerBankDetails? bankDetails;
  final List<UsedSellerItem> items;
  final String sellerTotal;
  final String sellerPercentageTotal;
  final String sellerPayableTotal;

  UsedSellerBreakdown({
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.userType,
    this.bankDetails,
    required this.items,
    required this.sellerTotal,
    required this.sellerPercentageTotal,
    required this.sellerPayableTotal,
  });

  factory UsedSellerBreakdown.fromJson(Map<String, dynamic> json) {
    return UsedSellerBreakdown(
      sellerId: json['seller_id'] ?? 0,
      sellerName: json['seller_name'] ?? '',
      sellerPhone: json['seller_phone'] ?? '',
      userType: json['user_type'] ?? '',
      bankDetails: json['bank_details'] != null
          ? UsedSellerBankDetails.fromJson(json['bank_details'])
          : null,
      items: (json['items'] as List? ?? [])
          .map((e) => UsedSellerItem.fromJson(e))
          .toList(),
      sellerTotal: json['seller_total']?.toString() ?? '0',
      sellerPercentageTotal: json['seller_percentage_total']?.toString() ?? '0',
      sellerPayableTotal: json['seller_payable_total']?.toString() ?? '0',
    );
  }
}

class UsedOrderSummary {
  final String totalPercentageAmount;
  final String totalSellerPayable;
  final String finalPayable;
  final String totalProfit;

  UsedOrderSummary({
    required this.totalPercentageAmount,
    required this.totalSellerPayable,
    required this.finalPayable,
    required this.totalProfit,
  });

  factory UsedOrderSummary.fromJson(Map<String, dynamic> json) {
    return UsedOrderSummary(
      totalPercentageAmount: json['total_percentage_amount']?.toString() ?? '0',
      totalSellerPayable: json['total_seller_payable']?.toString() ?? '0',
      finalPayable: json['final_payable']?.toString() ?? '0',
      totalProfit: json['total_profit']?.toString() ?? '0',
    );
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
  final String? note;
  final DateTime createdAt;
  final List<UsedOrderItem> items;
  // pricing is optional — list API returns flat fields, detail API nests them
  final UsedPricing? pricing;
  final List<UsedSellerBreakdown> sellerBreakdown;
  final UsedOrderSummary? summary;

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
    this.note,
    required this.createdAt,
    required this.items,
    this.pricing,
    required this.sellerBreakdown,
    this.summary,
  });

  // Convenience getter — works for both list (flat) and detail (nested) responses.
  String get finalPayable => pricing?.finalPayable ?? '0';

  factory UsedOrder.fromJson(Map<String, dynamic> json) {
    // The list API returns flat pricing fields at the root;
    // the detail API wraps them inside a "pricing" key.
    UsedPricing? pricing;
    if (json['pricing'] != null) {
      pricing = UsedPricing.fromJson(json['pricing']);
    } else if (json['final_payable'] != null) {
      // Build a UsedPricing from the flat fields present in the list response
      pricing = UsedPricing(
        subtotal: json['subtotal']?.toString() ?? '0',
        discountTotal: json['discount_total']?.toString() ?? '0',
        total: json['total']?.toString() ?? '0',
        platformFee: json['platform_fee']?.toString() ?? '0',
        convenienceFee: json['convenience_fee']?.toString() ?? '0',
        shipmentCharge: json['shipment_charge']?.toString() ?? '0',
        productPercentage: json['product_percentage']?.toString() ?? '0',
        finalPayable: json['final_payable']?.toString() ?? '0',
      );
    }

    return UsedOrder(
      id: json['id'] ?? 0,
      orderNo: json['order_no'] ?? '',
      status: json['status'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      razorpayPaymentRef: json['payment_ref'] ?? json['razorpay_payment_ref'],
      fullName: json['full_name'] ?? '',
      phone: json['phone']?.toString() ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'],
      city: json['city'] ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      note: json['note'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      items: (json['items'] as List? ?? [])
          .map((e) => UsedOrderItem.fromJson(e))
          .toList(),
      pricing: pricing,
      sellerBreakdown: (json['seller_breakdown'] as List? ?? [])
          .map((e) => UsedSellerBreakdown.fromJson(e))
          .toList(),
      summary: json['summary'] != null
          ? UsedOrderSummary.fromJson(json['summary'])
          : null,
    );
  }
}

// ─── Shared Helpers ───────────────────────────────────────────────────────────

Color _usedOrderStatusColor(String status) {
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

Widget _usedOrderGlassWrap({required Widget child, EdgeInsets? padding}) {
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

// ─── List Page ────────────────────────────────────────────────────────────────
enum UsedAllOrderSortType { latest, earliest }

enum UsedProductOrderViewType {
  coachUsedProducts,
  myUsedProducts,
  mySoldProducts,
  allUsedProducts,
}

class UsedProductOrdersPage extends StatefulWidget {
  const UsedProductOrdersPage({super.key});

  @override
  State<UsedProductOrdersPage> createState() => _UsedProductOrdersPageState();
}

class _UsedProductOrdersPageState extends State<UsedProductOrdersPage> {
  List<UsedOrder> _orders = [];
  UsedProductOrderViewType _selectedView =
      UsedProductOrderViewType.coachUsedProducts;
  UsedAllOrderSortType _selectedSort = UsedAllOrderSortType.latest;
  bool _isLoading = true;
  String? _error;

  // Pagination variables
  int _currentPage = 1;
  int _totalCount = 0;
  int _totalPages = 0;
  String? _nextPageUrl;
  String? _previousPageUrl;

  String get _selectedEndpoint {
    switch (_selectedView) {
      case UsedProductOrderViewType.coachUsedProducts:
        return '$api/api/myskates/used/product/all/orders/';

      case UsedProductOrderViewType.myUsedProducts:
        return '$api/api/myskates/used/product/my/orders/';

      case UsedProductOrderViewType.mySoldProducts:
        return '$api/api/myskates/used/product/sold/orders/view/';

      case UsedProductOrderViewType.allUsedProducts:
        return '$api/api/myskates/used/product/all/seller/orders/view/';
    }
  }

  // Search and date filter
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  // Debounce for search
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 1; // Reset to first page when searching
      _fetchOrders();
    });
  }

  void _goToPage(int page) {
    if (page == _currentPage) return;
    _currentPage = page;
    _fetchOrders();
  }

  void _nextPage() {
    if (_nextPageUrl != null) {
      _currentPage++;
      _fetchOrders();
    }
  }

  void _previousPage() {
    if (_previousPageUrl != null) {
      _currentPage--;
      _fetchOrders();
    }
  }

  Future<void> _pickDateRange() async {
    try {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _startDate != null && _endDate != null
            ? DateTimeRange(start: _startDate!, end: _endDate!)
            : null,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.tealAccent,
                onPrimary: Colors.black,
                surface: Color(0xFF001F1D),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _startDate = picked.start;
          _endDate = picked.end;
        });
        _goToPage(1);
      }
    } catch (e) {
      print('Error picking date range: $e');
      // Show error snackbar if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error selecting date range')),
      );
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _goToPage(1);
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

      final queryParams = <String, String>{'page': _currentPage.toString()};

      // Add search query
      if (_searchController.text.trim().isNotEmpty) {
        final searchTerm = _searchController.text.trim();

        // Try these one by one to see which works with your API:
        queryParams['search'] = searchTerm; // Common
        // queryParams['q'] = searchTerm;             // Alternative
        // queryParams['query'] = searchTerm;         // Alternative
        // queryParams['order_no'] = searchTerm;      // Specific field
        // queryParams['full_name'] = searchTerm;     // Specific field
        // queryParams['phone'] = searchTerm;         // Specific field

        print('Search term: $searchTerm'); // Debug print
      }

      // Add date filters
      if (_startDate != null) {
        queryParams['start_date'] = DateFormat(
          'yyyy-MM-dd',
        ).format(_startDate!);
        print('Start Date: ${queryParams['start_date']}'); // Debug print
      }
      if (_endDate != null) {
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(_endDate!);
        print('End Date: ${queryParams['end_date']}'); // Debug print
      }

      final uri = Uri.parse(
        _selectedEndpoint,
      ).replace(queryParameters: queryParams);

      print('USED ORDERS URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('USED ORDERS STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        _totalCount = jsonResponse['count'] ?? 0;
        _nextPageUrl = jsonResponse['next'];
        _previousPageUrl = jsonResponse['previous'];

        // Calculate total pages
        final List<dynamic> data =
            jsonResponse['results']?['data'] ?? jsonResponse['data'] ?? [];
        final pageSize = data.length;
        if (pageSize > 0) {
          _totalPages = (_totalCount / pageSize).ceil();
        } else {
          _totalPages = 1;
        }

        final newOrders = data.map((e) => UsedOrder.fromJson(e)).toList();

        setState(() {
          _orders = newOrders;
          _isLoading = false;
        });

        for (final order in _orders) {
          print(
            'USED ALL ORDER ${order.id} FINAL PAYABLE => ${order.finalPayable}',
          );
        }
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

  Widget _buildViewDropdown() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UsedProductOrderViewType>(
          value: _selectedView,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.tealAccent,
            size: 20,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (UsedProductOrderViewType? value) {
            if (value == null || value == _selectedView) return;

            setState(() {
              _selectedView = value;
              _orders = [];
              _currentPage = 1;
              _totalCount = 0;
              _totalPages = 0;
              _nextPageUrl = null;
              _previousPageUrl = null;
              _searchController.clear();
              _startDate = null;
              _endDate = null;
              _selectedSort = UsedAllOrderSortType.latest;
            });

            _fetchOrders();
          },
          selectedItemBuilder: (context) {
            return const [
              Row(
                children: [
                  Icon(
                    Icons.sports_rounded,
                    color: Colors.tealAccent,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coach Used Product Orders',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    color: Colors.tealAccent,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'My Used Product Orders',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.storefront_rounded,
                    color: Colors.tealAccent,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'My Sold Products',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.tealAccent,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All Used Products',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ];
          },
          items: const [
            DropdownMenuItem<UsedProductOrderViewType>(
              value: UsedProductOrderViewType.coachUsedProducts,
              child: Row(
                children: [
                  Icon(
                    Icons.sports_rounded,
                    color: Colors.tealAccent,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Coach Used Product Orders',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<UsedProductOrderViewType>(
              value: UsedProductOrderViewType.myUsedProducts,
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    color: Colors.tealAccent,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'My Used Product Orders',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<UsedProductOrderViewType>(
              value: UsedProductOrderViewType.mySoldProducts,
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_rounded,
                    color: Colors.tealAccent,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'My Sold Products',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<UsedProductOrderViewType>(
              value: UsedProductOrderViewType.allUsedProducts,
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.tealAccent,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'All Used Products',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<UsedOrder> get _sortedOrders {
    final List<UsedOrder> sortedList = List.from(_orders);

    sortedList.sort((a, b) {
      switch (_selectedSort) {
        case UsedAllOrderSortType.latest:
          return b.createdAt.compareTo(a.createdAt);

        case UsedAllOrderSortType.earliest:
          return a.createdAt.compareTo(b.createdAt);
      }
    });

    return sortedList;
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.tealAccent,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white54,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _currentPage = 1;
                                _fetchOrders();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(flex: 4, child: _buildSortDropdown()),
            ],
          ),

          if (_startDate != null && _endDate != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.tealAccent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.tealAccent.withOpacity(0.30)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range_rounded,
                    color: Colors.tealAccent,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearDateFilter,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UsedAllOrderSortType>(
          value: _selectedSort,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.tealAccent,
            size: 18,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: (UsedAllOrderSortType? value) {
            if (value == null) return;

            setState(() {
              _selectedSort = value;
            });
          },
          selectedItemBuilder: (context) {
            return const [
              Row(
                children: [
                  Icon(Icons.south_rounded, color: Colors.tealAccent, size: 17),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Latest',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.north_rounded, color: Colors.tealAccent, size: 17),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Earliest',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ];
          },
          items: const [
            DropdownMenuItem<UsedAllOrderSortType>(
              value: UsedAllOrderSortType.latest,
              child: Row(
                children: [
                  Icon(Icons.south_rounded, color: Colors.tealAccent, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Latest First',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem<UsedAllOrderSortType>(
              value: UsedAllOrderSortType.earliest,
              child: Row(
                children: [
                  Icon(Icons.north_rounded, color: Colors.tealAccent, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Earliest First',
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _selectedSort = UsedAllOrderSortType.latest;
    });
    _currentPage = 1; // Reset to first page
    _fetchOrders(); // Fetch immediately
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          GestureDetector(
            onTap: _previousPageUrl != null ? _previousPage : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _previousPageUrl != null
                    ? Colors.tealAccent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _previousPageUrl != null
                      ? Colors.tealAccent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chevron_left,
                    color: _previousPageUrl != null
                        ? Colors.tealAccent
                        : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Previous',
                    style: TextStyle(
                      color: _previousPageUrl != null
                          ? Colors.tealAccent
                          : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Text(
              'Page $_currentPage of $_totalPages',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Next button
          GestureDetector(
            onTap: _nextPageUrl != null ? _nextPage : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _nextPageUrl != null
                    ? Colors.tealAccent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _nextPageUrl != null
                      ? Colors.tealAccent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      color: _nextPageUrl != null
                          ? Colors.tealAccent
                          : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: _nextPageUrl != null
                        ? Colors.tealAccent
                        : Colors.white38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _usedOrderGlassWrap(
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

  Widget _orderCard(UsedOrder order) {
    final statusColor = _usedOrderStatusColor(order.status);

    return GestureDetector(
      onTap: () {
        if (_selectedView == UsedProductOrderViewType.myUsedProducts) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  my_used_detail.UsedProductOrderDetailPage(orderId: order.id),
            ),
          );
          return;
        }

        if (_selectedView == UsedProductOrderViewType.mySoldProducts) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UsedProductSoldOrderDetailPage(orderId: order.id),
            ),
          );
          return;
        }

        if (_selectedView == UsedProductOrderViewType.allUsedProducts) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  my_used_detail.UsedProductOrderDetailPage(orderId: order.id),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                my_used_detail.UsedProductOrderDetailPage(orderId: order.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: _usedOrderGlassWrap(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              if (order.items.isNotEmpty) ...[
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

  Widget _itemRow(UsedOrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _listItemImage(item),
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
        ],
      ),
    );
  }

  Widget _listItemImage(UsedOrderItem item) {
    if (item.image == null || item.image!.isEmpty) return _listImageFallback();

    final url = item.image!.startsWith('http')
        ? item.image!
        : '$api${item.image}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _listImageFallback(),
      ),
    );
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
            onRefresh: () async => _fetchOrders(),
            color: Colors.tealAccent,
            backgroundColor: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _selectedView ==
                                  UsedProductOrderViewType.coachUsedProducts
                              ? 'Coach Used Product Orders'
                              : _selectedView ==
                                    UsedProductOrderViewType.myUsedProducts
                              ? 'My Used Product Orders'
                              : _selectedView ==
                                    UsedProductOrderViewType.mySoldProducts
                              ? 'My Sold Products'
                              : 'All Used Products',
                          style: const TextStyle(
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
                            '$_totalCount',
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: _pickDateRange,
                            icon: Icon(
                              Icons.calendar_month_rounded,
                              color: _startDate != null && _endDate != null
                                  ? Colors.tealAccent
                                  : Colors.white70,
                            ),
                          ),
                          if (_startDate != null && _endDate != null)
                            Positioned(
                              right: 9,
                              top: 9,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildViewDropdown(),
                  _buildFilterBar(),
                  const SizedBox(height: 8),
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
                            itemCount: _sortedOrders.length,
                            itemBuilder: (_, i) => _orderCard(_sortedOrders[i]),
                          ),
                  ),
                  _buildPaginationControls(),
                  const SizedBox(height: 8),
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
        _usedOrderGlassWrap(
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
    final title = _selectedView == UsedProductOrderViewType.coachUsedProducts
        ? 'No coach used product orders yet'
        : _selectedView == UsedProductOrderViewType.myUsedProducts
        ? 'No my used product orders yet'
        : _selectedView == UsedProductOrderViewType.mySoldProducts
        ? 'No sold products yet'
        : 'No all used products yet';

    final subtitle = _selectedView == UsedProductOrderViewType.coachUsedProducts
        ? 'Coach used product orders will appear here'
        : _selectedView == UsedProductOrderViewType.myUsedProducts
        ? 'Your used product orders will appear here'
        : _selectedView == UsedProductOrderViewType.mySoldProducts
        ? 'Orders for your used products will appear here'
        : 'All seller used product orders will appear here';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        _usedOrderGlassWrap(
          padding: const EdgeInsets.all(36),
          child: Column(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white24,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
} // ─── Detail Page ──────────────────────────────────────────────────────────────

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

      final response = await http.get(
        Uri.parse(
          '$api/api/myskates/used/product/all/orders/detail/view/${widget.orderId}/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('USED ORDER DETAIL STATUS: ${response.statusCode}');
      print('USED ORDER DETAIL BODY: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
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

  double _amount(String value) => double.tryParse(value) ?? 0.0;

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

  Widget _pricingRow(String label, String value, {bool isDiscount = false}) {
    final amount = double.tryParse(value) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            '${isDiscount ? '- ' : ''}₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isDiscount ? Colors.redAccent : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
            width: 110,
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

  Widget _summaryRow({
    required String label,
    required String value,
    required Color dotColor,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
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
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
    final statusColor = _usedOrderStatusColor(order.status);
    final pricing = order.pricing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Order header ─────────────────────────────────────────────────
        _usedOrderGlassWrap(
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
        _usedOrderGlassWrap(
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
                  if (order.addressLine2 != null &&
                      order.addressLine2!.isNotEmpty)
                    order.addressLine2!,
                  '${order.city}, ${order.state} - ${order.pincode}',
                  order.country,
                ].join('\n'),
              ),
              if (order.note != null && order.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _infoRow(Icons.note_outlined, 'Order Note', order.note!),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Items + Pricing ──────────────────────────────────────────────
        _usedOrderGlassWrap(
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

              // Item rows
              ...order.items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isLast = i == order.items.length - 1;

                // Image URL — detail API sends full absolute URL
                final imageUrl = (item.image != null && item.image!.isNotEmpty)
                    ? (item.image!.startsWith('http')
                          ? item.image!
                          : '$api${item.image}')
                    : null;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
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
                                    // if ((double.tryParse(item.discount) ?? 0) >
                                    //     0)
                                    //   _chip(
                                    //     '${item.discount}% off',
                                    //     Colors.greenAccent,
                                    //   ),
                                  ],
                                ),
                              ],
                            ),
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

              // ── Pricing breakdown ──────────────────────────────────────
              if (pricing != null) ...[
                _pricingRow('Subtotal', pricing.total),
                if ((double.tryParse(pricing.discountTotal) ?? 0) > 0)
                  // _pricingRow(
                  //   'Discount',
                  //   pricing.discountTotal,
                  //   isDiscount: true,
                  // ),
                  if ((double.tryParse(pricing.platformFee) ?? 0) > 0) ...[
                    const SizedBox(height: 2),
                    _pricingRow('Platform Fee', pricing.platformFee),
                  ],
                if ((double.tryParse(pricing.convenienceFee) ?? 0) > 0) ...[
                  const SizedBox(height: 2),
                  _pricingRow('Convenience Fee', pricing.convenienceFee),
                ],
                if ((double.tryParse(pricing.shipmentCharge) ?? 0) > 0) ...[
                  const SizedBox(height: 2),
                  _pricingRow('Shipment Charge', pricing.shipmentCharge),
                ],
                if ((double.tryParse(pricing.productPercentage) ?? 0) > 0) ...[
                  const SizedBox(height: 2),
                  _pricingRow(
                    'Product Charge',
                    pricing.productPercentage,
                    isDiscount: true,
                  ),
                ],
              ],

              const Divider(color: Colors.white12, height: 16),

              // Final payable
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

              // ── Seller Breakdown ───────────────────────────────────────
              if (order.sellerBreakdown.isNotEmpty) ...[
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

                ...order.sellerBreakdown.asMap().entries.map((entry) {
                  final index = entry.key;
                  final seller = entry.value;
                  final bank = seller.bankDetails;
                  final initials = seller.sellerName.isNotEmpty
                      ? seller.sellerName
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
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seller header
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.tealAccent.withOpacity(
                                  0.15,
                                ),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      seller.sellerName.isEmpty
                                          ? 'Seller ${index + 1}'
                                          : seller.sellerName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (seller.sellerPhone.isNotEmpty)
                                      Text(
                                        seller.sellerPhone,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (seller.userType.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.tealAccent.withOpacity(
                                            0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.tealAccent
                                                .withOpacity(0.25),
                                            width: 0.7,
                                          ),
                                        ),
                                        child: Text(
                                          seller.userType,
                                          style: const TextStyle(
                                            color: Colors.tealAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'net payable',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    '₹${_amount(seller.sellerPayableTotal).toStringAsFixed(2)}',
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

                        const Divider(color: Colors.white10, height: 1),

                        // Items
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              ...seller.items.asMap().entries.map((e) {
                                final isLast = e.key == seller.items.length - 1;
                                final si = e.value;
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              si.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '₹${_amount(si.productTotal).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // if ((_amount(si.discountAmount)) > 0)
                                    //   _receiptRow(
                                    //     'Discount (${si.discountPercent}%)',
                                    //     '− ₹${_amount(si.discountAmount).toStringAsFixed(2)}',
                                    //     valueColor: Colors.orangeAccent,
                                    //   ),
                                    _receiptRow(
                                      'Product Charge (${si.productpercentage}%)',
                                      '− ₹${_amount(si.percentageAmount).toStringAsFixed(2)}',
                                      valueColor: Colors.redAccent,
                                    ),
                                    if (_amount(si.shipmentCharge) > 0)
                                      _receiptRow(
                                        'Shipping Charge',
                                        '+ ₹${_amount(si.shipmentCharge).toStringAsFixed(2)}',
                                        valueColor: Colors.green,
                                      ),
                                    _receiptRow(
                                      'Seller Payable',
                                      '₹${_amount(si.sellerPayable).toStringAsFixed(2)}',
                                      valueColor: Colors.tealAccent,
                                    ),
                                    const SizedBox(height: 5),
                                    if (!isLast)
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

                        // Seller totals
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                          child: Column(
                            children: [
                              // const Divider(color: Colors.white10, height: 20),
                              // _receiptRow(
                              //   'Subtotal',
                              //   '₹${_amount(seller.sellerTotal).toStringAsFixed(2)}',
                              // ),
                              // _receiptRow(
                              //   'Platform Commission',
                              //   '− ₹${_amount(seller.sellerPercentageTotal).toStringAsFixed(2)}',
                              //   valueColor: Colors.redAccent,
                              // ),
                              const Divider(color: Colors.white10, height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    '₹${_amount(seller.sellerPayableTotal).toStringAsFixed(2)}',
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

                        // Bank details
                        if (bank != null && bank.hasAny)
                          Container(
                            width: double.infinity,
                            color: Colors.white.withOpacity(0.04),
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                if (bank.accountHolderName.isNotEmpty)
                                  _bankRow(
                                    'Account holder',
                                    bank.accountHolderName,
                                  ),
                                if (bank.bankName.isNotEmpty)
                                  _bankRow('Bank', bank.bankName),
                                if (bank.branchName.isNotEmpty)
                                  _bankRow('Branch', bank.branchName),
                                if (bank.accountNumber.isNotEmpty)
                                  _bankRow('Account no.', bank.accountNumber),
                                if (bank.ifscCode.isNotEmpty)
                                  _bankRow('IFSC', bank.ifscCode),
                                if (bank.upiId.isNotEmpty)
                                  _bankRow('UPI', bank.upiId),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),

                // Order summary / profit card
                if (order.summary != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F1D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
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
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),
                        _summaryRow(
                          label: 'Total collected',
                          value:
                              '+ ₹${_amount(order.summary!.finalPayable).toStringAsFixed(2)}',
                          dotColor: Colors.green,
                          valueColor: Colors.green,
                        ),
                        const SizedBox(height: 10),
                        _summaryRow(
                          label: 'Platform commission',
                          value:
                              '+ ₹${_amount(order.summary!.totalPercentageAmount).toStringAsFixed(2)}',
                          dotColor: Colors.green,
                          valueColor: Colors.green,
                        ),
                        const SizedBox(height: 10),
                        _summaryRow(
                          label: 'Total payout to sellers',
                          value:
                              '− ₹${_amount(order.summary!.totalSellerPayable).toStringAsFixed(2)}',
                          dotColor: Colors.redAccent,
                          valueColor: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                '₹${_amount(order.summary!.totalProfit).toStringAsFixed(2)}',
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
    return _usedOrderGlassWrap(
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
          _usedOrderGlassWrap(
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
          _usedOrderGlassWrap(
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

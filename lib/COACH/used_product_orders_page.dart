import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_skates/COACH/used_product_my_order_detail_page.dart';
import 'package:my_skates/COACH/used_product_sold_order_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'package:my_skates/api.dart';

enum UsedOrderViewType { myOrders, mySoldProducts }

enum UsedOrderSortType { latest, earliest }

class UsedProductOrderItem {
  final int id;
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

  UsedProductOrderItem({
    required this.id,
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

  factory UsedProductOrderItem.fromJson(Map<String, dynamic> json) {
    return UsedProductOrderItem(
      id: json['id'] ?? 0,
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
}

class UsedProductOrder {
  final int id;
  final String orderNo;
  String status;
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
  final String productPercentage;
  final String finalPayable;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<UsedProductOrderItem> items;

  UsedProductOrder({
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
    required this.productPercentage,
    required this.finalPayable,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory UsedProductOrder.fromJson(Map<String, dynamic> json) {
    final itemList = json['items'] as List? ?? [];
    final pricing = json['pricing'] as Map<String, dynamic>? ?? json;

    return UsedProductOrder(
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

      subtotal: pricing['subtotal']?.toString() ?? '0',
      discountTotal: pricing['discount_total']?.toString() ?? '0',
      total: pricing['total']?.toString() ?? '0',
      platformFee: pricing['platform_fee']?.toString() ?? '0',
      convenienceFee: pricing['convenience_fee']?.toString() ?? '0',
      shipmentCharge: pricing['shipment_charge']?.toString() ?? '0',
      productPercentage: pricing['product_percentage']?.toString() ?? '0',
      finalPayable: pricing['final_payable']?.toString() ?? '0',

      note: json['note']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      items: itemList.map((e) => UsedProductOrderItem.fromJson(e)).toList(),
    );
  }
}

class CoachUsedProductOrdersPage extends StatefulWidget {
  const CoachUsedProductOrdersPage({super.key});

  @override
  State<CoachUsedProductOrdersPage> createState() => _CoachUsedProductOrdersPageState();
}

class _CoachUsedProductOrdersPageState extends State<CoachUsedProductOrdersPage> {
  UsedOrderViewType selectedView = UsedOrderViewType.myOrders;
  UsedOrderSortType selectedSort = UsedOrderSortType.latest;

  List<UsedProductOrder> orders = [];

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  DateTime? startDate;
  DateTime? endDate;

  bool isLoading = true;
  String? error;

  int currentPage = 1;
  int totalCount = 0;
  String? nextPageUrl;
  String? previousPageUrl;
  bool isPageLoading = false;

  final List<Map<String, String>> statusOptions = [
    {"value": "PLACED", "label": "Placed"},
    {"value": "PAID", "label": "Paid"},
    {"value": "SHIPPED", "label": "Shipped"},
    {"value": "DELIVERED", "label": "Delivered"},
    {"value": "CANCELLED", "label": "Cancelled"},
  ];

  String get apiUrl {
    String baseUrl;

    switch (selectedView) {
      case UsedOrderViewType.myOrders:
        baseUrl = '$api/api/myskates/used/product/my/orders/';
        break;

      case UsedOrderViewType.mySoldProducts:
        baseUrl = '$api/api/myskates/used/product/sold/orders/view/';
        break;
    }

    final queryParams = <String, String>{'page': currentPage.toString()};

    if (startDate != null) {
      queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate!);
    }

    if (endDate != null) {
      queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate!);
    }

    return Uri.parse(baseUrl).replace(queryParameters: queryParams).toString();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders({int page = 1}) async {
    setState(() {
      if (page == 1) {
        isLoading = true;
      } else {
        isPageLoading = true;
      }

      error = null;
      currentPage = page;

      if (page == 1) {
        orders = [];
        nextPageUrl = null;
        previousPageUrl = null;
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() {
          error = 'Authentication token missing';
          isLoading = false;
          isPageLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("USED ORDER STATUS: ${response.statusCode}");
      print("USED ORDER BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> list = [];

        if (decoded is Map<String, dynamic> &&
            decoded['results'] is Map<String, dynamic>) {
          final results = decoded['results'] as Map<String, dynamic>;

          totalCount = decoded['count'] ?? results['count'] ?? 0;
          nextPageUrl = decoded['next']?.toString();
          previousPageUrl = decoded['previous']?.toString();

          if (results['data'] is List) {
            list = results['data'] as List;
          }
        } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          totalCount = decoded['count'] ?? 0;
          nextPageUrl = decoded['next']?.toString();
          previousPageUrl = decoded['previous']?.toString();

          list = decoded['data'] as List;
        }

        final parsedOrders = list
            .map((e) => UsedProductOrder.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          orders = parsedOrders;
          isLoading = false;
          isPageLoading = false;
        });

        print("TOTAL COUNT => $totalCount");
        print("CURRENT PAGE => $currentPage");
        print("NEXT PAGE URL => $nextPageUrl");
        print("PREVIOUS PAGE URL => $previousPageUrl");

        for (final order in orders) {
          print("ORDER ${order.id} FINAL PAYABLE => ${order.finalPayable}");
        }
      } else {
        setState(() {
          error = 'Failed to load orders: ${response.statusCode}';
          isLoading = false;
          isPageLoading = false;
        });
      }
    } catch (e) {
      print("USED ORDER ERROR: $e");

      setState(() {
        error = e.toString();
        isLoading = false;
        isPageLoading = false;
      });
    }
  }

  Future<void> refreshOrders() async {
    await fetchOrders(page: 1);
  }

  Future<void> pickDateRange() async {
    DateTime? tempStartDate = startDate;
    DateTime? tempEndDate = endDate;
    bool selectingStart = true;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final DateTime now = DateTime.now();

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: Color(0xFF001F1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Select Date Range',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(bottomSheetContext),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectingStart = true;
                              });
                            },
                            child: _dateRangeBox(
                              title: 'Start Date',
                              date: tempStartDate,
                              isSelected: selectingStart,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectingStart = false;
                              });
                            },
                            child: _dateRangeBox(
                              title: 'End Date',
                              date: tempEndDate,
                              isSelected: !selectingStart,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.tealAccent,
                            onPrimary: Colors.black,
                            surface: Color(0xFF001F1D),
                            onSurface: Colors.white,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.tealAccent,
                            ),
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: selectingStart
                              ? tempStartDate ?? now
                              : tempEndDate ?? tempStartDate ?? now,
                          firstDate: DateTime(2020),
                          lastDate: now,
                          onDateChanged: (DateTime selectedDate) {
                            setModalState(() {
                              if (selectingStart) {
                                tempStartDate = selectedDate;

                                if (tempEndDate != null &&
                                    tempEndDate!.isBefore(selectedDate)) {
                                  tempEndDate = null;
                                }

                                selectingStart = false;
                              } else {
                                if (tempStartDate != null &&
                                    selectedDate.isBefore(tempStartDate!)) {
                                  tempEndDate = tempStartDate;
                                  tempStartDate = selectedDate;
                                } else {
                                  tempEndDate = selectedDate;
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (tempStartDate != null || tempEndDate != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.tealAccent.withOpacity(0.30),
                          ),
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
                                '${tempStartDate != null ? DateFormat('dd MMM yyyy').format(tempStartDate!) : 'Start Date'}  -  ${tempEndDate != null ? DateFormat('dd MMM yyyy').format(tempEndDate!) : 'End Date'}',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                startDate = null;
                                endDate = null;
                                currentPage = 1;
                              });

                              Navigator.pop(bottomSheetContext);
                              fetchOrders(page: 1);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.redAccent.withOpacity(0.6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (tempStartDate == null ||
                                  tempEndDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Please select start date and end date',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                startDate = tempStartDate;
                                endDate = tempEndDate;
                                currentPage = 1;
                              });

                              Navigator.pop(bottomSheetContext);
                              fetchOrders(page: 1);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Apply Filter',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _dateRangeBox({
    required String title,
    required DateTime? date,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.tealAccent.withOpacity(0.16)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? Colors.tealAccent.withOpacity(0.55)
              : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.tealAccent : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            date != null ? DateFormat('dd MMM yyyy').format(date) : 'Select',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void clearDateFilter() {
    setState(() {
      startDate = null;
      endDate = null;
      currentPage = 1;
    });

    fetchOrders(page: 1);
  }

  Future<void> updateUsedProductOrderStatus(
    int orderId,
    String newStatus,
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
        Uri.parse(
          '$api/api/myskates/used/product/order/status/update/$orderId/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': newStatus}),
      );

      print("USED PRODUCT STATUS UPDATE STATUS: ${response.statusCode}");
      print("USED PRODUCT STATUS UPDATE BODY: ${response.body}");

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
      print("USED PRODUCT STATUS UPDATE ERROR: $e");

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

  void showStatusBottomSheet(UsedProductOrder order) {
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
                    'Update Used Product Order Status',
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
                    final value = option['value']!;
                    final label = option['label']!;
                    final isSelected = order.status.toUpperCase() == value;
                    final statusColor = getStatusColor(value);

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);

                        if (!isSelected) {
                          updateUsedProductOrderStatus(order.id, value);
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
                                label,
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

  void openDetail(UsedProductOrder order) {
    if (selectedView == UsedOrderViewType.myOrders) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UsedProductOrderDetailPage(orderId: order.id),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UsedProductSoldOrderDetailPage(orderId: order.id),
        ),
      );
    }
  }

  Color getStatusColor(String status) {
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

  Widget glassWrap({required Widget child, EdgeInsets? padding}) {
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

  List<UsedProductOrder> get filteredOrders {
    if (searchQuery.trim().isEmpty) {
      return orders;
    }

    final query = searchQuery.toLowerCase().trim();

    return orders.where((order) {
      final firstItem = order.items.isNotEmpty ? order.items.first : null;

      final orderNo = order.orderNo.toLowerCase();
      final status = order.status.toLowerCase();
      final buyerName = order.fullName.toLowerCase();
      final phone = order.phone.toLowerCase();
      final paymentMethod = order.paymentMethod.toLowerCase();
      final productTitle = firstItem?.title.toLowerCase() ?? '';
      final productDescription = firstItem?.description.toLowerCase() ?? '';

      return orderNo.contains(query) ||
          status.contains(query) ||
          buyerName.contains(query) ||
          phone.contains(query) ||
          paymentMethod.contains(query) ||
          productTitle.contains(query) ||
          productDescription.contains(query);
    }).toList();
  }

  List<UsedProductOrder> get sortedFilteredOrders {
    final List<UsedProductOrder> sortedList = List.from(filteredOrders);

    sortedList.sort((a, b) {
      switch (selectedSort) {
        case UsedOrderSortType.latest:
          return b.createdAt.compareTo(a.createdAt);

        case UsedOrderSortType.earliest:
          return a.createdAt.compareTo(b.createdAt);
      }
    });

    return sortedList;
  }

  Widget buildViewDropdown() {
    return glassWrap(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UsedOrderViewType>(
          value: selectedView,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.tealAccent),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (UsedOrderViewType? newValue) {
            if (newValue != null && newValue != selectedView) {
              setState(() {
                selectedView = newValue;
                selectedSort = UsedOrderSortType.latest;
                currentPage = 1;
                nextPageUrl = null;
                previousPageUrl = null;
                totalCount = 0;
                orders = [];
                searchQuery = '';
                searchController.clear();
                startDate = null;
                endDate = null;
              });

              fetchOrders(page: 1);
            }
          },
          items: [
            DropdownMenuItem<UsedOrderViewType>(
              value: UsedOrderViewType.myOrders,
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
                      Icons.shopping_bag_outlined,
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
            DropdownMenuItem<UsedOrderViewType>(
              value: UsedOrderViewType.mySoldProducts,
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
                    'My Sold Products',
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

  Widget buildSearchBar() {
    final isMyOrders = selectedView == UsedOrderViewType.myOrders;

    return glassWrap(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: Colors.tealAccent,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: isMyOrders
              ? 'Search my orders...'
              : 'Search sold products...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.tealAccent,
            size: 20,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget buildSortDropdown() {
    return glassWrap(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UsedOrderSortType>(
          value: selectedSort,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.tealAccent,
            size: 18,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: (UsedOrderSortType? value) {
            if (value == null) return;

            setState(() {
              selectedSort = value;
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
            DropdownMenuItem<UsedOrderSortType>(
              value: UsedOrderSortType.latest,
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
            DropdownMenuItem<UsedOrderSortType>(
              value: UsedOrderSortType.earliest,
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

  Widget buildSearchAndSortRow() {
    return Row(
      children: [
        Expanded(flex: 6, child: buildSearchBar()),
        const SizedBox(width: 10),
        Expanded(flex: 4, child: buildSortDropdown()),
      ],
    );
  }

  Widget buildDateFilterBar() {
    if (startDate == null || endDate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
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
              '${DateFormat('dd MMM yyyy').format(startDate!)} - ${DateFormat('dd MMM yyyy').format(endDate!)}',
              style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: clearDateFilter,
            child: const Icon(
              Icons.close_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPaginationControls() {
    final bool hasPagination =
        nextPageUrl != null || previousPageUrl != null || totalCount > 0;

    if (!hasPagination) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: glassWrap(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: previousPageUrl == null || isPageLoading
                    ? null
                    : () {
                        if (currentPage > 1) {
                          fetchOrders(page: currentPage - 1);
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: previousPageUrl == null
                        ? Colors.white.withOpacity(0.04)
                        : Colors.tealAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: previousPageUrl == null
                          ? Colors.white.withOpacity(0.08)
                          : Colors.tealAccent.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chevron_left_rounded,
                        color: previousPageUrl == null
                            ? Colors.white24
                            : Colors.tealAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Prev',
                        style: TextStyle(
                          color: previousPageUrl == null
                              ? Colors.white24
                              : Colors.tealAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: isPageLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.tealAccent,
                      ),
                    )
                  : Text(
                      'Page $currentPage',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: GestureDetector(
                onTap: nextPageUrl == null || isPageLoading
                    ? null
                    : () {
                        fetchOrders(page: currentPage + 1);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: nextPageUrl == null
                        ? Colors.white.withOpacity(0.04)
                        : Colors.tealAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: nextPageUrl == null
                          ? Colors.white.withOpacity(0.08)
                          : Colors.tealAccent.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          color: nextPageUrl == null
                              ? Colors.white24
                              : Colors.tealAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: nextPageUrl == null
                            ? Colors.white24
                            : Colors.tealAccent,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader() {
    final bool hasDateFilter = startDate != null && endDate != null;

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
              'Used Product Orders',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: pickDateRange,
                icon: Icon(
                  Icons.calendar_month_rounded,
                  color: hasDateFilter ? Colors.tealAccent : Colors.white70,
                ),
              ),
              if (hasDateFilter)
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

          IconButton(
            onPressed: () => fetchOrders(page: 1),
            icon: const Icon(Icons.refresh_rounded, color: Colors.tealAccent),
          ),
        ],
      ),
    );
  }

  Widget buildImage(String? image) {
    if (image != null && image.isNotEmpty) {
      final imageUrl = image.startsWith('http') ? image : '$api$image';

      return Image.network(
        imageUrl,
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

  Widget buildStatusBadge(UsedProductOrder order) {
    final bool canUpdateStatus =
        selectedView == UsedOrderViewType.mySoldProducts;

    return GestureDetector(
      onTap: canUpdateStatus
          ? () {
              showStatusBottomSheet(order);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: getStatusColor(order.status).withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: getStatusColor(order.status).withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              order.status,
              style: TextStyle(
                color: getStatusColor(order.status),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (canUpdateStatus) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                color: getStatusColor(order.status),
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: glassWrap(
        padding: const EdgeInsets.all(12),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFF1A2B2A),
          highlightColor: const Color(0xFF2F4F4D),
          child: Column(
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
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        Container(height: 14, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 12, color: Colors.white),
                      ],
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
                  Container(width: 80, height: 14, color: Colors.white),
                  Container(width: 90, height: 18, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOrderCard(UsedProductOrder order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final payable = double.tryParse(order.finalPayable) ?? 0;

    return GestureDetector(
      onTap: () => openDetail(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: glassWrap(
          padding: const EdgeInsets.all(12),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  buildStatusBadge(order),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: buildImage(firstItem?.image),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstItem?.title.isNotEmpty == true
                              ? firstItem!.title
                              : 'Used Product',
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
                          selectedView == UsedOrderViewType.myOrders
                              ? 'Qty: ${firstItem?.quantity ?? 0}'
                              : 'Buyer: ${order.fullName}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(order.createdAt),
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
              if (order.items.length > 1) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 70),
                  child: Text(
                    '+${order.items.length - 1} more item',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.paymentMethod,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${payable.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                selectedView == UsedOrderViewType.mySoldProducts
                    ? 'Tap status to update • Tap card to view details'
                    : 'Tap to view details',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLoadingView() {
    return Column(
      children: [
        buildHeader(),
        const SizedBox(height: 12),
        buildViewDropdown(),
        const SizedBox(height: 10),
        buildDateFilterBar(),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (_, __) => buildShimmerCard(),
          ),
        ),
      ],
    );
  }

  Widget buildErrorView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        buildHeader(),
        const SizedBox(height: 12),
        buildViewDropdown(),
        const SizedBox(height: 80),
        glassWrap(
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
      ],
    );
  }

  Widget buildEmptyView() {
    final isMyOrders = selectedView == UsedOrderViewType.myOrders;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        buildHeader(),
        const SizedBox(height: 12),
        buildViewDropdown(),
        const SizedBox(height: 10),
        buildDateFilterBar(),
        const SizedBox(height: 80),
        glassWrap(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                isMyOrders
                    ? Icons.shopping_bag_outlined
                    : Icons.storefront_outlined,
                color: Colors.white38,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                isMyOrders
                    ? 'No used product orders yet'
                    : 'No sold products orders yet',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                isMyOrders
                    ? 'Your used product orders will appear here'
                    : 'Orders from your used products will appear here',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildLoadedView() {
    final isMyOrders = selectedView == UsedOrderViewType.myOrders;
    final filteredList = sortedFilteredOrders;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        buildHeader(),
        const SizedBox(height: 12),
        buildViewDropdown(),
        const SizedBox(height: 10),
        buildSearchAndSortRow(),
        const SizedBox(height: 10),
        buildDateFilterBar(),

        Row(
          children: [
            Text(
              isMyOrders
                  ? '$totalCount order${totalCount == 1 ? '' : 's'} found'
                  : '$totalCount sold order${totalCount == 1 ? '' : 's'} found',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.tealAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.tealAccent.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                isMyOrders ? 'My Orders' : 'My Sold Products',
                style: const TextStyle(color: Colors.tealAccent, fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (filteredList.isEmpty)
          glassWrap(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  color: Colors.white38,
                  size: 48,
                ),
                const SizedBox(height: 14),
                Text(
                  'No results found for "$searchQuery"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Try searching by order number, product name, buyer name, phone, status, or payment method',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ...filteredList.map(buildOrderCard).toList(),

        buildPaginationControls(),

        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (isLoading) {
      child = buildLoadingView();
    } else if (error != null) {
      child = buildErrorView();
    } else if (orders.isEmpty) {
      child = buildEmptyView();
    } else {
      child = buildLoadedView();
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
            onRefresh: refreshOrders,
            color: Colors.tealAccent,
            backgroundColor: Colors.black,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
  }
}

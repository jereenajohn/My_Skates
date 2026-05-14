import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_skates/ADMIN/admin_orders_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_skates/api.dart';

class ExpiredReturnPolicyProductsPage extends StatefulWidget {
  const ExpiredReturnPolicyProductsPage({super.key});

  @override
  State<ExpiredReturnPolicyProductsPage> createState() =>
      _ExpiredReturnPolicyProductsPageState();
}

class _ExpiredReturnPolicyProductsPageState
    extends State<ExpiredReturnPolicyProductsPage> {
  bool isLoading = true;
  bool isRefreshing = false;
  String? errorMessage;

  List<Map<String, dynamic>> expiredProducts = [];

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchExpiredReturnPolicyProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> openOrderDetailFromExpiredProduct(
    Map<String, dynamic> item,
  ) async {
    try {
      final int orderId =
          int.tryParse(item["order_id"]?.toString() ?? "0") ?? 0;
      final int selectedItemId =
          int.tryParse(item["id"]?.toString() ?? "0") ?? 0;

      if (orderId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid order id"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication token missing"),
            backgroundColor: Colors.redAccent,
          ),
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
        Uri.parse("$api/api/myskates/orders/$orderId/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print("EXPIRED PRODUCT ORDER DETAIL STATUS: ${response.statusCode}");
      print("EXPIRED PRODUCT ORDER DETAIL BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final orderJson = decoded["data"] ?? decoded;

        final order = Order.fromJson(orderJson);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminOrderDetailPage(
              order: order,
              isCoachProductOrder: true,
              selectedItemId: selectedItemId,
            ),
          ),
        );
      } else {
        String message = "Failed to open order detail: ${response.statusCode}";

        try {
          final decoded = jsonDecode(response.body);
          message =
              decoded["message"]?.toString() ??
              decoded["error"]?.toString() ??
              decoded["detail"]?.toString() ??
              message;
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> fetchExpiredReturnPolicyProducts({bool refresh = false}) async {
    try {
      setState(() {
        if (refresh) {
          isRefreshing = true;
        } else {
          isLoading = true;
        }
        errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null || token.isEmpty) {
        setState(() {
          errorMessage = "Authentication token missing";
          isLoading = false;
          isRefreshing = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse("$api/api/myskates/expired/return/policy/products/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("EXPIRED RETURN POLICY STATUS: ${response.statusCode}");
      print("EXPIRED RETURN POLICY BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List data = decoded["data"] is List ? decoded["data"] : [];

        setState(() {
          expiredProducts = data
              .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map),
              )
              .toList();

          isLoading = false;
          isRefreshing = false;
        });
      } else {
        String message = "Failed to fetch products: ${response.statusCode}";

        try {
          final decoded = jsonDecode(response.body);
          message =
              decoded["message"]?.toString() ??
              decoded["error"]?.toString() ??
              decoded["detail"]?.toString() ??
              message;
        } catch (_) {}

        setState(() {
          errorMessage = message;
          isLoading = false;
          isRefreshing = false;
        });
      }
    } catch (e) {
      print("EXPIRED RETURN POLICY ERROR: $e");

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredProducts {
    if (searchQuery.trim().isEmpty) {
      return expiredProducts;
    }

    final query = searchQuery.toLowerCase().trim();

    return expiredProducts.where((item) {
      final orderNo = item["order_no"]?.toString().toLowerCase() ?? "";
      final title = item["product_title"]?.toString().toLowerCase() ?? "";
      final sku = item["variant_sku"]?.toString().toLowerCase() ?? "";

      return orderNo.contains(query) ||
          title.contains(query) ||
          sku.contains(query);
    }).toList();
  }

  String formatDateTime(dynamic value) {
    if (value == null) return "-";

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return "-";

    return DateFormat("dd MMM yyyy, hh:mm a").format(parsed.toLocal());
  }

  String formatCurrency(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? "0") ?? 0;
    return "₹${amount.toStringAsFixed(2)}";
  }

  String imageUrl(dynamic value) {
    final url = value?.toString() ?? "";

    if (url.isEmpty) return "";

    if (url.startsWith("http://") || url.startsWith("https://")) {
      return url;
    }

    return "$api$url";
  }

  Widget glassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding ?? const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              "Expired Return Policy Products",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: isRefreshing
                ? null
                : () => fetchExpiredReturnPolicyProducts(refresh: true),
            icon: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.tealAccent,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.tealAccent),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryCard() {
    return glassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.assignment_late_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Return Policy Expired",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${expiredProducts.length} product${expiredProducts.length == 1 ? '' : 's'} found",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return glassContainer(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: Colors.tealAccent,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Search order no, product, SKU...",
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.tealAccent,
            size: 21,
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
                      searchQuery = "";
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget buildProductImage(String image) {
    if (image.isEmpty) {
      return Container(
        color: Colors.white.withOpacity(0.06),
        child: const Icon(
          Icons.image_not_supported_rounded,
          color: Colors.white38,
          size: 28,
        ),
      );
    }

    return Image.network(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.white.withOpacity(0.06),
          child: const Icon(
            Icons.broken_image_rounded,
            color: Colors.white38,
            size: 28,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return Container(
          color: Colors.white.withOpacity(0.05),
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.tealAccent,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white70,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductCard(Map<String, dynamic> item) {
    final String title = item["product_title"]?.toString() ?? "Product";
    final String orderNo = item["order_no"]?.toString() ?? "-";
    final String sku = item["variant_sku"]?.toString() ?? "-";
    final String image = imageUrl(item["image"]);
    final int quantity = int.tryParse(item["quantity"]?.toString() ?? "0") ?? 0;
    final String price = formatCurrency(item["product_price"]);
    final String sellerPayable = formatCurrency(item["seller_payable"]);
    final String returnDays = item["return_policy_days"]?.toString() ?? "0";
    final String createdAt = formatDateTime(item["created_at"]);
    final String expiryDate = formatDateTime(item["expiry_date"]);

    return GestureDetector(
      onTap: () => openOrderDetailFromExpiredProduct(item),
      child: glassContainer(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Order #$orderNo",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
                    color: Colors.redAccent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.45),
                    ),
                  ),
                  child: const Text(
                    "EXPIRED",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: buildProductImage(image),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "SKU: $sku",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.tealAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.tealAccent.withOpacity(0.30),
                              ),
                            ),
                            child: Text(
                              "Qty: $quantity",
                              style: const TextStyle(
                                color: Colors.tealAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.orangeAccent.withOpacity(0.30),
                              ),
                            ),
                            child: Text(
                              "$returnDays day policy",
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 26),
            infoRow(
              icon: Icons.sell_outlined,
              label: "Product Price",
              value: price,
              valueColor: Colors.white,
            ),
            infoRow(
              icon: Icons.account_balance_wallet_outlined,
              label: "Seller Payable",
              value: sellerPayable,
              valueColor: Colors.tealAccent,
            ),
            infoRow(
              icon: Icons.shopping_bag_outlined,
              label: "Ordered At",
              value: createdAt,
            ),
            infoRow(
              icon: Icons.timer_off_outlined,
              label: "Expired At",
              value: expiryDate,
              valueColor: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoadingView() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (_, __) {
        return glassContainer(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Container(
                height: 18,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildErrorView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),
        glassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 52,
              ),
              const SizedBox(height: 14),
              Text(
                errorMessage ?? "Something went wrong",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => fetchExpiredReturnPolicyProducts(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildEmptyView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        glassContainer(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Icon(
                Icons.verified_rounded,
                color: Colors.tealAccent.withOpacity(0.9),
                size: 58,
              ),
              const SizedBox(height: 14),
              const Text(
                "No expired return policy products",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Products whose return policy has expired will appear here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildLoadedView() {
    final list = filteredProducts;

    return RefreshIndicator(
      onRefresh: () => fetchExpiredReturnPolicyProducts(refresh: true),
      color: Colors.tealAccent,
      backgroundColor: Colors.black,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // buildSummaryCard(),
          buildSearchBar(),
          if (list.isEmpty)
            glassContainer(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    color: Colors.white38,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No results found for "$searchQuery"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ...list.map(buildProductCard).toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (isLoading) {
      body = buildLoadingView();
    } else if (errorMessage != null) {
      body = buildErrorView();
    } else if (expiredProducts.isEmpty) {
      body = buildEmptyView();
    } else {
      body = buildLoadedView();
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                buildHeader(),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

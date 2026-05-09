import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:shimmer/shimmer.dart';

class ReturnRefundProductsScreen extends StatefulWidget {
  const ReturnRefundProductsScreen({super.key});

  @override
  State<ReturnRefundProductsScreen> createState() =>
      _ReturnRefundProductsScreenState();
}

class _ReturnRefundProductsScreenState
    extends State<ReturnRefundProductsScreen> {
  List<RefundProduct> refundProducts = [];
  bool isLoading = true;
  String? error;

  // Pagination variables
  int currentPage = 1;
  int totalPages = 1;
  int totalCount = 0;

  // Search and filter
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;

  final List<String> refundStatusChoices = const [
    "pending",
    "approved",
    "rejected",
    "Waiting For Approval",
  ];

  final Set<int> updatingRefundIds = {};

  // Controllers
  final TextEditingController searchController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  // Filter panel visibility
  bool isFilterPanelOpen = false;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    fetchRefundProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoading && currentPage < totalPages) {
        fetchRefundProducts(loadMore: true);
      }
    }
  }

  Future<void> updateRefundStatus({
    required int refundId,
    required String status,
  }) async {
    if (updatingRefundIds.contains(refundId)) return;

    setState(() {
      updatingRefundIds.add(refundId);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        _showSnackBar("Authentication token missing", isError: true);
        return;
      }

      final uri = Uri.parse("$api/api/myskates/msk/refund/$refundId/");

      print("UPDATE REFUND STATUS URL: $uri");
      print("UPDATE REFUND STATUS BODY: ${jsonEncode({"status": status})}");

      final response = await http.put(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"status": status}),
      );

      print("UPDATE REFUND STATUS CODE: ${response.statusCode}");
      print("UPDATE REFUND STATUS RESPONSE: ${response.body}");

      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 202) {
        final message =
            decoded["message"]?.toString() ??
            "Refund status updated successfully";

        setState(() {
          refundProducts = refundProducts.map((refund) {
            if (refund.id == refundId) {
              return refund.copyWith(status: status);
            }
            return refund;
          }).toList();
        });

        _showSnackBar(message);
      } else {
        _showSnackBar(
          decoded["message"]?.toString() ??
              decoded["error"]?.toString() ??
              "Failed to update refund status",
          isError: true,
        );
      }
    } catch (e) {
      print("ERROR UPDATING REFUND STATUS: $e");
      _showSnackBar(
        "Something went wrong while updating status",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          updatingRefundIds.remove(refundId);
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF00AFA5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> fetchRefundProducts({bool loadMore = false}) async {
    if (loadMore) {
      if (currentPage >= totalPages) return;
      currentPage++;
    } else {
      setState(() {
        isLoading = true;
        error = null;
        refundProducts = [];
        currentPage = 1;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() {
          error = "Authentication token missing";
          isLoading = false;
        });
        return;
      }

      // Build query parameters
      final Map<String, String> queryParams = {};
      queryParams["page"] = currentPage.toString();

      if (searchQuery.trim().isNotEmpty) {
        queryParams["search"] = searchQuery.trim();
      }

      if (startDate != null) {
        queryParams["start_date"] = DateFormat('yyyy-MM-dd').format(startDate!);
      }

      if (endDate != null) {
        queryParams["end_date"] = DateFormat('yyyy-MM-dd').format(endDate!);
      }

      final uri = Uri.parse(
        "$api/api/myskates/msk/refund/product/owner/",
      ).replace(queryParameters: queryParams);

      print("REFUND PRODUCTS API URL: $uri");

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("REFUND PRODUCTS STATUS: ${response.statusCode}");
      print("REFUND PRODUCTS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] == true) {
          final List data = decoded["data"] ?? [];

          setState(() {
            if (loadMore) {
              refundProducts.addAll(
                data.map((item) => RefundProduct.fromJson(item)),
              );
            } else {
              refundProducts = data
                  .map((item) => RefundProduct.fromJson(item))
                  .toList();
            }
            currentPage = decoded["current_page"] ?? currentPage;
            totalPages = decoded["total_pages"] ?? 1;
            totalCount = decoded["count"] ?? 0;
            isLoading = false;
          });
        } else {
          setState(() {
            error = decoded["message"] ?? "Failed to load refund products";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = "Failed to load: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      print("ERROR FETCHING REFUND PRODUCTS: $e");
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    searchQuery = "";
    startDate = null;
    endDate = null;
    searchController.clear();
    startDateController.clear();
    endDateController.clear();
    await fetchRefundProducts();
  }

  Future<void> _applyFilters() async {
    setState(() {
      isFilterPanelOpen = false;
    });
    await fetchRefundProducts();
  }

  Future<void> _clearFilters() async {
    setState(() {
      searchQuery = "";
      startDate = null;
      endDate = null;
      searchController.clear();
      startDateController.clear();
      endDateController.clear();
    });
    await fetchRefundProducts();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() {
        startDate = selected;
        startDateController.text = DateFormat('dd MMM yyyy').format(selected);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() {
        endDate = selected;
        endDateController.text = DateFormat('dd MMM yyyy').format(selected);
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'waiting for approval':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "Pending";
      case 'approved':
        return "Approved";
      case 'rejected':
        return "Rejected";
      case 'waiting for approval':
        return "Waiting For Approval";
      default:
        return status;
    }
  }

  Future<void> _showStatusUpdateSheet(RefundProduct refund) async {
    final selectedStatus = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF001F1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Update Request Status",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Order #${refund.orderNo}",
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 18),

                ...refundStatusChoices.map((status) {
                  final bool isSelected =
                      refund.status.toLowerCase() == status.toLowerCase();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getStatusColor(status).withOpacity(0.18)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? _getStatusColor(status).withOpacity(0.7)
                            : Colors.white12,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => Navigator.pop(context, status),
                      leading: CircleAvatar(
                        radius: 17,
                        backgroundColor: _getStatusColor(
                          status,
                        ).withOpacity(0.18),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _getStatusColor(status),
                          size: 19,
                        ),
                      ),
                      title: Text(
                        _getStatusLabel(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: isSelected
                          ? const Text(
                              "Current",
                              style: TextStyle(
                                color: Colors.tealAccent,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selectedStatus == null) return;

    if (selectedStatus.toLowerCase() == refund.status.toLowerCase()) {
      return;
    }

    await updateRefundStatus(refundId: refund.id, status: selectedStatus);
  }

 Widget _buildExchangeVariantDetails(RefundProduct refund) {
  final details = refund.exchangeVariantDetails;

  if (details == null || refund.remark.toLowerCase() != "exchange") {
    return const SizedBox.shrink();
  }

  return Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.10)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Exchange Item Needed",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),

        Text(
          details.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            // Text(
            //   "Variant ID: ${details.id}",
            //   style: const TextStyle(
            //     color: Colors.white54,
            //     fontSize: 11,
            //   ),
            // ),
            // const SizedBox(width: 12),
            Text(
              "Stock: ${details.stock}",
              style: TextStyle(
                color: details.stock > 0 ? Colors.greenAccent : Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _exchangeInfoRow({
    required String label,
    required String value,
    Color valueColor = Colors.white70,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF001A18),
        highlightColor: const Color(0xFF00AFA5).withOpacity(0.25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildFilterPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isFilterPanelOpen ? 220 : 0,
      child: isFilterPanelOpen
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectStartDate(context),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: startDateController,
                              decoration: InputDecoration(
                                labelText: "Start Date",
                                labelStyle: const TextStyle(
                                  color: Colors.white54,
                                ),
                                hintText: "Select start date",
                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.tealAccent,
                                  size: 18,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white24,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.tealAccent,
                                  ),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectEndDate(context),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: endDateController,
                              decoration: InputDecoration(
                                labelText: "End Date",
                                labelStyle: const TextStyle(
                                  color: Colors.white54,
                                ),
                                hintText: "Select end date",
                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.tealAccent,
                                  size: 18,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white24,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.tealAccent,
                                  ),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Clear All",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AFA5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Apply Filters"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                        fetchRefundProducts();
                      },
                      decoration: const InputDecoration(
                        hintText: "Search by product name, order ID...",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          searchQuery = "";
                        });
                        fetchRefundProducts();
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: isFilterPanelOpen
                  ? const Color(0xFF00AFA5)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                color: isFilterPanelOpen ? Colors.white : Colors.tealAccent,
              ),
              onPressed: () {
                setState(() {
                  isFilterPanelOpen = !isFilterPanelOpen;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$totalCount ${totalCount == 1 ? 'Request' : 'Requests'}",
              style: const TextStyle(color: Colors.tealAccent, fontSize: 12),
            ),
          ),
          const Spacer(),
          if (searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, size: 12, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    searchQuery,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          if (startDate != null || endDate != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range, size: 12, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    "${startDate != null ? DateFormat('dd MMM').format(startDate!) : 'All'} - ${endDate != null ? DateFormat('dd MMM').format(endDate!) : 'All'}",
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefundCard(RefundProduct refund) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
            const Color(0xFF003E38).withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row - Order ID and Status
          Row(
            children: [
              Expanded(
                child: Text(
                  refund.orderNo.isNotEmpty
                      ? "Order #${refund.orderNo}"
                      : "Order ID: ${refund.orderId}",
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
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(refund.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getStatusColor(refund.status).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  _getStatusLabel(refund.status),
                  style: TextStyle(
                    color: _getStatusColor(refund.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product Image and Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: refund.productImage.isNotEmpty
                    ? Image.network(
                        refund.productImage.startsWith("http")
                            ? refund.productImage
                            : "$api${refund.productImage}",
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.white10,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.white38,
                          ),
                        ),
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        color: Colors.white10,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white38,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      refund.productTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (refund.variantLabel.isNotEmpty)
                      Text(
                        refund.variantLabel,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      "Qty: ${refund.quantity}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${refund.amount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    refund.remark.isNotEmpty
                        ? refund.remark
                        : refund.refundType,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          const Divider(color: Colors.white24, height: 20),

          // Reason and Customer Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Reason",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      refund.reason,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Customer",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      refund.customerName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          _buildExchangeVariantDetails(refund),
          const SizedBox(height: 8),

          // Request Date
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.white38),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(refund.requestDate),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: updatingRefundIds.contains(refund.id)
                  ? null
                  : () => _showStatusUpdateSheet(refund),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AFA5),
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: updatingRefundIds.contains(refund.id)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
              label: Text(
                updatingRefundIds.contains(refund.id)
                    ? "Updating..."
                    : "Update Status",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
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
          "Return / Refund Requests",
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
            icon: const Icon(Icons.refresh, color: Colors.tealAccent),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F1D), Color(0xFF003A36), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildSearchBar(), // Moved search bar here
            _buildFilterPanel(),
            _buildStatsBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: Colors.tealAccent,
                backgroundColor: Colors.black,
                child: isLoading && refundProducts.isEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 5,
                        itemBuilder: (_, index) => _buildShimmerCard(),
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
                              onPressed: fetchRefundProducts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      )
                    : refundProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.assignment_return,
                              color: Colors.white38,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No return/refund requests",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchQuery.isNotEmpty ||
                                      startDate != null ||
                                      endDate != null
                                  ? "Try adjusting your filters"
                                  : "When customers request returns or refunds, they'll appear here",
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (searchQuery.isNotEmpty ||
                                startDate != null ||
                                endDate != null)
                              TextButton(
                                onPressed: _clearFilters,
                                child: const Text(
                                  "Clear Filters",
                                  style: TextStyle(color: Colors.tealAccent),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            refundProducts.length +
                            (currentPage < totalPages ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == refundProducts.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.tealAccent,
                                ),
                              ),
                            );
                          }
                          return _buildRefundCard(refundProducts[index]);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model Class for Refund Product
class RefundProduct {
  final int id;
  final int orderId;
  final String orderNo;
  final int productId;
  final String productTitle;
  final String productImage;
  final int variantId;
  final String variantLabel;
  final int quantity;
  final double amount;
  final String refundType;
  final String remark;
  final String reason;
  final String status;
  final String customerName;
  final int customerId;
  final DateTime requestDate;
  final int? exchangeVariant;
  final ExchangeVariantDetails? exchangeVariantDetails;

  RefundProduct({
    required this.id,
    required this.orderId,
    required this.orderNo,
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.variantId,
    required this.variantLabel,
    required this.quantity,
    required this.amount,
    required this.refundType,
    required this.remark,
    required this.reason,
    required this.status,
    required this.customerName,
    required this.customerId,
    required this.requestDate,
    required this.exchangeVariant,
    required this.exchangeVariantDetails,
  });

  RefundProduct copyWith({
    int? id,
    int? orderId,
    String? orderNo,
    int? productId,
    String? productTitle,
    String? productImage,
    int? variantId,
    String? variantLabel,
    int? quantity,
    double? amount,
    String? refundType,
    String? remark,
    String? reason,
    String? status,
    String? customerName,
    int? customerId,
    int? exchangeVariant,
    ExchangeVariantDetails? exchangeVariantDetails,
    DateTime? requestDate,
  }) {
    return RefundProduct(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderNo: orderNo ?? this.orderNo,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productImage: productImage ?? this.productImage,
      variantId: variantId ?? this.variantId,
      variantLabel: variantLabel ?? this.variantLabel,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      refundType: refundType ?? this.refundType,
      remark: remark ?? this.remark,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      exchangeVariant: exchangeVariant ?? this.exchangeVariant,
      exchangeVariantDetails:
          exchangeVariantDetails ?? this.exchangeVariantDetails,
      requestDate: requestDate ?? this.requestDate,
    );
  }

  factory RefundProduct.fromJson(Map<String, dynamic> json) {
    return RefundProduct(
      id: json['id'] ?? 0,
      orderId: json['order'] ?? 0,
      orderNo: json['order_no']?.toString() ?? '',
      productId: json['product'] ?? 0,
      productTitle: json['product_title']?.toString() ?? '',
      productImage: json['product_image']?.toString() ?? '',
      variantId: json['variant'] ?? 0,
      variantLabel: json['variant_name']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      amount: (json['product_price'] ?? 0).toDouble(),
      refundType: json['refund_type']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      customerName: json['customer_name']?.toString() ?? '',
      customerId: json['customer'] ?? 0,
      requestDate:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      exchangeVariant: json["exchange_variant"],
      exchangeVariantDetails: json["exchange_variant_details"] != null
          ? ExchangeVariantDetails.fromJson(json["exchange_variant_details"])
          : null,
    );
  }
}

class ExchangeVariantDetails {
  final int id;
  final String name;
  final int stock;

  ExchangeVariantDetails({
    required this.id,
    required this.name,
    required this.stock,
  });

  factory ExchangeVariantDetails.fromJson(Map<String, dynamic> json) {
    return ExchangeVariantDetails(
      id: json["id"] ?? 0,
      name: json["name"]?.toString() ?? "",
      stock: json["stock"] ?? 0,
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductReviewData {
  final int id;
  final int rating;
  final String review;
  final String userName;
  final String? userImage;
  final String createdAt;
  final int userId;
  final int? productId;
  final String? productName;
  final int variantId;
  final String variantLabel;

  ProductReviewData({
    required this.id,
    required this.rating,
    required this.review,
    required this.userName,
    this.userImage,
    required this.createdAt,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantLabel,
  });

  factory ProductReviewData.fromJson(Map<String, dynamic> json) {
    return ProductReviewData(
      id: json['rating_id'] ?? 0,
      rating: json['rating'] ?? 0,
      review: json['review'] ?? '',
      userName: json['rated_user_name'] ?? 'User',
      userImage: json['rated_user_image'],
      createdAt: json['created_at'] ?? '',
      userId: json['rated_user_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'Product',
      variantId: json['variant_id'] ?? 0,
      variantLabel: json['variant_label'] ?? '',
    );
  }
}

class ProductReviewApprovalPage extends StatefulWidget {
  final int? productId;
  final String? productName;

  const ProductReviewApprovalPage({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<ProductReviewApprovalPage> createState() =>
      _ProductReviewApprovalPageState();
}

class _ProductReviewApprovalPageState extends State<ProductReviewApprovalPage> {
  List<ProductReviewData> _pendingReviews = [];
  List<ProductReviewData> _approvedReviews = [];
  List<ProductReviewData> _rejectedReviews = [];

  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _fetchAllReviews();
  }

  Future<void> _fetchAllReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse("$api/api/myskates/product/ratings/own/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("All product reviews response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        List<dynamic> reviews = [];
        if (jsonResponse is Map && jsonResponse['data'] != null) {
          reviews = jsonResponse['data'] as List;
        } else if (jsonResponse is List) {
          reviews = jsonResponse;
        }

        List<ProductReviewData> pending = [];
        List<ProductReviewData> approved = [];
        List<ProductReviewData> rejected = [];

        for (var review in reviews) {
          final reviewData = ProductReviewData.fromJson(review);

          switch ((review['approval_status'] ?? 'pending')
              .toString()
              .toLowerCase()) {
            case 'approved':
              approved.add(reviewData);
              break;
            case 'rejected':
              rejected.add(reviewData);
              break;
            default:
              pending.add(reviewData);
          }
        }

        setState(() {
          _pendingReviews = pending;
          _approvedReviews = approved;
          _rejectedReviews = rejected;
          _isLoading = false;
        });

        print(
          "Pending: ${pending.length}, Approved: ${approved.length}, Rejected: ${rejected.length}",
        );
      } else {
        print("Error response: ${response.statusCode}");
        print("Error body: ${response.body}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching reviews: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateReviewStatus(int reviewId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) return;

      final url = Uri.parse("$api/api/myskates/products/rating/$reviewId/");

      final response = await http.patch(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"approval_status": status}),
      );

      print("Update response: ${response.body}");
      print("Status Code: ${response.statusCode}");
      print("URL: $url");

      if (response.statusCode == 200) {
        String message = status == 'approved' ? "approved" : "rejected";
        Color bgColor = status == 'approved' ? Colors.teal : Colors.orange;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: bgColor,
            content: Text(
              "Review $message successfully",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );

        await _fetchAllReviews();

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update review: ${response.body}")),
        );
      }
    } catch (e) {
      print("Update Status Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showApprovalDialog(int reviewId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF06201A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Approve Review?",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Approve review from $userName? This will make it visible to all customers.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text(
                "Approve",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _updateReviewStatus(reviewId, 'approved');
              },
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(int reviewId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF06201A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Reject Review?",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Reject review from $userName? This will hide it from customers.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text(
                "Reject",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _updateReviewStatus(reviewId, 'rejected');
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return "${(difference.inDays / 365).floor()}y ago";
      } else if (difference.inDays > 30) {
        return "${(difference.inDays / 30).floor()}mo ago";
      } else if (difference.inDays > 0) {
        return "${difference.inDays}d ago";
      } else if (difference.inHours > 0) {
        return "${difference.inHours}h ago";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes}m ago";
      } else {
        return "Just now";
      }
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.teal;
      case 'rejected':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Review Approvals",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "All Your Product Reviews",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAllReviews,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00332D), Colors.black],
          ),
        ),
        child: Column(
          children: [
            // Tab Bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _buildTabButton("Pending", _pendingReviews.length, 0),
                  _buildTabButton("Approved", _approvedReviews.length, 1),
                  _buildTabButton("Rejected", _rejectedReviews.length, 2),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.teal),
                    )
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int count, int tabIndex) {
    final isSelected = _selectedTab == tabIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tabIndex;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00AFA5) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : _getStatusColor(title.toLowerCase()).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF00AFA5)
                          : _getStatusColor(title.toLowerCase()),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    List<ProductReviewData> currentList;
    String emptyMessage;

    switch (_selectedTab) {
      case 0:
        currentList = _pendingReviews;
        emptyMessage = "No pending reviews";
        break;
      case 1:
        currentList = _approvedReviews;
        emptyMessage = "No approved reviews";
        break;
      case 2:
        currentList = _rejectedReviews;
        emptyMessage = "No rejected reviews";
        break;
      default:
        currentList = [];
        emptyMessage = "";
    }

    if (currentList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTab == 0
                  ? Icons.pending_actions
                  : _selectedTab == 1
                  ? Icons.check_circle
                  : Icons.cancel,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentList.length,
      itemBuilder: (context, index) {
        final review = currentList[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(ProductReviewData review) {
    final isPending = _selectedTab == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(
            isPending
                ? 'pending'
                : _selectedTab == 1
                ? 'approved'
                : 'rejected',
          ).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: review.userImage != null
                    ? NetworkImage(review.userImage!)
                    : const AssetImage("lib/assets/placeholder.png")
                          as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    if ((review.productName ?? '').isNotEmpty)
                      Text(
                        review.productName!,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFF00AFA5),
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              isPending
                                  ? 'pending'
                                  : _selectedTab == 1
                                  ? 'approved'
                                  : 'rejected',
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedTab == 0
                                ? "PENDING"
                                : _selectedTab == 1
                                ? "APPROVED"
                                : "REJECTED",
                            style: TextStyle(
                              color: _getStatusColor(
                                isPending
                                    ? 'pending'
                                    : _selectedTab == 1
                                    ? 'approved'
                                    : 'rejected',
                              ),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (review.variantLabel.isNotEmpty)
                      Text(
                        "Variant: ${review.variantLabel}",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Review Text
          if (review.review.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review.review,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Date and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),

              if (isPending)
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () =>
                          _showApprovalDialog(review.id, review.userName),
                      child: const Text(
                        "Approve",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () =>
                          _showRejectDialog(review.id, review.userName),
                      child: const Text(
                        "Reject",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

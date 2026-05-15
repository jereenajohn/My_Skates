import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PendingRatingData {
  final int id;
  final int rating;
  final String review;
  final String userName;
  final String? userImage;
  final String createdAt;
  final int userId;

  PendingRatingData({
    required this.id,
    required this.rating,
    required this.review,
    required this.userName,
    this.userImage,
    required this.createdAt,
    required this.userId,
  });

  factory PendingRatingData.fromJson(Map<String, dynamic> json) {
    return PendingRatingData(
      id: json['id'] ?? 0,
      rating: json['rating'] ?? 0,
      review: json['review'] ?? '',
      userName: json['user_name'] ?? 'User ${json['user']}',
      userImage: json['user_image'],
      createdAt: json['created_at'] ?? '',
      userId: json['user'] ?? 0,
    );
  }
}

class ClubRatingApprovalPage extends StatefulWidget {
  final int clubId;
  final String clubName;

  const ClubRatingApprovalPage({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubRatingApprovalPage> createState() => _ClubRatingApprovalPageState();
}

class _ClubRatingApprovalPageState extends State<ClubRatingApprovalPage> {
  List<PendingRatingData> _pendingRatings = [];
  List<PendingRatingData> _approvedRatings = [];
  List<PendingRatingData> _rejectedRatings = [];

  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _fetchAllRatings();
  }

  Future<void> _fetchAllRatings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) return;

      final response = await http.get(
        Uri.parse("$api/api/myskates/club/rating/${widget.clubId}/"),
        headers: {"Authorization": "Bearer $token"},
      );
      print("responseee ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> ratings = jsonDecode(response.body);

        List<PendingRatingData> pending = [];
        List<PendingRatingData> approved = [];
        List<PendingRatingData> rejected = [];

        for (var rating in ratings) {
         
          String userName = '';
          String? firstName = rating['user_first_name'] as String?;
          String? lastName = rating['user_last_name'] as String?;

          
          if (firstName != null &&
              firstName.isNotEmpty &&
              lastName != null &&
              lastName.isNotEmpty) {
            userName = '$firstName $lastName';
          } else if (firstName != null && firstName.isNotEmpty) {
            userName = firstName;
          } else if (lastName != null && lastName.isNotEmpty) {
            userName = lastName;
          } else {
            String? username = rating['username'] as String?;
            userName = username ?? 'User ${rating['user']}';
          }

          String? userImage = rating['profile'] as String?;
          print("userimageee $userImage");

          if (userImage != null && userImage.isNotEmpty) {
            if (!userImage.startsWith('http')) {
              userImage = userImage.startsWith('/')
                  ? "$api$userImage"
                  : "$api/$userImage";
            }
          } else {
            userImage = rating['user_image'] as String?;
            if (userImage != null && userImage.isNotEmpty) {
              if (!userImage.startsWith('http')) {
                userImage = userImage.startsWith('/')
                    ? "$api$userImage"
                    : "$api/$userImage";
              }
            }
          }

          final ratingData = PendingRatingData(
            id: rating['id'] ?? 0,
            rating: rating['rating'] ?? 0,
            review: rating['review'] ?? '',
            userName: userName,
            userImage: userImage,
            createdAt: rating['created_at'] ?? '',
            userId: rating['user'] ?? 0,
          );

          switch (rating['approval_status'] ?? 'pending') {
            case 'approved':
              approved.add(ratingData);
              break;
            case 'rejected':
              rejected.add(ratingData);
              break;
            case 'pending':
            default:
              pending.add(ratingData);
              break;
          }
        }

        setState(() {
          _pendingRatings = pending;
          _approvedRatings = approved;
          _rejectedRatings = rejected;
          _isLoading = false;
        });

        // Print to verify data
        print(
          "Pending: ${pending.length}, Approved: ${approved.length}, Rejected: ${rejected.length}",
        );
        if (pending.isNotEmpty) {
          print(
            "First pending user: ${pending.first.userName}, image: ${pending.first.userImage}",
          );
        }
      } else {
        print("Error response: ${response.statusCode}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching ratings: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRatingStatus(int ratingId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) return;

      final url = Uri.parse("$api/api/myskates/club/rating/update/$ratingId/");

      final response = await http.patch(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"approval_status": status}),
      );
      print("resposeee ${response.body}");
      if (response.statusCode == 200) {
        String message = status == 'approved' ? "approved" : "rejected";
        Color bgColor = status == 'approved' ? Colors.teal : Colors.orange;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: bgColor,
            content: Text(
              "Rating $message successfully",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );

        _fetchAllRatings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update rating: ${response.body}")),
        );
      }
    } catch (e) {
      print("Update Status Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showApprovalDialog(int ratingId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF06201A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Approve Rating?",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Approve rating from $userName? This will make it visible to all students.",
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
                _updateRatingStatus(ratingId, 'approved');
              },
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(int ratingId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF06201A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Reject Rating?",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Reject rating from $userName? This will hide it from students.",
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
                _updateRatingStatus(ratingId, 'rejected');
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
        backgroundColor: Color(0xFF00332D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Rating Approvals",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.clubName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAllRatings,
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
                  _buildTabButton("Pending", _pendingRatings.length, 0),
                  _buildTabButton("Approved", _approvedRatings.length, 1),
                  _buildTabButton("Rejected", _rejectedRatings.length, 2),
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
    List<PendingRatingData> currentList;
    String emptyMessage;

    switch (_selectedTab) {
      case 0:
        currentList = _pendingRatings;
        emptyMessage = "No pending ratings";
        break;
      case 1:
        currentList = _approvedRatings;
        emptyMessage = "No approved ratings";
        break;
      case 2:
        currentList = _rejectedRatings;
        emptyMessage = "No rejected ratings";
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
        final rating = currentList[index];
        return _buildRatingCard(rating);
      },
    );
  }

  Widget _buildRatingCard(PendingRatingData rating) {
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
                backgroundImage: rating.userImage != null
                    ? NetworkImage(rating.userImage!)
                    : const AssetImage("lib/assets/placeholder.png")
                          as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < rating.rating ? Icons.star : Icons.star_border,
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
                  ],
                ),
              ),
            ],
          ),

          // Review Text
          if (rating.review.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rating.review,
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
                _formatDate(rating.createdAt),
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
                          _showApprovalDialog(rating.id, rating.userName),
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
                          _showRejectDialog(rating.id, rating.userName),
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

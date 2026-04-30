import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_skates/api.dart';

class StudentProductReviewpage extends StatefulWidget {
  final int productId;
  final String productTitle;
  final String? productImage;
  final int variantId;
  final String? variantImage;
  final String variantLabel;

  const StudentProductReviewpage({
    super.key,
    required this.productId,
    required this.productTitle,
    this.productImage,
    required this.variantId,
    this.variantImage,
    required this.variantLabel,
  });

  @override
  State<StudentProductReviewpage> createState() =>
      _StudentProductReviewpageState();
}

class _StudentProductReviewpageState extends State<StudentProductReviewpage> {
  double _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitted = false;
  bool _isLoading = false;
  bool _hasExistingReview = false;
  bool _isCheckingReview = true;
  Map<String, dynamic>? _existingReview;

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  Future<void> _checkExistingReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt('user_id') ?? prefs.getInt('id');

      if (token == null || userId == null) {
        setState(() {
          _isCheckingReview = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$api/api/myskates/products/${widget.productId}/ratings/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Fetched reviews status: ${response.statusCode}');
      print('Fetched reviews body: ${response.body}');
      print('Current user ID: $userId');
      print('Current product ID: ${widget.productId}');
      print('Current variant ID: ${widget.variantId}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> reviews = [];

        if (responseData is List) {
          reviews = responseData;
        } else if (responseData is Map) {
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            reviews = responseData['data'];
          } else if (responseData.containsKey('results') &&
              responseData['results'] is List) {
            reviews = responseData['results'];
          } else {
            reviews = responseData.values.whereType<Map>().toList();
          }
        }

        final userReview = reviews.cast<Map>().firstWhere((review) {
          final dynamic userField = review['user'];
          int reviewUserId = 0;

          if (userField is Map) {
            reviewUserId = userField['id'] ?? 0;
          } else {
            reviewUserId = userField ?? 0;
          }

          final int reviewProductId = review['product'] ?? 0;

          return reviewUserId == userId && reviewProductId == widget.productId;
        }, orElse: () => {});

        if (userReview.isNotEmpty) {
          setState(() {
            _hasExistingReview = true;
            _existingReview = Map<String, dynamic>.from(userReview);
            _selectedRating = (userReview['rating'] ?? 0).toDouble();
            _reviewController.text = userReview['review'] ?? '';
          });
        } else {
          print('No existing review found for this user and product');
        }
      } else {
        print('Failed to fetch reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking existing review: $e');
      print('Stack trace: ${StackTrace.current}');
    }

    if (mounted) {
      setState(() {
        _isCheckingReview = false;
      });
    }
  }

  Future<void> _submitReview() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to submit a review'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_hasExistingReview) {
        setState(() {
          _isSubmitted = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already reviewed this product'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final url = '$api/api/myskates/products/${widget.productId}/ratings/';

      final Map<String, dynamic> reviewData = {
        'rating': _selectedRating,
        'review': _reviewController.text.trim(),
        'variant': widget.variantId,
      };

      print('Submitting to URL: $url');
      print('Review data: $reviewData');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(reviewData),
      );

      print('Review API Status: ${response.statusCode}');
      print('Review API Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _isSubmitted = true;
          _hasExistingReview = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await _checkExistingReview();

        setState(() {
          _isLoading = false;
          _isSubmitted = true;
          _hasExistingReview = true;
        });
      } else {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Failed to submit review';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          }

          if (response.statusCode == 400 &&
              (errorMessage.contains('already') ||
                  errorMessage.contains('exists'))) {
            setState(() {
              _hasExistingReview = true;
              _isSubmitted = true;
            });
          }
        } catch (e) {
          print("Error parsing review submit response: $e");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error submitting review: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _goBack() {
    Navigator.pop(context, _isSubmitted || _hasExistingReview);
  }

  int? get _ratingId {
    if (_existingReview == null) return null;
    return _existingReview!["id"];
  }

  Future<void> _updateMyReview({
    required double rating,
    required String review,
  }) async {
    final id = _ratingId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Review id not found"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.put(
      Uri.parse("$api/api/myskates/products/rating/$id/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "rating": rating.toInt(),
        "review": review,
        "variant": widget.variantId,
      }),
    );

    print("UPDATE STATUS: ${res.statusCode}");
    print("UPDATE RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      setState(() {
        _selectedRating = rating;
        _reviewController.text = review;
        _hasExistingReview = true;
        _isSubmitted = true;
        _existingReview = {
          ...?_existingReview,
          "rating": rating.toInt(),
          "review": review,
          "variant": widget.variantId,
        };
      });

      await _checkExistingReview();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Review updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Update failed: ${res.body}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteMyReview() async {
    final id = _ratingId;
    if (id == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.delete(
      Uri.parse("$api/api/myskates/products/rating/$id/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 204 || res.statusCode == 200) {
      setState(() {
        _hasExistingReview = false;
        _existingReview = null;
        _isSubmitted = false;
        _selectedRating = 0;
        _reviewController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Review deleted"),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Delete failed: ${res.body}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditReviewDialog() {
    double tempRating = _selectedRating;
    final tempCtrl = TextEditingController(text: _reviewController.text);

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111111),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: const Text(
                "Edit Review",
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              tempRating = (i + 1).toDouble();
                            });
                          },
                          icon: Icon(
                            i < tempRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 30,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: tempCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Update your review...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                  ),
                  onPressed: () async {
                    if (tempRating == 0 || tempCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    await _updateMyReview(
                      rating: tempRating,
                      review: tempCtrl.text.trim(),
                    );
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteReview() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          "Delete Review?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete your review?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMyReview();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool disableInput = _isSubmitted || _hasExistingReview || _isLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _goBack,
        ),
        title: Text(
          _hasExistingReview ? 'Your Review' : 'Write a Review',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          if (_hasExistingReview && _existingReview != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: const Color(0xFF1A1A1A),
              onSelected: (value) {
                if (value == "edit") {
                  _showEditReviewDialog();
                } else if (value == "delete") {
                  _confirmDeleteReview();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: "edit",
                  child: Text("Edit", style: TextStyle(color: Colors.white)),
                ),
                PopupMenuItem(
                  value: "delete",
                  child: Text(
                    "Delete",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isCheckingReview
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  if (_isSubmitted || _hasExistingReview)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _hasExistingReview
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hasExistingReview
                              ? Colors.orange.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _hasExistingReview
                                  ? Colors.orange
                                  : Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _hasExistingReview ? Icons.info : Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hasExistingReview
                                      ? 'You have already reviewed this product'
                                      : 'Thank you for your Review!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Text(
                    'Rate this product',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: disableInput
                                ? null
                                : () {
                                    setState(() {
                                      _selectedRating = index + 1.0;
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                index < _selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 40,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Write your review',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    enabled: !disableInput,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _hasExistingReview
                          ? 'Your review is already submitted'
                          : 'Share your experience about this product...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (!_isSubmitted && !_hasExistingReview)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_selectedRating == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a rating'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                if (_reviewController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please write a review'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                _submitReview();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Review',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}

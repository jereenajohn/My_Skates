import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_skates/api.dart';

class ProductReviewPage extends StatefulWidget {
  final int productId;
  final String productTitle;
  final String? productImage;
  final int variantId;
  final String? variantImage;
  final String variantLabel;

  const ProductReviewPage({
    super.key,
    required this.productId,
    required this.productTitle,
    this.productImage,
    required this.variantId,
    this.variantImage,
    required this.variantLabel,
  });

  @override
  State<ProductReviewPage> createState() => _ProductReviewPageState();
}

class _ProductReviewPageState extends State<ProductReviewPage> {
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
      final userId = prefs.getInt('user_id');

      if (token == null) return;

      final response = await http.get(
        Uri.parse('$api/api/myskates/products/${widget.productId}/ratings/'),
        headers: {'Authorization': 'Bearer $token'},
      );

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

        print('Fetched reviews: $reviews');
        print('Current user ID: $userId');
        print('Current variant ID: ${widget.variantId}');

        if (userId != null) {
          final userReview = reviews.firstWhere((review) {
            int reviewUserId;
            if (review is Map) {
              if (review['user'] is Map) {
                reviewUserId = review['user']['id'] ?? 0;
              } else {
                reviewUserId = review['user'] ?? 0;
              }

              int reviewVariantId = review['variant'] ?? 0;

              
              print(
                "Review Variant: $reviewVariantId  Widget Variant: ${widget.variantId}",
              );

              return reviewUserId == userId &&
                  reviewVariantId == widget.variantId;
            }
            return false;
          }, orElse: () => null);

          if (userReview != null) {
            setState(() {
              _hasExistingReview = true;
              _existingReview = userReview;

              _selectedRating = (userReview['rating'] ?? 0).toDouble();
              _reviewController.text = userReview['review'] ?? '';
            });

            print('Found existing review: $userReview');
          } else {
            print('No existing review found for this user and variant');
          }
        }
      } else {
        print('Failed to fetch reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking existing review: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    setState(() {
      _isCheckingReview = false;
    });
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

      Map<String, dynamic> reviewData = {
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

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
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
        } catch (e) {}

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

  @override
  Widget build(BuildContext context) {
    bool disableInput = _isSubmitted || _hasExistingReview || _isLoading;

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Success/Info Message
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
                          const SizedBox(height: 4),
                          Text(
                            _hasExistingReview
                                ? 'You cannot submit another review for this variant'
                                : 'Your feedback helps us improve',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Rating Section
            const Text(
              'Rate this product',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // 5 Star Rating
            Center(
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

            const SizedBox(height: 24),

            // Review Text Field
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

            // Submit Button or Already Reviewed Message
            if (!_isSubmitted && !_hasExistingReview)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          // Validation
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

                          // Submit to API
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
              )
            else if (_hasExistingReview || _isSubmitted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      _hasExistingReview
                          ? Icons.info_outline
                          : Icons.check_circle,
                      color: _hasExistingReview ? Colors.orange : Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasExistingReview
                          ? 'You have already reviewed this product'
                          : 'Review submitted successfully',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _goBack,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Go Back'),
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
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}

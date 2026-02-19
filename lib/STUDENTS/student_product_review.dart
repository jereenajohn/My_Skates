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
  State<StudentProductReviewpage> createState() => _StudentProductReviewpageState();
}

class _StudentProductReviewpageState extends State<StudentProductReviewpage> {
  double _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitted = false;
  bool _isLoading = false;


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
        } catch (e) {
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
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

   Future<void> _fetchProductReviews() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    
    final response = await http.get(
      Uri.parse('$api/api/myskates/products/${widget.productId}/ratings/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Existing reviews: $data');
    }
  } catch (e) {
    print('Error fetching reviews: $e');
  }
}
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Write a Review',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            
            if (_isSubmitted)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thank you for your review!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your feedback helps us improve',
                            style: TextStyle(
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
                    onTap: (_isSubmitted || _isLoading) ? null : () { 
                      setState(() {
                        _selectedRating = index + 1.0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        index < _selectedRating ? Icons.star : Icons.star_border,
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
              enabled: !_isSubmitted && !_isLoading,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Share your experience about this product...',
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
            if (!_isSubmitted)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
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
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You have already reviewed this product',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
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
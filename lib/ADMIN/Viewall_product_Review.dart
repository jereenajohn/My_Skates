import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';

class Viewall_Product_Review extends StatefulWidget {
  final int productId;

  const Viewall_Product_Review({super.key, required this.productId});

  @override
  State<Viewall_Product_Review> createState() => _Viewall_Product_ReviewState();
}

class _Viewall_Product_ReviewState extends State<Viewall_Product_Review> {
  List reviews = [];
  bool loading = true;
  double averageRating = 0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse('$api/api/myskates/products/${widget.productId}/ratings/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List fetched = [];

        if (data is List) {
          fetched = data;
        } else if (data is Map && data['data'] != null) {
          fetched = data['data'];
        }

        double total = 0;
        for (var r in fetched) {
          total += (r["rating"] ?? 0);
        }

        setState(() {
          reviews = fetched;
          totalReviews = fetched.length;
          averageRating = fetched.isNotEmpty ? total / fetched.length : 0;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("All Reviews"),
        backgroundColor: Colors.black,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : Column(
              children: [
                // ================= SUMMARY =================
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.greenAccent.withOpacity(.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => Icon(
                                    index < averageRating.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.greenAccent,
                                    size: 18,
                                  ),
                                ),
                              ),
                              Text(
                                "$totalReviews reviews",
                                style: const TextStyle(
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ================= REVIEW LIST =================
                Expanded(
                  child: reviews.isEmpty
                      ? const Center(
                          child: Text(
                            "No reviews yet",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            final r = reviews[index];

                            String name =
                                "${r['user_first_name'] ?? ''} ${r['user_last_name'] ?? ''}"
                                    .trim();
                            if (name.isEmpty) {
                              name = r['user_name'] ?? "Anonymous";
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111111),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.greenAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // NAME + RATING
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            i < (r["rating"] ?? 0)
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 14,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // COMMENT
                                  Text(
                                    r["review"] ?? "",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
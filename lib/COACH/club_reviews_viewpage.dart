import 'package:flutter/material.dart';
import 'package:my_skates/COACH/club_detailed_view.dart';

class Club_reviewspage extends StatelessWidget {
  final int clubId;
  final List<RatingData> ratings;

  const Club_reviewspage({
    Key? key,
    required this.clubId,
    required this.ratings,
  }) : super(key: key);

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
        title: const Text(
          "All Reviews",
          style: TextStyle(color: Colors.white),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white24,
            height: 0.5,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00332D), Colors.black],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final rating = ratings[index];
            return _buildReviewCard(rating);
          },
        ),
      ),
    );
  }

  Widget _buildReviewCard(RatingData rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00AFA5).withOpacity(0.2),
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
                            i < rating.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFF00AFA5),
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(rating.createdAt),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
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
                color: Colors.black26,
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
        ],
      ),
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
}
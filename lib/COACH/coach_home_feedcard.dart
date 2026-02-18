import 'package:flutter/material.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/widgets/coachfeedcommentsheet.dart';

class CoachHomeFeedCard extends StatelessWidget {
  final Map<String, dynamic> feed;
  final Function(int) onLike;
  final Function(int) onRepost;

  const CoachHomeFeedCard({
    super.key,
    required this.feed,
    required this.onLike,
    required this.onRepost,
  });

  static const Color accentColor = Color(0xFF2EE6A6);

  @override
  Widget build(BuildContext context) {
    // Check if it's a repost - with null safety
    final bool isRepost = feed.containsKey('repost_id') && feed['repost_id'] != null;
    
    // Safely get the original feed data
    Map<String, dynamic> originalFeed;
    
    if (isRepost) {
      // Handle repost case with proper type checking
      final feedData = feed['feed'];
      if (feedData is Map<String, dynamic>) {
        originalFeed = feedData;
      } else if (feedData is Map) {
        // Convert if it's a Map but not typed
        originalFeed = Map<String, dynamic>.from(feedData);
      } else {
        // If it's not a map (like an int), create empty map
        originalFeed = {};
      }
    } else {
      originalFeed = feed;
    }
    
    // Safely get feedId with type checking
    final int feedId;
    if (isRepost) {
      feedId = originalFeed['id'] is int 
          ? originalFeed['id'] 
          : (originalFeed['id']?.toString().isEmpty ?? true ? 0 : int.tryParse(originalFeed['id'].toString()) ?? 0);
    } else {
      feedId = feed['id'] is int 
          ? feed['id'] 
          : (feed['id']?.toString().isEmpty ?? true ? 0 : int.tryParse(feed['id'].toString()) ?? 0);
    }

    final String caption = (originalFeed["description"] ?? "").toString();
    final List images = originalFeed["feed_image"] is List 
        ? originalFeed["feed_image"] 
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRepost) _repostHeader(),
        _header(originalFeed),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
        if (images.isNotEmpty) ...[
          const SizedBox(height: 10),
          _feedImage(images),
        ],
        _actions(context, feedId, originalFeed),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Colors.white12),
      ],
    );
  }

  Widget _repostHeader() {
    final reposterName = feed['reposted_by'] is Map 
        ? (feed['reposted_by']['first_name'] ?? 'User')
        : 'User';
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          const Icon(
            Icons.repeat,
            color: accentColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$reposterName reposted',
            style: const TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(Map<String, dynamic> feedData) {
    // Get user data with proper type checking
    final userData = feedData["user"] is Map 
        ? Map<String, dynamic>.from(feedData["user"]) 
        : <String, dynamic>{};
    
    String name = "";
    if (userData.isNotEmpty) {
      name = "${userData["first_name"] ?? ""} ${userData["last_name"] ?? ""}".trim();
    }
    if (name.isEmpty) name = "Coach";
    
    String userType = userData["user_type"] ?? "Coach";
    
    String profileUrl = "";
    if (userData["profile"] != null) {
      profileUrl = userData["profile"].toString();
    }
    
    if (profileUrl.isNotEmpty && !profileUrl.startsWith("http")) {
      profileUrl = "$api$profileUrl";
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white12,
            backgroundImage:
                profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
            child: profileUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white70, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  userType,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _feedImage(List images) {
    String imgUrl = "";
    
    if (images.isNotEmpty) {
      final imageData = images.first;
      final String? raw = imageData is Map ? imageData["image"]?.toString() : imageData.toString();
      imgUrl = (raw != null && raw.startsWith("http")) ? raw : "$api$raw";
    }

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: imgUrl.isNotEmpty
          ? Image.network(
              imgUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            )
          : _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image,
        color: Colors.white54,
        size: 40,
      ),
    );
  }

  Widget _actions(BuildContext context, int feedId, Map<String, dynamic> feedData) {
    final bool isLiked = feedData["is_liked"] == true;
    final int likes = feedData["likes_count"] ?? 0;
    final bool isReposted = feedData["is_reposted"] == true;
    final int reposts = feedData["shares_count"] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          InkWell(
            onTap: () => onLike(feedId),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.redAccent : Colors.white70,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    likes.toString(),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: () => onRepost(feedId),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Icon(
                    isReposted ? Icons.repeat : Icons.repeat_outlined,
                    color: isReposted ? accentColor : Colors.white70,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    reposts.toString(),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => FeedCommentsSheet(feedId: feedId),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.mode_comment_outlined,
                color: Colors.white70,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_skates/Providers/coach_homepage_feed_provider.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/widgets/coachfeedcommentsheet.dart';
// If you have repost sheet like RepostComposerSheet, import it here too.

class HomeFeedCard extends StatelessWidget {
  final Map<String, dynamic> feed;

  const HomeFeedCard({super.key, required this.feed});

  static const Color accentColor = Color(0xFF2EE6A6);

  @override
  Widget build(BuildContext context) {
    final String caption = (feed["description"] ?? "").toString();
    final List images = feed["feed_image"] is List ? feed["feed_image"] : [];

    // IMPORTANT: Home feed should NOT render repost wrapper.
    // So we ignore feed["feed"] or repost fields.

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),

          if (caption.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              caption,
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ],

          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            _feedImage(images),
          ],

          const SizedBox(height: 10),
          _actions(context),
        ],
      ),
    );
  }

  Widget _header() {
    final String first = (feed["first_name"] ?? "").toString();
    final String last = (feed["last_name"] ?? "").toString();
    final String name = ("$first $last").trim().isEmpty
        ? "User"
        : "$first $last".trim();

    final String? profile = feed["profile_image"]?.toString();
    final String profileUrl = (profile != null && profile.isNotEmpty)
        ? "$api$profile"
        : "";

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white12,
          backgroundImage: profileUrl.isNotEmpty
              ? NetworkImage(profileUrl)
              : null,
          child: profileUrl.isEmpty
              ? const Icon(Icons.person, color: Colors.white70, size: 18)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _feedImage(List images) {
    final String? raw = images.first["image"]?.toString();
    final String imgUrl = (raw != null && raw.startsWith("http"))
        ? raw
        : "$api$raw";

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imgUrl,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 220,
          color: Colors.black26,
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image,
            color: Colors.white54,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final int feedId = feed["id"];
    final bool isLiked = feed["is_liked"] == true;
    final int likes = feed["likes_count"] ?? 0;

    return Row(
      children: [
        IconButton(
          onPressed: () {
            context.read<HomeFeedProvider>().toggleLike(feedId);
          },
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.redAccent : Colors.white70,
          ),
        ),
        Text(likes.toString(), style: const TextStyle(color: Colors.white70)),

        const SizedBox(width: 12),

        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => FeedCommentsSheet(feedId: feedId),
            );
          },
          icon: const Icon(Icons.mode_comment_outlined, color: Colors.white70),
        ),

        IconButton(
          onPressed: () {
            context.read<HomeFeedProvider>().repostFeed(
              context: context,
              feedId: feedId,
            );
          },
          icon: const Icon(Icons.repeat, color: Color(0xFF2EE6A6)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:my_skates/Providers/coach_feed_provider.dart';
import 'package:my_skates/widgets/coach_repost_composer_sheet.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),

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

        _actions(context),

        // subtle separator between posts
        const SizedBox(height: 12),
        const Divider(height: 1, color: Colors.white12),
      ],
    );
  }

  // ───────────────── HEADER ─────────────────
Widget _header() {
  final String name =
      (feed["user_name"] ?? "").toString().trim().isEmpty
          ? "User"
          : feed["user_name"].toString();

  /// ✅ Try multiple possible keys safely
  String profileUrl = "";

  if (feed["profile_image"] != null) {
    profileUrl = feed["profile_image"].toString();
  } else if (feed["user_profile"]?["image"] != null) {
    profileUrl = feed["user_profile"]["image"].toString();
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
        const Icon(Icons.more_vert, color: Colors.white54),
      ],
    ),
  );
}


  // ───────────────── IMAGE (EDGE-TO-EDGE) ─────────────────
  Widget _feedImage(List images) {
    final String? raw = images.first["image"]?.toString();
    final String imgUrl =
        (raw != null && raw.startsWith("http")) ? raw : "$api$raw";

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Image.network(
        imgUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
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

  // ───────────────── ACTIONS ─────────────────
  Widget _actions(BuildContext context) {
    final int feedId = feed["id"];
    final bool isLiked = feed["is_liked"] == true;
    final int likes = feed["likes_count"] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              context.read<HomeFeedProvider>().toggleLike(feedId);
            },
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

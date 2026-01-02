import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coach_feed_provider.dart';

class RepostComposerSheet extends StatefulWidget {
  final int feedId;
  final Map<String, dynamic> feed;
  final CoachFeedProvider feedProvider;

  const RepostComposerSheet({
    super.key,
    required this.feedId,
    required this.feed,
    required this.feedProvider,
  });

  @override
  State<RepostComposerSheet> createState() => _RepostComposerSheetState();
}

class _RepostComposerSheetState extends State<RepostComposerSheet> {
  final TextEditingController controller = TextEditingController();
  bool posting = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _feedPreview() {
    final List images = widget.feed["feed_image"] is List
        ? widget.feed["feed_image"]
        : [];

    if (images.isEmpty) return const SizedBox.shrink();

    final imageUrl = images.first["image"];
    if (imageUrl == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Icon(Icons.drag_handle, color: Colors.white38)),

          const SizedBox(height: 12),

          TextField(
            controller: controller,
            maxLines: null,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Add a caption…",
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
          ),

          const Divider(color: Colors.white12),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((widget.feed["description"] ?? "").toString().isNotEmpty)
                    Text(
                      widget.feed["description"],
                      style: const TextStyle(color: Colors.white70),
                    ),

                  _feedPreview(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2EE6A6),
              ),
              onPressed: posting
                  ? null
                  : () async {
                      final text = controller.text.trim();

                      if (text.isEmpty) {
                        Navigator.pop(context); // plain repost
                        await widget.feedProvider.toggleRepost(widget.feedId);
                        return;
                      }

                      setState(() => posting = true);

                      await widget.feedProvider.repostWithText(
                        feedId: widget.feedId,
                        text: text,
                      );

                      Navigator.pop(context);
                    },

              child: Text(
                posting ? "Posting..." : "Repost",
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

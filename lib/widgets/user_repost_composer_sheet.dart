import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coach_feed_provider.dart';

class UserRepostComposerSheet extends StatefulWidget {
  final int feedId;
  final Map<String, dynamic> feed;
  final CoachFeedProvider feedProvider;

  // 🔹 OPTIONAL — used only for edit
  final bool isEdit;
  final int? repostId;
  final String? initialText;

  const UserRepostComposerSheet({
    super.key,
    required this.feedId,
    required this.feed,
    required this.feedProvider,
    this.isEdit = false,
    this.repostId,
    this.initialText,
  });

  @override
  State<UserRepostComposerSheet> createState() => _UserRepostComposerSheetState();
}

class _UserRepostComposerSheetState extends State<UserRepostComposerSheet> {
  final TextEditingController controller = TextEditingController();
  bool posting = false;

  @override
  void initState() {
    super.initState();

    // ✅ PRE-FILL TEXT WHEN EDITING
    if (widget.isEdit && widget.initialText != null) {
      controller.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /* ───────────────────────── FEED PREVIEW ───────────────────────── */

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

  /* ───────────────────────── BUILD ───────────────────────── */

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
          const Center(
            child: Icon(Icons.drag_handle, color: Colors.white38),
          ),

          const SizedBox(height: 12),

          // ✏️ TEXT INPUT
          TextField(
            controller: controller,
            maxLines: null,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText:
                  widget.isEdit ? "Edit your caption…" : "Add a caption…",
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
          ),

          const Divider(color: Colors.white12),

          // 📦 ORIGINAL FEED PREVIEW
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((widget.feed["description"] ?? "")
                      .toString()
                      .isNotEmpty)
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

          // 🔘 ACTION BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2EE6A6),
              ),
              onPressed: posting
                  ? null
                  : () async {
                      setState(() => posting = true);

                      // ✏️ EDIT REPOST
                      if (widget.isEdit &&
                          widget.repostId != null) {
                        await widget.feedProvider.updateRepostText(
                          repostId: widget.repostId!,
                          text: controller.text.trim(),
                        );
                      }
                      // 🔁 CREATE REPOST
                      else {
                        await widget.feedProvider.repostWithText(
                          feedId: widget.feedId,
                          text: controller.text.trim(),
                        );
                      }

                      Navigator.pop(context);
                    },
              child: Text(
                posting
                    ? (widget.isEdit ? "Updating..." : "Posting...")
                    : (widget.isEdit ? "Update" : "Repost"),
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

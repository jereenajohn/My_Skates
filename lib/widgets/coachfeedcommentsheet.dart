import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../providers/feed_comments_provider.dart';

class FeedCommentsSheet extends StatelessWidget {
  final int feedId;
  const FeedCommentsSheet({super.key, required this.feedId});

  static const Color accentColor = Color(0xFF2EE6A6);

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return ChangeNotifierProvider(
      create: (_) => FeedCommentsProvider(feedId),
      child: Consumer<FeedCommentsProvider>(
        builder: (_, p, __) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00312D), Colors.black],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 10),

                /* ───────── HEADER ───────── */
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Feedback",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const Divider(color: Colors.white12),

                /* ───────── COMMENTS ───────── */
                Expanded(
                  child: p.loading
                      ? const Center(
                          child: CircularProgressIndicator(color: accentColor))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: p.comments.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white10),
                          itemBuilder: (_, i) {
                            final c = p.comments[i];
                            final bool isMine = c["user"] == p.myUserId;


                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white12,
                                  backgroundImage: c["profile_image"] != null
                                      ? NetworkImage(
                                          "$api${c["profile_image"]}")
                                      : null,
                                  child: c["profile_image"] == null
                                      ? const Icon(Icons.person,
                                          color: Colors.white70, size: 18)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p.getUserName(c),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          if (isMine) ...[
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 18,
                                                  color: Colors.white70),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () =>
                                                  _openEditSheet(context, p, c),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: Colors.redAccent),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () =>
                                                  _confirmDelete(
                                                      context, p, c["id"]),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c["comment"] ?? "",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),

                /* ───────── INPUT ───────── */
                Container(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom + 10,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white12,
                        child: Icon(Icons.person,
                            color: Colors.white70, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (v) {
                            p.postComment(v);
                            controller.clear();
                          },
                          decoration: const InputDecoration(
                            hintText: "Add a comment...",
                            hintStyle:
                                TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          p.postComment(controller.text);
                          controller.clear();
                        },
                        child: const Text(
                          "Post",
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ───────────────────────── EDIT ───────────────────────── */

void _openEditSheet(
  BuildContext context,
  FeedCommentsProvider provider,
  Map<String, dynamic> c,
) {
  final controller = TextEditingController(text: c["comment"]);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient:
              LinearGradient(colors: [Color(0xFF00312D), Colors.black]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Edit Comment",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await provider.updateComment(
                  commentId: c["id"],
                  newText: controller.text,
                );
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    ),
  );
}

/* ───────────────────────── DELETE ───────────────────────── */

void _confirmDelete(
  BuildContext context,
  FeedCommentsProvider provider,
  int id,
) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.black,
      title: const Text("Delete Comment",
          style: TextStyle(color: Colors.white)),
      content: const Text(
        "Are you sure you want to delete this comment?",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            await provider.deleteComment(id);
            Navigator.pop(context);
          },
          child: const Text("Delete",
              style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );
}

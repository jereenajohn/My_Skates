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
    final h = MediaQuery.of(context).size.height;
    final controller = TextEditingController();

    return ChangeNotifierProvider(
      create: (_) => FeedCommentsProvider(feedId),
      child: Container(
        height: h * 0.85,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Consumer<FeedCommentsProvider>(
          builder: (_, p, __) {
            return Column(
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

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
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
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white12),

                // Comments
                Expanded(
                  child: p.loading
                      ? const Center(
                          child: CircularProgressIndicator(color: accentColor),
                        )
                      : p.comments.isEmpty
                          ? const Center(
                              child: Text(
                                "No comments yet.\nBe the first to share feedback.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54, height: 1.4),
                              ),
                            )
                          : RefreshIndicator(
                              color: accentColor,
                              onRefresh: p.fetchComments,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: p.comments.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(color: Colors.white10),
                                itemBuilder: (_, i) {
                                  final c = p.comments[i];

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white12,
                                      backgroundImage: c["profile_image"] != null
                                          ? NetworkImage("$api${c["profile_image"]}")
                                          : null,
                                      child: c["profile_image"] == null
                                          ? const Icon(Icons.person,
                                              color: Colors.white70, size: 18)
                                          : null,
                                    ),
                                    title: Text(
                                      p.getUserName(c),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        c["comment"] ?? "",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),

                // Input
                Container(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white12,
                        child: Icon(Icons.person, color: Colors.white70, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (v) {
                            p.postComment(v);
                            controller.clear();
                          },
                          decoration: const InputDecoration(
                            hintText: "Add a comment...",
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: p.posting
                            ? null
                            : () {
                                p.postComment(controller.text);
                                controller.clear();
                              },
                        child: Text(
                          p.posting ? "Posting..." : "Post",
                          style: TextStyle(
                            color: p.posting ? Colors.white30 : accentColor,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }
}

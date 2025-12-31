import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_skates/widgets/coachfeedcommentsheet.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../api.dart';
import '../providers/coach_profile_provider.dart';
import 'package:my_skates/providers/coach_feed_provider.dart';
import 'package:share_plus/share_plus.dart';

const Color accentColor = Color(0xFF2EE6A6);

class CoachTimelinePage extends StatefulWidget {
  final int? feedId; // 👈 optional

  const CoachTimelinePage({super.key, this.feedId});

  @override
  State<CoachTimelinePage> createState() => _CoachTimelinePageState();
}

class _CoachTimelinePageState extends State<CoachTimelinePage> {
  final Map<int, GlobalKey> _feedKeys = {};

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CoachProfileProvider()..fetchProfile(),
        ),
        ChangeNotifierProvider(
          create: (_) => CoachFeedProvider()
            ..fetchFeeds().then((_) {
              _scrollToFeedIfNeeded();
            }),
        ),
      ],
      child: _CoachTimelineView(feedKeys: _feedKeys),
    );
  }

  void _scrollToFeedIfNeeded() {
    if (widget.feedId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _feedKeys[widget.feedId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }
}
/* ───────────────────────── MAIN VIEW ───────────────────────── */

class _CoachTimelineView extends StatelessWidget {
  final Map<int, GlobalKey> feedKeys;

  const _CoachTimelineView({required this.feedKeys});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00312D), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const _TopBar(),
                  const SizedBox(height: 40),
                  const _ProfileHeader(),
                  const SizedBox(height: 20),
                  const _FeedComposer(),
                  const SizedBox(height: 20),

                  // ✅ this is dynamic, so the list cannot be const
                  _FeedList(feedKeys: feedKeys),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── TOP BAR ───────────────────────── */

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }
}

/* ───────────────────────── PROFILE ───────────────────────── */

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Consumer<CoachProfileProvider>(
      builder: (_, p, __) {
        if (p.loading) {
          return const CircularProgressIndicator(color: accentColor);
        }

        return Column(
          children: [
            CircleAvatar(
              radius: 64,
              backgroundColor: Colors.black,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: (p.image != null && p.image!.isNotEmpty)
                    ? NetworkImage("$api${p.image}")
                    : const AssetImage("lib/assets/img.jpg") as ImageProvider,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              p.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(p.role, style: const TextStyle(color: Colors.white70)),
          ],
        );
      },
    );
  }
}

/* ───────────────────────── COMPOSER ───────────────────────── */
class _FeedComposer extends StatelessWidget {
  const _FeedComposer();

  @override
  Widget build(BuildContext context) {
    final profile = context.read<CoachProfileProvider>();

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          barrierColor: Colors.black.withOpacity(0.75),
          builder: (sheetContext) {
            return _CreatePostSheet(
              feedProvider: context.read<CoachFeedProvider>(),
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [const Color(0xFF00312D), Colors.black.withOpacity(0.95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: accentColor.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🛼 PROFILE + ENERGY BADGE
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage:
                      (profile.image != null && profile.image!.isNotEmpty)
                      ? NetworkImage("$api${profile.image}")
                      : const AssetImage("lib/assets/img.jpg") as ImageProvider,
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    size: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            // ✍️ TEXT
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Post today’s update",
                    style: TextStyle(
                      color: Color.fromARGB(218, 176, 172, 172),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

            // 📸 ACTION ICON
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 18,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ───────────────────────── FEED LIST ───────────────────────── */

class _FeedList extends StatelessWidget {
  final Map<int, GlobalKey> feedKeys;

  const _FeedList({required this.feedKeys});

  @override
  Widget build(BuildContext context) {
    return Consumer<CoachFeedProvider>(
      builder: (_, p, __) {
        if (p.loading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: accentColor),
          );
        }

        if (p.feeds.isEmpty) {
          return const Text(
            "No posts yet",
            style: TextStyle(color: Colors.white54),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: p.feeds.length,
          itemBuilder: (_, i) {
            final feed = p.feeds[i];

            feedKeys.putIfAbsent(feed["id"], () => GlobalKey());

            return KeyedSubtree(
              key: feedKeys[feed["id"]],
              child: _FeedCard(feed: feed),
            );
          },
        );
      },
    );
  }
}

/* ───────────────────────── FEED CARD ───────────────────────── */
class _FeedCard extends StatelessWidget {
  final dynamic feed;
  const _FeedCard({required this.feed});
  Future<void> _shareFeed(BuildContext context) async {
    final int feedId = feed["id"];

    final String desc = (feed["description"] ?? "").toString().trim();

    final List images = (feed["feed_image"] ?? []) as List;

    // 🔗 PRODUCTION DEEP LINK
    final String deepLink = "https://myskates.app/feed/$feedId";
    // (for now you can use ngrok if needed)

    final String shareText = [
      if (desc.isNotEmpty) desc,
      "",
      "Open in MySkates 👇",
      deepLink,
    ].join("\n");

    // If no images → text + link only
    if (images.isEmpty || images.first["image"] == null) {
      Share.share(shareText, subject: "MySkates Feed");
      return;
    }

    try {
      // Download image for preview
      final imageUrl = images.first["image"].toString();
      final response = await http.get(Uri.parse(imageUrl));

      final tempDir = await Directory.systemTemp.createTemp();
      final file = File("${tempDir.path}/feed_$feedId.jpg");
      await file.writeAsBytes(response.bodyBytes);

      // Share image + caption + deep link
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: "MySkates Feed",
      );
    } catch (e) {
      Share.share(shareText, subject: "MySkates Feed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.read<CoachProfileProvider>();
    final feedProvider = context.watch<CoachFeedProvider>();
    print("FEED DATA: $feed");
    print("FEED IMAGES: ${feed["feed_image"]}");
    print("FEED DESC: ${feed["description"]}");
    print(profile.name);
    final List images = feed["feed_image"] ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟢 TIMELINE DOT
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: images.isNotEmpty ? 220 : 140,
                color: Colors.white12,
              ),
            ],
          ),

          const SizedBox(width: 12),

          // 🛼 FEED CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 HEADER (PROFILE + NAME)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage:
                          (profile.image != null && profile.image!.isNotEmpty)
                          ? NetworkImage("$api${profile.image}")
                          : const AssetImage("lib/assets/img.jpg")
                                as ImageProvider,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        profile.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                      color: Colors.transparent, // required for gradient
                      elevation: 0,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          padding: EdgeInsets.zero,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00312D), Color(0xFF000000)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                            ),
                            child: const ListTile(
                              dense: true,
                              leading: Padding(
                                padding: const EdgeInsets.only(
                                  left: 6,
                                ), // 👈 shift right
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),

                              title: Text(
                                "Update",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _openEditSheet(context);
                          },
                        ),
                        PopupMenuItem(
                          padding: EdgeInsets.zero,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00312D), Color(0xFF000000)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(10),
                              ),
                            ),
                            child: const ListTile(
                              dense: true,
                              leading: Padding(
                                padding: const EdgeInsets.only(
                                  left: 6,
                                ), // 👈 shift right
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),

                              title: Text(
                                "Delete",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            feedProvider.deleteFeed(feed["id"]);
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 🔹 MEDIA
                if (images.isNotEmpty)
                  _FeedMedia(
                    images: images.map((e) => "${e["image"]}").toList(),
                  ),

                // 🔹 DESCRIPTION
                if ((feed["description"] ?? "").isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      feed["description"],
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // 🔹 ACTIONS (LIKE / COMMENT / SCORE)
                Row(
                  children: [
                    _ActionButton(
                      icon: (feed["is_liked"] ?? false)
                          ? Icons.thumb_up
                          : Icons.thumb_up_alt_outlined,
                      label: "${feed["likes_count"] ?? 0}",
                      isActive: feed["is_liked"] ?? false,
                      onTap: () {
                        feedProvider.toggleLike(feed["id"]);
                      },
                    ),

                    const SizedBox(width: 18),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: "Feedback",
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => FeedCommentsSheet(feedId: feed["id"]),
                        );
                      },
                    ),
                    const Spacer(),
                    _ActionButton(
                      icon: Icons.share_outlined,
                      label: "", // empty = no visible text
                      onTap: () => _shareFeed(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => _CreatePostSheet(
        feedProvider: context.read<CoachFeedProvider>(),
        isEdit: true,
        feedId: feed["id"],
        initialText: feed["description"] ?? "",
        existingImageUrls: (feed["feed_image"] ?? [])
            .map<String>((e) => "$api${e["image"]}")
            .toList(),
      ),
    );
  }
}

/* ───────────────────────── MEDIA ───────────────────────── */

class _FeedMedia extends StatefulWidget {
  final List<String> images;
  const _FeedMedia({required this.images});

  @override
  State<_FeedMedia> createState() => _FeedMediaState();
}

class _FeedMediaState extends State<_FeedMedia> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: width * 0.85,
          child: PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => currentIndex = i),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openImagePopup(context, widget.images, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.images[index],
                    width: width,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),

        // 🔹 DOT INDICATOR (ONLY IF MULTIPLE IMAGES)
        if (widget.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentIndex == i ? 8 : 6,
                  height: currentIndex == i ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentIndex == i ? accentColor : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/* ───────────────────────── ACTION BUTTON ───────────────────────── */

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isActive ? accentColor : Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? accentColor : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── CREATE POST SHEET ───────────────────────── */
class _CreatePostSheet extends StatefulWidget {
  final CoachFeedProvider feedProvider;
  final bool isEdit;
  final int? feedId;
  final String initialText;
  final List<String> existingImageUrls;

  const _CreatePostSheet({
    super.key,
    required this.feedProvider,
    this.isEdit = false,
    this.feedId,
    this.initialText = "",
    this.existingImageUrls = const [],
  });

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final TextEditingController controller = TextEditingController();
  final List<File> images = [];
  final picker = ImagePicker();
  final List<String> networkImages = [];

  bool posting = false;
  bool showEmojiPicker = false;
  final FocusNode textFocusNode = FocusNode();
  late final List<String> _allEmojis;

  static const Color accentColor = Color(0xFF2EE6A6);

  @override
  void initState() {
    super.initState();
    _allEmojis = getAllEmojis();

    // ✅ THIS LINE SHOWS DESCRIPTION WHEN EDITING
    controller.text = widget.initialText;

    // ✅ THIS LINE SHOWS EXISTING IMAGES
    networkImages.addAll(widget.existingImageUrls);
  }

  @override
  void dispose() {
    controller.dispose();
    textFocusNode.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        images.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  List<String> getAllEmojis() {
    final List<String> emojis = [];

    // Unicode emoji ranges (covers modern emojis)
    final ranges = [
      [0x1F300, 0x1F5FF], // symbols & pictographs
      [0x1F600, 0x1F64F], // emoticons
      [0x1F680, 0x1F6FF], // transport & map
      [0x1F700, 0x1F77F],
      [0x1F780, 0x1F7FF],
      [0x1F800, 0x1F8FF],
      [0x1F900, 0x1F9FF], // supplemental symbols
      [0x1FA00, 0x1FAFF], // extended symbols
      [0x2600, 0x26FF], // misc symbols
      [0x2700, 0x27BF], // dingbats
    ];

    for (final range in ranges) {
      for (int code = range[0]; code <= range[1]; code++) {
        emojis.add(String.fromCharCode(code));
      }
    }

    return emojis;
  }

  Widget _imagePreview(Widget image, {required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 120, height: 120, child: image),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = showEmojiPicker
        ? 0.0
        : MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _SportyHandle(),
            const SizedBox(height: 12),

            // 🔹 HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "Create post",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.text.isEmpty && images.isEmpty
                        ? null
                        : _submit,
                    child: Text(
                      posting ? "Posting..." : "Post",
                      style: TextStyle(
                        color: controller.text.isEmpty && images.isEmpty
                            ? Colors.white30
                            : accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12),

            // 🔹 SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    // TEXT FIELD
                    TextField(
                      controller: controller,
                      focusNode: textFocusNode,
                      maxLines: null,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: const InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onTap: () => setState(() => showEmojiPicker = false),
                      onChanged: (_) => setState(() {}),
                    ),

                    // IMAGE PREVIEW
                    // IMAGE PREVIEW (EXISTING + NEW)
                    if (networkImages.isNotEmpty || images.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // EXISTING (NETWORK) IMAGES
                            ...networkImages.map(
                              (url) => _imagePreview(
                                Image.network(url, fit: BoxFit.cover),
                                onRemove: () {
                                  setState(() => networkImages.remove(url));
                                },
                              ),
                            ),

                            // NEW (LOCAL FILE) IMAGES
                            ...images.map(
                              (file) => _imagePreview(
                                Image.file(file, fit: BoxFit.cover),
                                onRemove: () {
                                  setState(() => images.remove(file));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 🔹 ACTION BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      showEmojiPicker
                          ? Icons.keyboard_alt_outlined
                          : Icons.emoji_emotions_outlined,
                      color: accentColor,
                    ),
                    onPressed: () {
                      setState(() => showEmojiPicker = !showEmojiPicker);
                      if (showEmojiPicker) {
                        FocusScope.of(context).unfocus();
                      } else {
                        FocusScope.of(context).requestFocus(textFocusNode);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.image, color: accentColor),
                    onPressed: pickImages,
                  ),
                  const Text(
                    "Photo / Emoji",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // 🔹 EMOJI PICKER
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: showEmojiPicker ? 260 : 0,
              child: showEmojiPicker
                  ? GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                      itemCount: _allEmojis.length,
                      itemBuilder: (context, index) {
                        final emoji = _allEmojis[index];
                        return GestureDetector(
                          onTap: () {
                            final text = controller.text;
                            final selection = controller.selection;

                            controller.text = text.replaceRange(
                              selection.start,
                              selection.end,
                              emoji,
                            );

                            controller.selection = TextSelection.collapsed(
                              offset: selection.start + emoji.length,
                            );

                            setState(() {});
                          },
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ ONLY CHANGE: Provider-based submit
  Future<void> _submit() async {
    setState(() => posting = true);

    await widget.feedProvider.postFeed(controller.text, images);

    Navigator.pop(context);
  }
}

class _SportyHandle extends StatelessWidget {
  const _SportyHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 6),
        ],
      ),
    );
  }
}

void _openImagePopup(
  BuildContext context,
  List<String> images,
  int startIndex,
) {
  showDialog(
    context: context,
    barrierColor: Colors.black,
    builder: (_) {
      return GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          child: PageView.builder(
            controller: PageController(initialPage: startIndex),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(images[index], fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

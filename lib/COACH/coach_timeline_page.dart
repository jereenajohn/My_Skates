import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/feed_comments_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class CoachTimelinePage extends StatefulWidget {
  // final String api;

  const CoachTimelinePage({super.key});

  @override
  State<CoachTimelinePage> createState() => _CoachTimelinePageState();
}

class _CoachTimelinePageState extends State<CoachTimelinePage> {
  // ================= PROFILE =================
  bool profileLoading = true;
  String coachName = "";
  String coachRole = "";
  String? coachImage;

  // ================= FEEDS =================
  bool feedLoading = true;
  List<dynamic> coachFeeds = [];

  final TextEditingController feedController = TextEditingController();
  List<File> feedImages = [];

  bool isEditingFeed = false;
  int? editingFeedId;

  static const Color accentColor = Color(0xFF2EE6A6);

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    fetchcoachDetails();
    fetchCoachFeeds();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ================= TOKEN =================
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access');
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt("id");
  }

  // Future<void> postFeedComment(int feedId, String comment) async {
  //   if (comment.trim().isEmpty) return;

  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString("access");

  //     final res = await http.post(
  //       Uri.parse("$api/api/myskates/feeds/$feedId/comment/"),
  //       headers: {
  //         "Authorization": "Bearer $token",
  //         "Content-Type": "application/json",
  //       },
  //       body: jsonEncode({"comment": comment}),
  //     );

  //     print("POST COMMENT STATUS = ${res.statusCode}");
  //     print("POST COMMENT BODY = ${res.body}");

  //     if (res.statusCode == 201) {
  //       fetchFeedComments(feedId); // 🔁 refresh list
  //     }
  //   } catch (e) {
  //     print("ERROR POSTING COMMENT = $e");
  //   }
  // }

  //   Future<void> fetchFeedComments(int feedId) async {
  //   try {
  //     setState(() => commentsLoading = true);

  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString("access");

  //     final res = await http.get(
  //       Uri.parse("$api/api/myskates/feeds/$feedId/comments/"),
  //       headers: {"Authorization": "Bearer $token"},
  //     );

  //     print("COMMENTS API STATUS = ${res.statusCode}");
  //     print("COMMENTS API BODY = ${res.body}");

  //     if (res.statusCode == 200) {
  //       final decoded = jsonDecode(res.body);

  //       setState(() {
  //         feedComments = decoded is List
  //             ? decoded
  //             : decoded['data'] ?? [];
  //         commentsLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     print("ERROR FETCHING COMMENTS = $e");
  //     setState(() => commentsLoading = false);
  //   }
  // }

  // ================= PROFILE API =================
  Future<void> fetchcoachDetails() async {
    try {
      String? token = await getToken();
      int? userId = await getUserId();

      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse("$api/api/myskates/profile/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("PROFILE API STATUS = ${response.statusCode}");
      print("PROFILE API BODY = ${response.body}");

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      if (data is List) {
        final user = data.cast<Map<String, dynamic>>().firstWhere(
          (item) => item["id"] == userId,
          orElse: () => {},
        );

        if (user.isEmpty) {
          print("Logged-in user not found in profile list");
          return;
        }

        final String firstName = (user["first_name"] ?? "").toString().trim();
        final String lastName = (user["last_name"] ?? "").toString().trim();
        final String userName = (user["u_name"] ?? "").toString().trim();

        setState(() {
          // ✅ Name logic (FIRST + LAST → USERNAME → Coach)
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            coachName = "$firstName $lastName".trim();
          } else if (userName.isNotEmpty) {
            coachName = userName;
          } else {
            coachName = "Coach";
          }

          coachRole = user["user_type"] ?? "Coach";
          coachImage = user["profile"];
          profileLoading = false;
        });

        print("Loaded PROFILE for user ID $userId");
      } else {
        print("PROFILE API did not return a list.");
      }
    } catch (e) {
      print("Error fetching coach profile: $e");
    }
  }

  // ================= FEED API =================
  Future<void> fetchCoachFeeds() async {
    try {
      setState(() => feedLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final id = prefs.getInt('id');
      final res = await http.get(
        Uri.parse("$api/api/myskates/feeds/user/$id/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("FEEDS API STATUS = ${res.statusCode}");
      print("FEEDS API BODY = ${res.body}");
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        setState(() {
          coachFeeds = decoded is List
              ? decoded
              : decoded['data'] ?? []; // fallback safety
          feedLoading = false;
        });
      }
    } catch (_) {
      setState(() => feedLoading = false);
    }
  }

  Future<void> postFeed() async {
    if (feedController.text.isEmpty && feedImages.isEmpty) return;

    final token = await getToken();
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$api/api/myskates/feeds/"),
    );

    request.headers["Authorization"] = "Bearer $token";
    request.fields["description"] = feedController.text;

    for (var img in feedImages) {
      request.files.add(await http.MultipartFile.fromPath("images", img.path));
    }

    await request.send();

    feedController.clear();
    feedImages.clear();
    isEditingFeed = false;
    editingFeedId = null;

    fetchCoachFeeds();
  }

  Future<void> updateFeed() async {
    if (editingFeedId == null) return;

    final token = await getToken();
    final request = http.MultipartRequest(
      "PUT",
      Uri.parse("$api/api/myskates/feeds/$editingFeedId/"),
    );

    request.headers["Authorization"] = "Bearer $token";
    request.fields["description"] = feedController.text;

    for (var img in feedImages) {
      request.files.add(await http.MultipartFile.fromPath("images", img.path));
    }

    await request.send();

    feedController.clear();
    feedImages.clear();
    isEditingFeed = false;
    editingFeedId = null;

    fetchCoachFeeds();
  }

  Future<void> deleteFeed(int id) async {
    final token = await getToken();
    await http.delete(
      Uri.parse("$api/api/myskates/feeds/update/$id/"),
      headers: {"Authorization": "Bearer $token"},
    );
    fetchCoachFeeds();
  }

  // ================= IMAGE PICK =================
  Future<void> addFeedImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        feedImages.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  void openComments(BuildContext context, int feedId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => FeedCommentsSheet(feedId: feedId),
    );
  }

  void _openRatingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        double rating = 3;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Rate this session",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        onPressed: () => setState(() => rating = i + 1),
                        icon: Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFF2EE6A6),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2EE6A6),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // TODO: send rating to API
                        Navigator.pop(context);
                      },
                      child: const Text("Submit Rating"),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String fullImageUrl(String path) => "$api$path";

  // ================= UI =================
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
                  _topBar(),
                  const SizedBox(height: 40),
                  _profileHeader(),
                  const SizedBox(height: 20),
                  _feedComposer(),
                  const SizedBox(height: 20),
                  _feedList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
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

  Widget _profileHeader() {
    if (profileLoading) {
      return const CircularProgressIndicator(color: accentColor);
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 64,
          backgroundColor: Colors.black,
          child: CircleAvatar(
            radius: 60,
            backgroundImage:
                (coachImage != null &&
                    coachImage!.isNotEmpty &&
                    !coachImage!.contains("none"))
                ? NetworkImage(fullImageUrl(coachImage!))
                : const AssetImage("lib/assets/img.jpg") as ImageProvider,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          coachName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(coachRole, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _feedComposer() {
    return GestureDetector(
      onTap: _openCreatePostSheet,
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
                      (coachImage != null && coachImage!.isNotEmpty)
                      ? NetworkImage(fullImageUrl(coachImage!))
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

            // ✍️ COPY (URGENCY + MOTIVATION)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // ✅ KEY FIX
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
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

            // 👉 ACTION CUE (POST ENERGY)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔥 Pulse dot
                const SizedBox(height: 8),

                // 📸 Post icon (professional)
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

                const SizedBox(height: 6),

                // ⬆️ Direction hint
                // const Icon(
                //   Icons.keyboard_arrow_up,
                //   color: Colors.white38,
                //   size: 18,
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openCreatePostSheet() {
    HapticFeedback.mediumImpact(); // 🛼 sporty feedback

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.92, end: 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              alignment: Alignment.bottomCenter,
              child: child,
            );
          },
          child: Container(
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF00312D), // your brand green
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: const [
                SizedBox(height: 12),

                // 🔹 Drag Handle
                _SportyHandle(),

                SizedBox(height: 12),

                // 🔹 Create Post Content
                Expanded(child: _CreatePostSheet()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _feedList() {
    if (!feedLoading && coachFeeds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text("No posts yet", style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: coachFeeds.length,
      itemBuilder: (context, index) {
        final feed = coachFeeds[index];
        return _feedCard(feed);
      },
    );
  }

  Widget _feedCard(dynamic feed) {
    final List images = (feed["feed_image"] is List) ? feed["feed_image"] : [];

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟢 LANE MARKER
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

          // 🛼 CONTENT LANE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 COACH HEADER
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage:
                          (coachImage != null && coachImage!.isNotEmpty)
                          ? NetworkImage(fullImageUrl(coachImage!))
                          : const AssetImage("lib/assets/img.jpg")
                                as ImageProvider,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        coachName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: "edit", child: Text("Edit")),
                        PopupMenuItem(value: "delete", child: Text("Delete")),
                      ],
                      onSelected: (v) {
                        if (v == "edit") {
                          setState(() {
                            isEditingFeed = true;
                            editingFeedId = feed["id"];
                            feedController.text = feed["description"] ?? "";
                          });
                        } else {
                          deleteFeed(feed["id"]);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 🔹 MEDIA STRIP (SESSION CLIP)
                if (images.isNotEmpty)
                  _FeedMediaBlock(
                    images: images
                        .map((e) => fullImageUrl(e["image"] ?? ""))
                        .toList(),
                  ),

                const SizedBox(height: 10),

                // 🔹 COACH NOTE
                if ((feed["description"] ?? "").isNotEmpty)
                  Text(
                    feed["description"],
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),

                const SizedBox(height: 12),

                // 🔹 CONTROLS (PERFORMANCE-STYLE)
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.thumb_up_alt_outlined,
                      label: "Good",
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: "Feedback",
                      onTap: () => openComments(context, feed["id"]),
                    ),

                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.star_border,
                      label: "Score",
                      onTap: () => _openRatingSheet(context),
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

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final TextEditingController controller = TextEditingController();
  final List<File> images = [];
  final picker = ImagePicker();
  bool posting = false;
  late final List<String> _allEmojis;

  @override
  void initState() {
    super.initState();
    _allEmojis = getAllEmojis();
  }

  bool showEmojiPicker = false;
  final FocusNode textFocusNode = FocusNode();
  @override
  void dispose() {
    controller.dispose();
    textFocusNode.dispose();
    super.dispose();
  }

  static const Color accentColor = Color(0xFF2EE6A6);

  Future<void> pickImages() async {
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        images.addAll(picked.map((e) => File(e.path)));
      });
    }
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
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00312D), // 🌿 brand green
              Colors.black,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
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
                      "Post",
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

            // 🔹 SCROLLABLE CONTENT (KEY FIX)
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
                    if (images.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(6),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      images[index],
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          images.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
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
              ),
            ),

            // 🔹 ACTION BAR (FIXED HEIGHT)
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

            // 🔹 EMOJI PICKER (CONSTRAINED)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: showEmojiPicker ? 260 : 0,
              child: showEmojiPicker
                  ? SafeArea(
                      top: false,
                      child: AnimatedContainer(
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

                                      controller
                                          .selection = TextSelection.collapsed(
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
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => posting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$api/api/myskates/feeds/"),
    );

    request.headers["Authorization"] = "Bearer $token";
    request.fields["description"] = controller.text;

    for (var img in images) {
      request.files.add(await http.MultipartFile.fromPath("images", img.path));
    }

    await request.send();

    Navigator.pop(context);
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

class _FeedMediaBlock extends StatefulWidget {
  final List<String> images;

  const _FeedMediaBlock({required this.images});

  @override
  State<_FeedMediaBlock> createState() => _FeedMediaBlockState();
}

class _FeedMediaBlockState extends State<_FeedMediaBlock> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: width * 0.85, // 🔥 Taller feed image
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
                    color: currentIndex == i
                        ? const Color(0xFF2EE6A6) // accent
                        : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
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

class InstagramMediaSlider extends StatefulWidget {
  final List<Map<String, dynamic>> media;

  const InstagramMediaSlider({required this.media});

  @override
  State<InstagramMediaSlider> createState() => _InstagramMediaSliderState();
}

class _InstagramMediaSliderState extends State<InstagramMediaSlider> {
  int index = 0;
  bool liked = false;
  bool showHeart = false;

  void _onLike() {
    setState(() {
      liked = true;
      showHeart = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() => showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onDoubleTap: _onLike,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: width,
            height: width * 1.15,
            child: PageView.builder(
              itemCount: widget.media.length,
              onPageChanged: (i) => setState(() => index = i),
              itemBuilder: (context, i) {
                final item = widget.media[i];
                final type = item["type"] ?? "image";
                final url = item["url"];

                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (c, child, progress) {
                    if (progress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.shade800,
                      highlightColor: Colors.grey.shade700,
                      child: Container(color: Colors.black),
                    );
                  },
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white38),
                );
              },
            ),
          ),

          // ❤️ DOUBLE TAP HEART
          if (showHeart)
            const Icon(Icons.favorite, size: 120, color: Colors.white),

          // 🔢 IMAGE COUNTER
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "${index + 1}/${widget.media.length}",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),

          // 🔵 DOTS
          if (widget.media.length > 1)
            Positioned(
              bottom: 12,
              child: Row(
                children: List.generate(
                  widget.media.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == index ? 7 : 5,
                    height: i == index ? 7 : 5,
                    decoration: BoxDecoration(
                      color: i == index
                          ? const Color(0xFF2EE6A6)
                          : Colors.white54,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class InstagramCommentsSheet extends StatelessWidget {
  const InstagramCommentsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Comments",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white12),

          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (_, i) => ListTile(
                leading: const CircleAvatar(radius: 16),
                title: Text(
                  "User $i",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  "Nice post!",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const CircleAvatar(radius: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Post",
                    style: TextStyle(color: Color(0xFF2EE6A6)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstagramFullWidthSlider extends StatefulWidget {
  final List<String> images;

  const _InstagramFullWidthSlider({required this.images});

  @override
  State<_InstagramFullWidthSlider> createState() =>
      _InstagramFullWidthSliderState();
}

class _InstagramFullWidthSliderState extends State<_InstagramFullWidthSlider> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          width: width,
          height: width * 1.15,
          child: PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => index = i),
            itemBuilder: (context, i) {
              return Image.network(
                widget.images[i],
                fit: BoxFit.cover,
                width: width,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black26,
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.white38,
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ),

        // DOT INDICATORS (only if more than 1 image)
        if (widget.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == index ? 7 : 5,
                  height: i == index ? 7 : 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == index
                        ? const Color(0xFF2EE6A6)
                        : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SkateTrackCarousel extends StatefulWidget {
  final List<String> images;

  const SkateTrackCarousel({required this.images});

  @override
  State<SkateTrackCarousel> createState() => _SkateTrackCarouselState();
}

class _SkateTrackCarouselState extends State<SkateTrackCarousel> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // 🔹 MEDIA WITH ANGLED ENERGY OVERLAY
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Stack(
            children: [
              SizedBox(
                width: w,
                height: w * 0.7,
                child: PageView.builder(
                  itemCount: widget.images.length,
                  onPageChanged: (i) => setState(() => index = i),
                  itemBuilder: (context, i) {
                    return Image.network(widget.images[i], fit: BoxFit.cover);
                  },
                ),
              ),

              // 🔹 ANGLED SKATE STRIPE
              Positioned(
                bottom: -20,
                left: -40,
                child: Transform.rotate(
                  angle: -0.12,
                  child: Container(
                    width: w + 80,
                    height: 26,
                    color: const Color(0xFF2EE6A6).withOpacity(0.85),
                  ),
                ),
              ),

              // 🔹 SESSION LABEL
              Positioned(
                bottom: 10,
                left: 16,
                child: Row(
                  children: const [
                    Icon(Icons.speed, size: 18, color: Colors.black),
                    SizedBox(width: 6),
                    Text(
                      "Skate Session",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 🔹 TRACK PROGRESS (LAP FEEL)
        if (widget.images.length > 1)
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (index + 1) / widget.images.length,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2EE6A6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



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
                            style: TextStyle(
                              color: Colors.white54,
                              height: 1.4,
                            ),
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
                                      ? NetworkImage(
                                          "$api${c["profile_image"]}",
                                        )
                                      : null,
                                  child: c["profile_image"] == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white70,
                                          size: 18,
                                        )
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
                        child: Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 16,
                        ),
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

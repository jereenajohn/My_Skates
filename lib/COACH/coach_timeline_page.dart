import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      Uri.parse("$api/api/myskates/feeds/$id/"),
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
                colors: [Color(0xFF00312D), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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

    return _glassBox(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  coachName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
          if ((feed["description"] ?? "").isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                feed["description"],
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          if (images.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: images.length,
              itemBuilder: (c, i) => Padding(
                padding: const EdgeInsets.all(4),
                child: Image.network(
                  fullImageUrl(images[i]["image"] ?? ""),
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white38),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _glassBox({Widget? child, EdgeInsets? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
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

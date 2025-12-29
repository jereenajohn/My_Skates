import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends StatefulWidget {
  final String profileUrl;
  final String name;
  final bool openGallery; // ✅ ADD THIS

  const CreatePostScreen({
    super.key,
    required this.profileUrl,
    required this.name,
    this.openGallery = false, // ✅ ADD THIS
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<File> _images = [];

  @override
void initState() {
  super.initState();

  if (widget.openGallery) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImages(); // your existing image picker
    });
  }
}


  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();

    if (files != null) {
      setState(() {
        _images.addAll(files.map((e) => File(e.path)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create post",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: _controller.text.trim().isEmpty && _images.isEmpty
                ? null
                : () {
                    Navigator.pop(context, {
                      "text": _controller.text,
                      "images": _images,
                    });
                  },
            child: const Text(
              "Post",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      // ---------------- BODY ----------------
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // USER INFO
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(widget.profileUrl),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        _chip(Icons.people, "Friends"),
                        _chip(Icons.photo_album, "Album"),
                        _chip(Icons.lock_open, "Off"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TEXT FIELD
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),

          // IMAGE PREVIEW
          if (_images.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(_images[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _images.removeAt(index);
                            });
                          },
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // BOTTOM ACTION SHEET
          Container(
            decoration: const BoxDecoration(
              border:
                  Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
            ),
            child: Column(
              children: [
                _bottomAction(Icons.photo_library, "Photo/video", _pickImages),
                _bottomAction(Icons.person_add, "Tag people", () {}),
                _bottomAction(Icons.emoji_emotions, "Feeling/activity", () {}),
                _bottomAction(Icons.location_on, "Check in", () {}),
                _bottomAction(Icons.live_tv, "Live video", () {}),
                _bottomAction(Icons.color_lens, "Background colour", () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _bottomAction(
      IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(label),
      onTap: onTap,
    );
  }
}

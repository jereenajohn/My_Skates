import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class CoachDetailsPage extends StatefulWidget {
  final int coachId;

  const CoachDetailsPage({super.key, required this.coachId});

  @override
  State<CoachDetailsPage> createState() => _CoachDetailsPageState();
}

class _CoachDetailsPageState extends State<CoachDetailsPage> {
  Map<String, dynamic>? coach;
  bool isLoading = true;
  List<dynamic> coachFeeds = [];
  bool feedLoading = true;
List<dynamic> existingImages = [];
List<File> newImages = [];
Set<int> removedImageIds = {};

  final TextEditingController feedController = TextEditingController();
  List<File> feedImages = [];
  int? editingFeedId;
bool isEditingFeed = false;
List<Map<String, dynamic>> editingFeedExistingImages = [];


  @override
  void initState() {
    super.initState();
    fetchCoachDetails();
    fetchCoachFeeds();
  }

  
 Future<void> updateFeed() async {
  if (editingFeedId == null) return;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  final request = http.MultipartRequest(
    "PUT",
    Uri.parse("$api/api/myskates/feeds/update/$editingFeedId/"),
  );

  request.headers["Authorization"] = "Bearer $token";
  request.fields["description"] = feedController.text;

  for (var img in editingFeedExistingImages) {
    request.fields["existing_images[]"] = img['id'].toString();
  }

  for (var img in feedImages) {
    request.files.add(
      await http.MultipartFile.fromPath("images", img.path),
    );
  }

  final streamedResponse = await request.send();
  final body = await streamedResponse.stream.bytesToString();

  print("STATUS: ${streamedResponse.statusCode}");
  print("BODYyyyyyyyy: $body");
}



 Future<void> postFeed() async {
  if (feedController.text.isEmpty && feedImages.isEmpty) return;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  final request = http.MultipartRequest(
    "POST",
    Uri.parse("$api/api/myskates/feeds/"),
  );

  request.headers["Authorization"] = "Bearer $token";
  request.fields["description"] = feedController.text;

  for (var img in feedImages) {
    request.files.add(
      await http.MultipartFile.fromPath("images", img.path),
    );
  }

  print("📤 POST FEED FIELDS: ${request.fields}");
  print("📸 TOTAL IMAGES: ${request.files.length}");

  // 🔥 SEND REQUEST
  final streamedResponse = await request.send();

  // 🔥 READ RESPONSE BODY
  final responseBody =
      await streamedResponse.stream.bytesToString();

  // ✅ PRINT EVERYTHING
  print("✅ POST FEED STATUS: ${streamedResponse.statusCode}");
  print("📩 POST FEED BODY: $responseBody");

  if (streamedResponse.statusCode == 201) {
    setState(() {
      feedController.clear();
      feedImages.clear();
    });
    fetchCoachFeeds();
  } else {
    print("❌ POST FEED FAILED");
  }
}


  Future<void> addFeedImages() async {
    final ImagePicker picker = ImagePicker();

    final List<XFile>? pickedImages = await picker.pickMultiImage();

    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        feedImages.addAll(pickedImages.map((xfile) => File(xfile.path)));
      });
    }
  }

  Future<void> fetchCoachFeeds() async {
    try {
      setState(() => feedLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final id = prefs.getInt('id');

      final res = await http.get(
        Uri.parse("$api/api/myskates/feeds/user/$id/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("Feed Status: ${res.statusCode}");
      print("Feed Body: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        setState(() {
          coachFeeds = decoded["data"] ?? [];
          feedLoading = false;
        });
      } else {
        feedLoading = false;
      }
    } catch (e) {
      print("Feed Error: $e");
      feedLoading = false;
    }
  }


  Future<void> _confirmDeleteFeed(int feedId) async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        "Delete Feed",
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        "Are you sure you want to delete this feed?",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await _deleteFeed(feedId);
          },
          child: const Text(
            "Delete",
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );
}

Future<void> _deleteFeed(int feedId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  final res = await http.delete(
    Uri.parse("$api/api/myskates/feeds/$feedId/"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode == 204 || res.statusCode == 200) {
    fetchCoachFeeds(); // refresh list
  }
}
Future<void> _updateFeedWithImages({
  required int feedId,
  required String description,
  required List<File> newImages,
  required Set<int> removedImageIds,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  final request = http.MultipartRequest(
    "PUT",
    Uri.parse("$api/api/myskates/feeds/$feedId/"),
  );

  request.headers["Authorization"] = "Bearer $token";
  request.fields["description"] = description;

  // REMOVED IMAGE IDS
  if (removedImageIds.isNotEmpty) {
    request.fields["remove_images"] =
        jsonEncode(removedImageIds.toList());
  }

  // ADD NEW IMAGES
  for (var img in newImages) {
    request.files.add(
      await http.MultipartFile.fromPath("images", img.path),
    );
  }

  final response = await request.send();

  if (response.statusCode == 200) {
    fetchCoachFeeds();
  } else {
    print("Update failed: ${response.statusCode}");
  }
}


  Future<void> fetchCoachDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final res = await http.get(
        Uri.parse("$api/api/myskates/user/extras/details/${widget.coachId}/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          coach = jsonDecode(res.body);
        });

        if (coach?["latitude"] != null && coach?["longitude"] != null) {
          getPlaceFromLatLong(coach!["latitude"], coach!["longitude"]);
        }

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching Coach: $e");
    }
  }

  String fullImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return "https://cdn-icons-png.flaticon.com/512/149/149071.png";
    }

    if (path.startsWith("http")) {
      return path;
    }

    String cleanBase = api.endsWith("/")
        ? api.substring(0, api.length - 1)
        : api;
    String cleanPath = path.startsWith("/") ? path.substring(1) : path;

    return "$cleanBase/$cleanPath";
  }

  String? userLocationName;

  Future<void> getPlaceFromLatLong(String lat, String long) async {
    try {
      double latitude = double.parse(lat);
      double longitude = double.parse(long);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      Placemark place = placemarks.first;

      setState(() {
        userLocationName =
            "${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}";
      });
    } catch (e) {
      userLocationName = "Unknown";
    }
  }

  // -----------------------------
  // LAUNCH INSTAGRAM
  // -----------------------------
  Future<void> openInstagram(String username) async {
    final url = "https://www.instagram.com/$username/";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print("Unable to open Instagram");
    }
  }

  // -----------------------------
  // LAUNCH WHATSAPP
  // -----------------------------
  Future<void> openWhatsApp(String phone) async {
    final url = "https://wa.me/$phone";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print("Unable to launch WhatsApp");
    }
  }

  // -----------------------------
  // CONNECT POPUP
  // -----------------------------
  void _showConnectPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(25),
            width: 260,
            height: 180,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 33, 30, 30),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // INSTAGRAM
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    final insta = coach?["instagram"];
                    if (insta != null && insta.isNotEmpty) {
                      openInstagram(insta);
                    }
                  },
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Image.network(
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Instagram_logo_2022.svg/512px-Instagram_logo_2022.svg.png",
                        height: 45,
                      ),
                    ),
                  ),
                ),

                // WHATSAPP
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    final phone = coach?["phone"];
                    if (phone != null && phone.isNotEmpty) {
                      openWhatsApp(phone);
                    }
                  },
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: SvgPicture.network(
                        "https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg",
                        height: 45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // UI STARTS HERE
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildUI(),

          
    );

    
  }

void _showEditFeedDialog(Map feed) {
  final TextEditingController editController =
      TextEditingController(text: feed["description"] ?? "");

  List<dynamic> existingImages =
      List.from(feed["feed_image"] ?? []);
  List<File> newImages = [];
  Set<int> removedImageIds = {};

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              "Update Feed",
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DESCRIPTION
                  TextField(
                    controller: editController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Edit description...",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // EXISTING IMAGES
                  if (existingImages.isNotEmpty) ...[
                    const Text(
                      "Existing Images",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: existingImages.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemBuilder: (context, index) {
                        final img = existingImages[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                fullImageUrl(img["image"]),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    removedImageIds.add(img["id"]);
                                    existingImages.removeAt(index);
                                  });
                                },
                                child: const CircleAvatar(
                                  radius: 11,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 12),

                  // NEW IMAGES
                  if (newImages.isNotEmpty) ...[
                    const Text(
                      "New Images",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: newImages.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                newImages[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    newImages.removeAt(index);
                                  });
                                },
                                child: const CircleAvatar(
                                  radius: 11,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ADD IMAGE BUTTON
                  TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked =
                          await picker.pickMultiImage();
                      if (picked != null) {
                        setModalState(() {
                          newImages.addAll(
                            picked.map((x) => File(x.path)),
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.photo, color: Colors.teal),
                    label: const Text(
                      "Add Images",
                      style: TextStyle(color: Colors.teal),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel",
                    style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _updateFeedWithImages(
                    feedId: feed["id"],
                    description: editController.text,
                    newImages: newImages,
                    removedImageIds: removedImageIds,
                  );
                },
                child: const Text(
                  "Update",
                  style: TextStyle(color: Colors.tealAccent),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
  Widget _buildUI() {
    return Stack(
      children: [
        Container(
          height: 260,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00342E), Color(0xFF000000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.topLeft,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.grey.shade900,
                  backgroundImage: NetworkImage(
                    fullImageUrl(coach?["profile"]),
                    headers: {"ngrok-skip-browser-warning": "1"},
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "${coach?["first_name"] ?? ""} ${coach?["last_name"] ?? ""}",
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  userLocationName ?? "Loading...",
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),

                const SizedBox(height: 3),

                const Text(
                  "COACH",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 25),

                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: [
                //     Column(
                //       children: [
                //         Text(
                //           (coach?["following"] ?? 0).toString(),
                //           style: const TextStyle(
                //             color: Colors.white,
                //             fontSize: 15,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //         const Text("Following",
                //             style: TextStyle(color: Colors.grey, fontSize: 15)),
                //       ],
                //     ),
                //     Column(
                //       children: [
                //         Text(
                //           (coach?["followers"] ?? 0).toString(),
                //           style: const TextStyle(
                //             color: Colors.white,
                //             fontSize: 15,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //         const Text("Followers",
                //             style: TextStyle(color: Colors.grey, fontSize: 15)),
                //       ],
                //     ),
                //   ],
                // ),

                // const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // CONNECT BUTTON

                    // FOLLOW BUTTON
                    // FOLLOW BUTTON (TRANSPARENT)
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            print("Follow pressed");
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                          ),
                          child: const Text(
                            "Follow",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _showConnectPopup(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const Text(
                            "Connect",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),
                  ],
                ),

                const SizedBox(height: 25),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Personal Info",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _personalInfoCard(),

                const SizedBox(height: 25),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Achievements",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                achievementCard(
                  title: "Langham Skating Club",
                  date: "November 18, 2025",
                  location: "Panamballi Nagar, Kochi",
                  subTitle: "Morning training session",
                  time: "1h 12m",
                  distance: "Panamballi Nagar - Kaicor",
                  // iconUrl: fullImageUrl(
                  //   "/media/profile_images/1000004721_K1a26PJ.jpg",
                  // ),
                ),

                const SizedBox(height: 20),

                achievementCard(
                  title: "RBT Skating Event",
                  date: "December 01, 2025",
                  location: "Kakkanad, Kochi",
                  time: "4h 54m",
                  distance: "89.05 km",
                ),

                const SizedBox(height: 40),

                // ======================= FEED SECTION =======================
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Feeds",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ------------------ FEED COMPOSER ------------------
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              fullImageUrl(coach?["profile"]),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: feedController,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: "Share something...",
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: const Color(0xFF262626),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (feedImages.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: feedImages.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                              ),
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    feedImages[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        feedImages.removeAt(index);
                                      });
                                    },
                                    child: const CircleAvatar(
                                      radius: 11,
                                      backgroundColor: Colors.black54,
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        // EXISTING IMAGES (EDIT MODE)
if (isEditingFeed && editingFeedExistingImages.isNotEmpty) ...[
  const SizedBox(height: 10),
  GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: editingFeedExistingImages.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
    ),
    itemBuilder: (context, index) {
      final img = editingFeedExistingImages[index];

      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              fullImageUrl(img['image']),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  editingFeedExistingImages.removeAt(index);
                });
              },
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black54,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    },
  ),
],

                      ],

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.photo_library,
                              color: Colors.grey,
                            ),
                            onPressed: addFeedImages,
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: isEditingFeed ? updateFeed : postFeed,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
  isEditingFeed ? "Update" : "Post",
  style: const TextStyle(color: Colors.white),
),

                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

              
                // ======================= FEED LIST (PROFESSIONAL) =======================
                feedLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : coachFeeds.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          "No feeds yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : Column(
                        children: coachFeeds.map((feed) {
                          final List images = feed["feed_image"] ?? [];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF151515),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ---------------- HEADER ----------------
                               // ---------------- HEADER ----------------
Row(
  children: [
    CircleAvatar(
      radius: 18,
      backgroundImage: NetworkImage(
        fullImageUrl(coach?["profile"]),
      ),
    ),
    const SizedBox(width: 10),

    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${coach?["first_name"] ?? ""} ${coach?["last_name"] ?? ""}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            feed["created_at"] ?? "",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),

    // ✏️ EDIT ICON
    GestureDetector(
     onTap: () {
  setState(() {
    editingFeedId = feed['id'];
    isEditingFeed = true;
    feedController.text = feed['description'] ?? "";
    feedImages.clear(); // new images only
    editingFeedExistingImages =
        List<Map<String, dynamic>>.from(feed['feed_image'] ?? []);
  });

  // scroll to composer
  Scrollable.ensureVisible(
    context,
    duration: const Duration(milliseconds: 300),
  );
},

      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.edit,
          color: Colors.white70,
          size: 18,
        ),
      ),
    ),
  ],
),


                                // ---------------- DESCRIPTION ----------------
                                if (feed["description"] != null &&
                                    feed["description"]
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    feed["description"],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                ],

                                // ---------------- IMAGE GRID ----------------
                                if (images.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: images.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: images.length == 1
                                              ? 1
                                              : 2,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                        ),
                                    itemBuilder: (context, index) {
                                      final imgPath = images[index]["image"];

                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FeedImageViewer(
                                                  images: images,
                                                  initialIndex: index,
                                                  fullImageUrl: fullImageUrl,
                                                ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Image.network(
                                              fullImageUrl(imgPath),
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) =>
                                                  Container(
                                                    color: Colors.grey.shade800,
                                                    child: const Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      color: Colors.white54,
                                                      size: 40,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],

                                const SizedBox(height: 14),
                                const Divider(
                                  color: Color(0xFF2A2A2A),
                                  height: 1,
                                ),
                                const SizedBox(height: 10),

                                // ---------------- ACTION BAR ----------------
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _actionButton(
                                      icon: Icons.thumb_up_alt_outlined,
                                      label: "Like",
                                    ),
                                    _actionButton(
                                      icon: Icons.mode_comment_outlined,
                                      label: "Comment",
                                    ),
                                    _actionButton(
                                      icon: Icons.share_outlined,
                                      label: "Share",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _personalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _row("Experience", "${coach?["experience"] ?? "0"} yr"),
          _row("Club/Organisation", coach?["club"] ?? "Not Available"),
          _row("Events", coach?["club"] ?? "Unknown"),
          _row("Area", userLocationName ?? "Unknown"),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget achievementCard({
    required String title,
    required String date,
    required String location,
    String? subTitle,
    String? time,
    String? distance,
    String? iconUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  iconUrl ??
                      "https://cdn-icons-png.flaticon.com/512/2997/2997563.png",
                  height: 45,
                  width: 45,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.yellow,
                          size: 22,
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Text(
                      location,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (subTitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (time != null || distance != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (time != null)
                  Text(
                    time,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                if (distance != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    distance,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class FeedImageViewer extends StatefulWidget {
  final List images;
  final int initialIndex;
  final String Function(String) fullImageUrl;

  const FeedImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.fullImageUrl,
  });

  @override
  State<FeedImageViewer> createState() => _FeedImageViewerState();
}

class _FeedImageViewerState extends State<FeedImageViewer> {
  late PageController _controller;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: currentIndex);

    // immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => currentIndex = i),
            itemBuilder: (context, index) {
              final img = widget.images[index]["image"];

              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.fullImageUrl(img),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),

          // CLOSE BUTTON
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),

          // IMAGE COUNT
          Positioned(
            top: 45,
            right: 16,
            child: Text(
              "${currentIndex + 1}/${widget.images.length}",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );

    
  }

  
}


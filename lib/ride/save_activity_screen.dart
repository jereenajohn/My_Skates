import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_skates/api.dart';
import 'package:my_skates/ride/activity_review_screen.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'ride_provider.dart';
import 'ride_models.dart';
import 'ride_math.dart';

class SaveActivityScreen extends StatefulWidget {
  const SaveActivityScreen({super.key});

  @override
  State<SaveActivityScreen> createState() => _SaveActivityScreenState();
}

class _SaveActivityScreenState extends State<SaveActivityScreen> {
  final title = TextEditingController(text: "Afternoon Ride");
  final desc = TextEditingController();
  final privateNote = TextEditingController();

  String? selectedTag;
  String? selectedFeeling;
  bool isSaving = false;

  final ImagePicker _picker = ImagePicker();
  List<File> selectedImages = [];

  final List<String> tags = [
    "Workout",
    "Commute",
    "Race",
    "Training",
    "Recovery",
  ];

  final List<String> feelings = ["Easy", "Moderate", "Hard", "Very Hard"];

  static String saveRideApi = "$api/api/myskates/user/activities/";

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    privateNote.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 80);

      if (picked.isNotEmpty) {
        setState(() {
          selectedImages.addAll(picked.map((e) => File(e.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to pick images: $e")));
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  Future<void> _saveActivity(RideProvider ride) async {
    if (isSaving) return;

    if (title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter activity title")),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final token = await _getToken();

      final payload = ride.buildActivityPayload(
        title: title.text.trim(),
        description: desc.text.trim(),
        activityTag: selectedTag,
        feeling: selectedFeeling,
        privateNote: privateNote.text.trim(),
      );

      // final response = await http.post(
      //   Uri.parse(saveRideApi),
      //   headers: {
      //     "Content-Type": "application/json",
      //     if (token != null && token.isNotEmpty)
      //       "Authorization": "Bearer $token",
      //   },
      //   body: jsonEncode(payload),
      // );

      final request = http.MultipartRequest("POST", Uri.parse(saveRideApi));

      if (token != null && token.isNotEmpty) {
        request.headers["Authorization"] = "Bearer $token";
      }

      payload.forEach((key, value) {
        if (value == null) return;

        if (value is List) {
          request.fields[key] = jsonEncode(value);
        } else if (value is Map) {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = value.toString();
        }
      });

      for (final image in selectedImages) {
        request.files.add(
          await http.MultipartFile.fromPath("images", image.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("Save response status: ${response.statusCode}");
      print("Save response body: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic body = jsonDecode(response.body);

        Map<String, dynamic> apiActivity = {};

        if (body is Map<String, dynamic>) {
          if (body["data"] is Map<String, dynamic>) {
            apiActivity = Map<String, dynamic>.from(body["data"]);
          } else if (body["activity"] is Map<String, dynamic>) {
            apiActivity = Map<String, dynamic>.from(body["activity"]);
          } else {
            apiActivity = Map<String, dynamic>.from(body);
          }
        }

        final Map<String, dynamic> reviewActivity = {
          ...payload,
          ...apiActivity,
        };

        await ride.stopAll();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ActivityReviewScreen(activity: reviewActivity),
          ),
        );
      } else {
        debugPrint("Save failed: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Save failed (${response.statusCode})")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving activity: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Save Activity",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        leadingWidth: 90,
        leading: TextButton(
          onPressed: isSaving
              ? null
              : () {
                  ride.uiState = RideUIState.tracking;
                  ride.notifyListeners();
                  Navigator.pop(context);
                },
          child: const Text(
            "Back",
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF14161A), Color(0xFF101114)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                _statCard(
                  value: RideMath.formatDuration(ride.moving),
                  label: "Time",
                  icon: Icons.timer_outlined,
                ),
                const SizedBox(width: 10),
                _statCard(
                  value: ride.avgSpeedKmh.toStringAsFixed(1),
                  label: "Avg km/h",
                  icon: Icons.speed,
                ),
                const SizedBox(width: 10),
                _statCard(
                  value: ride.distanceKm.toStringAsFixed(2),
                  label: "Distance",
                  icon: Icons.route,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _sectionTitle("Overview"),
          const SizedBox(height: 10),

          _field(
            controller: title,
            hint: "Activity title",
            maxLines: 1,
            prefixIcon: Icons.edit_road,
          ),
          const SizedBox(height: 12),
          _field(
            controller: desc,
            hint: "Write something about this activity",
            maxLines: 4,
            prefixIcon: Icons.notes,
          ),
          const SizedBox(height: 16),

          _sectionTitle("Sport"),
          const SizedBox(height: 10),
          _dropdownBox<SportType>(
            value: ride.selectedSport,
            items: SportType.values
                .map(
                  (s) => DropdownMenuItem<SportType>(
                    value: s,
                    child: Text(
                      s.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
            onChanged: (s) {
              if (s != null) {
                ride.selectedSport = s;
                ride.notifyListeners();
              }
            },
          ),

          const SizedBox(height: 16),
          _sectionTitle("Details"),
          const SizedBox(height: 10),

          _dropdownBox<String>(
            hint: "Activity Tag",
            value: selectedTag,
            items: tags
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e, style: const TextStyle(color: Colors.white)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedTag = v;
              });
            },
          ),
          const SizedBox(height: 12),

          _dropdownBox<String>(
            hint: "How did that activity feel?",
            value: selectedFeeling,
            items: feelings
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e, style: const TextStyle(color: Colors.white)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedFeeling = v;
              });
            },
          ),
          const SizedBox(height: 12),

          _field(
            controller: privateNote,
            hint: "Private note (only visible to you)",
            maxLines: 3,
            prefixIcon: Icons.lock_outline,
          ),

          const SizedBox(height: 18),
          _sectionTitle("Ride Summary"),
          const SizedBox(height: 10),

          const SizedBox(height: 16),
          _sectionTitle("Images"),
          const SizedBox(height: 10),

          InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF151517),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.photo_library_outlined, color: Colors.white70),
                  SizedBox(width: 10),
                  Text(
                    "Upload Images",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selectedImages.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          selectedImages[index],
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

          SizedBox(height: 16),

          _infoTile("Elapsed Time", RideMath.formatDuration(ride.elapsed)),
          _infoTile("Moving Time", RideMath.formatDuration(ride.moving)),
          _infoTile("Distance", "${ride.distanceKm.toStringAsFixed(2)} km"),
          _infoTile(
            "Average Speed",
            "${ride.avgSpeedKmh.toStringAsFixed(2)} km/h",
          ),
          _infoTile(
            "Current Speed",
            "${ride.currentSpeedKmh.toStringAsFixed(2)} km/h",
          ),
          _infoTile("Max Speed", "${ride.maxSpeedKmh.toStringAsFixed(2)} km/h"),
          _infoTile("Route Points", "${ride.route.length}"),

          const SizedBox(height: 22),

          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: isSaving ? null : () => _saveActivity(ride),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                disabledBackgroundColor: Colors.teal.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Save Activity",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF17191D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required IconData prefixIcon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(prefixIcon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF151517),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.teal),
        ),
      ),
    );
  }

  Widget _dropdownBox<T>({
    String? hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF151517),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          dropdownColor: const Color(0xFF151517),
          value: value,
          isExpanded: true,
          hint: hint != null
              ? Text(hint, style: const TextStyle(color: Colors.white38))
              : null,
          iconEnabledColor: Colors.white70,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF151517),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

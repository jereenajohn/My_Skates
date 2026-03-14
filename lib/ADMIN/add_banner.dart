import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:my_skates/api.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddBanner extends StatefulWidget {
  const AddBanner({super.key});

  @override
  State<AddBanner> createState() => _AddBannerState();
}

class _AddBannerState extends State<AddBanner> {
  final TextEditingController bannerNameCtrl = TextEditingController();
  int? editingBannerId;
  String? existingBannerImage;
  XFile? pickedImage;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getBanner();
  }

  @override
  void dispose() {
    bannerNameCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImageFromGallery() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      setState(() {
        pickedImage = img;
      });
    }
  }

  bool validateForm() {
    if (bannerNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Banner Name is required"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    if (editingBannerId == null && pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please upload a banner image"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> deleteBanner(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    var response = await http.delete(
      Uri.parse("$api/api/myskates/banner/$id/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Banner Deleted"),
          backgroundColor: Colors.green,
        ),
      );
      getBanner();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete Failed"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> updateBanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var url = Uri.parse("$api/api/myskates/banner/$editingBannerId/");
      var request = http.MultipartRequest("PUT", url);

      request.headers["Authorization"] = "Bearer $token";

      request.fields["title"] = bannerNameCtrl.text.trim();

      if (pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", pickedImage!.path),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Banner Updated Successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          editingBannerId = null;
          existingBannerImage = null;
          pickedImage = null;
          bannerNameCtrl.clear();
        });

        getBanner();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update Failed: $responseBody"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("UPDATE ERROR: $e");
    }
  }

  Future<void> submitClub() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final id = prefs.getInt("id");

      if (token == null) {
        print("No TOKEN found");
        return;
      }

      var url = Uri.parse("$api/api/myskates/banner/");

      var request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";

      request.fields.addAll({"title": bannerNameCtrl.text.trim()});

      if (pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", pickedImage!.path),
        );
      }

      print("Sending request...");
      var response = await request.send();

      var responseBody = await response.stream.bytesToString();
      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE: $responseBody");

     if (response.statusCode == 200 || response.statusCode == 201) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text("Banner Created Successfully!"),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  setState(() {
    bannerNameCtrl.clear();
    pickedImage = null;
    existingBannerImage = null;
    editingBannerId = null;
  });

  getBanner();
} else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: $responseBody"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print("UPLOAD ERROR: $e");
    }
  }

  List<Map<String, dynamic>> Banner = [];

  Future<void> getBanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var response = await http.get(
        Uri.parse('$api/api/myskates/banner/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> Bannerlist = [];
      print("response.bodyyyyyyyyyyyyyyyyy:${response.body}");
      print(response.statusCode);
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed;

        for (var productData in productsData) {
          String imageUrl = "$api${productData['image']}";
          Bannerlist.add({
            'id': productData['id'],
            'title': productData['title'],
            'image': imageUrl,
          });
        }
        setState(() {
          Banner = Bannerlist;
          print("statelistttttttttttttttttttt:$Banner");
        });
      }
    } catch (error) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F1D), Color(0xFF003A36), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white38),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_left,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Banners",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: pickImageFromGallery,
                        child: Container(
                          height: 110,
                          width: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color.fromARGB(157, 37, 37, 37),
                            image: pickedImage != null
                                ? DecorationImage(
                                    image: FileImage(File(pickedImage!.path)),
                                    fit: BoxFit.cover,
                                  )
                                : existingBannerImage != null
                                ? DecorationImage(
                                    image: NetworkImage(existingBannerImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              pickedImage == null && existingBannerImage == null
                              ? const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white54,
                                  size: 40,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Upload Photo",
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                buildLabel("Banner Name"),
                buildTextField(bannerNameCtrl),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (validateForm()) {
                        if (editingBannerId == null) {
                          submitClub();
                        } else {
                          updateBanner();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9B8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      editingBannerId == null ? "Submit" : "Update",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Existing Banners",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Column(
                  children: Banner.map((item) {
                    return bannerItem(item);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget bannerItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[900],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    item['image'] != null &&
                        item['image'].toString().contains("http")
                    ? Image.network(item['image'], fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Text(
                            "No Image",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['title']?.toString().isNotEmpty == true
                            ? item['title']
                            : "No Title",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          editingBannerId = item['id'];
                          bannerNameCtrl.text = item['title'] ?? "";
                          existingBannerImage = item['image'];
                          pickedImage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(172, 0, 0, 0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Color.fromARGB(255, 4, 255, 188),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        deleteBanner(item['id']);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(174, 0, 0, 0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

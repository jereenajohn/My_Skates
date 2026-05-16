import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_skates/api.dart';

class AddUsedProductBanner extends StatefulWidget {
  const AddUsedProductBanner({super.key});

  @override
  State<AddUsedProductBanner> createState() =>
      _AddUsedProductBannerState();
}

class _AddUsedProductBannerState
    extends State<AddUsedProductBanner> {
  final TextEditingController bannerNameCtrl =
      TextEditingController();

  XFile? pickedImage;
  final ImagePicker picker = ImagePicker();

  int? editingBannerId;
  String? existingBannerImage;

  List<Map<String, dynamic>> banners = [];

  @override
  void initState() {
    super.initState();
    getBanners();
  }

  @override
  void dispose() {
    bannerNameCtrl.dispose();
    super.dispose();
  }

  // PICK IMAGE
  Future<void> pickImageFromGallery() async {
    final XFile? img =
        await picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      setState(() {
        pickedImage = img;
      });
    }
  }

  // GET BANNERS
  Future<void> getBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var response = await http.get(
        Uri.parse(
          "$api/api/myskates/product/banner/two/",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("GET RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> temp = [];

        for (var item in parsed) {
          temp.add({
            "id": item["id"],
            "title": item["title"],
            "image": "$api${item['image']}",
          });
        }

        setState(() {
          banners = temp;
        });
      }
    } catch (e) {
      print("GET ERROR: $e");
    }
  }

  // CREATE BANNER
  Future<void> createBanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var request = http.MultipartRequest(
        "POST",
        Uri.parse(
          "$api/api/myskates/product/banner/two/",
        ),
      );

      request.headers["Authorization"] =
          "Bearer $token";

      request.fields["title"] =
          bannerNameCtrl.text.trim();

      if (pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "image",
            pickedImage!.path,
          ),
        );
      }

      var response = await request.send();

      var responseBody =
          await response.stream.bytesToString();

      print("CREATE STATUS: ${response.statusCode}");
      print("CREATE BODY: $responseBody");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Used Product Banner Created Successfully!",
            ),
            backgroundColor: Colors.green,
          ),
        );

        clearForm();

        getBanners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed: $responseBody",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("CREATE ERROR: $e");
    }
  }

  // UPDATE BANNER
  Future<void> updateBanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse(
          "$api/api/myskates/product/banner/two/edit/$editingBannerId/",
        ),
      );

      request.headers["Authorization"] =
          "Bearer $token";

      request.fields["title"] =
          bannerNameCtrl.text.trim();

      if (pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "image",
            pickedImage!.path,
          ),
        );
      }

      var response = await request.send();

      var responseBody =
          await response.stream.bytesToString();

      print("UPDATE STATUS: ${response.statusCode}");
      print("UPDATE BODY: $responseBody");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Banner Updated Successfully!",
            ),
            backgroundColor: Colors.green,
          ),
        );

        clearForm();

        getBanners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Update Failed: $responseBody",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("UPDATE ERROR: $e");
    }
  }

  // DELETE BANNER
  Future<void> deleteBanner(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var response = await http.delete(
        Uri.parse(
          "$api/api/myskates/product/banner/two/edit/$id/",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("DELETE STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Banner Deleted"),
            backgroundColor: Colors.green,
          ),
        );

        getBanners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Delete Failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("DELETE ERROR: $e");
    }
  }

  // VALIDATION
  bool validateForm() {
    if (bannerNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Banner Name is required"),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    }

    if (editingBannerId == null &&
        pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please upload banner image",
          ),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    }

    return true;
  }

  // CLEAR FORM
  void clearForm() {
    setState(() {
      bannerNameCtrl.clear();
      pickedImage = null;
      existingBannerImage = null;
      editingBannerId = null;
    });
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
            colors: [
              Color(0xFF001F1D),
              Color(0xFF003A36),
              Colors.black,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white38,
                          ),
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
                        "Used Product Banners",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // IMAGE PICKER
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap:
                            pickImageFromGallery,
                        child: Container(
                          height: 110,
                          width: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                const Color.fromARGB(
                                  157,
                                  37,
                                  37,
                                  37,
                                ),
                            image:
                                pickedImage != null
                                ? DecorationImage(
                                    image: FileImage(
                                      File(
                                        pickedImage!
                                            .path,
                                      ),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : existingBannerImage !=
                                      null
                                ? DecorationImage(
                                    image:
                                        NetworkImage(
                                          existingBannerImage!,
                                        ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              pickedImage == null &&
                                  existingBannerImage ==
                                      null
                              ? const Icon(
                                  Icons
                                      .camera_alt_outlined,
                                  color:
                                      Colors.white54,
                                  size: 40,
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Upload Photo",
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                buildLabel("Banner Name"),

                buildTextField(bannerNameCtrl),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (validateForm()) {
                        if (editingBannerId ==
                            null) {
                          createBanner();
                        } else {
                          updateBanner();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                            0xFF00C9B8,
                          ),
                      padding:
                          const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                      shape:
                          RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                  20,
                                ),
                          ),
                    ),
                    child: Text(
                      editingBannerId == null
                          ? "Submit"
                          : "Update",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  "Existing Banners",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Column(
                  children:
                      banners.map((item) {
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

  // BANNER ITEM
  Widget bannerItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(16),
          color: Colors.grey[900],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    item['image'] != null &&
                        item['image']
                            .toString()
                            .contains("http")
                    ? Image.network(
                        item['image'],
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Text(
                            "No Image",
                            style: TextStyle(
                              color:
                                  Colors.white54,
                            ),
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
                      padding:
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius:
                            BorderRadius.circular(
                              8,
                            ),
                      ),
                      child: Text(
                        item['title'] ??
                            "No Title",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // EDIT
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          editingBannerId =
                              item['id'];

                          bannerNameCtrl.text =
                              item['title'] ?? "";

                          existingBannerImage =
                              item['image'];

                          pickedImage = null;
                        });
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.all(8),
                        decoration:
                            const BoxDecoration(
                              color:
                                  Colors.black54,
                              shape:
                                  BoxShape.circle,
                            ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // DELETE
                    GestureDetector(
                      onTap: () {
                        deleteBanner(
                          item['id'],
                        );
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.all(8),
                        decoration:
                            const BoxDecoration(
                              color:
                                  Colors.black54,
                              shape:
                                  BoxShape.circle,
                            ),
                        child: const Icon(
                          Icons.delete,
                          color:
                              Colors.redAccent,
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

  // LABEL
  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 15,
        bottom: 8,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }

  // TEXTFIELD
  Widget buildTextField(
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            const Color.fromARGB(
              157,
              37,
              37,
              37,
            ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
        ),
      ),
    );
  }
}
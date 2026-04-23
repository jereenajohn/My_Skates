import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateUsedProductPage extends StatefulWidget {
  final int productId;
  const UpdateUsedProductPage({super.key, required this.productId});

  @override
  State<UpdateUsedProductPage> createState() => _UpdateUsedProductPageState();
}

class _UpdateUsedProductPageState extends State<UpdateUsedProductPage> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final discountController = TextEditingController();

  bool isLoading = true;
  bool isSubmitting = false;
  bool isStatusUpdating = false;

  File? selectedImage;
  int? selectedCategoryId;

  List<Map<String, dynamic>> categories = [];
  String existingImage = "";
  String currentStatus = "active";

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await getCategories();
    await getUsedProductDetails();
  }

  Future<void> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final response = await http.get(
        Uri.parse("$api/api/myskates/products/category/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("CATEGORY STATUS: ${response.statusCode}");
      print("CATEGORY BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        setState(() {
          categories = List<Map<String, dynamic>>.from(
            parsed.map((e) => {"id": e["id"], "name": e["name"]}),
          );
        });
      }
    } catch (e) {
      print("CATEGORY ERROR: $e");
    }
  }

  Future<void> getUsedProductDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final res = await http.get(
        Uri.parse("$api/api/myskates/used/products/update/${widget.productId}/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("USED PRODUCT DETAIL STATUS: ${res.statusCode}");
      print("USED PRODUCT DETAIL BODY: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded["data"];

        setState(() {
          titleController.text = data["title"]?.toString() ?? "";
          descriptionController.text = data["description"]?.toString() ?? "";
          priceController.text = data["price"]?.toString() ?? "";
          discountController.text = data["discount"]?.toString() ?? "";
          selectedCategoryId = data["category"];
          currentStatus = data["status"]?.toString() ?? "active";
          existingImage = data["image"] != null ? "$api${data["image"]}" : "";
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("DETAIL ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedImage = File(result.files.single.path!);
      });
    }
  }

  Future<void> updateUsedProduct() async {
    if (currentStatus.toLowerCase() == "sold") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sold product cannot be edited. Change status to Active first."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    setState(() {
      isSubmitting = true;
    });

    try {
      final request = http.MultipartRequest(
        "PUT",
        Uri.parse("$api/api/myskates/used/products/update/${widget.productId}/"),
      );

      request.headers["Authorization"] = "Bearer $token";
      request.fields["title"] = titleController.text.trim();
      request.fields["description"] = descriptionController.text.trim();
      request.fields["price"] = priceController.text.trim();
      request.fields["discount"] = discountController.text.trim();

      if (selectedCategoryId != null) {
        request.fields["category"] = selectedCategoryId.toString();
      }

      if (selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", selectedImage!.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print("UPDATE STATUS: ${response.statusCode}");
      print("UPDATE BODY: ${response.body}");

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Used product updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update failed: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("UPDATE ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<void> updateUsedProductStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    setState(() {
      isStatusUpdating = true;
    });

    try {
      final request = http.MultipartRequest(
        "PATCH",
        Uri.parse("$api/api/myskates/used/products/update/${widget.productId}/"),
      );

      request.headers["Authorization"] = "Bearer $token";
      request.fields["status"] = status;

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print("STATUS PATCH STATUS: ${response.statusCode}");
      print("STATUS PATCH BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          currentStatus = decoded["data"]?["status"]?.toString() ?? status;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded["message"] ?? "Status updated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        if (status.toLowerCase() == "sold") {
          Navigator.pop(context, true);
          return;
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status update failed: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("STATUS PATCH ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        isStatusUpdating = false;
      });
    }
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.tealAccent),
      ),
    );
  }

  Widget _statusSection() {
    final bool isSold = currentStatus.toLowerCase() == "sold";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Status",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isStatusUpdating || currentStatus == "active"
                      ? null
                      : () => updateUsedProductStatus("active"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: currentStatus == "active"
                          ? Colors.tealAccent
                          : Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentStatus == "active"
                            ? Colors.tealAccent
                            : Colors.white24,
                      ),
                    ),
                    child: Center(
                      child: isStatusUpdating && currentStatus != "active"
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Active",
                              style: TextStyle(
                                color: currentStatus == "active"
                                    ? Colors.black
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: isStatusUpdating || currentStatus == "sold"
                      ? null
                      : () => updateUsedProductStatus("sold"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: currentStatus == "sold"
                          ? Colors.redAccent
                          : Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentStatus == "sold"
                            ? Colors.redAccent
                            : Colors.white24,
                      ),
                    ),
                    child: Center(
                      child: isStatusUpdating && currentStatus != "sold"
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Sold",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Current status: ${isSold ? "Sold" : "Active"}",
            style: TextStyle(
              color: isSold ? Colors.redAccent : Colors.tealAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSold = currentStatus.toLowerCase() == "sold";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Update Used Product"),
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF00312D), Color(0xFF000000)],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (selectedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            selectedImage!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else if (existingImage.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            existingImage,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              width: double.infinity,
                              color: Colors.white10,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Text(
                            "Choose image",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration("Title"),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Enter title" : null,
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration("Category"),
                        items: categories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat["id"],
                            child: Text(
                              cat["name"],
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategoryId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration("Description"),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration("Price"),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Enter price" : null,
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: discountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: inputDecoration("Discount"),
                      ),

                      const SizedBox(height: 12),

                      _statusSection(),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSubmitting || isSold ? null : updateUsedProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AFA5),
                            disabledBackgroundColor: Colors.grey.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  isSold
                                      ? "Change status to Active to edit"
                                      : "Update Product",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }}
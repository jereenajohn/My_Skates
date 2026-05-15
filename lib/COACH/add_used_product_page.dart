import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class AddUsedProductPage extends StatefulWidget {
  const AddUsedProductPage({super.key});

  @override
  State<AddUsedProductPage> createState() => _AddUsedProductPageState();
}

class UsedAttributeModel {
  final int id;
  final String name;

  UsedAttributeModel({required this.id, required this.name});

  factory UsedAttributeModel.fromJson(Map<String, dynamic> json) {
    return UsedAttributeModel(
      id: int.tryParse(json["id"].toString()) ?? 0,
      name:
          json["name"]?.toString() ??
          json["attribute"]?.toString() ??
          json["title"]?.toString() ??
          "",
    );
  }
}

class UsedAttributeValueModel {
  final int id;
  final String name;
  final int attributeId;
  final String attributeName;

  UsedAttributeValueModel({
    required this.id,
    required this.name,
    required this.attributeId,
    required this.attributeName,
  });

  factory UsedAttributeValueModel.fromJson(Map<String, dynamic> json) {
    return UsedAttributeValueModel(
      id: int.tryParse(json["id"].toString()) ?? 0,
      name: json["name"]?.toString() ?? "",
      attributeId: int.tryParse(json["attributes"].toString()) ?? 0,
      attributeName: json["attribute_name"]?.toString() ?? "",
    );
  }
}

class SelectedUsedAttributeGroup {
  final UsedAttributeModel attribute;
  List<UsedAttributeValueModel> values;

  SelectedUsedAttributeGroup({required this.attribute, required this.values});
}

class _AddUsedProductPageState extends State<AddUsedProductPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  final TextEditingController returnPolicyController = TextEditingController();
  final TextEditingController shipmentChargeController =
      TextEditingController();

  String selectedStatus = "active";

  List<File> selectedImages = [];
  bool isSubmitting = false;

  List<UsedAttributeModel> attributes = [];
  List<UsedAttributeValueModel> allAttributeValues = [];

  List<SelectedUsedAttributeGroup> selectedAttributeGroups = [];

  bool isAttributeLoading = false;
  bool isAttributeValueLoading = false;

  List paymentMethods = [];
  List<String> selectedPaymentMethods = [];

  @override
  void initState() {
    super.initState();
    fetchAttributes();
    fetchAllAttributeValues();
    fetchPaymentMethods();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  Future<void> fetchPaymentMethods() async {
    try {
      final token = await getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse("$api/api/myskates/payment/methods/view/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("PAYMENT METHOD STATUS: ${response.statusCode}");
      print("PAYMENT METHOD BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          paymentMethods = decoded["data"] ?? [];
        });
      }
    } catch (e) {
      print("Payment method fetch error: $e");
    }
  }

  Future<void> fetchAttributes() async {
    try {
      setState(() {
        isAttributeLoading = true;
      });

      final token = await getToken();

      if (token == null) {
        print("TOKEN NULL");
        return;
      }

      final response = await http.get(
        Uri.parse("$api/api/myskates/attributes/"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("ATTRIBUTES STATUS: ${response.statusCode}");
      print("ATTRIBUTES BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List data = decoded["data"] is List
            ? decoded["data"]
            : decoded is List
            ? decoded
            : [];

        setState(() {
          attributes = data
              .map((e) => UsedAttributeModel.fromJson(e))
              .where((item) => item.id != 0 && item.name.isNotEmpty)
              .toList();
        });
      } else {
        print("FAILED TO FETCH ATTRIBUTES");
      }
    } catch (e) {
      print("FETCH ATTRIBUTES ERROR: $e");
    } finally {
      if (mounted) {
        setState(() {
          isAttributeLoading = false;
        });
      }
    }
  }

  List<UsedAttributeValueModel> getValuesForAttribute(int attributeId) {
    return allAttributeValues
        .where((value) => value.attributeId == attributeId)
        .toList();
  }

  Future<void> fetchAllAttributeValues() async {
    try {
      setState(() {
        isAttributeValueLoading = true;
      });

      final token = await getToken();

      if (token == null) {
        print("TOKEN NULL");
        return;
      }

      final response = await http.get(
        Uri.parse("$api/api/myskates/attributes/values/"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("ATTRIBUTE VALUES STATUS: ${response.statusCode}");
      print("ATTRIBUTE VALUES BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List data = decoded["data"] is List
            ? decoded["data"]
            : decoded is List
            ? decoded
            : [];

        setState(() {
          allAttributeValues = data
              .map((e) => UsedAttributeValueModel.fromJson(e))
              .where((item) => item.id != 0 && item.name.isNotEmpty)
              .toList();
        });
      } else {
        print("FAILED TO FETCH ATTRIBUTE VALUES");
      }
    } catch (e) {
      print("FETCH ATTRIBUTE VALUES ERROR: $e");
    } finally {
      if (mounted) {
        setState(() {
          isAttributeValueLoading = false;
        });
      }
    }
  }

  Future<void> pickImages() async {
    final pickedImages = await ImagePicker().pickMultiImage();

    if (pickedImages.isNotEmpty) {
      setState(() {
        selectedImages.addAll(
          pickedImages.map((image) => File(image.path)).toList(),
        );
      });
    }
  } 

  Future<void> submitUsedProduct() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one image"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPaymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one payment method"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    HttpClient? client;

    try {
      setState(() {
        isSubmitting = true;
      });

      final token = await getToken();

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token not found. Please login again."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final uri = Uri.parse("$api/api/myskates/used/products/view/");
      client = HttpClient();
      final request = await client.postUrl(uri);

      request.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
      request.headers.set(HttpHeaders.acceptHeader, "application/json");

      final boundary =
          "----FlutterFormBoundary${DateTime.now().microsecondsSinceEpoch}";
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        "multipart/form-data; boundary=$boundary",
      );

      void writeField(String name, String value) {
        request.write("--$boundary\r\n");
        request.write('Content-Disposition: form-data; name="$name"\r\n\r\n');
        request.write(value);
        request.write("\r\n");
      }

      request.write("--$boundary\r\n");
      request.write('Content-Disposition: form-data; name="title"\r\n\r\n');
      request.write(titleController.text.trim());
      request.write("\r\n");

      request.write("--$boundary\r\n");
      request.write(
        'Content-Disposition: form-data; name="description"\r\n\r\n',
      );
      request.write(descriptionController.text.trim());
      request.write("\r\n");

      request.write("--$boundary\r\n");
      request.write('Content-Disposition: form-data; name="price"\r\n\r\n');
      request.write(priceController.text.trim());
      request.write("\r\n");

      request.write("--$boundary\r\n");
      request.write('Content-Disposition: form-data; name="discount"\r\n\r\n');
      request.write(discountController.text.trim());
      request.write("\r\n");

      final List<Map<String, dynamic>> attributesPayload = [];

      for (final group in selectedAttributeGroups) {
        for (final value in group.values) {
          attributesPayload.add({
            "attribute": group.attribute.id,
            "attribute_value": value.id,
          });
        }
      }

      request.write("--$boundary\r\n");
      request.write(
        'Content-Disposition: form-data; name="attributes"\r\n\r\n',
      );
      request.write(jsonEncode(attributesPayload));
      request.write("\r\n");

      request.write("--$boundary\r\n");
      request.write(
        'Content-Disposition: form-data; name="return_policy_days"\r\n\r\n',
      );
      request.write(
        returnPolicyController.text.trim().isEmpty
            ? "0"
            : returnPolicyController.text.trim(),
      );
      request.write("\r\n");

      request.write("--$boundary\r\n");
      request.write(
        'Content-Disposition: form-data; name="shipment_charge"\r\n\r\n',
      );
      request.write(
        shipmentChargeController.text.trim().isEmpty
            ? "0"
            : shipmentChargeController.text.trim(),
      );
      request.write("\r\n");

      request.write("--$boundary\r\n");
      request.write('Content-Disposition: form-data; name="status"\r\n\r\n');
      request.write(selectedStatus);
      request.write("\r\n");

      if (categoryController.text.trim().isNotEmpty) {
        request.write("--$boundary\r\n");
        request.write(
          'Content-Disposition: form-data; name="category"\r\n\r\n',
        );
        request.write(categoryController.text.trim());
        request.write("\r\n");
      }

      // FIXED PART: send repeated payment_methods keys exactly as backend expects
      for (final paymentMethodId in selectedPaymentMethods) {
        request.write("--$boundary\r\n");
        request.write(
          'Content-Disposition: form-data; name="payment_methods"\r\n\r\n',
        );
        request.write(paymentMethodId);
        request.write("\r\n");
      }

      print("POST PAYMENT METHODS: $selectedPaymentMethods");

      for (final image in selectedImages) {
        final fileName = image.path.split(Platform.pathSeparator).last;
        final bytes = await image.readAsBytes();

        request.write("--$boundary\r\n");
        request.write(
          'Content-Disposition: form-data; name="images"; filename="$fileName"\r\n',
        );
        request.write("Content-Type: application/octet-stream\r\n\r\n");
        request.add(bytes);
        request.write("\r\n");
      }

      request.write("--$boundary--\r\n");

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print("ADD USED PRODUCT STATUS: ${response.statusCode}");
      print("ADD USED PRODUCT BODY: $responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Used product added successfully"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: $responseBody"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("ADD USED PRODUCT ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      client?.close(force: true);

      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    discountController.dispose();
    categoryController.dispose();
    returnPolicyController.dispose();
    shipmentChargeController.dispose();
    super.dispose();
  }

  Widget buildField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (requiredField && (value == null || value.trim().isEmpty)) {
            return "$label is required";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF00AFA5)),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    final selectedNames = paymentMethods
        .where((item) => selectedPaymentMethods.contains(item["id"].toString()))
        .map((item) => "${item["name"]} (${item["code"]})")
        .join(", ");

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _showPaymentMethodBottomSheet,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedPaymentMethods.isEmpty
                      ? "Select Payment Methods"
                      : selectedNames,
                  style: TextStyle(
                    color: selectedPaymentMethods.isEmpty
                        ? Colors.white70
                        : Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00AFA5)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            final activePaymentMethods = paymentMethods
                .where((item) => item["is_active"] == true)
                .toList();

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    "Select Payment Methods",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (activePaymentMethods.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "No active payment methods available",
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: activePaymentMethods.map((item) {
                          final id = item["id"].toString();
                          final isSelected = selectedPaymentMethods.contains(
                            id,
                          );

                          return CheckboxListTile(
                            value: isSelected,
                            activeColor: const Color(0xFF00AFA5),
                            checkColor: Colors.white,
                            title: Text(
                              "${item["name"]} (${item["code"]})",
                              style: const TextStyle(color: Colors.white),
                            ),
                            onChanged: (value) {
                              sheetSetState(() {
                                setState(() {
                                  if (value == true) {
                                    selectedPaymentMethods.add(id);
                                  } else {
                                    selectedPaymentMethods.remove(id);
                                  }
                                });
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AFA5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Done",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildStatusDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: selectedStatus,
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.white),
        isExpanded: true,
        decoration: InputDecoration(
          labelText: "Status",
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF00AFA5)),
          ),
        ),
        items: const [
          DropdownMenuItem(value: "active", child: Text("Active")),
          DropdownMenuItem(value: "sold", child: Text("Sold")),
          DropdownMenuItem(value: "inactive", child: Text("Inactive")),
        ],
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            selectedStatus = value;
          });
        },
      ),
    );
  }

  Widget buildAttributeDropdowns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isAttributeLoading
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  showAttributeMultiSelectSheet();
                },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isAttributeLoading
                        ? "Loading attributes..."
                        : selectedAttributeGroups.isEmpty
                        ? "Select Attributes"
                        : selectedAttributeGroups
                              .map((e) => e.attribute.name)
                              .join(", "),
                    style: TextStyle(
                      color: selectedAttributeGroups.isEmpty
                          ? Colors.white70
                          : Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00AFA5)),
              ],
            ),
          ),
        ),

        if (selectedAttributeGroups.isNotEmpty)
          Column(
            children: selectedAttributeGroups.map((group) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.attribute.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedAttributeGroups.removeWhere(
                                (item) =>
                                    item.attribute.id == group.attribute.id,
                              );
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        showAttributeValueMultiSelectSheet(group);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.values.isEmpty
                                    ? "Select ${group.attribute.name} Values"
                                    : group.values
                                          .map((value) => value.name)
                                          .join(", "),
                                style: TextStyle(
                                  color: group.values.isEmpty
                                      ? Colors.white54
                                      : Colors.white,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF00AFA5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (group.values.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: group.values.map((value) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00AFA5).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF00AFA5).withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  value.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      group.values.removeWhere(
                                        (item) => item.id == value.id,
                                      );
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void showAttributeMultiSelectSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        List<SelectedUsedAttributeGroup> tempSelected = selectedAttributeGroups
            .map(
              (group) => SelectedUsedAttributeGroup(
                attribute: group.attribute,
                values: List.from(group.values),
              ),
            )
            .toList();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Select Attributes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedAttributeGroups = tempSelected;
                          });

                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Done",
                          style: TextStyle(
                            color: Color(0xFF00AFA5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (attributes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        "No attributes found",
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: attributes.length,
                        itemBuilder: (context, index) {
                          final attribute = attributes[index];

                          final isSelected = tempSelected.any(
                            (item) => item.attribute.id == attribute.id,
                          );

                          return CheckboxListTile(
                            value: isSelected,
                            activeColor: const Color(0xFF00AFA5),
                            checkColor: Colors.white,
                            title: Text(
                              attribute.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  final alreadyExists = tempSelected.any(
                                    (item) => item.attribute.id == attribute.id,
                                  );

                                  if (!alreadyExists) {
                                    tempSelected.add(
                                      SelectedUsedAttributeGroup(
                                        attribute: attribute,
                                        values: [],
                                      ),
                                    );
                                  }
                                } else {
                                  tempSelected.removeWhere(
                                    (item) => item.attribute.id == attribute.id,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showAttributeValueMultiSelectSheet(SelectedUsedAttributeGroup group) {
    final valuesForAttribute = getValuesForAttribute(group.attribute.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        List<UsedAttributeValueModel> tempSelected = List.from(group.values);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Select ${group.attribute.name} Values",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            final index = selectedAttributeGroups.indexWhere(
                              (item) => item.attribute.id == group.attribute.id,
                            );

                            if (index != -1) {
                              selectedAttributeGroups[index].values =
                                  tempSelected;
                            }
                          });

                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Done",
                          style: TextStyle(
                            color: Color(0xFF00AFA5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (valuesForAttribute.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        "No values found for this attribute",
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: valuesForAttribute.length,
                        itemBuilder: (context, index) {
                          final value = valuesForAttribute[index];

                          final isSelected = tempSelected.any(
                            (item) => item.id == value.id,
                          );

                          return CheckboxListTile(
                            value: isSelected,
                            activeColor: const Color(0xFF00AFA5),
                            checkColor: Colors.white,
                            title: Text(
                              value.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onChanged: (checked) {
                              setModalState(() {
                                if (checked == true) {
                                  final alreadyExists = tempSelected.any(
                                    (item) => item.id == value.id,
                                  );

                                  if (!alreadyExists) {
                                    tempSelected.add(value);
                                  }
                                } else {
                                  tempSelected.removeWhere(
                                    (item) => item.id == value.id,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildImagePicker() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        pickImages();
      },
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: selectedImages.isEmpty
            ? const Center(
                child: Text(
                  "Tap to select multiple images",
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(10),
                scrollDirection: Axis.horizontal,
                itemCount: selectedImages.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          selectedImages[index],
                          width: 120,
                          height: 130,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Add Used Product",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildField("Title", titleController, requiredField: true),

              buildField("Description", descriptionController, maxLines: 3),

              buildField(
                "Price",
                priceController,
                keyboardType: TextInputType.number,
                requiredField: true,
              ),

              buildField(
                "Discount",
                discountController,
                keyboardType: TextInputType.number,
              ),

              buildAttributeDropdowns(),
              _buildPaymentMethodDropdown(),
              buildField(
                "Return Policy Days",
                returnPolicyController,
                keyboardType: TextInputType.number,
              ),

              buildField(
                "Shipment Charge",
                shipmentChargeController,
                keyboardType: TextInputType.number,
              ),

              // buildStatusDropdown(),

              // buildField(
              //   "Category ID",
              //   categoryController,
              //   keyboardType: TextInputType.number,
              // ),
              const SizedBox(height: 8),

              buildImagePicker(),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitUsedProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AFA5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Post Used Product",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

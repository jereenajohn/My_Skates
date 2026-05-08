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

  @override
  void initState() {
    super.initState();
    fetchAttributes();
    fetchAllAttributeValues();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
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
  }//gg

  Future<void> submitUsedProduct() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (selectedAttributeGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one attribute"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final hasEmptyValues = selectedAttributeGroups.any(
      (group) => group.values.isEmpty,
    );

    if (hasEmptyValues) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select values for all selected attributes"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one image"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$api/api/myskates/used/products/view/"),
      );

      request.headers["Authorization"] = "Bearer $token";
      request.headers["Accept"] = "application/json";

      request.fields["title"] = titleController.text.trim();
      request.fields["description"] = descriptionController.text.trim();
      request.fields["price"] = priceController.text.trim();
      request.fields["discount"] = discountController.text.trim();

      final List<Map<String, dynamic>> attributesPayload = [];

      for (final group in selectedAttributeGroups) {
        for (final value in group.values) {
          attributesPayload.add({
            "attribute": group.attribute.id,
            "attribute_value": value.id,
          });
        }
      }

      request.fields["attributes"] = jsonEncode(attributesPayload);

      request.fields["return_policy_days"] =
          returnPolicyController.text.trim().isEmpty
          ? "0"
          : returnPolicyController.text.trim();

      request.fields["shipment_charge"] =
          shipmentChargeController.text.trim().isEmpty
          ? "0"
          : shipmentChargeController.text.trim();

      request.fields["status"] = selectedStatus;

      if (categoryController.text.trim().isNotEmpty) {
        request.fields["category"] = categoryController.text.trim();
      }

      for (final image in selectedImages) {
        request.files.add(
          await http.MultipartFile.fromPath("images", image.path),
        );
      }

      print("POST ATTRIBUTES: ${request.fields["attributes"]}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("ADD USED PRODUCT STATUS: ${response.statusCode}");
      print("ADD USED PRODUCT BODY: ${response.body}");

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
            content: Text("Failed: ${response.body}"),
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

  Widget buildStatusDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedStatus,
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
                separatorBuilder: (_, __) => const SizedBox(width: 10),
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

              buildStatusDropdown(),

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

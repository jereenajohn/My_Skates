import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/COACH/coach_homepage.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:my_skates/api.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? gender;
  String? selectedCountry;
  String? selectedState;
  String? selectedDistrict;

  List<Map<String, dynamic>> countryList = [];
  List<Map<String, dynamic>> categoryList = [];
  List<Map<String, dynamic>> allDistricts = [];
  List<Map<String, dynamic>> districtList = [];

  File? profileImage;
  String? profileNetworkImage;
  final ImagePicker _picker = ImagePicker();

  DateTime? dob;

  String? productType;
  final TextEditingController stockCtrl = TextEditingController();
  final TextEditingController discount = TextEditingController();

  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController returnPolicyCtrl = TextEditingController();
  final TextEditingController shipmentChargeCtrl = TextEditingController();
  final List<Map<String, String>> productTypeList = [
    {"id": "single", "name": "Single Product"},
    {"id": "variant", "name": "Has Variants"},
  ];

  final TextEditingController paymentNameCtrl = TextEditingController();
  final TextEditingController paymentCodeCtrl = TextEditingController();

  bool isPaymentActive = true;
  List paymentMethods = [];
  List<String> selectedPaymentMethods = [];

  @override
  void initState() {
    super.initState();
    fetchPaymentMethods();
    loadAllData();
  }

  @override
  void dispose() {
    stockCtrl.dispose();
    discount.dispose();
    titleCtrl.dispose();
    descriptionCtrl.dispose();
    priceCtrl.dispose();
    returnPolicyCtrl.dispose();
    paymentNameCtrl.dispose();
    paymentCodeCtrl.dispose();
    shipmentChargeCtrl.dispose();
    super.dispose();
  }

  Future<void> loadAllData() async {
    await fetchcategory();
    await fetchProfileData();
    setState(() {});
  }

  Future<void> fetchcategory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/products/category/"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        categoryList = data
            .map((e) => {"id": e["id"], "name": e["name"]})
            .toList();
      }
    } catch (e) {}
  }

  Future<void> fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      final res = await http.get(
        Uri.parse("$api/api/myskates/user/extras/details/$userId/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        gender = data["gender"]?.toString();
        selectedCountry = data["country"]?.toString();
        selectedState = data["state"]?.toString();
        selectedDistrict = data["district"]?.toString();

        if (data["dob"] != null) {
          dob = DateTime.tryParse(data["dob"]);
        }

        if (data["profile"] != null) {
          profileNetworkImage = "$api${data["profile"]}";
        }
      }
    } catch (e) {}
  }

  Future<void> submitProduct() async {
    print("Submitting product...");
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      print("useriddddddddddddddddddddddddddd$userId");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login expired. Please login again.")),
        );
        return;
      }

      if (profileImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an image.")),
        );
        return;
      }

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$api/api/myskates/products/add/"),
      );

      request.headers["Authorization"] = "Bearer $token";
      request.fields["product_type"] = productType!;

      if (productType == "single") {
        request.fields["stock"] = stockCtrl.text.trim();
      }
      if (productType == "single") {
        request.fields["discount"] = discount.text.trim();
      }

      request.fields["user"] = userId.toString();
      request.fields["title"] = titleCtrl.text.trim();
      request.fields["description"] = descriptionCtrl.text.trim();
      request.fields["base_price"] = priceCtrl.text.trim();
      request.fields["return_policy_days"] = returnPolicyCtrl.text.trim();
      request.fields["shipment_charge"] = shipmentChargeCtrl.text.trim();
      for (int i = 0; i < selectedPaymentMethods.length; i++) {
        request.fields["payment_methods[$i]"] = selectedPaymentMethods[i];
      }

      if (selectedState != null) {
        request.fields["category"] = selectedState.toString();
      }

      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", profileImage!.path),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("STATUS: ${response.statusCode}");
      print("BODYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY: $responseBody");

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product added successfully!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AddProduct()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: $responseBody")));
      }
    } catch (e) {
      print("Error in submitProduct: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    }
  }

  Future<void> fetchPaymentMethods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse("$api/api/myskates/payment/methods/view/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("PAYMENT METHOD GET STATUS: ${response.statusCode}");
      print("PAYMENT METHOD GET BODY: ${response.body}");

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

  Future<void> addPaymentMethod() async {
    if (paymentNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment method name is required")),
      );
      return;
    }

    if (paymentCodeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment method code is required")),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final body = {
        "name": paymentNameCtrl.text.trim(),
        "code": paymentCodeCtrl.text.trim().toUpperCase(),
        "is_active": isPaymentActive,
      };

      final response = await http.post(
        Uri.parse("$api/api/myskates/payment/methods/view/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      print("PAYMENT METHOD POST STATUS: ${response.statusCode}");
      print("PAYMENT METHOD POST BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment method added successfully")),
        );

        paymentNameCtrl.clear();
        paymentCodeCtrl.clear();

        setState(() {
          isPaymentActive = true;
        });

        fetchPaymentMethods();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: ${response.body}")));
      }
    } catch (e) {
      print("Payment method add error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    }
  }

  Widget _paymentMethodDropdown() {
    final selectedNames = paymentMethods
        .where((item) => selectedPaymentMethods.contains(item["id"].toString()))
        .map((item) => "${item["name"]} (${item["code"]})")
        .join(", ");

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () {
          _showPaymentMethodBottomSheet();
        },
        child: InputDecorator(
          decoration: _dec("Payment Methods"),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedPaymentMethods.isEmpty
                      ? "Select payment methods"
                      : selectedNames,
                  style: TextStyle(
                    color: selectedPaymentMethods.isEmpty
                        ? Colors.white54
                        : Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF001F1D),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select Payment Methods",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (activePaymentMethods.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "No active payment methods available",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),

                  ...activePaymentMethods.map((item) {
                    final id = item["id"].toString();
                    final isSelected = selectedPaymentMethods.contains(id);

                    return CheckboxListTile(
                      value: isSelected,
                      activeColor: Colors.teal,
                      checkColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "${item["name"]} (${item["code"]})",
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Code: ${item["code"]}",
                        style: const TextStyle(color: Colors.white54),
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
                  }),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
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

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F1D), Color(0xFF003A36), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            134,
                            134,
                            134,
                          ).withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_left_rounded,
                          color: Colors.white70,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () async {
                      final pick = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (pick != null) {
                        setState(() {
                          profileImage = File(pick.path);
                        });
                      }
                    },
                    child: Container(
                      height: 180,
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: profileImage == null
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.10),
                                  ),
                                ),
                                child: const Text(
                                  "Upload Image",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(
                                profileImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  _inputField("Title", titleCtrl),
                  _inputFieldmax(
                    "Description",
                    descriptionCtrl,
                    maxLines: null,
                    minLines: 4,
                    isNumber: false,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _dropdownField(
                          label: "category",
                          value: selectedState,
                          items: categoryList,
                          onChange: (v) {
                            selectedState = v;

                            districtList = allDistricts
                                .where(
                                  (d) =>
                                      d["state"] ==
                                      categoryList.firstWhere(
                                        (s) => s["id"].toString() == v,
                                      )["name"],
                                )
                                .toList();

                            selectedDistrict = null;
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),

                  _dropdownField(
                    label: "Product Type",
                    value: productType,
                    items: productTypeList,
                    onChange: (v) {
                      setState(() {
                        productType = v;
                        if (productType != "single") {
                          stockCtrl.clear();
                        }
                      });
                    },
                  ),

                  if (productType == "single")
                    _inputField("Stock", stockCtrl, isNumber: true),

                  if (productType == "single")
                    _inputField("Discount", discount, isNumber: true),

                  _inputField("Price", priceCtrl, isNumber: true),

                  _inputField(
                    "Return Policy Days",
                    returnPolicyCtrl,
                    isNumber: true,
                  ),

                  _inputField(
                    "Shipment Charge",
                    shipmentChargeCtrl,
                    isNumber: true,
                  ),

                  _paymentMethodDropdown(),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;

                        // if (dob == null) {
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     const SnackBar(
                        //       content: Text("Date of Birth is required"),
                        //     ),
                        //   );
                        //   return;
                        // }

                        if (productType == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Product Type is required"),
                            ),
                          );
                          return;
                        }

                        if (productType == "single" &&
                            stockCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Stock is required for single product",
                              ),
                            ),
                          );
                          return;
                        }
                        if (productType == "single" &&
                            discount.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "discount is required for single product",
                              ),
                            ),
                          );
                          return;
                        }

                        if (returnPolicyCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Return Policy Days is required"),
                            ),
                          );
                          return;
                        }

                        if (shipmentChargeCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Shipment Charge is required"),
                            ),
                          );
                          return;
                        }

                        if (selectedPaymentMethods.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "At least one payment method is required",
                              ),
                            ),
                          );
                          return;
                        }

                        submitProduct();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Submit",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    bool isNumber = false,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: [
          if (isNumber) FilteringTextInputFormatter.digitsOnly,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        style: TextStyle(color: readOnly ? Colors.white70 : Colors.white),
        decoration: _dec(label).copyWith(
          fillColor: readOnly
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.05),
        ),
        validator: (v) {
          final value = v?.trim() ?? "";
          if (value.isEmpty) return "$label is required";

          if (label == "Email") {
            final regex = RegExp(r"^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$");
            if (!regex.hasMatch(value)) return "Enter valid email";
          }
          if (label == "Alt Phone" && value.length != 10) {
            return "Alt Phone must be 10 digits";
          }

          return null;
        },
      ),
    );
  }

  // Widget _paymentInputField(String label, TextEditingController controller) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 20),
  //     child: TextField(
  //       controller: controller,
  //       style: const TextStyle(color: Colors.white),
  //       decoration: _dec(label),
  //     ),
  //   );
  // }
  Widget _inputFieldmax(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    bool isNumber = false,
    int? maxLength,
    int? maxLines = 1,
    int minLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardType: maxLines == null || maxLines > 1
            ? TextInputType.multiline
            : (isNumber ? TextInputType.number : TextInputType.text),
        maxLines: maxLines,
        minLines: minLines,
        inputFormatters: [
          if (isNumber && maxLines == 1) FilteringTextInputFormatter.digitsOnly,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        style: TextStyle(color: readOnly ? Colors.white70 : Colors.white),
        decoration: _dec(label).copyWith(
          alignLabelWithHint: true,
          fillColor: readOnly
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.05),
        ),
        validator: (v) {
          final value = v?.trim() ?? "";

          if (value.isEmpty) return "$label is required";

          if (label == "Email") {
            final regex = RegExp(r"^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$");
            if (!regex.hasMatch(value)) return "Enter valid email";
          }

          if (label == "Alt Phone" && maxLines == 1 && value.length != 10) {
            return "Alt Phone must be 10 digits";
          }

          return null;
        },
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      floatingLabelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value, // ID
    required List<Map<String, dynamic>> items,
    required Function(String?) onChange,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _dec(label),
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.white),
        items: items.map((e) {
          return DropdownMenuItem<String>(
            value: e["id"].toString(),
            child: Text(e["name"], style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: onChange,
        validator: (v) => v == null || v.isEmpty ? "$label is required" : null,
      ),
    );
  }

  // Widget _dobPicker() {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 20),
  //     child: GestureDetector(
  //       onTap: () async {
  //         DateTime? picked = await showDatePicker(
  //           context: context,
  //           initialDate: DateTime(2005),
  //           firstDate: DateTime(1950),
  //           lastDate: DateTime.now(),
  //           builder: (c, child) => Theme(data: ThemeData.dark(), child: child!),
  //         );
  //         if (picked != null) setState(() => dob = picked);
  //       },
  //       child: FormField(
  //         validator: (_) => dob == null ? "Date of Birth is required" : null,
  //         builder: (state) => Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             InputDecorator(
  //               decoration: _dec("Date of Birth"),
  //               child: Text(
  //                 dob == null
  //                     ? "Select Date"
  //                     : "${dob!.day}/${dob!.month}/${dob!.year}",
  //                 style: const TextStyle(color: Colors.white),
  //               ),
  //             ),
  //             if (state.hasError)
  //               Padding(
  //                 padding: const EdgeInsets.only(top: 5, left: 12),
  //                 child: Text(
  //                   state.errorText!,
  //                   style: const TextStyle(
  //                     color: Colors.redAccent,
  //                     fontSize: 12,
  //                   ),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

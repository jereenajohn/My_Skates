import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Dropdown selected IDs
  String? gender;
  String? selectedCountry;
  String? selectedState;
  String? selectedDistrict;

  // Lists
  List<Map<String, dynamic>> countryList = [];
  List<Map<String, dynamic>> stateList = [];
  List<Map<String, dynamic>> allDistricts = [];
  List<Map<String, dynamic>> districtList = [];

  // Image
  File? profileImage;
  String? profileNetworkImage;
  final ImagePicker _picker = ImagePicker();

  // DOB
  DateTime? dob;

  // Controllers
  final TextEditingController firstCtrl = TextEditingController();
  final TextEditingController lastCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController altPhoneCtrl = TextEditingController();
  final TextEditingController ageCtrl = TextEditingController();
  final TextEditingController zipCtrl = TextEditingController();
  final TextEditingController instaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  // MASTER LOAD FUNCTION
  Future<void> loadAllData() async {
    await fetchProfileData();

    await Future.wait([fetchCountries(), fetchStates(), fetchDistricts()]);

    mapExistingIDs();
  }

  // MAP PROFILE VALUES (names) → IDs
  void mapExistingIDs() {
    // Country
    if (selectedCountry != null) {
      final c = countryList.firstWhere(
        (e) => e["name"] == selectedCountry,
        orElse: () => {},
      );
      if (c.isNotEmpty) selectedCountry = c["id"].toString();
    }

    // State
    if (selectedState != null) {
      final s = stateList.firstWhere(
        (e) => e["name"] == selectedState,
        orElse: () => {},
      );
      if (s.isNotEmpty) selectedState = s["id"].toString();
    }

    // District
    if (selectedDistrict != null) {
      final d = allDistricts.firstWhere(
        (e) => e["name"] == selectedDistrict,
        orElse: () => {},
      );
      if (d.isNotEmpty) selectedDistrict = d["id"].toString();
    }

    // FILTER DISTRICTS based on selected state ID
    if (selectedState != null) {
      String stateName = stateList.firstWhere(
        (s) => s["id"].toString() == selectedState,
      )["name"];

      districtList = allDistricts.where((d) => d["state"] == stateName).toList();
    }

    setState(() {});
  }

  // ----------- FETCH API DATA -----------

  Future<void> fetchCountries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/country/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        countryList = data.map((e) => {"id": e["id"], "name": e["name"]}).toList();
      }
    } catch (e) {
      print("Country error: $e");
    }
  }

  Future<void> fetchStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/state/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        stateList = data.map((e) => {"id": e["id"], "name": e["name"]}).toList();
      }
    } catch (e) {
      print("State error: $e");
    }
  }

  Future<void> fetchDistricts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/district/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        allDistricts = data
            .map((e) => {"id": e["id"], "name": e["name"], "state": e["state"]})
            .toList();
      }
    } catch (e) {
      print("District error: $e");
    }
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

        firstCtrl.text = data["first_name"] ?? "";
        lastCtrl.text = data["last_name"] ?? "";
        phoneCtrl.text = data["phone"] ?? "";
        emailCtrl.text = data["email"] ?? "";
        altPhoneCtrl.text = data["alt_phone"] ?? "";
        ageCtrl.text = data["age"]?.toString() ?? "";
        zipCtrl.text = data["zip_code"]?.toString() ?? "";
        instaCtrl.text = data["instagram"] ?? "";

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
    } catch (e) {
      print("Profile fetch error: $e");
    }
  }

  // ------------ SUBMIT PROFILE ------------

  Future<void> submitProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$api/api/myskates/user/extras/details/$userId/"),
      );

      request.headers["Authorization"] = "Bearer $token";

      request.fields["first_name"] = firstCtrl.text.trim();
      request.fields["last_name"] = lastCtrl.text.trim();
      request.fields["phone"] = phoneCtrl.text.trim();
      request.fields["email"] = emailCtrl.text.trim();
      request.fields["alt_phone"] = altPhoneCtrl.text.trim();
      request.fields["gender"] = gender ?? "";
      request.fields["age"] = ageCtrl.text.trim();
      request.fields["zip_code"] = zipCtrl.text.trim();
      request.fields["instagram"] = instaCtrl.text.trim();

      request.fields["dob"] =
          dob != null ? dob!.toIso8601String().substring(0, 10) : "";

      request.fields["country"] = selectedCountry ?? "";
      request.fields["state"] = selectedState ?? "";
      request.fields["district"] = selectedDistrict ?? "";

      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile', profileImage!.path),
        );
      }

      final response = await request.send();
      final result = await response.stream.bytesToString();

      print("UPDATE: ${response.statusCode}\n$result");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    backgroundColor: Colors.teal,
    content: Text(
      "Profile updated successfully",
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    duration: Duration(seconds: 2),
  ),
);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    } catch (e) {
      print("Submit error: $e");
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Color(0xFF000000)],
            begin: Alignment.topLeft,
            // end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Profile Image
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
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.white24,
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage!)
                          : (profileNetworkImage != null
                              ? NetworkImage(profileNetworkImage!)
                              : null) as ImageProvider<Object>?,
                      child: profileImage == null && profileNetworkImage == null
                          ? const Text(
                              "Upload",
                              style: TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ------------------ FIRST NAME + LAST NAME ROW ------------------
                  Row(
                    children: [
                      Expanded(
                        child: _inputField("First Name", firstCtrl),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _inputField("Last Name", lastCtrl),
                      ),
                    ],
                  ),

                  _inputField("Phone", phoneCtrl, readOnly: true),

                  // EMAIL + ALT PHONE (as-is, but validated)
                  _inputField("Email", emailCtrl),
                  _inputField(
                    "Alt Phone",
                    altPhoneCtrl,
                    isNumber: true,
                    maxLength: 10, // STRICT 10 DIGITS
                  ),

                  // ------------------ GENDER + DOB ROW ------------------
                  Row(
                    children: [
                      Expanded(
                        child: _dropdownField(
                          label: "Gender",
                          value: gender,
                          items: const ["Male", "Female", "Other"],
                          onChange: (v) => setState(() => gender = v),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(child: _dobPicker()), // DOB picker fits perfectly
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ------------------ ZIP + COUNTRY ROW ------------------
                  Row(
                    children: [
                      Expanded(
                        child: _inputField(
                          "Zip Code",
                          zipCtrl,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _dropdownField(
                          label: "Country",
                          value: selectedCountry == null
                              ? null
                              : countryList.firstWhere(
                                  (e) =>
                                      e["id"].toString() == selectedCountry,
                                  orElse: () => {"name": null},
                                )["name"],
                          items: countryList
                              .map((e) => e["name"] as String)
                              .toList(),
                          onChange: (v) {
                            final selected = countryList.firstWhere(
                              (e) => e["name"] == v,
                            );
                            selectedCountry = selected["id"].toString();
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ------------------ STATE + DISTRICT ROW ------------------
                  Row(
                    children: [
                      Expanded(
                        child: _dropdownField(
                          label: "State",
                          value: selectedState == null
                              ? null
                              : stateList.firstWhere(
                                  (e) =>
                                      e["id"].toString() == selectedState,
                                  orElse: () => {"name": null},
                                )["name"],
                          items: stateList
                              .map((e) => e["name"] as String)
                              .toList(),
                          onChange: (v) {
                            final selected = stateList.firstWhere(
                              (e) => e["name"] == v,
                            );
                            selectedState = selected["id"].toString();

                            districtList = allDistricts
                                .where((d) => d["state"] == v)
                                .toList();
                            selectedDistrict = null;
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _dropdownField(
                          label: "District",
                          value: selectedDistrict == null
                              ? null
                              : districtList.firstWhere(
                                  (e) =>
                                      e["id"].toString() ==
                                      selectedDistrict,
                                  orElse: () => {"name": null},
                                )["name"],
                          items: districtList
                              .map((e) => e["name"] as String)
                              .toList(),
                          onChange: (v) {
                            final selected = districtList.firstWhere(
                              (e) => e["name"] == v,
                            );
                            selectedDistrict = selected["id"].toString();
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),

                  _inputField("Instagram", instaCtrl),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity, // full width
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: Colors.black87,
    content: const Text(
      "Please fix the errors in the form.",
      style: TextStyle(
        color: Colors.redAccent,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    duration: Duration(seconds: 2),
  ),
);

                          return;
                        }

                        if (dob == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Date of Birth is required"),
                            ),
                          );
                          return;
                        }

                        submitProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Update Profile",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- REUSABLE UI ----------------

  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    bool isNumber = false,
    bool isRequired = true,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,

        controller: controller,
        readOnly: readOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: [
          if (isNumber) FilteringTextInputFormatter.digitsOnly,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        style: TextStyle(color: readOnly ? Colors.white70 : Colors.white),
        decoration: _dec(label).copyWith(
          fillColor: readOnly ? Colors.black26 : const Color(0xFF1E1E1E),
        ),
        validator: (value) {
          final v = value?.trim() ?? "";

          if (isRequired && v.isEmpty) {
            return "$label is required";
          }

          if (label == "Email" && v.isNotEmpty) {
            final validEmail =
                RegExp(r"^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$");
            if (!validEmail.hasMatch(v)) {
              return "Enter valid email";
            }
          }

          if (label == "Zip Code" && v.isNotEmpty) {
            if (int.tryParse(v) == null) {
              return "Zip must be numeric";
            }
          }

          if (label == "Alt Phone") {
            if (v.isEmpty) {
              return "Alt Phone is required";
            }
            if (v.length != 10) {
              return "Alt Phone must be 10 digits";
            }
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
    fillColor: const Color(0xFF1E1E1E),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Colors.white24),
    ),

    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Colors.white24),
    ),

    // IMPORTANT: prevent Flutter from changing border on error
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Colors.white24),
    ),

    errorStyle: const TextStyle(
      color: Colors.redAccent,
      fontSize: 12,
    ),
  );
}


  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChange,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _dec(label),
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.white),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ),
            )
            .toList(),
        onChanged: onChange,
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return "$label is required";
          }
          return null;
        },
      ),
    );
  }

  Widget _dobPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2005),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
            builder: (c, child) => Theme(data: ThemeData.dark(), child: child!),
          );

          if (picked != null) setState(() => dob = picked);
        },
        child: FormField(
          validator: (_) => dob == null ? "Date of Birth is required" : null,
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputDecorator(
                decoration: _dec("Date of Birth"),
                child: Text(
                  dob == null
                      ? "Select Date"
                      : "${dob!.day}/${dob!.month}/${dob!.year}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 12),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
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

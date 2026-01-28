import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/STUDENTS/Home_Page.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? gender;
  String? selectedCountry;
  String? selectedState;
  String? selectedDistrict; 

  List<Map<String, dynamic>> countryList = [];
  List<Map<String, dynamic>> stateList = [];
  List<Map<String, dynamic>> allDistricts = [];
  List<Map<String, dynamic>> districtList = [];

  File? profileImage;
  String? profileNetworkImage;
  final ImagePicker _picker = ImagePicker();

  DateTime? dob;

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

  Future<void> loadAllData() async {
    await fetchProfileData();
    await Future.wait([fetchCountries(), fetchStates(), fetchDistricts()]);
    mapExistingIDs();
  }

  void mapExistingIDs() {
    if (gender != null) {
      gender = gender!.toLowerCase(); 
    }

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

    // Filter districts based on selected state ID
    if (selectedState != null) {
      String stateName = stateList.firstWhere(
        (s) => s["id"].toString() == selectedState,
      )["name"];

      districtList = allDistricts
          .where((d) => d["state"] == stateName)
          .toList();
    }

    setState(() {});
  }

  // ---------------- FETCH API ----------------

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
        countryList = data
            .map((e) => {"id": e["id"], "name": e["name"]})
            .toList();
      }
    } catch (e) {}
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
        stateList = data
            .map((e) => {"id": e["id"], "name": e["name"]})
            .toList();
      }
    } catch (e) {}
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
    } catch (e) {}
  }

  // ---------------- SUBMIT ----------------

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

      request.fields.addAll({
        "first_name": firstCtrl.text.trim(),
        "last_name": lastCtrl.text.trim(),
        "phone": phoneCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "alt_phone": altPhoneCtrl.text.trim(),
        "gender": gender ?? "",
        "age": ageCtrl.text.trim(),
        "zip_code": zipCtrl.text.trim(),
        "instagram": instaCtrl.text.trim(),
        "dob": dob != null ? dob!.toIso8601String().substring(0, 10) : "",
        "country": selectedCountry ?? "",
        "state": selectedState ?? "",
        "district": selectedDistrict ?? "",
      });

      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("profile", profileImage!.path),
        );
      }

      final response = await request.send();
      final result = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text(
              "Profile updated successfully",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result)));
      }
    } catch (e) {}
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
                                    : null)
                                as ImageProvider<Object>?,
                      child: profileImage == null && profileNetworkImage == null
                          ? const Text(
                              "Upload",
                              style: TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(child: _inputField("First Name", firstCtrl)),
                      const SizedBox(width: 15),
                      Expanded(child: _inputField("Last Name", lastCtrl)),
                    ],
                  ),

                  _inputField("Phone", phoneCtrl, readOnly: true),
                  _inputField("Email", emailCtrl),
                  _inputField(
                    "Alt Phone",
                    altPhoneCtrl,
                    isNumber: true,
                    maxLength: 10,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _dropdownField(
                          label: "Gender",
                          value: gender,
                          items: const [
                            {"id": "male", "name": "Male"},
                            {"id": "female", "name": "Female"},
                            {"id": "other", "name": "Other"},
                          ],
                          onChange: (v) => setState(() => gender = v),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(child: _dobPicker()),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _inputField("Zip Code", zipCtrl, isNumber: true),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _dropdownField(
                          label: "Country",
                          value: selectedCountry,
                          items: countryList,
                          onChange: (v) {
                            selectedCountry = v;
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _dropdownField(
                          label: "State",
                          value: selectedState,
                          items: stateList,
                          onChange: (v) {
                            selectedState = v;

                            districtList = allDistricts
                                .where(
                                  (d) =>
                                      d["state"] ==
                                      stateList.firstWhere(
                                        (s) => s["id"].toString() == v,
                                      )["name"],
                                )
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
                          value: selectedDistrict,
                          items: districtList,
                          onChange: (v) {
                            selectedDistrict = v;
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),

                  _inputField("Instagram", instaCtrl),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;

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

  // ---------------- REUSABLE ----------------

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
          fillColor: readOnly ? Colors.black26 : const Color(0xFF1E1E1E),
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
    required String? value, 
    required List<Map<String, dynamic>> items,
    required Function(String?) onChange,
  }) {
    //  SAFETY CHECK (THIS FIXES THE CRASH)
    final String? safeValue =
        (value != null && items.any((e) => e["id"].toString() == value))
        ? value
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: safeValue, // USE SAFE VALUE
        decoration: _dec(label),
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.white),
        items: items.map((e) {
          return DropdownMenuItem<String>(
            value: e["id"].toString(),
            child: Text(e["name"]),
          );
        }).toList(),
        onChanged: onChange,
        validator: (v) => v == null || v.isEmpty ? "$label is required" : null,
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

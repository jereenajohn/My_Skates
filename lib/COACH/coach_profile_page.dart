import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:my_skates/api.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class CoachProfilePage extends StatefulWidget {
  const CoachProfilePage({super.key});

  @override
  State<CoachProfilePage> createState() => _CoachProfilePageState();
}

class _CoachProfilePageState extends State<CoachProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Store IDs only - same as first page
  String? gender;            // "male", "female", "other"
  String? selectedCountry;   // ID
  String? selectedState;     // ID
  String? selectedDistrict;  // ID

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

  // Username controllers
  final TextEditingController usernameCtrl = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  String? usernameError;
  bool isUsernameValid = false;
  bool isCheckingUsername = false;
  Timer? _debounceTimer;
  String? _originalUsername;

  bool _isLoading = true;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _usernameFocusNode.addListener(() {
      if (_usernameFocusNode.hasFocus) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    loadAllData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _usernameFocusNode.dispose();
    usernameCtrl.dispose();
    firstCtrl.dispose();
    lastCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    altPhoneCtrl.dispose();
    ageCtrl.dispose();
    zipCtrl.dispose();
    instaCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await fetchProfileData();
      await Future.wait([fetchCountries(), fetchStates(), fetchDistricts()]);
      mapExistingIDs(); // Same mapping function as first page
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load data: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Same mapping function as first page - converts backend NAME to ID
  void mapExistingIDs() {
    // Gender fix (backend sends "Male")
    if (gender != null) {
      gender = gender!.toLowerCase(); // Male → male
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

    // Filter districts based on selected state ID - using name comparison as in first page
    if (selectedState != null) {
      String stateName = stateList
          .firstWhere((s) => s["id"].toString() == selectedState)["name"];

      districtList = allDistricts.where((d) => d["state"] == stateName).toList();
    }

    setState(() {});
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    return {
      "Authorization": "Bearer $token",
      "ngrok-skip-browser-warning": "true",
      "Content-Type": "application/json",
    };
  }

  // ---------------- FETCH PROFILE DATA ----------------

  Future<void> fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      final res = await http.get(
        Uri.parse("$api/api/myskates/user/extras/details/$userId/"),
        headers: {
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "true",
        },
      );

      print("Profile data: ${res.body}");

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

        gender = data["gender"]?.toString(); // ex: "Male"
        selectedCountry = data["country"]?.toString();
        selectedState = data["state"]?.toString();
        selectedDistrict = data["district"]?.toString();

        if (data["u_name"] != null) {
          final loadedUsername = data["u_name"].toString().trim();
          usernameCtrl.text = loadedUsername;
          _originalUsername = loadedUsername;
          isUsernameValid = true;
          print("Username loaded: $loadedUsername");
        } else {
          print("No username found in profile data");
          isUsernameValid = false;
        }

        if (data["dob"] != null) {
          dob = DateTime.tryParse(data["dob"]);
        }

        if (data["profile"] != null) {
          profileNetworkImage = "$api${data["profile"]}";
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  // ---------------- CHECK USERNAME ----------------

  Future<void> checkUsername(String username) async {
    username = username.trim().toLowerCase();

    if (username.isEmpty) {
      setState(() {
        usernameError = null;
        isUsernameValid = false;
      });
      return;
    }

    if (username == _originalUsername) {
      setState(() {
        usernameError = null;
        isUsernameValid = true;
        isCheckingUsername = false;
      });
      return;
    }

    if (username.length < 3) {
      setState(() {
        usernameError = "Username must be at least 3 characters";
        isUsernameValid = false;
      });
      return;
    }

    if (username.length > 30) {
      setState(() {
        usernameError = "Username must be less than 30 characters";
        isUsernameValid = false;
      });
      return;
    }

    if (!RegExp(r'^[a-z]').hasMatch(username)) {
      setState(() {
        usernameError = "Username must start with a letter";
        isUsernameValid = false;
      });
      return;
    }

    if (username.endsWith('.')) {
      setState(() {
        usernameError = "Username cannot end with a dot";
        isUsernameValid = false;
      });
      return;
    }

    if (username.contains('..')) {
      setState(() {
        usernameError = "Username cannot contain consecutive dots";
        isUsernameValid = false;
      });
      return;
    }

    if (!RegExp(r'^[a-z]([a-z0-9_.]{1,28}[a-z0-9])?$').hasMatch(username)) {
      setState(() {
        usernameError =
            "Username can only contain lowercase letters, numbers, dots, and underscores";
        isUsernameValid = false;
      });
      return;
    }

    setState(() {
      isCheckingUsername = true;
      usernameError = null;
    });

    try {
      final headers = await _getHeaders();

      final res = await http.get(
        Uri.parse("$api/api/myskates/username/check/?u_name=$username"),
        headers: headers,
      );

      print("Username check response: ${res.statusCode} - ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["available"] == true) {
          setState(() {
            usernameError = null;
            isUsernameValid = true;
          });
        } else {
          setState(() {
            usernameError = data["error"] ?? "Username is not available";
            isUsernameValid = false;
          });
        }
      } else {
        setState(() {
          usernameError = "Error checking username";
          isUsernameValid = false;
        });
      }
    } catch (e) {
      print("Network error: $e");
      setState(() {
        usernameError = "Network error";
        isUsernameValid = false;
      });
    } finally {
      setState(() {
        isCheckingUsername = false;
      });
    }
  }

  // ---------------- SET/UPDATE USERNAME ----------------

  Future<bool> setUsername(String username) async {
    try {
      final headers = await _getHeaders();
      final trimmed = username.trim().toLowerCase();

      if (trimmed == _originalUsername) {
        print("Username unchanged, skipping update");
        return true;
      }

      print("Attempting to update username to: $trimmed");

      final res = await http.patch(
        Uri.parse("$api/api/myskates/username/set/"),
        headers: headers,
        body: jsonEncode({
          "u_name": trimmed,
        }),
      );

      print("Username set response: ${res.statusCode} - ${res.body}");

      if (res.statusCode == 200 ||
          res.statusCode == 201 ||
          res.statusCode == 204) {
        final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        _originalUsername = trimmed;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.teal,
              content: Text(
                data["message"] ?? "Username updated successfully",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        return true;
      } else {
        final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        print("Username update failed: ${data["error"] ?? data["message"]}");

        if (mounted) {
          setState(() {
            usernameError = data["error"] ?? "Username update failed";
            isUsernameValid = false;
          });
        }
        return false;
      }
    } catch (e) {
      print("Error setting username: $e");
      if (mounted) {
        setState(() {
          usernameError = "Network error: $e";
          isUsernameValid = false;
        });
      }
      return false;
    }
  }

  // ---------------- FETCH LOCATION DATA ----------------

  Future<void> fetchCountries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/country/"),
        headers: {
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "true",
        },
      );

      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        countryList =
            data.map((e) => {"id": e["id"], "name": e["name"]}).toList();
      }
    } catch (e) {
      print("Error fetching countries: $e");
    }
  }

  Future<void> fetchStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/state/"),
        headers: {
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "true",
        },
      );

      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        stateList =
            data.map((e) => {"id": e["id"], "name": e["name"]}).toList();
      }
    } catch (e) {
      print("Error fetching states: $e");
    }
  }

  Future<void> fetchDistricts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/district/"),
        headers: {
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "true",
        },
      );

      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        allDistricts = data
            .map((e) => {"id": e["id"], "name": e["name"], "state": e["state"]})
            .toList();
      }
    } catch (e) {
      print("Error fetching districts: $e");
    }
  }

  // ---------------- SUBMIT PROFILE ----------------

  Future<void> submitProfile() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      final currentUsername = usernameCtrl.text.trim().toLowerCase();

      // Update username only if it changed
      if (isUsernameValid && currentUsername.isNotEmpty) {
        if (currentUsername != _originalUsername) {
          print("Attempting to update username to: $currentUsername");

          bool usernameUpdated = await setUsername(currentUsername);

          if (!usernameUpdated) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    "Username update failed. Please choose a different username.",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
            await fetchProfileData();
            setState(() => _isLoading = false);
            return;
          }

          print("Username updated successfully to: $currentUsername");
        } else {
          print("Username unchanged, skipping update");
        }
      }

      // Build multipart PUT request for profile
      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("$api/api/myskates/user/extras/details/$userId/"),
      );

      request.headers["Authorization"] = "Bearer $token";
      request.headers["ngrok-skip-browser-warning"] = "true";

      request.fields.addAll({
        "first_name": firstCtrl.text.trim(),
        "last_name": lastCtrl.text.trim(),
        "phone": phoneCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "alt_phone": altPhoneCtrl.text.trim(),
        "gender": gender ?? "", // sends ID like "male"
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

      print("Profile update response: ${response.statusCode} - $result");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.teal,
              content: Text(
                "Profile updated successfully",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      } else {
        throw Exception("Update failed: ${response.statusCode}\n$result");
      }
    } catch (e) {
      print("Submit error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Error: $e",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- USERNAME UI METHOD ----------------

  Widget _buildUsernameField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Username",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                " *",
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUsernameValid
                    ? Colors.green
                    : usernameError != null
                        ? Colors.redAccent
                        : Colors.white24,
                width: isUsernameValid || usernameError != null ? 1.5 : 1,
              ),
            ),
            child: TextFormField(
              controller: usernameCtrl,
              focusNode: _usernameFocusNode,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                hintText: "Choose a unique username",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Colors.white54,
                  size: 22,
                ),
                suffixIcon: _buildSuffixIcon(),
              ),
              onChanged: (value) {
                if (_debounceTimer?.isActive ?? false) {
                  _debounceTimer?.cancel();
                }

                final trimmed = value.trim().toLowerCase();

                // If same as original → keep valid
                if (trimmed == _originalUsername) {
                  setState(() {
                    usernameError = null;
                    isUsernameValid = true;
                    isCheckingUsername = false;
                  });
                  return;
                }

                setState(() {
                  isUsernameValid = false;
                  usernameError = null;
                });

                _debounceTimer = Timer(const Duration(milliseconds: 600), () {
                  checkUsername(trimmed);
                });
              },
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Username is required";
                }
                if (!isUsernameValid) {
                  return usernameError ?? "Please enter a valid username";
                }
                return null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: _buildHelperText(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuffixIcon() {
    if (isCheckingUsername) {
      return Container(
        margin: const EdgeInsets.all(12),
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
        ),
      );
    }

    if (isUsernameValid && usernameCtrl.text.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        child: const Icon(Icons.check_circle, color: Colors.green, size: 22),
      );
    }

    if (usernameError != null && usernameCtrl.text.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        child: const Icon(Icons.error, color: Colors.redAccent, size: 22),
      );
    }

    return const SizedBox(width: 40);
  }

  Widget _buildHelperText() {
    if (isCheckingUsername) {
      return Row(
        children: [
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Checking availability...",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    if (isUsernameValid && usernameCtrl.text.isNotEmpty) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          const Text(
            "Username available",
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (usernameError != null) {
      return Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              usernameError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        children: const [
          TextSpan(text: "• Start with letter • "),
          TextSpan(text: "Lowercase letters, numbers, _ or . • "),
          TextSpan(text: "No consecutive dots • "),
          TextSpan(text: "Can't end with dot"),
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Color(0xFF000000)],
            begin: Alignment.topLeft,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                )
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: loadAllData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                            ),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
                                backgroundImage:
                                    (profileImage != null
                                            ? FileImage(profileImage!)
                                            : (profileNetworkImage != null
                                                ? NetworkImage(
                                                    profileNetworkImage!,
                                                  )
                                                : null))
                                        as ImageProvider<Object>?,
                                child: profileImage == null &&
                                        profileNetworkImage == null
                                    ? const Text(
                                        "Upload",
                                        style: TextStyle(color: Colors.white),
                                      )
                                    : null,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // USERNAME FIELD
                            _buildUsernameField(),

                            const SizedBox(height: 10),

                            // Name Fields
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
                            _inputField("Email", emailCtrl),
                            _inputField(
                              "Alt Phone",
                              altPhoneCtrl,
                              isNumber: true,
                              maxLength: 10,
                            ),

                            // Gender and DOB
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
                                    onChange: (v) =>
                                        setState(() => gender = v),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(child: _dobPicker()),
                              ],
                            ),

                            // Zip Code and Country
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

                            // State and District - Updated to match first page pattern
                            Row(
                              children: [
                                Expanded(
                                  child: _dropdownField(
                                    label: "State",
                                    value: selectedState,
                                    items: stateList,
                                    onChange: (v) {
                                      selectedState = v;

                                      // Filter districts based on selected state ID - using name comparison as in first page
                                      String stateName = stateList.firstWhere(
                                        (s) => s["id"].toString() == v,
                                      )["name"];

                                      districtList = allDistricts
                                          .where((d) =>
                                              d["state"] == stateName)
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

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        if (!_formKey.currentState!
                                            .validate()) {
                                          return;
                                        }

                                        if (dob == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Date of Birth is required",
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        if (!isUsernameValid) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Please choose a valid username",
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        submitProfile();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Update Profile",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  // ---------------- REUSABLE WIDGETS ----------------

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
            child: Text(e["name"]),
          );
        }).toList(),
        onChanged: onChange,
        validator: (v) =>
            v == null || v.isEmpty ? "$label is required" : null,
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
            initialDate: dob ?? DateTime(2005),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
            builder: (c, child) =>
                Theme(data: ThemeData.dark(), child: child!),
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
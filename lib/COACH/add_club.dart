import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:my_skates/api.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddClub extends StatefulWidget {
  const AddClub({super.key});

  @override
  State<AddClub> createState() => _AddClubState();
}

class _AddClubState extends State<AddClub> {
  // Controllers
  final TextEditingController clubNameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController instaCtrl = TextEditingController();
  final TextEditingController placeCtrl = TextEditingController();
  Map<String, int> stateNameToId = {};

  // Dropdown variables
  int? selectedStateId;
  String? selectedStateName;

  int? selectedDistrictId;
  String? selectedDistrictName;

  List<Map<String, dynamic>> stat = [];
  List<Map<String, dynamic>> district = [];
  double? currentLat;
  double? currentLong;
  String? currentAddress;
  XFile? pickedImage;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getstate();
    getdistrict();
  }

  Future<void> pickImageFromGallery() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      setState(() {
        pickedImage = img;
      });
    }
  }

  Future<void> getstate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    var response = await http.get(
      Uri.parse('$api/api/myskates/state/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      setState(() {
        stat = data.map((e) => {'id': e['id'], 'name': e['name']}).toList();

        stateNameToId = {for (var s in stat) s["name"]: s["id"]};
      });
    }
  }

  Future<void> getdistrict() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    var response = await http.get(
      Uri.parse('$api/api/myskates/district/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      setState(() {
        district = data
            .map(
              (e) => {
                'id': e['id'],
                'name': e['name'],
                'state': stateNameToId[e['state']] ?? 0, // map state name → id
              },
            )
            .toList();
      });
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

      var url = Uri.parse(
        "$api/api/myskates/club/",
      ); // Replace with actual endpoint

      var request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";

      // Add all text fields
      request.fields.addAll({
        "club_name": clubNameCtrl.text.trim(),
        "coach": "$id",
        "description": descCtrl.text.trim(),
        "instagram": instaCtrl.text.trim(),
        "state": selectedStateId?.toString() ?? "",
        "district": selectedDistrictId?.toString() ?? "",
        "place": placeCtrl.text.trim(),
        "latitude": currentLat?.toString() ?? "",
        "longitude": currentLong?.toString() ?? "",
      });

      // Upload image if selected
      if (pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "image", // backend field name
            pickedImage!.path,
          ),
        );
      }
      print("REQUEST FIELDS: ${request.fields}");
      print("REQUEST FILES: ${request.files.length}");
      print(pickedImage);
      print("Sending request...");
      var response = await request.send();

      var responseBody = await response.stream.bytesToString();
      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE: $responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Club Created Successfully!"),
            backgroundColor: Colors.green, // SUCCESS GREEN
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddClub()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: $responseBody"),
            backgroundColor: Colors.red, // ERROR RED
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

  // UI STARTS HERE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.center,
            colors: [Color(0xFF0A332E), Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BACK BUTTON
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
                  ],
                ),

                const SizedBox(height: 20),

                // UPLOAD PHOTO
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
                                : null,
                          ),
                          child: pickedImage == null
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

                const SizedBox(height: 15),

                buildLabel("Club Name"),
                buildTextField(clubNameCtrl),

                buildLabel("Description"),
                buildTextField(descCtrl, maxLines: 4),

                buildLabel("Add official Instagram ID"),
                buildTextField(instaCtrl),

                buildLabel("State?"),
                buildStateDropdown(),

                buildLabel("District?"),
                buildDistrictDropdown(),

                buildLabel("Place?"),
                buildTextField(placeCtrl),

                const SizedBox(height: 10),
                const Text(
                  "Where is your Club Located?",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectLocationOSM(),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        currentLat = result['lat'];
                        currentLong = result['lng'];
                        currentAddress = result['address'];
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006A63),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            currentAddress ?? "Tap Change Location",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // CREATE CLUB BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      submitClub();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9B8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Create Club",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // LABEL WIDGET
  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  // TEXTFIELD UI
  Widget buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(157, 37, 37, 37),
        borderRadius: BorderRadius.circular(18),
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

  // STATE DROPDOWN
  Widget buildStateDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(157, 37, 37, 37),
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          dropdownColor: const Color(0xFF1A1A1A),
          isExpanded: true,

          value: selectedStateId,
          iconEnabledColor: Colors.white70,
          hint: const Text(
            "Select State",
            style: TextStyle(color: Colors.white54),
          ),
          items: stat.map<DropdownMenuItem<int>>((item) {
            return DropdownMenuItem<int>(
              value: item['id'] as int,
              child: Text(
                item['name'].toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),

          onChanged: (value) {
            setState(() {
              selectedStateId = value;
              selectedStateName = stat.firstWhere(
                (e) => e['id'] == value,
              )['name'];

              // reset district
              selectedDistrictId = null;
              selectedDistrictName = null;
            });
          },
        ),
      ),
    );
  }

  // DISTRICT DROPDOWN (FILTERED BY STATE)
  Widget buildDistrictDropdown() {
    List<Map<String, dynamic>> filteredDistricts = district
        .where((d) => d['state'] == selectedStateId)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(157, 37, 37, 37),
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          dropdownColor: const Color(0xFF1A1A1A),
          isExpanded: true,

          value: selectedDistrictId,
          iconEnabledColor: Colors.white70,
          hint: const Text(
            "Select District",
            style: TextStyle(color: Colors.white54),
          ),
          items: filteredDistricts.map<DropdownMenuItem<int>>((item) {
            return DropdownMenuItem<int>(
              value: item['id'] as int,
              child: Text(
                item['name'].toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),

          onChanged: (value) {
            setState(() {
              selectedDistrictId = value;
              selectedDistrictName = filteredDistricts.firstWhere(
                (e) => e['id'] == value,
              )['name'];
            });
          },
        ),
      ),
    );
  }
}

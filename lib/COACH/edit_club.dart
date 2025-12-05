import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_skates/COACH/location.dart';
import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditClub extends StatefulWidget {
  final int clubId;

  const EditClub({super.key, required this.clubId});

  @override
  State<EditClub> createState() => _EditClubState();
}

class _EditClubState extends State<EditClub> {
  final ImagePicker picker = ImagePicker();

  // CONTROLLERS
  final TextEditingController clubNameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController instaCtrl = TextEditingController();
  final TextEditingController placeCtrl = TextEditingController();

  // DROPDOWNS
  List<Map<String, dynamic>> stat = [];
  List<Map<String, dynamic>> district = [];

  int? selectedStateId;
  String? selectedStateName;
  int? selectedDistrictId;

  // LOCATION
  double? currentLat;
  double? currentLong;
  String? currentAddress;

  // IMAGE
  XFile? pickedImage;
  String? existingImage;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ---------------------------------------------------------------------------
  // TOKEN
  // ---------------------------------------------------------------------------
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  // ---------------------------------------------------------------------------
  // INITIAL LOAD
  // ---------------------------------------------------------------------------
  Future<void> loadData() async {
    await getStates();
    await getDistricts();
    await fetchClubDetails();
    setState(() => loading = false);
  }

  // ---------------------------------------------------------------------------
  // GET STATES
  // ---------------------------------------------------------------------------
  Future<void> getStates() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$api/api/myskates/state/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      stat = data
          .map((e) => {
                "id": e["id"],
                "name": e["name"],
              })
          .toList();
    }
  }

  // ---------------------------------------------------------------------------
  // GET DISTRICTS
  // ---------------------------------------------------------------------------
  Future<void> getDistricts() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$api/api/myskates/district/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      district = data
          .map((e) => {
                "id": e["id"],
                "name": e["name"],
                "state": e["state"], // STRING (e.g. "Kerala")
              })
          .toList();
    }
  }

  // ---------------------------------------------------------------------------
  // REVERSE GEOCODING (OSM NOMINATIM) - OPTION A (FULL ADDRESS)
  // ---------------------------------------------------------------------------
  Future<String?> getAddressFromLatLng(double lat, double lng) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json");

    final response = await http.get(
      url,
      headers: {
        "User-Agent": "my_skates_flutter_app", // required by Nominatim
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["display_name"]; // FULL address string
    } else {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // FETCH CLUB DETAILS
  // ---------------------------------------------------------------------------
  Future<void> fetchClubDetails() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$api/api/myskates/club/${widget.clubId}/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // BASIC FIELDS
      clubNameCtrl.text = data["club_name"] ?? "";
      descCtrl.text = data["description"] ?? "";
      instaCtrl.text = data["instagram"] ?? "";
      placeCtrl.text = data["place"] ?? "";

      existingImage = data["image"];

      // LAT / LNG
      currentLat = double.tryParse(data["latitude"].toString());
      currentLong = double.tryParse(data["longitude"].toString());

      // ADDRESS: PRIMARY SOURCE = reverse geocoding from lat/lng
      // FALLBACK = backend address field (if you add later) or place
      String? addr;
      if (currentLat != null && currentLong != null) {
        addr = await getAddressFromLatLng(currentLat!, currentLong!);
      }
      currentAddress = addr ?? data["address"] ?? data["place"] ?? "";

      // STATE / DISTRICT IDs FROM API
      selectedStateId = data["state"];
      selectedDistrictId = data["district"];

      // FIND STATE NAME FOR DISTRICT FILTERING
      selectedStateName = stat.firstWhere(
        (s) => s["id"] == selectedStateId,
        orElse: () => {"name": null},
      )["name"];

      setState(() {});
    }
  }

  // ---------------------------------------------------------------------------
  // IMAGE PICKER
  // ---------------------------------------------------------------------------
  Future<void> pickImage() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => pickedImage = img);
    }
  }

  // ---------------------------------------------------------------------------
  // SUBMIT CLUB UPDATE
  // ---------------------------------------------------------------------------
  Future<void> submitEditClub() async {
    final token = await getToken();

    var request = http.MultipartRequest(
      "PUT",
      Uri.parse("$api/api/myskates/club/${widget.clubId}/"),
    );

    request.headers["Authorization"] = "Bearer $token";

    request.fields.addAll({
      "club_name": clubNameCtrl.text,
      "description": descCtrl.text,
      "instagram": instaCtrl.text,
      "place": placeCtrl.text,
      "state": selectedStateId.toString(),
      "district": selectedDistrictId.toString(),
      "latitude": currentLat.toString(),
      "longitude": currentLong.toString(),
      "address": currentAddress ?? "",
    });

    if (pickedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath("image", pickedImage!.path),
      );
    }

    var response = await request.send();
    var resp = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Club Updated Successfully"),
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed: $resp"),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : buildUI(),
    );
  }

  Widget buildUI() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),

            const SizedBox(height: 20),

            // IMAGE UPLOAD
            Center(
              child: GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade700,
                  backgroundImage: pickedImage != null
                      ? FileImage(File(pickedImage!.path))
                      : (existingImage != null
                          ? NetworkImage("$api$existingImage")
                          : null) as ImageProvider?,
                  child: pickedImage == null && existingImage == null
                      ? const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 35,
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // TEXT FIELDS
            label("Club Name"),
            input(clubNameCtrl),

            label("Description"),
            input(descCtrl, maxLines: 4),

            label("Instagram ID"),
            input(instaCtrl),

            label("State"),
            buildStateDropdown(),

            label("District"),
            buildDistrictDropdown(),

            label("Place"),
            input(placeCtrl),

            const SizedBox(height: 22),

            // LOCATION FIELD (LIKE TEXTFIELD BUT TAPPABLE)
           label("Where is your Club Located?"),

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
    decoration: BoxDecoration(
      color: const Color(0xFF006A63), // TEAL COLOR
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    child: Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          color: Colors.white,
          size: 22,
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Text(
            currentAddress?.isNotEmpty == true
                ? currentAddress!
                : "Tap to Select Location",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  ),
),


            const SizedBox(height: 22),

            // UPDATE BUTTON
            ElevatedButton(
              onPressed: submitEditClub,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Center(
                child: Text(
                  "Update Club",
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI HELPERS
  // ---------------------------------------------------------------------------
  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget input(TextEditingController controller, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
        ),
      ),
    );
  }

  // STATE DROPDOWN
  Widget buildStateDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          dropdownColor: Colors.black87,
          value: selectedStateId,
          hint: const Text(
            "Select State",
            style: TextStyle(color: Colors.white70),
          ),
          items: stat.map<DropdownMenuItem<int>>((s) {
            return DropdownMenuItem<int>(
              value: s["id"],
              child: Text(
                s["name"],
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedStateId = value;
              selectedStateName =
                  stat.firstWhere((s) => s["id"] == value)["name"];
              selectedDistrictId = null;
            });
          },
        ),
      ),
    );
  }

  // DISTRICT DROPDOWN — FILTER BY STATE NAME
  Widget buildDistrictDropdown() {
    List filteredDistricts =
        district.where((d) => d["state"] == selectedStateName).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          dropdownColor: Colors.black87,
          value: selectedDistrictId,
          hint: const Text(
            "Select District",
            style: TextStyle(color: Colors.white70),
          ),
          items: filteredDistricts.map<DropdownMenuItem<int>>((d) {
            return DropdownMenuItem<int>(
              value: d["id"],
              child: Text(
                d["name"],
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => selectedDistrictId = value);
          },
        ),
      ),
    );
  }
}

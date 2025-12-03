import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

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

  // Dropdown variables
  int? selectedStateId;
  String? selectedStateName;

  int? selectedDistrictId;
  String? selectedDistrictName;

  List<Map<String, dynamic>> stat = [];
  List<Map<String, dynamic>> district = [];

  @override
  void initState() {
    super.initState();
    getstate();
    getdistrict();
  }

  // FETCH STATES
  Future<void> getstate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

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
          stat = data.map((e) {
            return {
              'id': e['id'],
              'name': e['name'],
              'country': e['country'],
            };
          }).toList();
        });
      }
    } catch (e) {
      print("STATE ERROR: $e");
    }
  }

  // FETCH DISTRICTS
  Future<void> getdistrict() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

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
          district = data.map((e) {
            return {
              'id': e['id'],
              'name': e['name'],
              'state': e['state'],
            };
          }).toList();
        });
      }
    } catch (e) {
      print("DISTRICT ERROR: $e");
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
            colors: [
              Color(0xFF0A332E),
              Colors.black,
            ],
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
                        child: const Icon(Icons.keyboard_arrow_left, color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // UPLOAD PHOTO
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromARGB(157, 37, 37, 37),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white54,
                          size: 40,
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

                // LOCATION SELECT BOX
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006A63),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        "Kochi, Kerala",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          "Change",
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // CREATE CLUB BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
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
          hint: const Text("Select State", style: TextStyle(color: Colors.white54)),
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
              selectedStateName =
                  stat.firstWhere((e) => e['id'] == value)['name'];

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
    List<Map<String, dynamic>> filteredDistricts =
        district.where((d) => d['state'] == selectedStateId).toList();

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
          hint:
              const Text("Select District", style: TextStyle(color: Colors.white54)),
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
              selectedDistrictName = filteredDistricts
                  .firstWhere((e) => e['id'] == value)['name'];
            });
          },
        ),
      ),
    );
  }
}

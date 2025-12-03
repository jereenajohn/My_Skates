import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class state extends StatefulWidget {
  const state({super.key});

  @override
  State<state> createState() => _stateState();
}

class _stateState extends State<state> {
  String? selectedCountryName;
  int? selectedCountryId;                 // ← will hold selected country id
bool showForm = false;

  TextEditingController statetext = TextEditingController();

  @override
  void initState() {
    super.initState();
    getcountry();
    getstate();
  }
  bool isEditMode = false;
int? editingStateId;
Future<void> updateStateInSameForm(
  int id,
  String newName,
  int newCountryId,
  BuildContext context,
) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  try {
    var response = await http.put(
      Uri.parse("$api/api/myskates/state/$id/"),
      headers: {
        "Authorization": "Bearer $token",
      },
      body: {
        "name": newName,
        "country_id": newCountryId.toString(),
      },
    );

    print("UPDATE status: ${response.statusCode}");
    print("UPDATE body: ${response.body}");

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("State updated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        isEditMode = false;
        editingStateId = null;
        statetext.clear();
        selectedCountryId = null;
        selectedCountryName = null;
      });

      getstate();
    }
  } catch (e) {
    print(e);
  }
}


  List<Map<String, dynamic>> country = [];

  Future<void> getcountry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      var response = await http.get(
        Uri.parse('$api/api/myskates/country/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> statelist = [];
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed;
        print("productsData:$productsData");

        for (var productData in productsData) {
          statelist.add({
            'id': productData['id'],
            'name': productData['name'],
            'code': productData['code'],
          });
        }

        setState(() {
          country = statelist;
        });
      }
    } catch (error) {
      print(error);
    }
  }
 List<Map<String, dynamic>> stat = [];

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
        
        List<Map<String, dynamic>> statelist = [];
print("response.bodyyyyyyyyyyyyyyyyy:${response.body}");
      print(response.statusCode);
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed;

        
 for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          statelist.add({
            'id': productData['id'],
            'name': productData['name'],
            'country_code': productData['country_code'],
            'country': productData['country'],

            
          });
        
        }
        setState(() {
          stat = statelist;
          print("statelistttttttttttttttttttt:$stat");
                  

          
        });
      }
    } catch (error) {
      
    }
  }
 Future<void> addstate(
  String stateName, int countryId, BuildContext context) async {

  print("countryId: $countryId");

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  try {
    var response = await http.post(
      Uri.parse('$api/api/myskates/state/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        "name": stateName,
        "country_id": countryId.toString(),   // FIXED
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color.fromARGB(255, 49, 212, 4),
          content: Text('Success'),
        ),
      );

      statetext.clear();

      setState(() {
        selectedCountryId = null;
        selectedCountryName = null;
      });
    }

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text('An error occurred. Please try again.'),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
  backgroundColor: Colors.black,
  elevation: 0,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () => Navigator.pop(context),
  ),
  title: const Text(
    "States",
    style: TextStyle(color: Colors.white, fontSize: 20),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.add, color: Colors.white, size: 28),
      onPressed: () {
  setState(() {
    if (showForm) {
      // Hide form when clicked again
      showForm = false;
      isEditMode = false;
      statetext.clear();
      selectedCountryId = null;
      selectedCountryName = null;
    } else {
      // Show form for adding new state
      showForm = true;
      isEditMode = false;
      statetext.clear();
      selectedCountryId = null;
      selectedCountryName = null;
    }
  });
},

    ),
  ],
),

      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showForm) ...[
  _label("Country"),
  const SizedBox(height: 5),
  _countryDropdown(),

  const SizedBox(height: 5),

  _label("State"),
  _inputField(),

  const SizedBox(height: 20),

  GestureDetector(
   onTap: () {
  if (selectedCountryId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select a country"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (statetext.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enter state name"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // --------------------------
  // DUPLICATE VALIDATION
  // --------------------------
  bool exists = stat.any((s) =>
      s['name'].toString().toLowerCase() == statetext.text.trim().toLowerCase() &&
      s['country'] == selectedCountryName &&
      (isEditMode ? s['id'] != editingStateId : true));

  if (exists) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text("State already exists in this country"),
      ),
    );
    return;
  }
  // --------------------------

  // PROCESS ADD OR UPDATE
  if (isEditMode) {
    updateStateInSameForm(
      editingStateId!,
      statetext.text.trim(),
      selectedCountryId!,
      context,
    );
  } else {
    addstate(
      statetext.text.trim(),
      selectedCountryId!,
      context,
    );
  }
},

    child: Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: isEditMode ? Colors.orange : const Color(0xFF018074),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          isEditMode ? "Update" : "Submit",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  ),

],


              const SizedBox(height: 30),

// STATE LIST TITLE
_label("States"),

const SizedBox(height: 10),

_stateListWidget(),

            ],
          ),
        ),
      ),
    );
  }

  // LABEL WIDGET
  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // COUNTRY DROPDOWN WIDGET
  Widget _countryDropdown() {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
             isExpanded: true,  
          value: selectedCountryId,
          dropdownColor: const Color(0xFF1E1E1E),
          hint: const Text(
            "Select Country",
            style: TextStyle(color: Colors.white70),
          ),
          items: country
              .map(
                (c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(
                    c['name'],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedCountryId = value;
              selectedCountryName = country
                  .firstWhere((c) => c['id'] == value)['name']
                  .toString();
            });
          },
        ),
      ),
    );
  }
Widget _stateListWidget() {
  if (stat.isEmpty) {
    return const Text(
      "No states available",
      style: TextStyle(color: Colors.white70),
    );
  }

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: stat.length,
    itemBuilder: (context, index) {
      final item = stat[index];

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT SIDE TEXTS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item['name'] ?? "-",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6),
                         Text(
                    ", ${item['country']}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                    ],
                  ),
                 
                ],
              ),
            ),

            // EDIT ICON
            GestureDetector(
             onTap: () {
  setState(() {
    showForm = true;     // <-- show form when editing
    isEditMode = true;
    editingStateId = item['id'];

    statetext.text = item['name'];

    selectedCountryId = country
        .firstWhere(
          (c) => c['name'] == item['country'],
          orElse: () => country[0],
        )['id'];

    selectedCountryName = item['country'];
  });
},

              child: const Icon(
                Icons.edit,
                color: Colors.orangeAccent,
                size: 26,
              ),
            ),
          ],
        ),
      );
    },
  );
}

  // UNIFORM INPUT FIELD
  Widget _inputField({int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: statetext,
        maxLines: 1,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
        ),
      ),
    );
  }
} 
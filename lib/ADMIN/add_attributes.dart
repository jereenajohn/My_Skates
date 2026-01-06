import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class attributes extends StatefulWidget {
  const attributes({super.key});

  @override
  State<attributes> createState() => _attributesState();
}

class _attributesState extends State<attributes> {
  String? selectedCountryName;
  int? selectedCountryId;                 // ← will hold selected country id
bool showForm = false;

  TextEditingController statetext = TextEditingController();

  @override
  void initState() {
    super.initState();
    getstate();
  }
  bool isEditMode = false;
int? editingStateId;
Future<void> updateattributeInSameForm(
  int id,
  String newName,
  BuildContext context,
) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  try {
    var response = await http.put(
      Uri.parse("$api/api/myskates/attributes/update/$id/"),
      headers: {
        "Authorization": "Bearer $token",
      },
      body: {
        "name": newName,
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
getstate();
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

 
 List<Map<String, dynamic>> stat = [];

    Future<void> getstate() async {
    try {
       final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var response = await http.get(
        Uri.parse('$api/api/myskates/attributes/'),
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
        var productsData = parsed['data'];

        
 for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          statelist.add({
            'id': productData['id'],
            'name': productData['name'],   
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
 Future<void> addattribute(
  String stateName,BuildContext context) async {


  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  try {
    var response = await http.post(
      Uri.parse('$api/api/myskates/attributes/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        "name": stateName,
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
getstate();
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
    "Attributes",
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

  const SizedBox(height: 5),

  _label("Attribute Name"),
  _inputField(),

  const SizedBox(height: 20),

  GestureDetector(
   onTap: () {
 

  if (statetext.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enter attribute name"),
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
        content: Text("Attribute already exists in this country"),
      ),
    );
    return;
  }
  // --------------------------

  // PROCESS ADD OR UPDATE
  if (isEditMode) {
    updateattributeInSameForm(
      editingStateId!,
      statetext.text.trim(),
     
      context,
    );
  } else {
    addattribute(
      statetext.text.trim(),
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
_label("Attributes"),

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

Widget _stateListWidget() {
  if (stat.isEmpty) {
    return const Text(
      "No attributes available",
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
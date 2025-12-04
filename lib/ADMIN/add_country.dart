import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';

import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class AddCountry extends StatefulWidget {
  const AddCountry({super.key});

  @override
  State<AddCountry> createState() => _AddCountryState();
}

class _AddCountryState extends State<AddCountry> {
  String? selectedCountry;
  String? selectedState;
  String? selectedDistrict;
TextEditingController countryCtrl = TextEditingController();
TextEditingController codeCtrl = TextEditingController();

int? editingId;      // null = add mode, not null = update mode
bool isEditing = false;


  @override
   void initState() {
    super.initState();
    getcountry();
  }

bool showForm = false;


 List<Map<String, dynamic>> country = [];

    Future<void> getcountry() async {
    try {

 final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
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
          String imageUrl = "${productData['image']}";
          statelist.add({
            'id': productData['id'],
            'name': productData['name'],
            'code': productData['code'],
            
          });
        
        }
        setState(() {
          country = statelist;
          print(country);
                  

          
        });
      }
    } catch (error) {
      
    }
  }
  
Future<void> updateCountry(int id, String name, String code) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  try {
    var response = await http.put(
      Uri.parse('$api/api/myskates/country/view/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        "name": name,
        "code": code,
      },
    );

    print("Update: ${response.statusCode}");
    print("Update body: ${response.body}");

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("Updated Successfully"),
        ),
      );

      // RESET
      setState(() {
        isEditing = false;
        editingId = null;
        countryCtrl.clear();
        codeCtrl.clear();
      });

      // REFRESH LIST
      getcountry();
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}


    void addcountry(String country, String code, BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  try {
    var response = await http.post(
      Uri.parse('$api/api/myskates/country/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        "name": country,
        "code": code,
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 49, 212, 4),
          content: Text('Success'),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text('An error occurred. Please try again.'),
      ),
    );
  }
}

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
    "Add Country",
    style: TextStyle(color: Colors.white, fontSize: 20),
  ),
  actions: [
    IconButton(
      icon: Icon(showForm ? Icons.close : Icons.add, color: Colors.white, size: 28),
      onPressed: () {
        setState(() {
          showForm = !showForm;

          // Reset fields when hiding form
          if (!showForm) {
            isEditing = false;
            editingId = null;
            countryCtrl.clear();
            codeCtrl.clear();
          }
        });
      },
    )
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
  SizedBox(height: 10),

  _label("Country"),
  _inputField(countryCtrl),
  SizedBox(height: 10),

  _label("Code"),
  _inputField(codeCtrl),

  SizedBox(height: 20),

  GestureDetector(
    onTap: () {
  String name = countryCtrl.text.trim();
  String code = codeCtrl.text.trim();

  if (name.isEmpty || code.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text("Please enter both country and code"),
      ),
    );
    return;
  }

  // ------------------------------------
  // DUPLICATE CHECK (ADD + UPDATE)
  // ------------------------------------
  bool exists = country.any((c) =>
      c['name'].toString().toLowerCase() == name.toLowerCase() &&
      (isEditing ? c['id'] != editingId : true));

  bool codeExists = country.any((c) =>
      c['code'].toString().toLowerCase() == code.toLowerCase() &&
      (isEditing ? c['id'] != editingId : true));

  if (exists) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text("Country name already exists"),
      ),
    );
    return;
  }

  if (codeExists) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text("Country code already exists"),
      ),
    );
    return;
  }
  // ------------------------------------


  // PROCESS ADD / UPDATE
  if (isEditing && editingId != null) {
    updateCountry(editingId!, name, code);
  } else {
    addcountry(name, code, context);
  }
},

    child: Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF018074),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          isEditing ? "Update" : "Submit",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  ),

  SizedBox(height: 25),
],

_label("Existing Countries"),

country.isEmpty
    ? const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text(
          "No countries available",
          style: TextStyle(color: Colors.white70),
        ),
      )
    : ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: country.length,
        itemBuilder: (context, index) {
          final item = country[index];

          return Container(
  margin: const EdgeInsets.symmetric(vertical: 6),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: const Color(0xFF1E1E1E),
    borderRadius: BorderRadius.circular(15),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item['name'], style: TextStyle(color: Colors.white, fontSize: 16)),
              SizedBox(width: 5),

                        Text(",${item['code']}", style: TextStyle(color: Colors.white70, fontSize: 15)),

            ],
          ),
        ],
      ),

      Row(
        children: [
          // EDIT BUTTON
          IconButton(
            icon: Icon(Icons.edit, color: const Color(0xFF018074)),
            onPressed: () {
              setState(() {
                isEditing = true;
                editingId = item['id'];
                countryCtrl.text = item['name'];
                codeCtrl.text = item['code'];
              });
            },
          ),

          // DELETE BUTTON
         
        ],
      ),
    ],
  ),
);

        },
      ),

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
          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
    );
  }
Widget _inputField(TextEditingController controller) {
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
      controller: controller,
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
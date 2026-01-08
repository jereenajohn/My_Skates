import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class AddAddress extends StatefulWidget {
  const AddAddress({super.key});

  @override
  State<AddAddress> createState() => _AddAddressState();
}

class _AddAddressState extends State<AddAddress> {
  final _formKey = GlobalKey<FormState>();

  final fullNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final altPhoneCtrl = TextEditingController();
  final address1Ctrl = TextEditingController();
  final address2Ctrl = TextEditingController();
  final landmarkCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();

  int? selectedCountryId;
int? selectedStateId;
int? selectedDistrictId;


  String addressType = "home";
  bool isDefault = false;
@override
void initState() {
  super.initState();
  getcountry();
  getstate();
  getdistrict();
}




Future<void> addAddress({
  required BuildContext context,
  required String fullName,
  required String phone,
  String? altPhone,
  required String addressLine1,
  String? addressLine2,
  String? landmark,
  required String city,
  required String pincode,
  required String addressType,
  required bool isDefault,
  int? countryId,
  int? stateId,
  int? districtId,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Login expired. Please login again."),
        ),
      );
      return;
    }

    final Map<String, dynamic> body = {
      "full_name": fullName,
      "phone": phone,
      "alt_phone": altPhone,
      "address_line1": addressLine1,
      "address_line2": addressLine2,
      "landmark": landmark,
      "city": city,
      "pincode": pincode,
      "address_type": addressType,
      "is_default": isDefault,
      "country": countryId,
      "state": stateId,
      "district": districtId,
    };

    // 🔹 Remove null values
    body.removeWhere((key, value) => value == null);

    final response = await http.post(
      Uri.parse("$api/api/myskates/user/addresses/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );
print("ADD ADDRESS STATUS: ${response.statusCode}");
    print("ADD ADDRESS BODY: ${response.body}");
    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Address added successfully"),
        ),
      );

      Navigator.pop(context, true); // refresh previous page
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to add address"),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text("Something went wrong"),
      ),
    );
  }
}

InputDecoration _dropdownInput(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: const Color(0xFF1A1A1A),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.tealAccent),
    ),
  );
}

  InputDecoration _input(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon:
          icon != null ? Icon(icon, color: Colors.tealAccent) : null,
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.tealAccent),
      ),
    );
  }

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
        print("response.statusCode:${response.statusCode}");

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

  List<Map<String, dynamic>> stat = [];

    Future<void> getstate() async {
    try {
       final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var response = await http.get(
        Uri.parse('$api/api/myskates/state/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
        
        List<Map<String, dynamic>> statelist = [];
print("response stateeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee:${response.body}");
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
            'country_id': int.tryParse(productData['country_ids'].toString()),
            
          });
        
        }
        setState(() {
          stat = statelist;
          print("statelistttttttttttttttttttt:$stat");
                  

          
        });
      }
    } catch (error) {
      print("errorrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr:$error");
      
    }
  }

  
List<Map<String, dynamic>> district = [];

    Future<void> getdistrict() async {
    try {
       final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var response = await http.get(
        Uri.parse('$api/api/myskates/district/'),
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
            'state': int.tryParse(productData['state_ids'].toString()),


            
          });
        
        }
        setState(() {
          district = statelist;
          print("distriiiiiiiiiiictssssssss:$district");
                  

          
        });
      }
    } catch (error) {
      
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Add Address",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: 'Poppins'
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color.fromARGB(255, 255, 255, 255), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ADDRESS TYPE
              const Text(
                "ADDRESS TYPE",
                style: TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 12,
                    letterSpacing: 1),
              ),
              const SizedBox(height: 10),

              Row(
                children: ["home", "office", "other"].map((type) {
                  final selected = addressType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => addressType = type),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.tealAccent
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          type.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              TextFormField(
                  controller: fullNameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      _input("Full Name", icon: Icons.person_outline)),

              const SizedBox(height: 12),

              TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      _input("Phone Number", icon: Icons.phone)),

              const SizedBox(height: 12),

              TextFormField(
                  controller: altPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _input("Alternate Phone (Optional)",
                      icon: Icons.phone_android)),

              const SizedBox(height: 12),

              TextFormField(
                  controller: address1Ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      _input("Address Line 1", icon: Icons.home)),

              const SizedBox(height: 12),

              TextFormField(
                  controller: address2Ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      _input("Address Line 2 (Optional)")),

              const SizedBox(height: 12),

              TextFormField(
                  controller: landmarkCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      _input("Landmark (Optional)", icon: Icons.place)),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                        controller: cityCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration:
                            _input("City", icon: Icons.location_city)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                        controller: pincodeCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _input("Pincode")),
                  ),
                ],
              ),

//               const SizedBox(height: 12),

// DropdownButtonFormField<int>(
//   value: selectedCountryId,
//   dropdownColor: const Color(0xFF1A1A1A),
//   decoration: _dropdownInput("Country"),
//   iconEnabledColor: Colors.tealAccent,
//   style: const TextStyle(color: Colors.white),
//   items: country.map((c) {
//     return DropdownMenuItem<int>(
//       value: c['id'],
//       child: Text(c['name'], style: const TextStyle(color: Colors.white)),
//     );
//   }).toList(),
//   onChanged: (value) {
//     setState(() {
//       selectedCountryId = value;
//       selectedStateId = null;
//       selectedDistrictId = null;
//     });
//   },
// ),
// const SizedBox(height: 12),

// DropdownButtonFormField<int>(
//   value: selectedStateId,
//   dropdownColor: const Color(0xFF1A1A1A),
//   decoration: _dropdownInput("State"),
//   iconEnabledColor: Colors.tealAccent,
//   style: const TextStyle(color: Colors.white),
//   items: stat
//       .where((s) => s['country_id'] == selectedCountryId)
//       .map((s) {
//     return DropdownMenuItem<int>(
//       value: s['id'],
//       child: Text(s['name'], style: const TextStyle(color: Colors.white)),
//     );
//   }).toList(),
//   onChanged: selectedCountryId == null
//       ? null
//       : (value) {
//           setState(() {
//             selectedStateId = value;
//             selectedDistrictId = null;
//           });
//         },
// ),
// const SizedBox(height: 12),

// DropdownButtonFormField<int>(
//   value: selectedDistrictId,
//   dropdownColor: const Color(0xFF1A1A1A),
//   decoration: _dropdownInput("District"),
//   iconEnabledColor: Colors.tealAccent,
//   style: const TextStyle(color: Colors.white),
//   items: district
//       .where((d) => d['state'] == selectedStateId)
//       .map((d) {
//     return DropdownMenuItem<int>(
//       value: d['id'],
//       child: Text(d['name'], style: const TextStyle(color: Colors.white)),
//     );
//   }).toList(),
//   onChanged: selectedStateId == null
//       ? null
//       : (value) {
//           setState(() {
//             selectedDistrictId = value;
//           });
//         },
// ),


             const SizedBox(height: 16),

              // DEFAULT SWITCH
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Set as default address",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Switch(
                      value: isDefault,
                      activeColor: Colors.tealAccent,
                      onChanged: (v) => setState(() => isDefault = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      addAddress(
  context: context,
  fullName: fullNameCtrl.text.trim(),
  phone: phoneCtrl.text.trim(),
  altPhone: altPhoneCtrl.text.trim(),
  addressLine1: address1Ctrl.text.trim(),
  addressLine2: address2Ctrl.text.trim(),
  landmark: landmarkCtrl.text.trim(),
  city: cityCtrl.text.trim(),
  pincode: pincodeCtrl.text.trim(),
  addressType: addressType,
  isDefault: isDefault,
  countryId: selectedCountryId,
  stateId: selectedStateId,
  districtId: selectedDistrictId,
);

                    }
                  },
                  child: const Text(
                    "SAVE ADDRESS",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
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

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
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

  final TextEditingController countryCtrl = TextEditingController();
  final TextEditingController codeCtrl = TextEditingController();

  int? editingId;
  bool isEditing = false;
  bool showForm = false;

  List<Map<String, dynamic>> country = [];

  @override
  void initState() {
    super.initState();
    getcountry();
  }

  @override
  void dispose() {
    countryCtrl.dispose();
    codeCtrl.dispose();
    super.dispose();
  }

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
          statelist.add({
            'id': productData['id'],
            'name': productData['name'],
            'code': productData['code'],
          });
        }

        if (mounted) {
          setState(() {
            country = statelist;
            print(country);
          });
        }
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> updateCountry(int id, String name, String code) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      var response = await http.put(
        Uri.parse('$api/api/myskates/country/view/$id/'),
        headers: {'Authorization': 'Bearer $token'},
        body: {"name": name, "code": code},
      );

      print("Update: ${response.statusCode}");
      print("Update body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Updated Successfully"),
          ),
        );

        setState(() {
          isEditing = false;
          editingId = null;
          showForm = false;
          countryCtrl.clear();
          codeCtrl.clear();
        });

        getcountry();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void addcountry(String countryName, String code, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      var response = await http.post(
        Uri.parse('$api/api/myskates/country/'),
        headers: {'Authorization': 'Bearer $token'},
        body: {"name": countryName, "code": code},
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

        getcountry();

        setState(() {
          showForm = false;
          isEditing = false;
          editingId = null;
          countryCtrl.clear();
          codeCtrl.clear();
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
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF001F1D),
              Color(0xFF003A36),
              Colors.black,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        "Add Country",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        showForm ? Icons.close : Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          showForm = !showForm;

                          if (!showForm) {
                            isEditing = false;
                            editingId = null;
                            countryCtrl.clear();
                            codeCtrl.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (showForm)
                  _glassBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Country"),
                        _inputField(countryCtrl),
                        const SizedBox(height: 10),
                        _label("Code"),
                        _inputField(codeCtrl),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            String name = countryCtrl.text.trim();
                            String code = codeCtrl.text.trim();

                            if (name.isEmpty || code.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(
                                    "Please enter both country and code",
                                  ),
                                ),
                              );
                              return;
                            }

                            bool exists = country.any(
                              (c) =>
                                  c['name'].toString().toLowerCase() ==
                                      name.toLowerCase() &&
                                  (isEditing ? c['id'] != editingId : true),
                            );

                            bool codeExists = country.any(
                              (c) =>
                                  c['code'].toString().toLowerCase() ==
                                      code.toLowerCase() &&
                                  (isEditing ? c['id'] != editingId : true),
                            );

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
                    ),
                  ),

                if (showForm) const SizedBox(height: 18),

                _glassBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("Existing Countries"),
                      const SizedBox(height: 10),
                      country.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                "No countries available",
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: country.length,
                              itemBuilder: (context, index) {
                                final item = country[index];

                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                item['name'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              ",${item['code']}",
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Color(0xFF018074),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                showForm = true;
                                                isEditing = true;
                                                editingId = item['id'];
                                                countryCtrl.text = item['name'];
                                                codeCtrl.text = item['code'];
                                              });
                                            },
                                          ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _inputField(TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
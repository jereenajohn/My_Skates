import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
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
  int? selectedCountryId;
  bool showForm = false;

  TextEditingController statetext = TextEditingController();

  @override
  void initState() {
    super.initState();
    getstate();
  }

  @override
  void dispose() {
    statetext.dispose();
    super.dispose();
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
        headers: {"Authorization": "Bearer $token"},
        body: {"name": newName},
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
          showForm = false;
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
          statelist.add({'id': productData['id'], 'name': productData['name']});
        }
        setState(() {
          stat = statelist;
          print("statelistttttttttttttttttttt:$stat");
        });
      }
    } catch (error) {}
  }

  Future<void> addattribute(String stateName, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      var response = await http.post(
        Uri.parse('$api/api/myskates/attributes/'),
        headers: {'Authorization': 'Bearer $token'},
        body: {"name": stateName},
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
          showForm = false;
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
                        "Attributes",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 28),
                      onPressed: () {
                        setState(() {
                          if (showForm) {
                            showForm = false;
                            isEditMode = false;
                            statetext.clear();
                            selectedCountryId = null;
                            selectedCountryName = null;
                          } else {
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

                const SizedBox(height: 14),

                if (showForm)
                  _glassBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                            bool exists = stat.any(
                              (s) =>
                                  s['name'].toString().toLowerCase() ==
                                      statetext.text.trim().toLowerCase() &&
                                  s['country'] == selectedCountryName &&
                                  (isEditMode ? s['id'] != editingStateId : true),
                            );

                            if (exists) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(
                                    "Attribute already exists in this country",
                                  ),
                                ),
                              );
                              return;
                            }

                            if (isEditMode) {
                              updateattributeInSameForm(
                                editingStateId!,
                                statetext.text.trim(),
                                context,
                              );
                            } else {
                              addattribute(statetext.text.trim(), context);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              color: isEditMode
                                  ? Colors.orange
                                  : const Color(0xFF018074),
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
                    ),
                  ),

                const SizedBox(height: 18),

                _glassBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("Attributes"),
                      const SizedBox(height: 10),
                      _stateListWidget(),
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
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              GestureDetector(
                onTap: () {
                  setState(() {
                    showForm = true;
                    isEditMode = true;
                    editingStateId = item['id'];

                    statetext.text = item['name'];

                    selectedCountryId = country.firstWhere(
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
  Widget _inputField() {
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
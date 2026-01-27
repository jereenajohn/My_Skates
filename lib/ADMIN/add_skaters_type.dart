import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class AddSkatersType extends StatefulWidget {
  const AddSkatersType({super.key});

  @override
  State<AddSkatersType> createState() => _AddSkatersTypeState();
}

class _AddSkatersTypeState extends State<AddSkatersType> {
  bool showForm = false;

  TextEditingController skatersTypeCtrl = TextEditingController();

  List<Map<String, dynamic>> skatersTypes = [];

  bool isEditMode = false;
  int? editingCategoryId;

  @override
  void initState() {
    super.initState();
    GetSkatersType();
  }

  // FETCH SKATERS TYPE LIST
  Future<void> GetSkatersType() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      var response = await http.get(
        Uri.parse("$api/api/myskates/skate/types/add/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("Skaters LIST STATUS: ${response.statusCode}");
      print("Skaters LIST BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> list = [];

        for (var item in parsed) {
          list.add({"id": item["id"], 
          "name": item["type"]});
        }

        setState(() {
          skatersTypes = list;
        });
      }
    } catch (e) {
      print("ERROR: $e");
    }
  }

  // ADD CATEGORY
  Future<void> addskaterCategory(
    String categoryName,
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      var response = await http.post(
        Uri.parse("$api/api/myskates/skate/types/add/"),
        headers: {"Authorization": "Bearer $token"},
        body: {"type": categoryName},
      );

      print("ADD CATEGORY STATUS: ${response.statusCode}");
      print("ADD CATEGORY BODY: ${response.body}");

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00C853),
            content: Text("Skater added successfully"),
          ),
        );

        skatersTypeCtrl.clear();
        showForm = false;

        GetSkatersType();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      print("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Something went wrong. Try again."),
        ),
      );
    }
  }

  Future<void> updateSkatersType(
    int id,
    String name,
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      var response = await http.put(
        Uri.parse("$api/api/myskates/skate/types/edit/$id/"),
        headers: {"Authorization": "Bearer $token"},
        body: {"type": name},
      );

      print("UPDATE STATUS: ${response.statusCode}");
      print("UPDATE BODY: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Category updated successfully"),
            backgroundColor: Colors.orange,
          ),
        );

        isEditMode = false;
        editingCategoryId = null;
        skatersTypeCtrl.clear();
        showForm = false;

        await GetSkatersType();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Product Categories",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () {
              setState(() {
                if (showForm) {
                  showForm = false;
                  isEditMode = false;
                  skatersTypeCtrl.clear();
                } else {
                  showForm = true;
                  isEditMode = false;
                  skatersTypeCtrl.clear();
                }
              });
            },
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showForm) ...[
                _label("Category Name"),
                _inputField(skatersTypeCtrl),

                const SizedBox(height: 20),

                _submitButton(),
              ],

              const SizedBox(height: 30),

              // _label("Categories"),
              // const SizedBox(height: 10),
              _categoryList(),
            ],
          ),
        ),
      ),
    );
  }

  // LABEL
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

  // INPUT FIELD
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
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }

  // SUBMIT BUTTON
  Widget _submitButton() {
    return GestureDetector(
      onTap: () {
        if (skatersTypeCtrl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Enter category name"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (isEditMode) {
          updateSkatersType(
            editingCategoryId!,
            skatersTypeCtrl.text.trim(),
            context,
          );
        } else {
          addskaterCategory(skatersTypeCtrl.text.trim(), context);
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
    );
  }

  // CATEGORY LIST
  Widget _categoryList() {
    if (skatersTypes.isEmpty) {
      return const Text(
        "No categories found",
        style: TextStyle(color: Colors.white70),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: skatersTypes.length,
      itemBuilder: (context, index) {
        final item = skatersTypes[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item["name"],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  setState(() {
                    showForm = true;
                    isEditMode = true;
                    editingCategoryId = item["id"];
                    skatersTypeCtrl.text = item["name"];
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
}

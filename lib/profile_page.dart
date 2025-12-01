import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? gender;
  String? selectedCountry;
  String? selectedState;
  String? selectedDistrict;
  File? profileImage;
  final ImagePicker _picker = ImagePicker();

  DateTime? dob;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Back Icon
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 30),

              // PROFILE LABEL
              // _label("Profile"),
              const SizedBox(height: 10),

              // IMAGE UPLOAD CIRCLE
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final XFile? pickedFile =
                        await _picker.pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      setState(() {
                        profileImage = File(pickedFile.path);
                      });
                    }
                  },
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E1E1E),
                      border: Border.all(color: Colors.white24, width: 2),
                      image: profileImage != null
                          ? DecorationImage(
                              image: FileImage(profileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: profileImage == null
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade700.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Text("Upload",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // FORM FIELDS
              _label("First Name"),
              _inputField(),

              const SizedBox(height: 20),

              _label("Last Name"),
              _inputField(),

              const SizedBox(height: 20),

              _label("Phone"),
              _inputField(),

              const SizedBox(height: 20),

              _label("Email"),
              _inputField(),

              const SizedBox(height: 20),

              _label("Alt Phone"),
              _inputField(),

              const SizedBox(height: 20),

              _label("Gender"),
              _dropdown(
                value: gender,
                items: ["Male", "Female", "Other"],
                onChange: (v) => setState(() => gender = v),
              ),

              const SizedBox(height: 20),

              _label("Age"),
              _inputField(),

              const SizedBox(height: 20),

              _label("Date of Birth"),
              _dobPicker(),

              const SizedBox(height: 20),

              _label("Zip Code"),
              _inputField(),

              const SizedBox(height: 20),

              _label("Country"),
              _dropdown(
                value: selectedCountry,
                items: ["India", "USA", "UK"],
                onChange: (v) => setState(() => selectedCountry = v),
              ),

              const SizedBox(height: 20),

              _label("State"),
              _dropdown(
                value: selectedState,
                items: ["Kerala", "Tamil Nadu", "Karnataka", "Maharashtra"],
                onChange: (v) => setState(() => selectedState = v),
              ),

              const SizedBox(height: 20),

              _label("District"),
              _dropdown(
                value: selectedDistrict,
                items: ["Kollam", "Ernakulam", "Chennai", "Mumbai"],
                onChange: (v) => setState(() => selectedDistrict = v),
              ),

              const SizedBox(height: 20),

              _label("Instagram"),
              _inputField(),

              const SizedBox(height: 30),

              // SUBMIT BUTTON
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFF018074),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    "Update",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
       bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.black,
            selectedItemColor: const Color(0xFF00AFA5),
            unselectedItemColor: Colors.white70,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            currentIndex: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ''),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: '',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.event), label: ''),
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
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
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
        maxLines: 1,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
        ),
      ),
    );
  }

  // UNIFORM DROPDOWN FIELD
  Widget _dropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChange,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.black87,
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChange,
        ),
      ),
    );
  }

  // UNIFORM DOB PICKER
  Widget _dobPicker() {
    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(data: ThemeData.dark(), child: child!);
          },
        );

        if (picked != null) {
          setState(() => dob = picked);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          dob == null
              ? "Select Date of Birth"
              : "${dob!.day}/${dob!.month}/${dob!.year}",
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}

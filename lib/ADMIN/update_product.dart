import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/Home_Page.dart';
import 'package:my_skates/api.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class UpdateProduct extends StatefulWidget {
  var productId;
  UpdateProduct({super.key,required this.productId});

  @override
  State<UpdateProduct> createState() => _UpdateProductState();
}

class _UpdateProductState extends State<UpdateProduct> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Store IDs only
  String? gender;            // "male", "female", "other"
  String? selectedCountry;   // ID
  String? selectedState;     // ID
  String? selectedDistrict;  // ID

  List<Map<String, dynamic>> countryList = [];
  List<Map<String, dynamic>> categoryList = [];
  List<Map<String, dynamic>> allDistricts = [];
  List<Map<String, dynamic>> districtList = [];

  File? profileImage;
  String? profileNetworkImage;
  final ImagePicker _picker = ImagePicker();

  DateTime? dob;

  
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
   final TextEditingController priceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAllData();
  }
  Future<void> loadAllData() async {

    getproductDetails();

    await fetchcategory();
   // await fetchProfileData();
    setState(() {});
  }

 
 Future<void> getproductDetails() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.get(
      Uri.parse("$api/api/myskates/products/update/${widget.productId}/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final data = json["data"]; // ✅ IMPORTANT

      setState(() {
        titleCtrl.text = data["title"] ?? "";
        descriptionCtrl.text = data["description"] ?? "";
        priceCtrl.text = data["price"]?.toString() ?? "";

        selectedState = data["category"]?.toString();

        // show existing image
        if (data["image"] != null && data["image"] != "") {
          profileNetworkImage = "$api${data["image"]}";
        }
      });
    }
  } catch (e) {
    debugPrint("Error in getproductDetails: $e");
  }
}

  Future<void> fetchcategory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/products/category/"),
        headers: {"Authorization": "Bearer $token"},
      );
print("res.body:;;;;;;;;;;;;: ${res.body}");
      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        categoryList =
            data.map((e) => {"id": e["id"], "name": e["name"]}).toList();
      }
    } catch (e) {}
  }

  Future<void> fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      final res = await http.get(
        Uri.parse("$api/api/myskates/user/extras/details/$userId/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

      
       
        gender = data["gender"]?.toString(); // ex: "Male"
        selectedCountry = data["country"]?.toString();
        selectedState = data["state"]?.toString();
        selectedDistrict = data["district"]?.toString();

        if (data["dob"] != null) {
          dob = DateTime.tryParse(data["dob"]);
        }

        if (data["profile"] != null) {
          profileNetworkImage = "$api${data["profile"]}";
        }
      }
    } catch (e) {}
  }

  Future<void> submitProduct() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    final userId = prefs.getInt("id");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login expired. Please login again.")),
      );
      return;
    }

    if(profileImage == null && profileNetworkImage == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image.")),
      );
      return;
    }
    


    var request = http.MultipartRequest(
      "PUT",
      Uri.parse("$api/api/myskates/products/update/${widget.productId}/"),
    );

    request.headers["Authorization"] = "Bearer $token";

    // Add normal text fields
    request.fields["user"] = userId.toString();
    request.fields["title"] = titleCtrl.text.trim();
    request.fields["description"] = descriptionCtrl.text.trim();
    request.fields["price"] = priceCtrl.text.trim();

    if (selectedState != null) {
      request.fields["category"] = selectedState.toString();
    }

    // Add Image if selected
    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath("image", profileImage!.path),
      );
    }

    // Send request
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    print("STATUS: ${response.statusCode}");
    print("BODY: $responseBody");

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product added successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  DashboardPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $responseBody")),
      );
    }
  } catch (e) {
    print("Error in submitProduct: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Something went wrong")),
    );
  }
}

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0), 
  resizeToAvoidBottomInset: false,
  extendBody: true,  // IMPORTANT
  extendBodyBehindAppBar: true,  
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Color(0xFF000000)],
            begin: Alignment.topLeft,
          ),
        ),
        child: SafeArea(
           bottom: false, 
          child: SingleChildScrollView(
             keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Align(
  alignment: Alignment.topLeft,
  child: GestureDetector(
    onTap: () {
      Navigator.pop(context);
    },
    child: Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 134, 134, 134).withOpacity(0.15),   // soft transparent circle
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: const Icon(
        Icons.keyboard_arrow_left_rounded,
        color: Color.fromARGB(255, 78, 78, 78),
        size: 28,
      ),
    ),
  ),
),

SizedBox(height: 20),


           GestureDetector(
  onTap: () async {
    final pick = await _picker.pickImage(source: ImageSource.gallery);
    if (pick != null) {
      setState(() {
        profileImage = File(pick.path);
      });
    }
  },
  child: Container(
    height: 180,
    width: MediaQuery.of(context).size.width * 0.9,
    decoration: BoxDecoration(
      color: const Color.fromARGB(195, 30, 29, 29),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: const Color.fromARGB(172, 90, 90, 90),
        width: 1,
      ),
    ),

    // SHOW IMAGE IF SELECTED
   child: profileImage != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          profileImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      )
    : profileNetworkImage != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              profileNetworkImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          )
        : Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(244, 55, 55, 55),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text(
                "Upload Image",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

  ),
),




                  const SizedBox(height: 30),

                
                  _inputField("Title", titleCtrl),
                  _inputFieldmax(
                    "Description",
                    
                    descriptionCtrl,
                    maxLines: 4,     // description style
  maxLength: 100,
  isNumber: false,
                  ),

                

                 

                  Row(
                    children: [
                      Expanded(
                        child: _dropdownField(
                          label: "category",
                          value: selectedState,
                          items: categoryList,
                          onChange: (v) {
                            selectedState = v;

                            districtList = allDistricts.where(
                              (d) =>
                                  d["state"] ==
                                  categoryList.firstWhere(
                                    (s) => s["id"].toString() == v,
                                  )["name"],
                            ).toList();

                            selectedDistrict = null;
                            setState(() {});
                          },
                        ),
                      ),
                    
                    ],
                  ),

                  _inputField("Price", priceCtrl),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;

                        // if (dob == null) {
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     const SnackBar(
                        //       content: Text("Date of Birth is required"),
                        //     ),
                        //   );
                        //   return;
                        // }

                       submitProduct();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Submit",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- REUSABLE ----------------

  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    bool isNumber = false,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: [
          if (isNumber) FilteringTextInputFormatter.digitsOnly,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        style: TextStyle(color: readOnly ? Colors.white70 : Colors.white),
        decoration: _dec(label).copyWith(
          fillColor: readOnly ? const Color.fromARGB(172, 30, 29, 29) : const Color(0xFF1E1E1E),
        ),
        validator: (v) {
          final value = v?.trim() ?? "";
          if (value.isEmpty) return "$label is required";

          if (label == "Email") {
            final regex = RegExp(r"^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$");
            if (!regex.hasMatch(value)) return "Enter valid email";
          }
          if (label == "Alt Phone" && value.length != 10) {
            return "Alt Phone must be 10 digits";
          }

          return null;
        },
      ),
    );
  }

  Widget _inputFieldmax(
  String label,
  TextEditingController controller, {
  bool readOnly = false,
  bool isNumber = false,
  int? maxLength,
  int maxLines = 1,      // NEW: multiline support
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      controller: controller,
      readOnly: readOnly,
      autovalidateMode: AutovalidateMode.onUserInteraction,

      // If multiline → always use multiline keyboard
      keyboardType: maxLines > 1
          ? TextInputType.multiline
          : (isNumber ? TextInputType.number : TextInputType.text),

      maxLines: maxLines,     // NEW

      inputFormatters: [
        if (isNumber && maxLines == 1) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],

      style: TextStyle(color: readOnly ? Colors.white70 : Colors.white),

      decoration: _dec(label).copyWith(
        fillColor: readOnly
            ? const Color.fromARGB(172, 30, 29, 29)
            : const Color(0xFF1E1E1E),
      ),

      validator: (v) {
        final value = v?.trim() ?? "";

        if (value.isEmpty) return "$label is required";

        if (label == "Email") {
          final regex =
              RegExp(r"^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$");
          if (!regex.hasMatch(value)) return "Enter valid email";
        }

        // Only validate phone length if the field is SINGLE LINE
        if (label == "Alt Phone" && maxLines == 1 && value.length != 10) {
          return "Alt Phone must be 10 digits";
        }

        return null;
      },
    ),
  );
}


  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      floatingLabelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      errorStyle: const TextStyle(
        color: Colors.redAccent,
        fontSize: 12,
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value, // ID
    required List<Map<String, dynamic>> items,
    required Function(String?) onChange,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _dec(label),
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.white),
        items: items.map((e) {
          return DropdownMenuItem<String>(
            value: e["id"].toString(),
            child: Text(e["name"]),
          );
        }).toList(),
        onChanged: onChange,
        validator: (v) =>
            v == null || v.isEmpty ? "$label is required" : null,
      ),
    );
  }

  Widget _dobPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2005),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
            builder: (c, child) =>
                Theme(data: ThemeData.dark(), child: child!),
          );
          if (picked != null) setState(() => dob = picked);
        },
        child: FormField(
          validator: (_) =>
              dob == null ? "Date of Birth is required" : null,
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputDecorator(
                decoration: _dec("Date of Birth"),
                child: Text(
                  dob == null
                      ? "Select Date"
                      : "${dob!.day}/${dob!.month}/${dob!.year}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 12),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddBankDetailsPage extends StatefulWidget {
  const AddBankDetailsPage({super.key});

  @override
  State<AddBankDetailsPage> createState() => _AddBankDetailsPageState();
}

class _AddBankDetailsPageState extends State<AddBankDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController coachNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController accountHolderController =
      TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController branchNameController = TextEditingController();
  final TextEditingController accountNumberController =
      TextEditingController();
  final TextEditingController ifscController = TextEditingController();
  final TextEditingController upiController = TextEditingController();

  bool isLoading = false;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  Future<void> addBankDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final token = await getToken();

      final response = await http.post(
        Uri.parse("$api/api/myskates/bank/details/add/view/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "coach_name": coachNameController.text.trim(),
          "phone": phoneController.text.trim(),
          "account_holder_name": accountHolderController.text.trim(),
          "bank_name": bankNameController.text.trim(),
          "branch_name": branchNameController.text.trim(),
          "account_number": accountNumberController.text.trim(),
          "ifsc_code": ifscController.text.trim(),
          "upi_id": upiController.text.trim(),
        }),
      );

      print("ADD BANK STATUS: ${response.statusCode}");
      print("ADD BANK BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bank details added successfully"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add bank details"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("ADD BANK ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (requiredField && (value == null || value.trim().isEmpty)) {
            return "$label is required";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: const Color(0xFF2EE6A6)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2EE6A6)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    coachNameController.dispose();
    phoneController.dispose();
    accountHolderController.dispose();
    bankNameController.dispose();
    branchNameController.dispose();
    accountNumberController.dispose();
    ifscController.dispose();
    upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Add Bank Details"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _field(
                  controller: coachNameController,
                  label: "Coach Name",
                  icon: Icons.person,
                ),
                _field(
                  controller: phoneController,
                  label: "Phone",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                _field(
                  controller: accountHolderController,
                  label: "Account Holder Name",
                  icon: Icons.person_outline,
                ),
                _field(
                  controller: bankNameController,
                  label: "Bank Name",
                  icon: Icons.account_balance,
                ),
                _field(
                  controller: branchNameController,
                  label: "Branch Name",
                  icon: Icons.location_city,
                ),
                _field(
                  controller: accountNumberController,
                  label: "Account Number",
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                ),
                _field(
                  controller: ifscController,
                  label: "IFSC Code",
                  icon: Icons.code,
                ),
                _field(
                  controller: upiController,
                  label: "UPI ID",
                  icon: Icons.payment,
                  requiredField: false,
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : addBankDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EE6A6),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Save Bank Details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
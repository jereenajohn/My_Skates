import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/add_bank_details.dart';
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';


class BankDetailsPage extends StatefulWidget {
  const BankDetailsPage({super.key});

  @override
  State<BankDetailsPage> createState() => _BankDetailsPageState();
}

class _BankDetailsPageState extends State<BankDetailsPage> {
  List<Map<String, dynamic>> bankDetails = [];
  bool isLoading = true;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  @override
  void initState() {
    super.initState();
    fetchBankDetails();
  }

  Future<void> fetchBankDetails() async {
    setState(() => isLoading = true);

    try {
      final token = await getToken();

      final response = await http.get(
        Uri.parse("$api/api/myskates/bank/details/add/view/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("GET BANK STATUS: ${response.statusCode}");
      print("GET BANK BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List data = [];

        if (decoded is Map && decoded["status"] == "success") {
          data = decoded["data"] ?? [];
        } else if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded["data"] is List) {
          data = decoded["data"];
        } else if (decoded is Map && decoded["data"] is Map) {
          data = [decoded["data"]];
        }

        bankDetails = data
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e),
            )
            .toList();
      } else {
        bankDetails = [];
      }
    } catch (e) {
      print("GET BANK ERROR: $e");
      bankDetails = [];
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> openAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddBankDetailsPage()),
    );

    if (result == true) {
      fetchBankDetails();
    }
  }

  Future<void> openEditSheet(int bankId) async {
    final token = await getToken();

    try {
      final response = await http.get(
        Uri.parse("$api/api/myskates/bank/details/update/$bankId/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("GET SINGLE BANK STATUS: ${response.statusCode}");
      print("GET SINGLE BANK BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        Map<String, dynamic> data = {};

        if (decoded is Map && decoded["data"] is Map) {
          data = Map<String, dynamic>.from(decoded["data"]);
        } else if (decoded is Map && decoded["data"] is List) {
          final List list = decoded["data"];
          if (list.isNotEmpty) {
            data = Map<String, dynamic>.from(list.first);
          }
        } else if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }

        if (data.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bank details not found"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (!mounted) return;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EditBankDetailsSheet(
            bankData: data,
            onUpdated: fetchBankDetails,
          ),
        );
      }
    } catch (e) {
      print("GET SINGLE BANK ERROR: $e");
    }
  }

  Widget _infoRow(String title, String value, IconData icon) {
    if (value.trim().isEmpty || value == "null") {
      value = "N/A";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2EE6A6), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankCard(Map<String, dynamic> item) {
    final int id = int.tryParse((item["id"] ?? "0").toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2EE6A6).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF2EE6A6).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Color(0xFF2EE6A6),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Bank Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: id == 0 ? null : () => openEditSheet(id),
                icon: const Icon(Icons.edit, color: Color(0xFF2EE6A6)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _infoRow(
            "Coach Name",
            item["coach_name"]?.toString() ?? "",
            Icons.person,
          ),
          _infoRow(
            "Phone",
            item["phone"]?.toString() ?? "",
            Icons.phone,
          ),
          _infoRow(
            "Account Holder",
            item["account_holder_name"]?.toString() ?? "",
            Icons.person_outline,
          ),
          _infoRow(
            "Bank Name",
            item["bank_name"]?.toString() ?? "",
            Icons.account_balance,
          ),
          _infoRow(
            "Branch Name",
            item["branch_name"]?.toString() ?? "",
            Icons.location_city,
          ),
          _infoRow(
            "Account Number",
            item["account_number"]?.toString() ?? "",
            Icons.numbers,
          ),
          _infoRow(
            "IFSC Code",
            item["ifsc_code"]?.toString() ?? "",
            Icons.code,
          ),
          _infoRow(
            "UPI ID",
            item["upi_id"]?.toString() ?? "",
            Icons.payment,
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFF2EE6A6),
                size: 48,
              ),
              const SizedBox(height: 14),
              const Text(
                "No bank details added",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Add your bank details to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: openAddPage,
                icon: const Icon(Icons.add),
                label: const Text("Add Bank Details"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2EE6A6),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2EE6A6)),
      );
    }

    if (bankDetails.isEmpty) {
      return _emptyView();
    }

    return RefreshIndicator(
      onRefresh: fetchBankDetails,
      color: const Color(0xFF2EE6A6),
      backgroundColor: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bankDetails.length,
        itemBuilder: (_, index) {
          return _bankCard(bankDetails[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Bank Details"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: fetchBankDetails,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: openAddPage,
            icon: const Icon(Icons.add),
          ),
        ],
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
        child: _body(),
      ),
    );
  }
}

class EditBankDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> bankData;
  final Future<void> Function() onUpdated;

  const EditBankDetailsSheet({
    super.key,
    required this.bankData,
    required this.onUpdated,
  });

  @override
  State<EditBankDetailsSheet> createState() => _EditBankDetailsSheetState();
}

class _EditBankDetailsSheetState extends State<EditBankDetailsSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController coachNameController;
  late TextEditingController phoneController;
  late TextEditingController accountHolderController;
  late TextEditingController bankNameController;
  late TextEditingController branchNameController;
  late TextEditingController accountNumberController;
  late TextEditingController ifscController;
  late TextEditingController upiController;

  bool isUpdating = false;

  @override
  void initState() {
    super.initState();

    coachNameController = TextEditingController(
      text: widget.bankData["coach_name"]?.toString() ?? "",
    );
    phoneController = TextEditingController(
      text: widget.bankData["phone"]?.toString() ?? "",
    );
    accountHolderController = TextEditingController(
      text: widget.bankData["account_holder_name"]?.toString() ?? "",
    );
    bankNameController = TextEditingController(
      text: widget.bankData["bank_name"]?.toString() ?? "",
    );
    branchNameController = TextEditingController(
      text: widget.bankData["branch_name"]?.toString() ?? "",
    );
    accountNumberController = TextEditingController(
      text: widget.bankData["account_number"]?.toString() ?? "",
    );
    ifscController = TextEditingController(
      text: widget.bankData["ifsc_code"]?.toString() ?? "",
    );
    upiController = TextEditingController(
      text: widget.bankData["upi_id"]?.toString() ?? "",
    );
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  Future<void> updateBankDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isUpdating = true);

    final int bankId =
        int.tryParse((widget.bankData["id"] ?? "0").toString()) ?? 0;

    if (bankId == 0) {
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid bank detail ID"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final token = await getToken();

      final response = await http.put(
        Uri.parse("$api/api/myskates/bank/details/update/$bankId/"),
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

      print("UPDATE BANK STATUS: ${response.statusCode}");
      print("UPDATE BANK BODY: ${response.body}");

      if (response.statusCode == 200) {
        await widget.onUpdated();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bank details updated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update bank details"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("UPDATE BANK ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => isUpdating = false);
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
      padding: const EdgeInsets.only(bottom: 14),
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
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                "Edit Bank Details",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
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
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isUpdating ? null : updateBankDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EE6A6),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Update Bank Details",
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
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddCoupon extends StatefulWidget {
  const AddCoupon({super.key});

  @override
  State<AddCoupon> createState() => _AddCouponState();
}

class _AddCouponState extends State<AddCoupon> {
  bool showForm = false;
  bool isEditMode = false;
  int? editingCouponId;
  bool disablePercent = false;
  bool disablePrice = false;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController percentCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  DateTime? validFrom;
  DateTime? validTo;

  List<Map<String, dynamic>> coupons = [];

  @override
  void initState() {
    super.initState();
    getCoupons();
  }

  /* ================= FETCH COUPONS ================= */

  Future<void> getCoupons() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.get(
      Uri.parse("$api/api/myskates/coupons/add/"),
      headers: {"Authorization": "Bearer $token"},
    );

    print("res.body: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        coupons = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  /* ================= ADD / UPDATE ================= */

  Future<void> submitCoupon() async {
    if (nameCtrl.text.trim().isEmpty || validFrom == null || validTo == null) {
      snack("Fill all required fields", Colors.red);
      return;
    }

    if (percentCtrl.text.isEmpty && priceCtrl.text.isEmpty) {
      snack("Enter percentage or price discount", Colors.red);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final body = {
      "coupon_name": nameCtrl.text.trim(),
      "discount_percentage": percentCtrl.text,
      "discount_price": priceCtrl.text,
      "valid_from": validFrom!.toIso8601String().split("T")[0],
      "valid_to": validTo!.toIso8601String().split("T")[0],
      "description": descCtrl.text.trim(),
    };

    http.Response res;

    if (isEditMode) {
      res = await http.put(
        Uri.parse("$api/api/myskates/coupons/edit/$editingCouponId/"),
        headers: {"Authorization": "Bearer $token"},
        body: body,
      );

      print("res.statusCode: ${res.statusCode}");
      print("res.bodyyyy up: ${res.body}");
    } else {
      res = await http.post(
        Uri.parse("$api/api/myskates/coupons/add/"),
        headers: {"Authorization": "Bearer $token"},
        body: body,
      );
      print("res.statusCode: ${res.statusCode}");
      print("res.bodyyyy: ${res.body}");
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      snack(isEditMode ? "Coupon updated" : "Coupon added", Colors.green);
      resetForm();
      getCoupons();
    }
  }

  /* ================= DELETE ================= */

  Future<void> deleteCoupon(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.delete(
      Uri.parse("$api/api/myskates/coupons/edit/$id/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      snack("Coupon deleted", Colors.green);
      getCoupons();
    }
  }

  /* ================= UI HELPERS ================= */

  void resetForm() {
    setState(() {
      showForm = false;
      isEditMode = false;
      editingCouponId = null;
      nameCtrl.clear();
      percentCtrl.clear();
      priceCtrl.clear();
      descCtrl.clear();
      validFrom = null;
      validTo = null;
    });
  }

  void snack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        isFrom ? validFrom = picked : validTo = picked;
      });
    }
  }

  /* ================= BUILD ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Coupons", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              setState(() {
                showForm = !showForm;
                if (!showForm) resetForm();
              });
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showForm) couponForm(),
            const SizedBox(height: 20),
            label("Coupons"),
            couponList(),
          ],
        ),
      ),
    );
  }

  /* ================= FORM ================= */

  Widget couponForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label("Coupon Name"),
        input(nameCtrl),

        label("Discount %"),
        input(
          percentCtrl,
          keyboard: TextInputType.number,
          enabled: !disablePercent,
          onChanged: (val) {
            setState(() {
              disablePrice = val.trim().isNotEmpty;
              if (disablePrice) priceCtrl.clear();
            });
          },
        ),

        label("Discount Price"),
        input(
          priceCtrl,
          keyboard: TextInputType.number,
          enabled: !disablePrice,
          onChanged: (val) {
            setState(() {
              disablePercent = val.trim().isNotEmpty;
              if (disablePercent) percentCtrl.clear();
            });
          },
        ),

        label("Valid From"),
        dateBox(validFrom, () => pickDate(true)),

        label("Valid To"),
        dateBox(validTo, () => pickDate(false)),

        label("Description"),
        input(descCtrl, maxLines: 3),

        const SizedBox(height: 20),
        GestureDetector(
          onTap: submitCoupon,
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: isEditMode ? Colors.orange : const Color(0xFF018074),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                isEditMode ? "Update" : "Submit",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /* ================= LIST ================= */

  Widget couponList() {
    if (coupons.isEmpty) {
      return const Text(
        "No coupons",
        style: TextStyle(color: Colors.white70),
        strutStyle: StrutStyle(fontSize: 16),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: coupons.length,
      itemBuilder: (_, i) {
        final c = coupons[i];
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['coupon_name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c['discount_percentage'] != null
                          ? "${c['discount_percentage']}% off"
                          : "₹${c['discount_price']} off",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: () {
                  setState(() {
                    showForm = true;
                    isEditMode = true;
                    editingCouponId = c['id'];
                    nameCtrl.text = c['coupon_name'];
                    percentCtrl.text =
                        c['discount_percentage']?.toString() ?? "";
                    priceCtrl.text = c['discount_price']?.toString() ?? "";
                    descCtrl.text = c['description'] ?? "";
                    validFrom = DateTime.parse(c['valid_from']);
                    validTo = DateTime.parse(c['valid_to']);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => deleteCoupon(c['id']),
              ),
            ],
          ),
        );
      },
    );
  }

  /* ================= SMALL WIDGETS ================= */

  Widget label(String t) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 14)),
  );

  Widget input(
    TextEditingController c, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    bool enabled = true,
    Function(String)? onChanged,
  }) {
    return Container(
      height: maxLines == 1 ? 55 : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF1E1E1E) : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: c,
        enabled: enabled,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: TextStyle(color: enabled ? Colors.white : Colors.white54),
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }

  Widget dateBox(DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date == null ? "Select date" : date.toString().split(" ")[0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/add_address.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/update_address.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;

class ViewAddress extends StatefulWidget {
  const ViewAddress({super.key});

  @override
  State<ViewAddress> createState() => _ViewAddressState();
}

class _ViewAddressState extends State<ViewAddress> {
  List<Map<String, dynamic>> addresses = [];
  bool addressLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  // ================= FETCH ADDRESSES =================
  Future<void> fetchAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    setState(() => addressLoading = true);

    try {
      final res = await http.get(
        Uri.parse("$api/api/myskates/user/addresses/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      print("Address fetch response: ${res.body}");
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is List) {
          setState(() {
            addresses = List<Map<String, dynamic>>.from(decoded);
            addressLoading = false;
          });
        } else {
          addressLoading = false;
        }
      } else {
        addressLoading = false;
      }
    } catch (e) {
      debugPrint("Address fetch error: $e");
      addressLoading = false;
    }
  }

  // ================= DEFAULT ADDRESS =================
  Map<String, dynamic>? _defaultAddress() {
    try {
      return addresses.firstWhere((e) => e["is_default"] == true);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteAddress(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    setState(() => addressLoading = true);

    try {
      final res = await http.delete(
        Uri.parse("$api/api/myskates/user/addresses/$id/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      print("Address delete response: ${res.statusCode}");
      print("Address delete response body: ${res.body}");
      if (res.statusCode == 200) {
        fetchAddresses(); 
      } else {
        setState(() => addressLoading = false);
      }
    } catch (e) {
      debugPrint("Address delete error: $e");
      setState(() => addressLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Addresses",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(context, slideRightToLeftRoute(AddAddress()));
            },
            child: const Text(
              "+ Add Address",
              style: TextStyle(
                color: Colors.tealAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: addressLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- DEFAULT ADDRESS ----------
                  if (_defaultAddress() != null) ...[
                    const Text(
                      "Default Address",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _addressCard(_defaultAddress()!, isDefault: true),
                    const SizedBox(height: 24),
                  ],

                  // ---------- ALL ADDRESS ----------
                  const Text(
                    "All Address",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...addresses
                      .where((e) => e["is_default"] != true)
                      .map(
                        (addr) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _addressCard(addr),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
    );
  }

  // ================= ADDRESS CARD =================
  Widget _addressCard(Map<String, dynamic> addr, {bool isDefault = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.tealAccent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "DEFAULT",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          if (isDefault) const SizedBox(height: 10),

          Text(
            addr["full_name"] ?? "",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _formatAddress(addr),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Phone : ${addr["phone"] ?? ""}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const Divider(height: 28, color: Colors.white24),

          Row(
            children: [
              _actionText("Delete", Colors.redAccent, () {
                deleteAddress(addr["id"]);
              }),
              const SizedBox(width: 24),
              _actionText("Edit", Colors.tealAccent, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateAddress(id: addr["id"]),
                  ),
                );
                // Edit navigation
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================
  Widget _actionText(String text, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> addr) {
    final parts = [
      addr["address_line1"],
      addr["address_line2"],
      addr["landmark"],
      addr["city"],
      addr["district_name"],
      addr["state_name"],
      addr["country_name"],
      addr["pincode"],
    ];

    return parts
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(", ");
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/add_address.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class cart extends StatefulWidget {
  const cart({super.key});

  @override
  State<cart> createState() => _cartState();
}

class _cartState extends State<cart> {
  bool loading = true;
  List cartItems = [];

  @override
  void initState() {
    super.initState();
    fetchCart();
    fetchAddresses();
  }

  String subtotal = "0.00";
  String discountTotal = "0.00";
  String total = "0.00";
  Map<String, dynamic>? selectedAddress;
  List addresses = [];
  bool addressLoading = false;
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

      debugPrint("ADDRESS LIST STATUS: ${res.statusCode}");
      debugPrint("ADDRESS LIST BODY: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is List) {
          final List<Map<String, dynamic>> list =
              List<Map<String, dynamic>>.from(decoded);

          // AUTO-SELECT DEFAULT ADDRESS
          Map<String, dynamic>? defaultAddr;
          for (final addr in list) {
            if (addr["is_default"] == true) {
              defaultAddr = addr;
              break;
            }
          }

          setState(() {
            addresses = list;

            // pick default if exists, else keep previous
            selectedAddress ??= defaultAddr;

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

  Future ordercreate() async {}

  Future<void> _removeFromCart(dynamic item) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final response = await http.delete(
        Uri.parse('$api/api/myskates/cart/item/${item["id"]}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          cartItems.removeWhere((cartItem) => cartItem["id"] == item["id"]);
        });
      } else {
        debugPrint("Failed to delete cart item: ${response.body}");
      }
    } catch (e) {
      debugPrint("Remove cart error: $e");
    }
  }

  updatecart(int cartItemId, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final response = await http.patch(
        Uri.parse('$api/api/myskates/cart/item/$cartItemId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'quantity': quantity}),
      );

      debugPrint(
        'Update Cart Response cartttttttttttttttttttt: ${response.body}',
      );

      if (response.statusCode == 200) {
        // Successfully updated cart item
        // Optionally, you can refresh the cart data here
        fetchCart();
      } else {
        debugPrint('Failed to update cart item');
      }
    } catch (e) {
      debugPrint("Cart update error: $e");
    }
  }

  Future<void> fetchCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final response = await http.get(
        Uri.parse('$api/api/myskates/cart/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Cart Response: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final cartData = decoded["data"];
        final List items = cartData["items"] ?? [];

        setState(() {
          cartItems = items;
          subtotal = cartData["subtotal"];
          discountTotal = cartData["discount_total"];
          total = cartData["total"];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint("Cart fetch error: $e");
      setState(() => loading = false);
    }
  }

  void _showAddressPopup() async {
    await fetchAddresses();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Select Delivery Address",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ADDRESS LIST
                if (addressLoading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  )
                else if (addresses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No saved addresses",
                      style: TextStyle(color: Colors.white60),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: addresses.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.white.withOpacity(0.08)),
                      itemBuilder: (context, index) {
                        final Map<String, dynamic> addr = addresses[index];

                        final bool isSelected =
                            selectedAddress != null &&
                            selectedAddress!["id"] == addr["id"];

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            setState(() {
                              selectedAddress = addr;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.tealAccent
                                    : Colors.white24,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: Colors.tealAccent,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        addr["full_name"] ?? "",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${addr["address_line1"] ?? ""}, ${addr["city"] ?? ""}, ${addr["pincode"] ?? ""}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // ADD NEW ADDRESS
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddAddress()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Add New Address",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      //FIXED PROCEED BUTTON
      bottomNavigationBar: loading ? null : _buildBottomBar(context),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00312D), 
              Color(0xFF000000), 
            ],
            stops: [0.0, 0.35],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Cart View",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    // InkWell(
                    //   borderRadius: BorderRadius.circular(30),
                    //   onTap: () {},
                    //   child: const Padding(
                    //     padding: EdgeInsets.all(6),
                    //     child: Icon(
                    //       Icons.favorite_border,
                    //       color: Colors.white,
                    //       size: 22,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                  itemCount: cartItems.length + 3, 
                  itemBuilder: (context, index) {
                    // Address section (TOP)
                    if (index == 0) {
                      return _buildAddressSection();
                    }

                    //  Cart items
                    if (index >= 1 && index <= cartItems.length) {
                      final item = cartItems[index - 1];
                      final variant = item["variant"];
                      return _buildCartItem(item, variant);
                    }

                    // Payment Method (AFTER PRODUCTS)
                    if (index == cartItems.length + 1) {
                      return _buildPaymentMethodSection();
                    }

                    // Order Summary (LAST)
                    return _buildOrderSummary();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String selectedPayment = "cod"; // default COD
  Widget _buildPaymentMethodSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Payment Method",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 13),

          _paymentTile(
            value: "cod",
            title: "Cash on Delivery",
            subtitle: "Pay when your order arrives",
            icon: Icons.payments_outlined,
          ),

          const SizedBox(height: 10),

          _paymentTile(
            value: "online",
            title: "Online Payment",
            subtitle: "UPI / Card / Netbanking",
            icon: Icons.credit_card,
          ),
        ],
      ),
    );
  }

  Widget _paymentTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool selected = selectedPayment == value;

    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () {
        setState(() {
          selectedPayment = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.tealAccent : Colors.white24,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.tealAccent),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),

            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: Colors.tealAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final double bagTotal = double.tryParse(subtotal) ?? 0;
    final double discount = double.tryParse(discountTotal) ?? 0;
    final double platformFee = 29.0;
    final double deliveryFee = 99.0;

    final double payable = bagTotal - discount + platformFee; // delivery free

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE
          const Text(
            "Order Details",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 14),

          _row("Bag Total", "₹${bagTotal.toStringAsFixed(2)}"),

          const SizedBox(height: 10),

          _row(
            "Bag Savings",
            "-₹${discount.toStringAsFixed(2)}",
            valueColor: Colors.greenAccent,
          ),

          const SizedBox(height: 10),

          InkWell(
            onTap: () {
            },
            child: _row(
              "Coupon Savings",
              "Apply Coupon",
              valueColor: Colors.tealAccent,
            ),
          ),

          const SizedBox(height: 12),

          Divider(color: Colors.white.withOpacity(0.08)),

          const SizedBox(height: 12),

          // Convenience Fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    "Convenience Fee",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {},
                    child: const Text(
                      "What's this?",
                      style: TextStyle(color: Colors.tealAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    "Free",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "₹99.00",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          _row("Platform Fee", "₹${platformFee.toStringAsFixed(2)}"),

          const SizedBox(height: 14),

          Divider(color: Colors.white.withOpacity(0.12)),

          const SizedBox(height: 12),

          // TOTAL PAYABLE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Amount Payable",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "₹${payable.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // SAVINGS BANNER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "🎉 Cheers! You saved ₹${discount.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color valueColor = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return GestureDetector(
      onTap: () {
        _showAddressPopup();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF121212), const Color(0xFF1A1A1A)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.tealAccent.withOpacity(0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ICON BADGE
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.tealAccent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.tealAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // ADDRESS TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Deliver to",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedAddress == null
                        ? "No address selected"
                        : "${selectedAddress!["full_name"]}, ${selectedAddress!["city"]}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

            // CHANGE
            TextButton(
              onPressed: () {},
              child: const Text(
                "CHANGE",
                style: TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(dynamic item, dynamic variant) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  "$api${variant["first_image"]}",
                  height: 64,
                  width: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              // DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant["product_title"] ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (variant["attribute_names"] as List).join(", "),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "₹${variant["price"]}",
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // RIGHT ACTIONS
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // DELETE ICON
                  GestureDetector(
                    onTap: () => _confirmDelete(item),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // QTY BOX
                  GestureDetector(
                    onTap: () => _showQtyPopup(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.tealAccent),
                      ),
                      child: Text(
                        "Qty ${item["quantity"]}",
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          child: Divider(
            color: Colors.white.withOpacity(0.08),
            height: 1,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(dynamic item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "Remove item?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "This item will be removed from your cart.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromCart(item); 
            },
            child: const Text(
              "Remove",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showQtyPopup(dynamic item) {
    int qty = item["quantity"];
    final TextEditingController controller = TextEditingController(
      text: qty.toString(),
    );

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 60),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TITLE
                    const Text(
                      "Quantity",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _miniQtyButton(
                          icon: Icons.remove,
                          onTap: qty > 1
                              ? () {
                                  setStateDialog(() {
                                    qty--;
                                    controller.text = qty.toString();
                                  });
                                }
                              : null,
                        ),

                        const SizedBox(width: 12),

                        SizedBox(
                          width: 52,
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: Colors.black,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.tealAccent,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.tealAccent,
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null && parsed > 0) {
                                qty = parsed;
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        _miniQtyButton(
                          icon: Icons.add,
                          onTap: () {
                            setStateDialog(() {
                              qty++;
                              controller.text = qty.toString();
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ACTIONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {
                            final parsed =
                                int.tryParse(controller.text) ??
                                item["quantity"];

                            updatecart(item["id"], parsed);

                            Navigator.pop(context);

                            setState(() {
                              item["quantity"] = parsed < 1 ? 1 : parsed;
                            });

                          
                          },
                          child: const Text(
                            "OK",
                            style: TextStyle(
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _miniQtyButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap == null ? Colors.white24 : Colors.tealAccent,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.white24 : Colors.tealAccent,
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // TOTAL
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Total",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹$total",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

            // PROCEED BUTTON
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: cartItems.isEmpty ? null : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Proceed",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartSkeleton extends StatelessWidget {
  const CartSkeleton({super.key});

  Widget _box({
    double height = 12,
    double width = double.infinity,
    double radius = 6,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.tealAccent.withOpacity(0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE SKELETON
              _box(height: 70, width: 70, radius: 12),

              const SizedBox(width: 12),

              // TEXT SKELETON
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(height: 14, width: double.infinity),
                    const SizedBox(height: 8),
                    _box(height: 12, width: 100),
                    const SizedBox(height: 10),
                    _box(height: 14, width: 80),
                  ],
                ),
              ),

              // QTY SKELETON
              Column(
                children: [
                  _box(height: 10, width: 24),
                  const SizedBox(height: 6),
                  _box(height: 26, width: 40, radius: 8),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

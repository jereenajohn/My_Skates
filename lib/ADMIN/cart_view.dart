import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/add_address.dart';
import 'package:my_skates/ADMIN/order_failure_page.dart';
import 'package:my_skates/ADMIN/order_success_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class cart extends StatefulWidget {
  const cart({super.key});

  @override
  State<cart> createState() => _cartState();
}

class _cartState extends State<cart> {
  bool loading = true;
  List cartItems = [];
  late Razorpay _razorpay;
  String? razorpayOrderId;
  List<Map<String, dynamic>> coupons = [];
  String? cartErrorMessage;

  bool placingOrder = false;

  // ================= COUPON =================
  TextEditingController couponController = TextEditingController();

  // ================= CART SUMMARY VALUES =================
  String bagTotal = "0.00";
  String bagSavings = "0.00";
  String subtotal = "0.00";
  String couponCode = "";
  String couponDiscount = "0.00";
  String platformFee = "0.00";
  String convenienceFee = "0.00";
  String amountPayable = "0.00";

  // ================= ADDRESS =================
  Map<String, dynamic>? selectedAddress;
  List addresses = [];
  bool addressLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCart();
    fetchCartSummary();
    fetchAddresses();
    getCoupons();

    _razorpay = Razorpay();
    debugPrint("RAZORPAY INITIALIZED ✅");

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    couponController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // ================= GET COUPONS =================
  Future<void> getCoupons() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.get(
      Uri.parse("$api/api/myskates/coupons/add/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        coupons = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  // ================= CART SUMMARY API =================
  Future<void> fetchCartSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final response = await http.get(
        Uri.parse("$api/api/myskates/cart/summary/"),
        headers: {"Authorization": "Bearer $token"},
      );

      debugPrint("SUMMARY STATUS: ${response.statusCode}");
      debugPrint("SUMMARY BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] == "success") {
          final data = decoded["data"];

          setState(() {
            bagTotal = data["bag_total"].toString();
            bagSavings = data["bag_savings"].toString();
            subtotal = data["subtotal"].toString();

            couponCode = data["coupon_code"] == null
                ? ""
                : data["coupon_code"].toString();

            couponDiscount = data["coupon_discount"].toString();
            platformFee = data["platform_fee"].toString();
            convenienceFee = data["convenience_fee"].toString();
            amountPayable = data["amount_payable"].toString();

            if (couponCode.isNotEmpty) {
              couponController.text = couponCode;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Cart Summary Error: $e");
    }
  }

  // ================= APPLY COUPON API =================
  Future<void> applyCouponBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    String code = couponController.text.trim().toUpperCase();

    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter coupon code")));
      return;
    }

    try {
      setState(() => loading = true);

      final response = await http.post(
        Uri.parse("$api/api/myskates/cart/apply/coupon/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"coupon_code": code}),
      );

      debugPrint("APPLY COUPON STATUS: ${response.statusCode}");
      debugPrint("APPLY COUPON BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Coupon Applied ✅")));

        await fetchCartSummary();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Coupon Failed: ${response.body}")),
        );
      }
    } catch (e) {
      debugPrint("Apply Coupon Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= REMOVE COUPON API =================
  Future<void> removeCouponBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      setState(() => loading = true);

      final response = await http.post(
        Uri.parse("$api/api/myskates/cart/remove/coupon/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({}),
      );

      debugPrint("REMOVE COUPON STATUS: ${response.statusCode}");
      debugPrint("REMOVE COUPON BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        couponController.clear();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Coupon Removed")));

        await fetchCartSummary();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Remove Coupon Failed: ${response.body}")),
        );
      }
    } catch (e) {
      debugPrint("Remove Coupon Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= ORDER CREATE =================
  Future<void> ordercreate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login required")));
      return;
    }

    if (selectedAddress == null) {
      placingOrder = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select delivery address")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      // ✅ GET FRESH SUMMARY BEFORE PAYMENT (IMPORTANT)
      final summaryRes = await http.get(
        Uri.parse("$api/api/myskates/cart/summary/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (summaryRes.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load cart summary")),
        );
        return;
      }

      final summaryDecoded = jsonDecode(summaryRes.body);

      double payableAmount =
          double.tryParse(
            summaryDecoded["data"]["amount_payable"].toString(),
          ) ??
          0;

      debugPrint("PAYABLE AMOUNT SENDING TO RAZORPAY: $payableAmount");

      if (payableAmount <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid amount")));
        return;
      }
      String code = couponController.text.trim().toUpperCase();
      final response = await http.post(
        Uri.parse("$api/api/myskates/razorpay/create/order/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "amount": payableAmount,
          if (code.isNotEmpty) "coupon_code": code,
        }),
      );

      debugPrint("ORDER CREATE STATUS: ${response.statusCode}");
      debugPrint("ORDER CREATE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        razorpayOrderId = decoded["order_id"].toString();
        final int amountInPaise = decoded["amount"];

        openRazorpayCheckout(
          amountInPaise: amountInPaise,
          orderId: razorpayOrderId!,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order creation failed: ${response.body}")),
        );
      }
    } catch (e) {
      debugPrint("Order Create Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      placingOrder = false;
      setState(() => loading = false);
    }
  }

  // ================= VERIFY PAYMENT =================
  Future<bool> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) {
      debugPrint("VERIFY ERROR: Token missing");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse("$api/api/myskates/razorpay/verify/payment/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "razorpay_order_id": razorpayOrderId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_signature": razorpaySignature,
        }),
      );

      debugPrint("VERIFY STATUS: ${response.statusCode}");
      debugPrint("VERIFY BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        if (decoded["success"] == true ||
            decoded["verified"] == true ||
            decoded["status"] == "success") {
          debugPrint("PAYMENT VERIFIED SUCCESS ✅");
          return true;
        }
      }

      debugPrint("PAYMENT VERIFY FAILED ❌");
      return false;
    } catch (e) {
      debugPrint("VERIFY ERROR: $e");
      return false;
    }
  }

  // ================= OPEN RAZORPAY =================
  void openRazorpayCheckout({
    required int amountInPaise,
    required String orderId,
  }) {
    var options = {
      'key': 'rzp_test_S8mkawKvbCtNbt',
      'amount': amountInPaise,
      'name': 'My Skates',
      'description': 'Order Payment',
      'order_id': orderId,
      'currency': 'INR',
      'timeout': 300,
      'prefill': {
        'contact': selectedAddress?["phone"] ?? "",
        'email': selectedAddress?["email"] ?? "",
      },
      'theme': {'color': '#00C2A8'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay Open Error: $e");
    }
  }

  // ================= PAYMENT SUCCESS =================
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      loading = true;
    });

    bool verified = await verifyRazorpayPayment(
      razorpayOrderId: response.orderId ?? "",
      razorpayPaymentId: response.paymentId ?? "",
      razorpaySignature: response.signature ?? "",
    );

    if (!verified) {
      setState(() {
        placingOrder = false;
        loading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailedPage(
            reason: "Payment verification failed",
            amount: amountPayable,
          ),
        ),
      );
      return;
    }

    // ✅ Create order first
    bool orderCreated = await checkoutOrder(
      paymentMethod: "ONLINE",
      paymentRef: response.paymentId ?? "",
      fullName: (selectedAddress?["full_name"] ?? "").toString(),
      phone: (selectedAddress?["phone"] ?? "").toString(),
      addressLine1: (selectedAddress?["address_line1"] ?? "").toString(),
      addressLine2: (selectedAddress?["address_line2"] ?? "").toString(),
      city: (selectedAddress?["city"] ?? "").toString(),
      state: (selectedAddress?["state"] ?? selectedAddress?["state_name"] ?? "")
          .toString()
          .trim(),
      pincode: (selectedAddress?["pincode"] ?? "").toString(),
      country: (selectedAddress?["country"] ?? "India").toString(),
      note: "",
    );

    // ❌ If order not created, stop here
    if (!orderCreated) {
      setState(() {
        placingOrder = false;
        loading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailedPage(
            reason: "Order creation failed after payment",
            amount: amountPayable,
          ),
        ),
      );
      return;
    }

    // ✅ REMOVE COUPON AFTER ORDER SUCCESS
    await removeCouponBackend(); // 🔥 IMPORTANT FIX

    // ✅ Then go to success page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSuccessPage(
          orderId: response.orderId ?? "",
          paymentId: response.paymentId ?? "",
          amount: amountPayable,
        ),
      ),
    );
  }

  // ================= CHECKOUT =================
  Future<bool> checkoutOrder({
    required String paymentMethod,
    required String paymentRef,
    required String fullName,
    required String phone,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String pincode,
    required String country,
    required String note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login required")));
      return false;
    }

    try {
      setState(() => loading = true);

      final response = await http.post(
        Uri.parse("$api/api/myskates/checkout/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "payment_method": paymentMethod,
          "payment_ref": paymentRef,
          "full_name": fullName,
          "phone": phone,
          "address_line1": addressLine1,
          "address_line2": addressLine2,
          "city": city,
          "state": state,
          "pincode": pincode,
          "country": country,
          "note": note,
        }),
      );

      debugPrint("CHECKOUT STATUS: ${response.statusCode}");
      debugPrint("CHECKOUT BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed successfully ✅")),
        );

        fetchCart();
        fetchCartSummary();

        return true; // ✅ success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Checkout failed: ${response.body}")),
        );
        return false;
      }
    } catch (e) {
      debugPrint("Checkout Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
      return false;
    } finally {
      placingOrder = false;
      setState(() => loading = false);
    }
  }

  // ================= PAYMENT ERROR =================
  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      placingOrder = false;
      loading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentFailedPage(
          reason: response.message ?? "Payment Cancelled / Failed",
          amount: amountPayable,
        ),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Wallet Selected: ${response.walletName}")),
    );
  }

  // ================= ADDRESS =================
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

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is List) {
          final List<Map<String, dynamic>> list =
              List<Map<String, dynamic>>.from(decoded);

          Map<String, dynamic>? defaultAddr;
          for (final addr in list) {
            if (addr["is_default"] == true) {
              defaultAddr = addr;
              break;
            }
          }

          setState(() {
            addresses = list;
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
      addressLoading = false;
    }
  }

  // ================= REMOVE CART ITEM =================
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

        fetchCartSummary();
      }
    } catch (e) {
      debugPrint("Remove cart error: $e");
    }
  }

  // ================= UPDATE CART =================
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

      if (response.statusCode == 200) {
        fetchCart();
        fetchCartSummary();
      }
    } catch (e) {
      debugPrint("Cart update error: $e");
    }
  }

  // ================= FETCH CART ITEMS =================
  Future<void> fetchCart() async {
    print("Fetching cart items...");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      print("Token: $token");
      print("API URL: $api/api/myskates/cart/");
      print("Making GET request to fetch cart items...");
      final response = await http.get(
        Uri.parse('$api/api/myskates/cart/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        print("CART RESPONSE: ${response.body}");

        final cartData = decoded["data"];
        final List items = cartData["items"] ?? [];

        setState(() {
          cartItems = items;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint("Cart Fetch Error: $e");

      setState(() {
        cartErrorMessage =
            "Unable to load cart. Please check your internet connection.";
        loading = false;
      });
    }
  }

  // ================= ADDRESS POPUP =================
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: loading || cartItems.isEmpty
          ? null
          : _buildBottomBar(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00312D), Color(0xFF000000)],
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
                  ],
                ),
              ),
              Expanded(
                child: loading
                    ? const CartSkeleton()
                    : cartErrorMessage != null
                    ? _buildErrorUI(cartErrorMessage!)
                    : cartItems.isEmpty
                    ? _buildEmptyCartUI()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                        itemCount: cartItems.length + 4,
                        itemBuilder: (context, index) {
                          if (index == 0) return _buildAddressSection();

                          if (index >= 1 && index <= cartItems.length) {
                            final item = cartItems[index - 1];
                            final variant = item["variant"];
                            return _buildCartItem(item, variant);
                          }

                          if (index == cartItems.length + 1) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _buildCouponSectionPremiumInput(),
                            );
                          }

                          if (index == cartItems.length + 2) {
                            return _buildPaymentMethodSection();
                          }

                          if (index == cartItems.length + 3) {
                            return _buildOrderSummary();
                          }

                          return const SizedBox.shrink();
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorUI(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Colors.redAccent,
              size: 60,
            ),
            const SizedBox(height: 12),
            const Text(
              "Something went wrong",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: "Poppins",
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    cartErrorMessage = null;
                    loading = true;
                  });

                  fetchCart();
                  fetchCartSummary();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCartUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.tealAccent.withOpacity(0.25),
                    Colors.tealAccent.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.tealAccent.withOpacity(0.35)),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.tealAccent,
                size: 52,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Your Cart is Empty",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Looks like you haven’t added anything yet.\nBrowse products and start shopping now!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Continue Shopping",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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

  // ================= COUPON UI =================
  Widget _buildCouponSectionPremiumInput() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 0, 0, 0).withOpacity(0.18),
            const Color(0xFF121212),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.local_offer_rounded,
                color: Colors.tealAccent,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                "Apply Coupon",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Have a promo code? Get instant savings",
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.tealAccent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                    decoration: const InputDecoration(
                      hintText: "ENTER COUPON CODE",
                      hintStyle: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (couponCode.isNotEmpty) {
                      removeCouponBackend();
                    } else {
                      applyCouponBackend();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.tealAccent, Color(0xFF00C2A8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      couponCode.isNotEmpty ? "REMOVE" : "APPLY",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.flash_on_rounded, size: 14, color: Colors.tealAccent),
              SizedBox(width: 6),
              Text(
                "Best coupons auto-applied at checkout",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= PAYMENT METHOD =================
  String selectedPayment = "cod";

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
              fontSize: 12,
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
          const SizedBox(height: 12),
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

  // ================= ORDER SUMMARY =================
  Widget _buildOrderSummary() {
    final double bagTotalValue = double.tryParse(bagTotal) ?? 0;
    final double bagSavingsValue = double.tryParse(bagSavings) ?? 0;
    final double couponDiscountValue = double.tryParse(couponDiscount) ?? 0;
    final double platformFeeValue = double.tryParse(platformFee) ?? 0;
    final double payableValue = double.tryParse(amountPayable) ?? 0;

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
          _row("Bag Total", "₹${bagTotalValue.toStringAsFixed(2)}"),
          const SizedBox(height: 10),
          _row(
            "Bag Savings",
            "-₹${bagSavingsValue.toStringAsFixed(2)}",
            valueColor: Colors.greenAccent,
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {},
            child: _row(
              "Coupon Savings",
              couponCode.isEmpty
                  ? "Apply Coupon"
                  : "-₹${couponDiscountValue.toStringAsFixed(2)}",
              valueColor: couponCode.isEmpty
                  ? Colors.tealAccent
                  : Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 12),
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
          _row("Platform Fee", "₹${platformFeeValue.toStringAsFixed(2)}"),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 12),
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
                "₹${payableValue.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "🎉 Cheers! You saved ₹${bagSavingsValue.toStringAsFixed(2)}",
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

  // ================= ADDRESS UI =================
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

  // ================= CART ITEM UI =================
  Widget _buildCartItem(dynamic item, dynamic variant) {
    String imageUrl = "";

    if (variant != null &&
        variant["first_image"] != null &&
        variant["first_image"].toString().isNotEmpty) {
      imageUrl = "$api${variant["first_image"]}";
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isEmpty
                    ? Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white54,
                          size: 26,
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        height: 64,
                        width: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white54,
                              size: 26,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(width: 12),

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

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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

  // ================= BOTTOM BAR =================
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
                    "₹$amountPayable",
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
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: cartItems.isEmpty
                    ? null
                    : () {
                        if (placingOrder) return;

                        if (selectedAddress == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select delivery address"),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          placingOrder = true;
                        });

                        if (selectedPayment == "cod") {
                          checkoutOrder(
                            paymentMethod: "COD",
                            paymentRef: "",
                            fullName: (selectedAddress?["full_name"] ?? "")
                                .toString(),
                            phone: (selectedAddress?["phone"] ?? "").toString(),
                            addressLine1:
                                (selectedAddress?["address_line1"] ?? "")
                                    .toString(),
                            addressLine2:
                                (selectedAddress?["address_line2"] ?? "")
                                    .toString(),
                            city: (selectedAddress?["city"] ?? "").toString(),
                            state:
                                (selectedAddress?["state_name"] ??
                                        selectedAddress?["state"] ??
                                        "")
                                    .toString()
                                    .trim(),
                            pincode: (selectedAddress?["pincode"] ?? "")
                                .toString(),
                            country:
                                (selectedAddress?["country_name"] ??
                                        selectedAddress?["country"] ??
                                        "India")
                                    .toString(),
                            note: "",
                          );
                        } else {
                          ordercreate();
                        }
                      },
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
              _box(height: 70, width: 70, radius: 12),
              const SizedBox(width: 12),
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

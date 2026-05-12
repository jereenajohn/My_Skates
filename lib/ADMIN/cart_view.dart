import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/add_address.dart';
import 'package:my_skates/ADMIN/coach_product_view.dart';
import 'package:my_skates/ADMIN/order_failure_page.dart';
import 'package:my_skates/ADMIN/order_success_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_skates/ADMIN/cart_count_notifier.dart';

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
  String shipmentfee = "0.00";
  String offerDiscount = "0.00";
  List<Map<String, dynamic>> offerDetails = [];
  Set<int> freeCartItemIds = {};

  List<Map<String, dynamic>> restrictedProducts =
      []; // Products causing restrictions
  String? globalRestrictionReason;

  // ================= ADDRESS =================
  Map<String, dynamic>? selectedAddress;
  List addresses = [];
  bool addressLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCart();
    // fetchCartSummary();
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
          if (!mounted) return;
          setState(() {
            bagTotal = (data["bag_total"] ?? "0.00").toString();
            bagSavings = (data["bag_savings"] ?? "0.00").toString();
            subtotal = (data["subtotal"] ?? "0.00").toString();

            couponCode = data["coupon_code"] == null
                ? ""
                : data["coupon_code"].toString();

            couponDiscount = (data["coupon_discount"] ?? "0.00").toString();
            platformFee = (data["platform_fee"] ?? "0.00").toString();
            convenienceFee = (data["convenience_fee"] ?? "0.00").toString();
            amountPayable = (data["amount_payable"] ?? "0.00").toString();
            shipmentfee = (data["shipment_charge"] ?? "0.00").toString();
            offerDiscount = (data["offer_discount"] ?? "0.00").toString();

            offerDetails = List<Map<String, dynamic>>.from(
              data["offer_details"] ?? [],
            );

            freeCartItemIds = offerDetails
                .expand((offer) => offer["free_products"] ?? [])
                .map<int?>((freeProduct) {
                  final value = freeProduct["cart_item_id"];
                  if (value == null) return null;
                  return int.tryParse(value.toString());
                })
                .whereType<int>()
                .toSet();

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
      if (!mounted) return;
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
      'key': dotenv.env['RAZORPAY_KEY'],
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
    if (selectedPaymentId == null) {
      setState(() {
        placingOrder = false;
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select payment method")),
      );
      return;
    }

    bool orderCreated = await checkoutOrder(
      paymentMethodId: selectedPaymentId!,
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
    required int paymentMethodId,
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
          "payment_method": paymentMethodId,
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
          setState(() {
            addressLoading = false;
          });
        }
      } else {
        setState(() {
          addressLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        addressLoading = false;
      });
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

        // Recalculate payment methods with remaining items
        calculateDynamicPaymentMethods(cartItems);

        fetchCartSummary();
        await CartCountNotifier.refreshCartCount();
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
        await fetchCart();
        fetchCartSummary();
        // Payment methods will be recalculated in fetchCart() via calculateDynamicPaymentMethods
        await CartCountNotifier.refreshCartCount();
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

        if (!mounted) return;
        setState(() {
          cartItems = items;
        });
        calculateDynamicPaymentMethods(items);

        final int count = items.fold<int>(
          0,
          (sum, item) => sum + (((item["quantity"] ?? 0) as num).toInt()),
        );
        CartCountNotifier.cartCount.value = count;

        await fetchCartSummary();

        setState(() {
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
    final int itemCount = cartItems.fold<int>(
      0,
      (sum, item) => sum + _toInt(item["quantity"]),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      bottomNavigationBar: loading || cartItems.isEmpty
          ? null
          : _buildBottomBar(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF062F2B),
              Color(0xFF071614),
              Color(0xFF050505),
            ],
            stops: [0.0, 0.26, 0.58],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Shopping Bag",
                            style: TextStyle(
                              fontSize: 19,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            itemCount == 1
                                ? "1 item ready for checkout"
                                : "$itemCount items ready for checkout",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withOpacity(0.60),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!loading && cartItems.isNotEmpty)
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.tealAccent.withOpacity(0.30),
                          ),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.tealAccent,
                          size: 21,
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
                    : RefreshIndicator(
                        color: Colors.tealAccent,
                        backgroundColor: const Color(0xFF111111),
                        onRefresh: () async {
                          await fetchCart();
                          await fetchCartSummary();
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: cartItems.length + 5,
                          itemBuilder: (context, index) {
                            if (index == 0) return _buildAddressSection();

                            if (index >= 1 && index <= cartItems.length) {
                              final item = cartItems[index - 1];
                              final variant = item["variant"];
                              return _buildCartItem(item, variant);
                            }

                            if (index == cartItems.length + 1) {
                              return _buildOfferUnlockHintSection();
                            }

                            if (index == cartItems.length + 2) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: _buildCouponSectionPremiumInput(),
                              );
                            }

                            if (index == cartItems.length + 3) {
                              return _buildPaymentMethodSection();
                            }

                            if (index == cartItems.length + 4) {
                              return _buildOrderSummary();
                            }

                            return const SizedBox.shrink();
                          },
                        ),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserApprovedProducts()),
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
    final bool hasCoupon = couponCode.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasCoupon
              ? Colors.greenAccent.withOpacity(0.38)
              : Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.tealAccent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Coupons & Rewards",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Apply a code and reduce your payable amount",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              if (hasCoupon)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "APPLIED",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(13, 7, 7, 7),
            decoration: BoxDecoration(
              color: const Color(0xFF070707),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasCoupon
                    ? Colors.greenAccent.withOpacity(0.35)
                    : Colors.white.withOpacity(0.10),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sell_outlined,
                  color: Colors.white38,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    controller: couponController,
                    enabled: !hasCoupon,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      fontFamily: 'Poppins',
                    ),
                    decoration: const InputDecoration(
                      hintText: "COUPON CODE",
                      hintStyle: TextStyle(
                        color: Colors.white30,
                        fontSize: 12,
                        letterSpacing: 1,
                        fontFamily: 'Poppins',
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
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 17),
                    decoration: BoxDecoration(
                      color: hasCoupon
                          ? Colors.redAccent.withOpacity(0.16)
                          : Colors.tealAccent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasCoupon
                            ? Colors.redAccent.withOpacity(0.35)
                            : Colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      hasCoupon ? "REMOVE" : "APPLY",
                      style: TextStyle(
                        color: hasCoupon ? Colors.redAccent : Colors.black,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasCoupon) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    "$couponCode coupon is active on this cart",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void calculateDynamicPaymentMethods(List items) {
    final Map<String, Map<String, dynamic>> allMethods = {};
    restrictedProducts.clear();
    globalRestrictionReason = null;

    // Step 1: Collect all payment methods from all cart items
    for (final item in items) {
      final List methods = item["payment_methods"] ?? [];

      for (final method in methods) {
        final code = method["code"]?.toString().toUpperCase() ?? "";

        if (code.isNotEmpty) {
          if (!allMethods.containsKey(code)) {
            allMethods[code] = {
              "id": method["id"],
              "name": method["name"],
              "code": code,
              "is_available": true,
              "restricted_by":
                  <String>[], // Track which products restrict this method
            };
          }
        }
      }
    }

    // Step 2: Check each method is available in every cart item
    for (final code in allMethods.keys) {
      final List<String> restrictedBy = [];

      for (final item in items) {
        final variant = item["variant"];
        final productName =
            variant?["product_title"]?.toString() ?? "One product";
        final productId = variant?["id"]?.toString() ?? item["id"].toString();

        final List methods = item["payment_methods"] ?? [];
        final List<String> itemCodes = methods
            .map((m) => m["code"].toString().toUpperCase())
            .toList();

        if (!itemCodes.contains(code)) {
          allMethods[code]!["is_available"] = false;
          restrictedBy.add(productName);

          // Add to restricted products list if not already there
          final existingProductIndex = restrictedProducts.indexWhere(
            (p) => p["id"] == productId,
          );

          if (existingProductIndex == -1) {
            restrictedProducts.add({
              "id": productId,
              "name": productName,
              "missing_methods": [allMethods[code]!["name"]],
            });
          } else {
            final existingProduct = restrictedProducts[existingProductIndex];
            final missingMethods = existingProduct["missing_methods"] as List;
            if (!missingMethods.contains(allMethods[code]!["name"])) {
              missingMethods.add(allMethods[code]!["name"]);
            }
          }
        }
      }

      if (restrictedBy.isNotEmpty) {
        allMethods[code]!["restricted_by"] = restrictedBy;
      }
    }

    final List<Map<String, dynamic>> methodsList = allMethods.values.toList();

    // Set global restriction reason
    if (methodsList.any((m) => m["is_available"] == false)) {
      if (restrictedProducts.length == 1) {
        final product = restrictedProducts.first;
        final missingMethods = (product["missing_methods"] as List).join(", ");
        globalRestrictionReason =
            "${product["name"]} does not support $missingMethods";
      } else if (restrictedProducts.length > 1) {
        final productNames = restrictedProducts
            .map((p) => p["name"])
            .join(", ");
        globalRestrictionReason =
            "$productNames do not support some payment methods";
      }
    }

    Map<String, dynamic>? firstAvailable;
    for (final method in methodsList) {
      if (method["is_available"] == true) {
        firstAvailable = method;
        break;
      }
    }

    setState(() {
      dynamicPaymentMethods = methodsList;

      if (firstAvailable != null) {
        selectedPaymentId = firstAvailable["id"];
        selectedPaymentCode = firstAvailable["code"];
        selectedPaymentName = firstAvailable["name"];
      } else {
        selectedPaymentId = null;
        selectedPaymentCode = "";
        selectedPaymentName = "";
      }
    });
  }

  String selectedPaymentCode = "";
  String selectedPaymentName = "";
  int? selectedPaymentId;

  List<Map<String, dynamic>> dynamicPaymentMethods = [];

  Widget _buildPaymentMethodSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.tealAccent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Method",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Choose a payment option available for all items",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (dynamicPaymentMethods.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.20)),
              ),
              child: const Text(
                "No payment methods available for these cart items",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: "Poppins",
                ),
              ),
            )
          else
            ...dynamicPaymentMethods.map((method) {
              final bool isAvailable = method["is_available"] == true;
              final String code = method["code"]?.toString() ?? "";
              final String name = method["name"]?.toString() ?? "";
              final List<String> restrictedBy =
                  (method["restricted_by"] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _paymentTile(
                  id: method["id"],
                  code: code,
                  title: name,
                  icon: code == "COD"
                      ? Icons.payments_outlined
                      : Icons.credit_card_rounded,
                  isEnabled: isAvailable,
                  restrictedBy: restrictedBy,
                ),
              );
            }).toList(),
          if (restrictedProducts.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.11),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orangeAccent.withOpacity(0.30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orangeAccent,
                        size: 17,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Payment restrictions found",
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ...restrictedProducts.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "• ",
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "${product["name"]} - ${(product["missing_methods"] as List).join(", ")} not available",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                height: 1.35,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Remove restricted items to unlock all payment options.",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentTile({
    required int id,
    required String code,
    required String title,
    required IconData icon,
    required bool isEnabled,
    List<String> restrictedBy = const [],
  }) {
    final bool selected = selectedPaymentCode == code;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isEnabled
          ? () {
              setState(() {
                selectedPaymentId = id;
                selectedPaymentCode = code;
                selectedPaymentName = title;
              });
              debugPrint("SELECTED PAYMENT ID: $selectedPaymentId");
              debugPrint("SELECTED PAYMENT CODE: $selectedPaymentCode");
              debugPrint("SELECTED PAYMENT NAME: $selectedPaymentName");
            }
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isEnabled ? 1 : 0.50,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? Colors.tealAccent.withOpacity(0.12)
                : const Color(0xFF080808),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? Colors.tealAccent.withOpacity(0.85)
                  : Colors.white.withOpacity(0.08),
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.tealAccent.withOpacity(0.17)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? Colors.tealAccent : Colors.white38,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isEnabled ? Colors.white : Colors.white54,
                              fontSize: 13.2,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        if (!isEnabled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Unavailable",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 9.8,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      code == "COD"
                          ? "Pay when your order arrives"
                          : "Secure online payment via Razorpay",
                      style: TextStyle(
                        color: isEnabled ? Colors.white54 : Colors.white30,
                        fontSize: 10.6,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (!isEnabled && restrictedBy.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Not supported by: ${restrictedBy.take(2).join(", ")}${restrictedBy.length > 2 ? " +${restrictedBy.length - 2} more" : ""}",
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isEnabled ? Colors.tealAccent : Colors.white24,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getActuallyAppliedOffers() {
    return offerDetails.where((offer) {
      final bool canApplyOffer = offer["can_apply_offer"] == true;

      final double offerDiscountValue =
          double.tryParse((offer["offer_discount"] ?? "0").toString()) ?? 0;

      final int freeItemsCount = _toInt(offer["free_items_count"]);

      final List freeProducts = offer["free_products"] ?? [];

      return canApplyOffer ||
          offerDiscountValue > 0 ||
          freeItemsCount > 0 ||
          freeProducts.isNotEmpty;
    }).toList();
  }

  List<Map<String, dynamic>> _getOfferUnlockHints() {
    return offerDetails.where((offer) {
      final bool canApplyOffer = offer["can_apply_offer"] == true;
      final int eligibleCount = _toInt(offer["eligible_items_count"]);
      final int needToAdd = _toInt(offer["need_to_add"]);

      return !canApplyOffer && eligibleCount > 0 && needToAdd > 0;
    }).toList();
  }

  Widget _buildOfferUnlockHintSection() {
    final hints = _getOfferUnlockHints();

    if (hints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 2, 4, 14),
      child: Column(
        children: hints.map((offer) {
          final int eligibleCount = _toInt(offer["eligible_items_count"]);
          final int requiredCount = _toInt(offer["required_items_count"]);
          final int needToAdd = _toInt(offer["need_to_add"]);

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF073F39), Color(0xFF101010)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.tealAccent.withOpacity(0.34)),
              boxShadow: [
                BoxShadow(
                  color: Colors.tealAccent.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.tealAccent.withOpacity(0.32),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.tealAccent,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer["title"]?.toString() ?? "Offer available",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          fontFamily: "Poppins",
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        needToAdd == 1
                            ? "Add 1 more eligible product to unlock this deal"
                            : "Add $needToAdd more eligible products to unlock this deal",
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: "Poppins",
                        ),
                      ),
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: requiredCount <= 0
                              ? 0
                              : (eligibleCount / requiredCount).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withOpacity(0.10),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.tealAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$eligibleCount of $requiredCount eligible items added",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10.5,
                          fontFamily: "Poppins",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppliedOfferDetails() {
    final List<Map<String, dynamic>> appliedOffers =
        _getActuallyAppliedOffers();

    if (appliedOffers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.tealAccent.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_rounded,
                color: Colors.tealAccent,
                size: 16,
              ),
              SizedBox(width: 7),
              Text(
                "Applied Offers",
                style: TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: "Poppins",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...appliedOffers.map((offer) {
            final List freeProducts = offer["free_products"] ?? [];
            final String message = (offer["message"] ?? "").toString().trim();

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFF070707),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer["title"]?.toString() ?? "Offer Applied",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: "Poppins",
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.isNotEmpty
                        ? message
                        : "Buy ${offer["buy_quantity"]} Get ${offer["free_quantity"]} Free",
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontFamily: "Poppins",
                    ),
                  ),
                  if (freeProducts.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    ...freeProducts.map((freeProduct) {
                      final String freeAmount =
                          (freeProduct["free_amount"] ??
                                  freeProduct["free_price"] ??
                                  "0.00")
                              .toString();

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.card_giftcard_rounded,
                              color: Colors.greenAccent,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${freeProduct["product_title"] ?? "Free product"} is free",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                                fontFamily: "Poppins",
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "-₹$freeAmount",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ================= ORDER SUMMARY =================
  Widget _buildOrderSummary() {
    final double bagTotalValue = double.tryParse(bagTotal) ?? 0;
    final double bagSavingsValue = double.tryParse(bagSavings) ?? 0;
    final double couponDiscountValue = double.tryParse(couponDiscount) ?? 0;
    final double platformFeeValue = double.tryParse(platformFee) ?? 0;
    final double convieniencefeevalue = double.tryParse(convenienceFee) ?? 0;
    final double payableValue = double.tryParse(amountPayable) ?? 0;
    final double shipmentcharge = double.tryParse(shipmentfee) ?? 0;
    final double offerDiscountValue = double.tryParse(offerDiscount) ?? 0;
    final double totalSavingsValue =
        bagSavingsValue + couponDiscountValue + offerDiscountValue;

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 2, 4, 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.tealAccent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order Summary",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Price breakdown before placing order",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _row("Bag Total", "₹${bagTotalValue.toStringAsFixed(2)}"),
          const SizedBox(height: 11),
          _row(
            "Bag Savings",
            "-₹${bagSavingsValue.toStringAsFixed(2)}",
            valueColor: Colors.greenAccent,
          ),
          const SizedBox(height: 11),
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
          if (offerDiscountValue > 0) ...[
            const SizedBox(height: 11),
            _row(
              "Offer Discount",
              "-₹${offerDiscountValue.toStringAsFixed(2)}",
              valueColor: Colors.greenAccent,
            ),
          ],
          if (_getActuallyAppliedOffers().isNotEmpty) ...[
            const SizedBox(height: 13),
            _buildAppliedOfferDetails(),
          ],
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 14),
          _row(
            "Convenience Fee",
            "₹${convieniencefeevalue.toStringAsFixed(2)}",
          ),
          const SizedBox(height: 11),
          _row(
            "Shipment Charge",
            "₹${shipmentcharge.toStringAsFixed(2)}",
          ),
          const SizedBox(height: 11),
          _row("Platform Fee", "₹${platformFeeValue.toStringAsFixed(2)}"),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Amount Payable",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Inclusive of all charges",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                Text(
                  "₹${payableValue.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          if (totalSavingsValue > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.20)),
              ),
              child: Center(
                child: Text(
                  "🎉 You saved ₹${totalSavingsValue.toStringAsFixed(2)} on this order",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color valueColor = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: valueColor,
            fontSize: 12.8,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  // ================= ADDRESS UI =================
  Widget _buildAddressSection() {
    final bool hasAddress = selectedAddress != null;

    return GestureDetector(
      onTap: () {
        _showAddressPopup();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(4, 4, 4, 14),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF123A35), Color(0xFF101010)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasAddress
                ? Colors.tealAccent.withOpacity(0.36)
                : Colors.orangeAccent.withOpacity(0.40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.tealAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.tealAccent.withOpacity(0.28)),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.tealAccent,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        hasAddress ? "Delivering to" : "Delivery Address",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (hasAddress && selectedAddress!["is_default"] == true) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "DEFAULT",
                            style: TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasAddress
                        ? "${selectedAddress!["full_name"] ?? ""}, ${selectedAddress!["city"] ?? ""}"
                        : "Select address to continue checkout",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (hasAddress) ...[
                    const SizedBox(height: 3),
                    Text(
                      "${selectedAddress!["address_line1"] ?? ""}, ${selectedAddress!["pincode"] ?? ""}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                hasAddress ? "CHANGE" : "ADD",
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Map<String, dynamic>? _getEligibleOfferForCartItem(dynamic item) {
  final variant = item["variant"];

  final int productId = _toInt(variant?["product_id"]);
  final int variantId = _toInt(variant?["id"]);

  if (productId <= 0 && variantId <= 0) return null;

  for (final offer in offerDetails) {
    final List eligibleProductIds = offer["eligible_product_ids"] ?? [];
    final List eligibleVariantIds = offer["eligible_variant_ids"] ?? [];

    final bool isProductEligible = eligibleProductIds
        .map((e) => _toInt(e))
        .contains(productId);

    final bool isVariantEligible = eligibleVariantIds
        .map((e) => _toInt(e))
        .contains(variantId);

    if (isProductEligible || isVariantEligible) {
      return offer;
    }
  }

  return null;
}
  Map<String, dynamic>? _getFreeOfferForCartItem(dynamic item) {
    final int? cartItemId = int.tryParse(item["id"].toString());

    if (cartItemId == null) return null;

    for (final offer in offerDetails) {
      final List freeProducts = offer["free_products"] ?? [];

      for (final freeProduct in freeProducts) {
        final int? freeCartItemId = int.tryParse(
          freeProduct["cart_item_id"].toString(),
        );

        if (freeCartItemId == cartItemId) {
          return {"offer": offer, "free_product": freeProduct};
        }
      }
    }

    return null;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  // ================= CART ITEM UI =================
  Widget _buildCartItem(dynamic item, dynamic variant) {
    String imageUrl = "";

    if (variant != null &&
        variant["first_image"] != null &&
        variant["first_image"].toString().isNotEmpty) {
      imageUrl = "$api${variant["first_image"]}";
    }

    final attrs = (variant?["attribute_names"] as List?) ?? [];
    final Map<String, dynamic>? freeOfferData = _getFreeOfferForCartItem(item);
    final bool isFreeOfferItem = freeOfferData != null;

    final Map<String, dynamic>? eligibleOffer = _getEligibleOfferForCartItem(
      item,
    );

    final bool isOfferEligibleItem = eligibleOffer != null && !isFreeOfferItem;

    final Map<String, dynamic>? appliedOffer =
        freeOfferData?["offer"] as Map<String, dynamic>?;

    final Map<String, dynamic>? freeProduct =
        freeOfferData?["free_product"] as Map<String, dynamic>?;

    final String productTitle =
        variant?["product_title"]?.toString() ?? "Product unavailable";
    final String variantText = attrs.isEmpty ? "Default" : attrs.join(" • ");
    final String sellingPrice = item["product_price"]?.toString() ?? "0.00";
    final String mrpPrice = variant?["price"]?.toString() ?? "0.00";
    final String lineTotal = item["line_total"]?.toString() ?? "0.00";
    final int qty = _toInt(item["quantity"]);
    final int availableStock = _toInt(item["available_stock"]);
    final bool isOutOfStock = item["is_out_of_stock"] == true;
    final bool isQtyExceeded = item["is_qty_exceeded"] == true;
    final double sellingPriceValue = double.tryParse(sellingPrice) ?? 0;
    final double mrpPriceValue = double.tryParse(mrpPrice) ?? 0;
    final double lineTotalValue = double.tryParse(lineTotal) ?? 0;
    final double discountPercentage =
        mrpPriceValue > sellingPriceValue && mrpPriceValue > 0
        ? ((mrpPriceValue - sellingPriceValue) / mrpPriceValue) * 100
        : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 7, 4, 13),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFreeOfferItem
              ? Colors.greenAccent.withOpacity(0.45)
              : isOfferEligibleItem
              ? Colors.tealAccent.withOpacity(0.35)
              : Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 118,
                        width: 98,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: imageUrl.isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.white54,
                                    size: 30,
                                  ),
                                )
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.white54,
                                        size: 30,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 11,
                        child: Builder(
                          builder: (_) {
                            if (isFreeOfferItem) {
                              return _cartImageBadge(
                                text: "FREE",
                                color: const Color(0xFF00A676),
                              );
                            }
                            if (isOfferEligibleItem) {
                              return _cartImageBadge(
                                text: "OFFER",
                                color: const Color(0xFF009688),
                              );
                            }
                            if (discountPercentage > 0) {
                              return _cartImageBadge(
                                text: "${discountPercentage.round()}% OFF",
                                color: const Color(0xFFE53935),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                productTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  height: 1.25,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _confirmDelete(item),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                height: 32,
                                width: 32,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: Colors.redAccent.withOpacity(0.22),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 17,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _cartMetaChip(
                              text: variantText,
                              icon: Icons.tune_rounded,
                            ),
                            if (availableStock > 0)
                              _cartMetaChip(
                                text: "Stock $availableStock",
                                icon: Icons.inventory_2_outlined,
                                color: Colors.tealAccent,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹$sellingPrice",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 7),
                            if (mrpPriceValue > sellingPriceValue)
                              Text(
                                "₹$mrpPrice",
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.white38,
                                  decorationThickness: 1.4,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF070707),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.tealAccent.withOpacity(0.42),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: qty > 1
                                        ? () {
                                            final int newQty = qty - 1;
                                            setState(() {
                                              item["quantity"] = newQty;
                                            });
                                            updatecart(item["id"], newQty);
                                          }
                                        : null,
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(14),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(7),
                                      child: Icon(
                                        Icons.remove_rounded,
                                        size: 16,
                                        color: qty > 1
                                            ? Colors.tealAccent
                                            : Colors.white24,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 36,
                                    alignment: Alignment.center,
                                    child: Text(
                                      qty.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.8,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap:
                                        availableStock == 0 ||
                                            qty >= availableStock
                                        ? null
                                        : () {
                                            final int newQty = qty + 1;
                                            setState(() {
                                              item["quantity"] = newQty;
                                            });
                                            updatecart(item["id"], newQty);
                                          },
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(14),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(7),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color:
                                            availableStock == 0 ||
                                                qty >= availableStock
                                            ? Colors.white24
                                            : Colors.tealAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "Item Total",
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 9.8,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "₹${lineTotalValue.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Colors.tealAccent,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isOfferEligibleItem) ...[
              _cartInfoStrip(
                icon: Icons.local_offer_rounded,
                iconColor: Colors.tealAccent,
                title: "${eligibleOffer?["title"] ?? "Offer product"} eligible",
                subtitle: "Add required eligible items to unlock this deal",
                borderColor: Colors.tealAccent.withOpacity(0.28),
                backgroundColor: Colors.tealAccent.withOpacity(0.09),
              ),
            ],
            if (isFreeOfferItem) ...[
              _cartInfoStrip(
                icon: Icons.card_giftcard_rounded,
                iconColor: Colors.greenAccent,
                title: "${appliedOffer?["title"] ?? "Offer Applied"} • FREE",
                subtitle:
                    "You saved ₹${freeProduct?["free_amount"] ?? freeProduct?["free_price"] ?? "0.00"} on this item",
                borderColor: Colors.greenAccent.withOpacity(0.30),
                backgroundColor: Colors.greenAccent.withOpacity(0.09),
              ),
            ],
            if (isOutOfStock || isQtyExceeded)
              _cartInfoStrip(
                icon: Icons.error_outline_rounded,
                iconColor: Colors.redAccent,
                title: isOutOfStock
                    ? "This item is currently out of stock"
                    : "Selected quantity is higher than available stock",
                subtitle: "Please update quantity or remove this item",
                borderColor: Colors.redAccent.withOpacity(0.28),
                backgroundColor: Colors.redAccent.withOpacity(0.09),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cartImageBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          fontFamily: "Poppins",
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _cartMetaChip({
    required String text,
    required IconData icon,
    Color color = Colors.white70,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(color == Colors.white70 ? 0.06 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(color == Colors.white70 ? 0.08 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.2,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartInfoStrip({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color borderColor,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 11),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    fontFamily: "Poppins",
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 10.4,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Poppins",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  void _showCodConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.tealAccent.withOpacity(0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Colors.tealAccent,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Confirm Cash on Delivery",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: "Poppins",
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Your order will be placed with Cash on Delivery. You can pay ₹$amountPayable when the order arrives.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                    fontFamily: "Poppins",
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.tealAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedAddress == null
                              ? "No address selected"
                              : "${selectedAddress!["full_name"] ?? ""}, ${selectedAddress!["city"] ?? ""}, ${selectedAddress!["pincode"] ?? ""}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            placingOrder = false;
                          });
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.25),
                          ),
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);

                          if (selectedPaymentId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please select payment method"),
                              ),
                            );
                            return;
                          }

                          checkoutOrder(
                            paymentMethodId: selectedPaymentId!,
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
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          "Place Order",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= BOTTOM BAR =================
  Widget _buildBottomBar(BuildContext context) {
    final double payableValue = double.tryParse(amountPayable) ?? 0;
    final double savedValue =
        (double.tryParse(bagSavings) ?? 0) +
        (double.tryParse(couponDiscount) ?? 0) +
        (double.tryParse(offerDiscount) ?? 0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF090909),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
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
                    "Payable Amount",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11.2,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "₹${payableValue.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (savedValue > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Saved ₹${savedValue.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              height: 52,
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

                        if (selectedPaymentCode.isEmpty) {
                          setState(() {
                            placingOrder = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "No payment method available for all cart items",
                              ),
                            ),
                          );
                          return;
                        }

                        if (selectedPaymentCode == "COD") {
                          _showCodConfirmationDialog();
                        } else {
                          ordercreate();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      placingOrder ? "Processing" : "Checkout",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
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
    double radius = 8,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF101010),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: index == 0
              ? Row(
                  children: [
                    _box(height: 42, width: 42, radius: 15),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(height: 13, width: 130),
                          const SizedBox(height: 8),
                          _box(height: 11, width: double.infinity),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(height: 118, width: 98, radius: 20),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(height: 15, width: double.infinity),
                          const SizedBox(height: 8),
                          _box(height: 13, width: 150),
                          const SizedBox(height: 12),
                          _box(height: 18, width: 95),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _box(height: 34, width: 96, radius: 14),
                              const Spacer(),
                              _box(height: 25, width: 70, radius: 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

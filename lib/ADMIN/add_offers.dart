import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddOffers extends StatefulWidget {
  const AddOffers({super.key});

  @override
  State<AddOffers> createState() => _AddOffersState();
}

class _AddOffersState extends State<AddOffers> {
  bool showForm = false;
  bool isEditMode = false;
  bool isLoading = false;
  bool isSubmitting = false;
  bool isProductsLoading = false;

  int? editingOfferId;
  int? selectedCategoryId;

  bool isActive = true;

  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController buyQtyCtrl = TextEditingController();
  final TextEditingController freeQtyCtrl = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  List<Map<String, dynamic>> offers = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> categoryProducts = [];

  List<int> selectedProductIds = [];
  List<int> selectedVariantIds = [];

  final String offerApi = "$api/api/myskates/offers/";

  @override
  void initState() {
    super.initState();
    getProductCategories();
    getOffers();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    buyQtyCtrl.dispose();
    freeQtyCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  Map<String, String> _headers(String? token) {
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  Future<void> getProductCategories() async {
    final token = await _getToken();

    try {
      final response = await http.get(
        Uri.parse("$api/api/myskates/products/category/"),
        headers: _headers(token),
      );

      print("CATEGORY LIST STATUS: ${response.statusCode}");
      print("CATEGORY LIST BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> list = [];

        if (parsed is List) {
          list = parsed
              .whereType<Map<String, dynamic>>()
              .map((item) {
                return {
                  "id": item["id"],
                  "name": item["name"] ??
                      item["title"] ??
                      item["category_name"] ??
                      "Category",
                };
              })
              .toList();
        } else if (parsed is Map && parsed["data"] is List) {
          list = (parsed["data"] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) {
                return {
                  "id": item["id"],
                  "name": item["name"] ??
                      item["title"] ??
                      item["category_name"] ??
                      "Category",
                };
              })
              .toList();
        } else if (parsed is Map && parsed["results"] is List) {
          list = (parsed["results"] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) {
                return {
                  "id": item["id"],
                  "name": item["name"] ??
                      item["title"] ??
                      item["category_name"] ??
                      "Category",
                };
              })
              .toList();
        }

        if (!mounted) return;

        setState(() {
          categories = list;
        });
      } else {
        snack("Failed to load categories", Colors.redAccent);
      }
    } catch (e) {
      print("CATEGORY LIST ERROR: $e");
      snack("Something went wrong while loading categories", Colors.redAccent);
    }
  }

  Future<void> getProductsByCategory(int categoryId) async {
    final token = await _getToken();

    try {
      setState(() {
        isProductsLoading = true;
        categoryProducts = [];
        selectedProductIds = [];
        selectedVariantIds = [];
      });

      final response = await http.get(
        Uri.parse("$api/api/myskates/products/category/$categoryId/details/"),
        headers: _headers(token),
      );

      print("PRODUCT CATEGORY DETAILS STATUS: ${response.statusCode}");
      print("PRODUCT CATEGORY DETAILS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> list = [];

        if (parsed is Map && parsed["data"] is List) {
          list = List<Map<String, dynamic>>.from(parsed["data"]);
        } else if (parsed is Map && parsed["results"] is List) {
          list = List<Map<String, dynamic>>.from(parsed["results"]);
        } else if (parsed is List) {
          list = List<Map<String, dynamic>>.from(parsed);
        }

        if (!mounted) return;

        setState(() {
          categoryProducts = list;
        });
      } else {
        snack("Failed to load products", Colors.redAccent);
      }
    } catch (e) {
      print("PRODUCT CATEGORY DETAILS ERROR: $e");
      snack("Something went wrong while loading products", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          isProductsLoading = false;
        });
      }
    }
  }

  Future<void> getProductsByCategoryForEdit({
    required int categoryId,
    required List<int> productIds,
    required List<int> variantIds,
  }) async {
    final token = await _getToken();

    try {
      setState(() {
        isProductsLoading = true;
        categoryProducts = [];
      });

      final response = await http.get(
        Uri.parse("$api/api/myskates/products/category/$categoryId/details/"),
        headers: _headers(token),
      );

      print("PRODUCT CATEGORY EDIT STATUS: ${response.statusCode}");
      print("PRODUCT CATEGORY EDIT BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> list = [];

        if (parsed is Map && parsed["data"] is List) {
          list = List<Map<String, dynamic>>.from(parsed["data"]);
        } else if (parsed is Map && parsed["results"] is List) {
          list = List<Map<String, dynamic>>.from(parsed["results"]);
        } else if (parsed is List) {
          list = List<Map<String, dynamic>>.from(parsed);
        }

        if (!mounted) return;

        setState(() {
          categoryProducts = list;
          selectedProductIds = productIds;
          selectedVariantIds = variantIds;
        });
      } else {
        snack("Failed to load products", Colors.redAccent);
      }
    } catch (e) {
      print("PRODUCT CATEGORY EDIT ERROR: $e");
      snack("Something went wrong while loading products", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          isProductsLoading = false;
        });
      }
    }
  }

  Future<void> getOffers() async {
    try {
      setState(() {
        isLoading = true;
      });

      final token = await _getToken();

      final response = await http.get(
        Uri.parse(offerApi),
        headers: _headers(token),
      );

      print("OFFERS STATUS: ${response.statusCode}");
      print("OFFERS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List data = [];

        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded["data"] is List) {
          data = decoded["data"];
        } else if (decoded is Map && decoded["results"] is List) {
          data = decoded["results"];
        }

        if (!mounted) return;

        setState(() {
          offers = data.whereType<Map<String, dynamic>>().toList();
        });
      } else {
        snack("Failed to load offers", Colors.redAccent);
      }
    } catch (e) {
      print("OFFERS ERROR: $e");
      snack("Something went wrong while loading offers", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> submitOffer() async {
    if (selectedCategoryId == null) {
      snack("Select category", Colors.redAccent);
      return;
    }

    if (selectedProductIds.isEmpty && selectedVariantIds.isEmpty) {
      snack("Select at least one product or variant", Colors.redAccent);
      return;
    }

    if (titleCtrl.text.trim().isEmpty) {
      snack("Enter offer title", Colors.redAccent);
      return;
    }

    final int? buyQty = int.tryParse(buyQtyCtrl.text.trim());
    final int? freeQty = int.tryParse(freeQtyCtrl.text.trim());

    if (buyQty == null || buyQty <= 0) {
      snack("Buy quantity must be greater than 0", Colors.redAccent);
      return;
    }

    if (freeQty == null || freeQty <= 0) {
      snack("Free quantity must be greater than 0", Colors.redAccent);
      return;
    }

    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
      snack("End date cannot be before start date", Colors.redAccent);
      return;
    }

    try {
      setState(() {
        isSubmitting = true;
      });

      final token = await _getToken();

      final Map<String, dynamic> body = {
        "category": selectedCategoryId,
        "products": selectedProductIds,
        "variants": selectedVariantIds,
        "title": titleCtrl.text.trim(),
        "buy_quantity": buyQty,
        "free_quantity": freeQty,
        "is_active": isActive,
        "start_date": startDate?.toIso8601String(),
        "end_date": endDate?.toIso8601String(),
      };

      print("OFFER BODY: ${jsonEncode(body)}");

      http.Response response;

      if (isEditMode && editingOfferId != null) {
        response = await http.put(
          Uri.parse("$offerApi$editingOfferId/"),
          headers: _headers(token),
          body: jsonEncode(body),
        );
      } else {
        response = await http.post(
          Uri.parse(offerApi),
          headers: _headers(token),
          body: jsonEncode(body),
        );
      }

      print("SUBMIT OFFER STATUS: ${response.statusCode}");
      print("SUBMIT OFFER BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        snack(
          isEditMode ? "Offer updated successfully" : "Offer added successfully",
          Colors.green,
        );

        resetForm();
        await getOffers();
      } else {
        String message =
            isEditMode ? "Failed to update offer" : "Failed to add offer";

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map) {
            message = decoded["message"]?.toString() ??
                decoded["detail"]?.toString() ??
                decoded["error"]?.toString() ??
                decoded.toString();
          }
        } catch (_) {}

        snack(message, Colors.redAccent);
      }
    } catch (e) {
      print("SUBMIT OFFER ERROR: $e");
      snack("Something went wrong while saving offer", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> deleteOffer(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101010),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Delete Offer?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to delete this offer?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse("$offerApi$id/"),
        headers: _headers(token),
      );

      print("DELETE OFFER STATUS: ${response.statusCode}");
      print("DELETE OFFER BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        snack("Offer deleted successfully", Colors.green);
        await getOffers();
      } else {
        snack("Failed to delete offer", Colors.redAccent);
      }
    } catch (e) {
      print("DELETE OFFER ERROR: $e");
      snack("Something went wrong while deleting offer", Colors.redAccent);
    }
  }

  Future<void> toggleOfferStatus(Map<String, dynamic> offer) async {
  final int? offerId = int.tryParse(offer["id"].toString());

  if (offerId == null) {
    snack("Invalid offer id", Colors.redAccent);
    return;
  }

  final bool currentStatus = offer["is_active"] == true;
  final bool newStatus = !currentStatus;

  try {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse("$offerApi$offerId/"),
      headers: _headers(token),
      body: jsonEncode({
        "is_active": newStatus,
      }),
    );

    print("TOGGLE OFFER STATUS CODE: ${response.statusCode}");
    print("TOGGLE OFFER STATUS BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 202) {
      setState(() {
        final index = offers.indexWhere(
          (item) => item["id"].toString() == offerId.toString(),
        );

        if (index != -1) {
          offers[index]["is_active"] = newStatus;
        }
      });

      snack(
        newStatus ? "Offer activated successfully" : "Offer deactivated successfully",
        Colors.green,
      );
    } else {
      String message = "Failed to update offer status";

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          message = decoded["message"]?.toString() ??
              decoded["detail"]?.toString() ??
              decoded["error"]?.toString() ??
              decoded.toString();
        }
      } catch (_) {}

      snack(message, Colors.redAccent);
    }
  } catch (e) {
    print("TOGGLE OFFER STATUS ERROR: $e");
    snack("Something went wrong while updating offer status", Colors.redAccent);
  }
}

Future<void> confirmToggleOfferStatus(Map<String, dynamic> offer) async {
  final bool active = offer["is_active"] == true;

  final bool? confirm = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        backgroundColor: const Color(0xFF101010),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          active ? "Deactivate Offer?" : "Activate Offer?",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          active
              ? "This offer will be turned off and users will not get this offer."
              : "This offer will be turned on and eligible users can get this offer.",
          style: const TextStyle(
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              active ? "Deactivate" : "Activate",
              style: TextStyle(
                color: active ? Colors.redAccent : Colors.greenAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await toggleOfferStatus(offer);
  }
}
  void resetForm() {
    setState(() {
      showForm = false;
      isEditMode = false;
      editingOfferId = null;
      selectedCategoryId = null;
      selectedProductIds = [];
      selectedVariantIds = [];
      categoryProducts = [];
      titleCtrl.clear();
      buyQtyCtrl.clear();
      freeQtyCtrl.clear();
      isActive = true;
      startDate = null;
      endDate = null;
    });
  }

  void snack(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return "Select date";
    return date.toString().split(" ")[0];
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  String getCategoryNameById(dynamic id) {
    if (id == null) return "Category";

    final int? categoryId = int.tryParse(id.toString());

    final matched = categories.where((cat) {
      final int? catId = int.tryParse(cat["id"].toString());
      return catId == categoryId;
    }).toList();

    if (matched.isEmpty) return "Category ID: $id";

    return matched.first["name"]?.toString() ??
        matched.first["title"]?.toString() ??
        matched.first["category_name"]?.toString() ??
        "Category ID: $id";
  }

  String getFullImageUrl(String? image) {
    if (image == null || image.trim().isEmpty) return "";

    final trimmed = image.trim();

    if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
      return trimmed;
    }

    return "$api$trimmed";
  }

  List<int> extractProductIds(dynamic products) {
    final List<int> ids = [];

    if (products is List) {
      for (final item in products) {
        if (item is Map) {
          final int? id = int.tryParse(item["id"].toString());
          if (id != null) ids.add(id);
        } else {
          final int? id = int.tryParse(item.toString());
          if (id != null) ids.add(id);
        }
      }
    }

    return ids;
  }

  List<int> extractVariantIds(dynamic variants) {
    final List<int> ids = [];

    if (variants is List) {
      for (final item in variants) {
        if (item is Map) {
          final int? id = int.tryParse(item["id"].toString());
          if (id != null) ids.add(id);
        } else {
          final int? id = int.tryParse(item.toString());
          if (id != null) ids.add(id);
        }
      }
    }

    return ids;
  }

  List<int> getVariantIdsFromProduct(Map<String, dynamic> product) {
    final List variants = product["variants"] is List ? product["variants"] : [];

    return variants
        .map((variant) => int.tryParse(variant["id"].toString()) ?? 0)
        .where((id) => id != 0)
        .toList();
  }

  bool isVariantBelongsToSelectedFullProduct(int variantId) {
    for (final product in categoryProducts) {
      final int productId = int.tryParse(product["id"].toString()) ?? 0;

      if (!selectedProductIds.contains(productId)) continue;

      final variantIds = getVariantIdsFromProduct(product);

      if (variantIds.contains(variantId)) {
        return true;
      }
    }

    return false;
  }

  void fillEditForm(Map<String, dynamic> offer) {
    final int? categoryId = int.tryParse(
      (offer["category"] ?? offer["category_id"] ?? "").toString(),
    );

    final List<int> productIds = extractProductIds(offer["products"]);
    final List<int> variantIds = extractVariantIds(offer["variants"]);

    setState(() {
      showForm = true;
      isEditMode = true;
      editingOfferId = offer["id"];
      selectedCategoryId = categoryId;
      selectedProductIds = productIds;
      selectedVariantIds = variantIds;

      titleCtrl.text = offer["title"]?.toString() ?? "";
      buyQtyCtrl.text = offer["buy_quantity"]?.toString() ?? "";
      freeQtyCtrl.text = offer["free_quantity"]?.toString() ?? "";
      isActive = offer["is_active"] == true;

      startDate = parseDate(offer["start_date"]);
      endDate = parseDate(offer["end_date"]);
    });

    if (categoryId != null) {
      getProductsByCategoryForEdit(
        categoryId: categoryId,
        productIds: productIds,
        variantIds: variantIds,
      );
    }
  }

  Future<void> pickDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
      initialDate: isStartDate
          ? startDate ?? DateTime.now()
          : endDate ?? startDate ?? DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF001A18),
            canvasColor: const Color(0xFF071412),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00F5D4),
              onPrimary: Colors.black,
              surface: Color(0xFF071412),
              onSurface: Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: const Color(0xFF071412),
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: const Color(0xFF001A18),
              headerForegroundColor: Colors.white,
              weekdayStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              dayStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              yearStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.white54;
                  }

                  return Colors.white;
                },
              ),
              yearForegroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.white54;
                  }

                  return Colors.white;
                },
              ),
              todayBorder: const BorderSide(
                color: Color(0xFF00F5D4),
                width: 1.4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00F5D4),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF071412)),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;

          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = null;
          }
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF001A18),
              Color(0xFF003A36),
              Color(0xFF000000),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFF00F5D4),
            backgroundColor: Colors.black,
            onRefresh: () async {
              await getProductCategories();
              await getOffers();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header(),
                  const SizedBox(height: 14),
                  if (showForm) ...[
                    glassBox(child: offerForm()),
                    const SizedBox(height: 18),
                  ],
                  glassBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label("Offers"),
                        const SizedBox(height: 4),
                        offerList(),
                      ],
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

  Widget header() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            "Add Offers",
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            showForm ? Icons.close_rounded : Icons.add_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            if (showForm) {
              resetForm();
            } else {
              setState(() {
                showForm = true;
              });
            }
          },
        ),
      ],
    );
  }

  Widget glassBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.11)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.24),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget offerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditMode ? "Update Offer" : "Create New Offer",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        label("Category"),
        categoryDropdown(),
        label("Products / Variants"),
        productMultiSelector(),
        selectedProductsPreview(),
        label("Offer Title"),
        input(
          titleCtrl,
          hint: "Example: Buy 2 Get 1",
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label("Buy Quantity"),
                  input(
                    buyQtyCtrl,
                    hint: "2",
                    keyboard: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label("Free Quantity"),
                  input(
                    freeQtyCtrl,
                    hint: "1",
                    keyboard: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],
        ),
        label("Start Date"),
        dateBox(startDate, () => pickDate(true)),
        label("End Date"),
        dateBox(endDate, () => pickDate(false)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Offer Active",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: isActive,
                activeThumbColor: const Color(0xFF00F5D4),
                onChanged: (value) {
                  setState(() {
                    isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: isSubmitting ? null : submitOffer,
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: isEditMode ? Colors.orange : const Color(0xFF00A895),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEditMode ? "Update Offer" : "Submit Offer",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget categoryDropdown() {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedCategoryId,
          isExpanded: true,
          dropdownColor: const Color(0xFF101010),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          hint: const Text(
            "Select category",
            style: TextStyle(color: Colors.white54),
          ),
          style: const TextStyle(color: Colors.white),
          items: categories.map((cat) {
            final int? id = int.tryParse(cat["id"].toString());

            final String name = cat["name"]?.toString() ??
                cat["title"]?.toString() ??
                cat["category_name"]?.toString() ??
                "Category";

            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              selectedCategoryId = value;
              selectedProductIds = [];
              selectedVariantIds = [];
              categoryProducts = [];
            });

            getProductsByCategory(value);
          },
        ),
      ),
    );
  }

  Widget productMultiSelector() {
    if (selectedCategoryId == null) {
      return emptySelectorBox("Select a category first");
    }

    if (isProductsLoading) {
      return Container(
        height: 70,
        alignment: Alignment.center,
        decoration: selectorDecoration(),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF00F5D4),
          ),
        ),
      );
    }

    if (categoryProducts.isEmpty) {
      return emptySelectorBox("No products found in this category");
    }

    return GestureDetector(
      onTap: openProductSelectionSheet,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 55),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: selectorDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedProductIds.isEmpty && selectedVariantIds.isEmpty
                    ? "Select products / variants"
                    : "${selectedProductIds.length} product(s), ${selectedVariantIds.length} variant(s) selected",
                style: TextStyle(
                  color: selectedProductIds.isEmpty && selectedVariantIds.isEmpty
                      ? Colors.white54
                      : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  BoxDecoration selectorDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.10)),
    );
  }

  Widget emptySelectorBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: selectorDecoration(),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget selectedProductsPreview() {
    if (selectedProductIds.isEmpty && selectedVariantIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Widget> chips = [];

    for (final productId in selectedProductIds) {
      final product = categoryProducts.firstWhere(
        (p) => int.tryParse(p["id"].toString()) == productId,
        orElse: () => {},
      );

      final String title =
          product["title"]?.toString() ?? "Product ID: $productId";

      chips.add(
        selectedChip(
          title: "All variants: $title",
          onRemove: () {
            setState(() {
              selectedProductIds.remove(productId);
            });
          },
        ),
      );
    }

    for (final variantId in selectedVariantIds) {
      if (isVariantBelongsToSelectedFullProduct(variantId)) {
        continue;
      }

      String variantName = "Variant ID: $variantId";

      for (final product in categoryProducts) {
        final List variants =
            product["variants"] is List ? product["variants"] : [];

        for (final variant in variants) {
          final int id = int.tryParse(variant["id"].toString()) ?? 0;

          if (id == variantId) {
            final String productTitle = product["title"]?.toString() ?? "";
            final String currentVariantName =
                variant["variant_name"]?.toString() ?? variantName;

            variantName = productTitle.trim().isEmpty
                ? currentVariantName
                : "$productTitle - $currentVariantName";
          }
        }
      }

      chips.add(
        selectedChip(
          title: "Variant: $variantName",
          onRemove: () {
            setState(() {
              selectedVariantIds.remove(variantId);
            });
          },
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Widget selectedChip({
    required String title,
    required VoidCallback onRemove,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF00A895).withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00F5D4).withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              color: Colors.white70,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  void openProductSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        List<int> tempSelectedProducts = List<int>.from(selectedProductIds);
        List<int> tempSelectedVariants = List<int>.from(selectedVariantIds);

        Map<int, bool> expandedProductsInSheet = {};

        return StatefulBuilder(
          builder: (context, modalSetState) {
            bool isProductFullySelected(Map<String, dynamic> product) {
              final int productId =
                  int.tryParse(product["id"].toString()) ?? 0;

              return tempSelectedProducts.contains(productId);
            }

            bool isProductPartiallySelected(Map<String, dynamic> product) {
              final int productId =
                  int.tryParse(product["id"].toString()) ?? 0;

              if (tempSelectedProducts.contains(productId)) return false;

              final List<int> variantIds = getVariantIdsFromProduct(product);

              if (variantIds.isEmpty) return false;

              return variantIds.any(
                (id) => tempSelectedVariants.contains(id),
              );
            }

            void toggleFullProduct(Map<String, dynamic> product) {
              final int productId =
                  int.tryParse(product["id"].toString()) ?? 0;

              final List<int> productVariantIds =
                  getVariantIdsFromProduct(product);

              final bool alreadySelected =
                  tempSelectedProducts.contains(productId);

              modalSetState(() {
                if (alreadySelected) {
                  tempSelectedProducts.remove(productId);
                } else {
                  if (productId != 0) {
                    tempSelectedProducts.add(productId);
                  }

                  tempSelectedVariants.removeWhere(
                    (variantId) => productVariantIds.contains(variantId),
                  );
                }
              });
            }

            void toggleVariant({
              required int productId,
              required int variantId,
            }) {
              modalSetState(() {
                tempSelectedProducts.remove(productId);

                if (tempSelectedVariants.contains(variantId)) {
                  tempSelectedVariants.remove(variantId);
                } else {
                  if (variantId != 0) {
                    tempSelectedVariants.add(variantId);
                  }
                }
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.86,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF071412),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Select Products & Variants",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "${tempSelectedProducts.length} products • ${tempSelectedVariants.length} variants",
                        style: const TextStyle(
                          color: Color(0xFF00F5D4),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select product for all variants. Select individual variants for variant-only offer.",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.builder(
                      itemCount: categoryProducts.length,
                      itemBuilder: (_, productIndex) {
                        final product = categoryProducts[productIndex];

                        final int productId =
                            int.tryParse(product["id"].toString()) ?? 0;

                        final String imageUrl = getFullImageUrl(
                          product["image"]?.toString(),
                        );

                        final String title =
                            product["title"]?.toString() ?? "Product";

                        final String categoryName =
                            product["category_name"]?.toString() ?? "";

                        final String basePrice =
                            product["base_price"]?.toString() ?? "0";

                        final String shipmentCharge =
                            product["shipment_charge"]?.toString() ?? "0";

                        final List variants =
                            product["variants"] is List ? product["variants"] : [];

                        final bool productSelected =
                            isProductFullySelected(product);

                        final bool partiallySelected =
                            isProductPartiallySelected(product);

                        final bool isExpanded =
                            expandedProductsInSheet[productId] ?? false;

                        final List visibleVariants =
                            isExpanded ? variants : variants.take(3).toList();

                        final int hiddenVariantCount =
                            variants.length - visibleVariants.length;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.055),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: productSelected
                                  ? const Color(0xFF00F5D4).withOpacity(0.65)
                                  : partiallySelected
                                      ? Colors.orangeAccent.withOpacity(0.55)
                                      : Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () => toggleFullProduct(product),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: imageUrl.isEmpty
                                            ? imageFallback(68, 68)
                                            : Image.network(
                                                imageUrl,
                                                width: 68,
                                                height: 68,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) {
                                                  return imageFallback(68, 68);
                                                },
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              categoryName,
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "Base ₹$basePrice • Ship ₹$shipmentCharge",
                                              style: const TextStyle(
                                                color: Color(0xFF00F5D4),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              productSelected
                                                  ? "All ${variants.length} variant(s) included"
                                                  : partiallySelected
                                                      ? "Some variants selected"
                                                      : "${variants.length} variant(s)",
                                              style: TextStyle(
                                                color: productSelected
                                                    ? const Color(0xFF00F5D4)
                                                    : partiallySelected
                                                        ? Colors.orangeAccent
                                                        : Colors.white38,
                                                fontSize: 11,
                                                fontWeight: productSelected ||
                                                        partiallySelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Checkbox(
                                        value: productSelected,
                                        activeColor: const Color(0xFF00A895),
                                        checkColor: Colors.white,
                                        side: const BorderSide(
                                          color: Colors.white54,
                                        ),
                                        onChanged: (_) =>
                                            toggleFullProduct(product),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (variants.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color: Colors.white.withOpacity(0.08),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    10,
                                    12,
                                    12,
                                  ),
                                  child: Column(
                                    children: [
                                      ...visibleVariants.map<Widget>((variant) {
                                        final int variantId = int.tryParse(
                                              variant["id"].toString(),
                                            ) ??
                                            0;

                                        final bool variantSelected =
                                            tempSelectedVariants
                                                .contains(variantId);

                                        final bool disabledByFullProduct =
                                            tempSelectedProducts
                                                .contains(productId);

                                        final String variantName =
                                            variant["variant_name"]
                                                    ?.toString() ??
                                                "Variant";

                                        final String sku =
                                            variant["sku"]?.toString() ?? "";

                                        final String price =
                                            variant["price"]?.toString() ?? "0";

                                        final String discountedPrice =
                                            variant["discounted_price"]
                                                    ?.toString() ??
                                                price;

                                        final String discount =
                                            variant["discount"]?.toString() ??
                                                "0";

                                        final String stock =
                                            variant["stock"]?.toString() ?? "0";

                                        final List attributes =
                                            variant["attributes"] is List
                                                ? variant["attributes"]
                                                : [];

                                        final String attributeText = attributes
                                            .map(
                                              (a) =>
                                                  "${a["attribute_name"]}: ${a["value_name"]}",
                                            )
                                            .join(" • ");

                                        return GestureDetector(
                                          onTap: disabledByFullProduct
                                              ? null
                                              : () {
                                                  toggleVariant(
                                                    productId: productId,
                                                    variantId: variantId,
                                                  );
                                                },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: disabledByFullProduct
                                                  ? const Color(0xFF00A895)
                                                      .withOpacity(0.10)
                                                  : variantSelected
                                                      ? const Color(0xFF00A895)
                                                          .withOpacity(0.18)
                                                      : Colors.black
                                                          .withOpacity(0.18),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: disabledByFullProduct
                                                    ? const Color(0xFF00F5D4)
                                                        .withOpacity(0.25)
                                                    : variantSelected
                                                        ? const Color(
                                                            0xFF00F5D4,
                                                          ).withOpacity(0.55)
                                                        : Colors.white
                                                            .withOpacity(0.06),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              variantName,
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  const TextStyle(
                                                                color:
                                                                    Colors.white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ),
                                                          if (disabledByFullProduct)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 8,
                                                                vertical: 3,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                        0xFF00F5D4)
                                                                    .withOpacity(
                                                                        0.14),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20),
                                                              ),
                                                              child:
                                                                  const Text(
                                                                "Included",
                                                                style:
                                                                    TextStyle(
                                                                  color: Color(
                                                                    0xFF00F5D4,
                                                                  ),
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      if (attributeText
                                                          .isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                            top: 4,
                                                          ),
                                                          child: Text(
                                                            attributeText,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              color: Colors
                                                                  .white54,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ),
                                                      const SizedBox(height: 6),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 4,
                                                        children: [
                                                          Text(
                                                            "₹$discountedPrice",
                                                            style:
                                                                const TextStyle(
                                                              color: Color(
                                                                0xFF00F5D4,
                                                              ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                          Text(
                                                            "₹$price",
                                                            style:
                                                                const TextStyle(
                                                              color: Colors
                                                                  .white38,
                                                              fontSize: 11,
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                              decorationColor:
                                                                  Colors
                                                                      .white38,
                                                            ),
                                                          ),
                                                          Text(
                                                            "Stock: $stock",
                                                            style:
                                                                const TextStyle(
                                                              color: Colors
                                                                  .white54,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (sku.isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          sku,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors
                                                                .white38,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ],
                                                      if (discount != "0" &&
                                                          discount != "0.0" &&
                                                          discount != "0.00" &&
                                                          discount !=
                                                              "null") ...[
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          "$discount% discount",
                                                          style:
                                                              const TextStyle(
                                                            color: Colors
                                                                .orangeAccent,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                Checkbox(
                                                  value: disabledByFullProduct
                                                      ? true
                                                      : variantSelected,
                                                  activeColor:
                                                      const Color(0xFF00A895),
                                                  checkColor: Colors.white,
                                                  side: const BorderSide(
                                                    color: Colors.white54,
                                                  ),
                                                  onChanged:
                                                      disabledByFullProduct
                                                          ? null
                                                          : (_) {
                                                              toggleVariant(
                                                                productId:
                                                                    productId,
                                                                variantId:
                                                                    variantId,
                                                              );
                                                            },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                      if (variants.length > 3)
                                        GestureDetector(
                                          onTap: () {
                                            modalSetState(() {
                                              expandedProductsInSheet[
                                                      productId] =
                                                  !isExpanded;
                                            });
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 11,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.05),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.08),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                isExpanded
                                                    ? "See less variants"
                                                    : "See $hiddenVariantCount more variant(s)",
                                                style: const TextStyle(
                                                  color: Color(0xFF00F5D4),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedProductIds = tempSelectedProducts;
                        selectedVariantIds = tempSelectedVariants;
                      });

                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A895),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Center(
                        child: Text(
                          "Done",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget imageFallback(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.white10,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white38,
      ),
    );
  }

  Widget offerList() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00F5D4),
          ),
        ),
      );
    }

    if (offers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: const Column(
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: Colors.white38,
              size: 44,
            ),
            SizedBox(height: 10),
            Text(
              "No offers added",
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offers.length,
      itemBuilder: (_, index) {
        final offer = offers[index];

        final categoryValue = offer["category"] ?? offer["category_id"];

        final String categoryName = offer["category_name"]?.toString() ??
            offer["category_title"]?.toString() ??
            getCategoryNameById(categoryValue);

        final String title = offer["title"]?.toString() ?? "Offer";
        final String buyQty = offer["buy_quantity"]?.toString() ?? "0";
        final String freeQty = offer["free_quantity"]?.toString() ?? "0";
        final bool active = offer["is_active"] == true;

        final dynamic offerProducts = offer["products"];
        final dynamic offerVariants = offer["variants"];

        int productCount = 0;
        int variantCount = 0;

        if (offerProducts is List) {
          productCount = offerProducts.length;
        }

        if (offerVariants is List) {
          variantCount = offerVariants.length;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12, top: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
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
                      color: const Color(0xFF00A895).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Color(0xFF00F5D4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
               GestureDetector(
  onTap: () => confirmToggleOfferStatus(offer),
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      color: active
          ? Colors.green.withOpacity(0.15)
          : Colors.redAccent.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: active
            ? Colors.green.withOpacity(0.35)
            : Colors.redAccent.withOpacity(0.35),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          active ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
          color: active ? Colors.greenAccent : Colors.redAccent,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          active ? "Active" : "Inactive",
          style: TextStyle(
            color: active ? Colors.greenAccent : Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  ),
),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                categoryName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "$productCount full product(s) • $variantCount selected variant(s)",
                style: const TextStyle(
                  color: Color(0xFF00F5D4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Buy $buyQty",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white54,
                      size: 18,
                    ),
                    Expanded(
                      child: Text(
                        "Get $freeQty Free",
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Color(0xFF00F5D4),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Start: ${offer["start_date"] == null ? "-" : offer["start_date"].toString().split("T")[0]}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "End: ${offer["end_date"] == null ? "-" : offer["end_date"].toString().split("T")[0]}",
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => fillEditForm(offer),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      final int? id = int.tryParse(offer["id"].toString());

                      if (id != null) {
                        deleteOffer(id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget input(
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    bool enabled = true,
    String? hint,
    Function(String)? onChanged,
  }) {
    return Container(
      height: maxLines == 1 ? 55 : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: enabled ? Colors.white.withOpacity(0.06) : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: TextStyle(color: enabled ? Colors.white : Colors.white54),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
        ),
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
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formatDate(date),
                style: TextStyle(
                  color: date == null ? Colors.white54 : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
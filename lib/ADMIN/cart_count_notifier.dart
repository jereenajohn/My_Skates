import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class CartCountNotifier {
  static final ValueNotifier<int> cartCount = ValueNotifier<int>(0);

  static Future<void> refreshCartCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse('$api/api/myskates/cart/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List items = decoded["data"]?["items"] ?? [];

        final int count = items.fold<int>(
          0,
          (sum, item) => sum + (((item["quantity"] ?? 0) as num).toInt()),
        );

        cartCount.value = count;
      }
    } catch (e) {
      debugPrint("Cart count refresh error: $e");
    }
  }

  static void clear() {
    cartCount.value = 0;
  }
}
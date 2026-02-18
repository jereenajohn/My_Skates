import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';


class CoachProfileProvider extends ChangeNotifier {
  bool loading = true;
  String name = "Coach";
  String role = "Coach";
  String? image;

Future<void> fetchProfile({int? coachId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final userId = prefs.getInt("id");

      if (token == null || userId == null) return;

      final res = await http.get(
        Uri.parse("$api/api/myskates/profile/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("${res.statusCode}");
      print("==============>>>>>${res.body}");
      if (res.statusCode != 200) return;

      final List data = jsonDecode(res.body);
      final user = data.firstWhere(
        (e) => e["id"] == userId,
        orElse: () => null,
      );

      if (user == null) return;

      name = [
        user["first_name"],
        user["last_name"]
      ].where((e) => e != null && e.toString().isNotEmpty).join(" ");

      role = user["user_type"] ?? "Coach";
      image = user["profile"];
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

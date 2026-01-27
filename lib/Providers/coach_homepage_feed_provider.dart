import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';

class HomeFeedProvider extends ChangeNotifier {
  bool loading = true;
  List feeds = [];

  Future<void> toggleLike(int feedId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final index = feeds.indexWhere((f) => f["id"] == feedId);
    if (index == -1) return;

    final bool currentlyLiked = feeds[index]["is_liked"] == true;

    // 🔁 Optimistic update
    feeds[index]["is_liked"] = !currentlyLiked;
    feeds[index]["likes_count"] =
        (feeds[index]["likes_count"] ?? 0) + (currentlyLiked ? -1 : 1);

    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse("$api/api/myskates/feeds/$feedId/like/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        // rollback
        feeds[index]["is_liked"] = currentlyLiked;
        feeds[index]["likes_count"] =
            (feeds[index]["likes_count"] ?? 0) + (currentlyLiked ? 1 : -1);
        notifyListeners();
      }
      
    } catch (_) {
      // rollback
      feeds[index]["is_liked"] = currentlyLiked;
      feeds[index]["likes_count"] =
          (feeds[index]["likes_count"] ?? 0) + (currentlyLiked ? 1 : -1);
      notifyListeners();
    }
  }

  Future<void> repostFeed({
    required BuildContext context,
    required int feedId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final res = await http.post(
        Uri.parse("$api/api/myskates/feeds/repost/$feedId/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print(res.statusCode);
      print(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Post reposted to your timeline"),
            backgroundColor: Color(0xFF2EE6A6),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showError(context);
      }
    } catch (_) {
      _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Failed to repost. Try again."),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> fetchHomeFeeds() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final res = await http.get(
      Uri.parse("$api/api/myskates/feeds/"),
      headers: {"Authorization": "Bearer $token"},
    );

    print("============${res.statusCode}");
    print("=============>>${res.body}");

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      feeds = decoded is List ? decoded : decoded["data"] ?? [];
    }

    loading = false;
    notifyListeners();
  }
}

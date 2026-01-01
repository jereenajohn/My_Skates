import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';

class CoachFeedProvider extends ChangeNotifier {
  bool loading = true;
  List feeds = [];

  Future<void> fetchFeeds() async {
    loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    final id = prefs.getInt("id");

    final res = await http.get(
      Uri.parse("$api/api/myskates/feeds/user/$id/"),
      headers: {"Authorization": "Bearer $token"},
    );
    print("Fetch Feeds Response: ${res.statusCode} - ${res.body}");
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      feeds = decoded is List ? decoded : decoded["data"] ?? [];

      print("============$feeds");
    }

    loading = false;
    notifyListeners();
  }

  // Future<void> fetchAllFeeds() async {
  //   loading = true;
  //   notifyListeners();

  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString("access");

  //   final res = await http.get(
  //     Uri.parse("$api/api/myskates/feeds/"),
  //     headers: {"Authorization": "Bearer $token"},
  //   );

  //   if (res.statusCode == 200) {
  //     final decoded = jsonDecode(res.body);

  //     // API returns LIST directly
  //     feeds = decoded is List ? decoded : [];
  //   }

  //   loading = false;
  //   notifyListeners();
  // }

  Future<void> toggleLike(int feedId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final index = feeds.indexWhere((f) => f["id"] == feedId);
    if (index == -1) return;

    final bool wasLiked = feeds[index]["is_liked"] ?? false;
    final int currentCount = feeds[index]["likes_count"] ?? 0;

    // 🔹 Optimistic UI update
    feeds[index]["is_liked"] = !wasLiked;
    feeds[index]["likes_count"] = wasLiked
        ? currentCount - 1
        : currentCount + 1;

    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse("$api/api/myskates/feeds/$feedId/like/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("Like API response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // 🔹 Trust backend response
        feeds[index]["is_liked"] = body["liked"] ?? false;
      } else {
        throw Exception("Like API failed");
      }
    } catch (e) {
      // 🔴 Proper rollback
      feeds[index]["is_liked"] = wasLiked;
      feeds[index]["likes_count"] = wasLiked ? currentCount : currentCount;
    }

    notifyListeners();
  }

  Future<void> postFeed(String text, List<File> images) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final req = http.MultipartRequest(
      "POST",
      Uri.parse("$api/api/myskates/feeds/"),
    );

    req.headers["Authorization"] = "Bearer $token";
    req.fields["description"] = text;

    for (final img in images) {
      req.files.add(await http.MultipartFile.fromPath("images", img.path));
    }

    await req.send();
    fetchFeeds();
  }

  Future<void> updateFeed(int id, String text, List<File> images) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    final req = http.MultipartRequest(
      "PUT",
      Uri.parse("$api/api/myskates/feeds/$id/"),
    );

    req.headers["Authorization"] = "Bearer $token";
    req.fields["description"] = text;

    for (final img in images) {
      req.files.add(await http.MultipartFile.fromPath("images", img.path));
    }

    await req.send();
    fetchFeeds();
  }

  Future<void> deleteFeed(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    await http.delete(
      Uri.parse("$api/api/myskates/feeds/update/$id/"),
      headers: {"Authorization": "Bearer $token"},
    );

    fetchFeeds();
  }


Future<void> toggleRepost(int feedId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");
  if (token == null) return;

  final index = feeds.indexWhere((f) => f["id"] == feedId);
  if (index == -1) return;

  final bool isReposted = feeds[index]["is_reposted"] == true;
  final int currentCount = feeds[index]["shares_count"] ?? 0;

  // 🔐 LOCK (prevents double tap)
  if (feeds[index]["_repost_loading"] == true) return;
  feeds[index]["_repost_loading"] = true;

  // 🔥 OPTIMISTIC UI
  feeds[index]["is_reposted"] = !isReposted;
  feeds[index]["shares_count"] = isReposted
      ? (currentCount > 0 ? currentCount - 1 : 0)
      : currentCount + 1;

  notifyListeners();

  try {
    final uri = Uri.parse("$api/api/myskates/feeds/repost/$feedId/");

    http.Response res;

    if (isReposted) {
      // 🗑️ REMOVE REPOST
      res = await http.delete(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );
      print("🗑️ DELETE REPOST RESPONSE:");
    } else {
      // 🔁 CREATE REPOST
      res = await http.post(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );
      print("🔁 POST REPOST RESPONSE:");
    }

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Repost failed");
    }
  } catch (e) {
    // 🔴 ROLLBACK
    feeds[index]["is_reposted"] = isReposted;
    feeds[index]["shares_count"] = currentCount;
    print("❌ REPOST ERROR: $e");
  } finally {
    feeds[index].remove("_repost_loading");
  }

  notifyListeners();
}

}

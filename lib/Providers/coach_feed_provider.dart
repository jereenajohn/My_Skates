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
    }

    loading = false;
    notifyListeners();
  }

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

    print("---- TOGGLE REPOST ----");
    print("Feed ID: $feedId");
    print("Token exists: ${token != null}");

    if (token == null) return;

    final index = feeds.indexWhere((f) => f["id"] == feedId);
    if (index == -1) {
      print("Feed not found in provider list");
      return;
    }

    final bool wasReposted = feeds[index]["is_reposted"] ?? false;
    final int currentCount = feeds[index]["reposts_count"] ?? 0;

    print("Was Reposted: $wasReposted");
    print("Current Repost Count: $currentCount");

    // 🔹 Optimistic UI update
    feeds[index]["is_reposted"] = !wasReposted;
    feeds[index]["reposts_count"] = wasReposted
        ? currentCount - 1
        : currentCount + 1;

    print("Optimistic is_reposted: ${feeds[index]["is_reposted"]}");
    print("Optimistic reposts_count: ${feeds[index]["reposts_count"]}");

    notifyListeners();

    try {
      final uri = Uri.parse("$api/api/myskates/feeds/repost/$feedId/");

      print("API URL: $uri");
      print("API METHOD: ${wasReposted ? "DELETE" : "POST"}");

      final response = wasReposted
          ? await http.delete(uri, headers: {"Authorization": "Bearer $token"})
          : await http.post(
              uri,
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json",
              },
            );

      print("API STATUS: ${response.statusCode}");
      print("API BODY: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Repost API failed");
      }

      print("Repost API success");
    } catch (e) {
      print("Repost API ERROR: $e");

      // 🔴 Rollback
      feeds[index]["is_reposted"] = wasReposted;
      feeds[index]["reposts_count"] = currentCount;

      print("Rollback is_reposted: ${feeds[index]["is_reposted"]}");
      print("Rollback reposts_count: ${feeds[index]["reposts_count"]}");

      notifyListeners();
    }

    print("---- END TOGGLE REPOST ----");
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';

class CoachFeedProvider extends ChangeNotifier {
  bool loading = true;

  /// USER-SPECIFIC FEEDS (is_liked, is_reposted)
  List _userFeeds = [];

  /// GLOBAL FEEDS (shares_count source of truth)
  List _allFeeds = [];

  /// 🔑 SINGLE READ-ONLY LIST FOR UI
  List get feeds {
    final Map<int, dynamic> allFeedMap = {
      for (final f in _allFeeds)
        if (f["id"] != null) f["id"]: f,
    };

    return _userFeeds.map((f) {
      final all = allFeedMap[f["id"]];
      return {
        ...f,
        "shares_count": all?["shares_count"] ?? f["shares_count"] ?? 0,
      };
    }).toList();
  }

  /* -----------------------------------------------------------
   * FETCH FEEDS (MERGED)
   * --------------------------------------------------------- */
  Future<void> fetchFeeds() async {
    loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final id = prefs.getInt("id");
      if (token == null || id == null) return;

      final responses = await Future.wait([
        http.get(
          Uri.parse("$api/api/myskates/feeds/user/$id/"),
          headers: {"Authorization": "Bearer $token"},
        ),
        http.get(
          Uri.parse("$api/api/myskates/feeds/"),
          headers: {"Authorization": "Bearer $token"},
        ),
      ]);

      // USER FEEDS
      if (responses[0].statusCode == 200) {
        final decoded = jsonDecode(responses[0].body);
        _userFeeds = decoded is List ? decoded : decoded["data"] ?? [];
      }

      // ALL FEEDS (COUNTS)
      if (responses[1].statusCode == 200) {
        final decoded = jsonDecode(responses[1].body);
        _allFeeds = decoded is List ? decoded : [];
      }
    } catch (e) {
      print("❌ fetchFeeds ERROR: $e");
    }

    loading = false;
    notifyListeners();
  }

  /* -----------------------------------------------------------
   * LIKE
   * --------------------------------------------------------- */
  Future<void> toggleLike(int feedId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final index = _userFeeds.indexWhere((f) => f["id"] == feedId);
    if (index == -1) return;

    final bool wasLiked = _userFeeds[index]["is_liked"] == true;
    final int currentCount = _userFeeds[index]["likes_count"] ?? 0;

    // Optimistic
    _userFeeds[index]["is_liked"] = !wasLiked;
    _userFeeds[index]["likes_count"] = wasLiked
        ? currentCount - 1
        : currentCount + 1;

    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse("$api/api/myskates/feeds/$feedId/like/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode != 200) throw Exception();
    } catch (_) {
      _userFeeds[index]["is_liked"] = wasLiked;
      _userFeeds[index]["likes_count"] = currentCount;
    }

    notifyListeners();
  }

  /* -----------------------------------------------------------
   * REPOST (NO COUNT MATH)
   * --------------------------------------------------------- */
  Future<void> toggleRepost(int feedId) async {
    print("🔁 toggleRepost called for feedId: $feedId");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) {
      print("❌ No token found");
      return;
    }

    final index = _userFeeds.indexWhere((f) => f["id"] == feedId);
    if (index == -1) {
      print("❌ Feed not found in _userFeeds");
      return;
    }

    if (_userFeeds[index]["_repost_loading"] == true) {
      print("⏳ Repost already in progress for feedId: $feedId");
      return;
    }

    _userFeeds[index]["_repost_loading"] = true;

    final bool isReposted = _userFeeds[index]["is_reposted"] == true;

    print("📌 Current repost state: $isReposted");
    print(
      "📊 Current shares_count (before API): ${_userFeeds[index]["shares_count"]}",
    );

    // 🔹 toggle icon ONLY (no count math)
    _userFeeds[index]["is_reposted"] = !isReposted;
    notifyListeners();

    try {
      final uri = Uri.parse("$api/api/myskates/feeds/repost/$feedId/");
      print("🌐 API URL: $uri");
      print(
        "➡️ API METHOD: ${isReposted ? "DELETE (remove repost)" : "POST (add repost)"}",
      );

      final res = isReposted
          ? await http.delete(uri, headers: {"Authorization": "Bearer $token"})
          : await http.post(uri, headers: {"Authorization": "Bearer $token"});

      print("✅ API STATUS: ${res.statusCode}");
      print("📦 API BODY: ${res.body}");

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("Repost failed");
      }

      print("🔄 Fetching feeds again for authoritative count...");
      await fetchFeeds();

      // after refresh
      final refreshedIndex = _userFeeds.indexWhere((f) => f["id"] == feedId);
      if (refreshedIndex != -1) {
        print(
          "📊 Updated shares_count (after fetch): ${_userFeeds[refreshedIndex]["shares_count"]}",
        );
      }
    } catch (e) {
      _userFeeds[index]["is_reposted"] = isReposted;
      print("❌ REPOST ERROR: $e");
    } finally {
      _userFeeds[index].remove("_repost_loading");
      print("✅ Repost flow completed for feedId: $feedId");
    }

    notifyListeners();
  }

  /* -----------------------------------------------------------
   * CREATE / UPDATE / DELETE FEED
   * --------------------------------------------------------- */
  Future<void> postFeed(String text, List<File> images) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

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
    await fetchFeeds();
  }

  Future<void> updateFeed(int id, String text, List<File> images) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

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
    await fetchFeeds();
  }

  Future<void> deleteFeed(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    await http.delete(
      Uri.parse("$api/api/myskates/feeds/update/$id/"),
      headers: {"Authorization": "Bearer $token"},
    );

    await fetchFeeds();
  }
}

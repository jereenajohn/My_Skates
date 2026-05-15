import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';

class UserFeedProvider extends ChangeNotifier {
  bool loading = true;

  /// USER-SPECIFIC FEEDS (is_liked, is_reposted)
  List _userFeeds = [];

  /// GLOBAL FEEDS (shares_count source of truth)
  List _allFeeds = [];

  /// REPOST FEEDS (SEPARATE TIMELINE ITEMS)
  List _repostFeeds = [];

  /// 🔑 SINGLE READ-ONLY LIST FOR UI
  List get feeds {
    final List combined = [..._repostFeeds, ..._userFeeds];

    combined.sort((a, b) {
      final aTime = DateTime.parse(a["created_at"]);
      final bTime = DateTime.parse(b["created_at"]);
      return bTime.compareTo(aTime); // newest first
    });

    return combined;
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
        http.get(
          Uri.parse("$api/api/myskates/feeds/reposts/user/$id/"),
          headers: {"Authorization": "Bearer $token"},
        ),
      ]);

      // USER FEEDS
      if (responses[0].statusCode == 200) {
        final decoded = jsonDecode(responses[0].body);
        _userFeeds = decoded is List ? decoded : decoded["data"] ?? [];
      }

      // GLOBAL FEEDS (COUNTS)
      if (responses[1].statusCode == 200) {
        final decoded = jsonDecode(responses[1].body);
        _allFeeds = decoded is List ? decoded : [];
      }

      // ✅ REPOST FEEDS
      if (responses[2].statusCode == 200) {
        final decoded = jsonDecode(responses[2].body);
        final List data = decoded["data"] ?? [];

        _repostFeeds = data.map((item) {
          final originalFeed = _userFeeds.firstWhere(
            (f) => f["id"] == item["feed_id"],
            orElse: () => {},
          );

          return {
            "id": "repost_${item["id"]}",
            "repost_id": item["id"],
            "text": item["text"],
            "created_at": item["created_at"],
            "reposted_by": item["reposted_by"],

            "feed": {
              "id": item["feed_id"],
              "description": item["feed_description"],
              "likes_count": item["likes_count"],
              "comments_count": item["comments_count"],
              "shares_count": item["reposts_count"],
              "is_liked": false,
              "is_reposted": true,

              // ✅ IMAGE RESTORED
              "feed_image": originalFeed["feed_image"] ?? [],
            },
          };
        }).toList();

        print("✅ Fetched ${_repostFeeds.length} repost feeds");
        print("📦 Repost Feeds Data: $_repostFeeds");
        print("📦 User Feeds Data: $_userFeeds");
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

    bool? wasLiked;
    int? originalCount;

    // 🔑 Detect state from SOURCE lists
    for (final f in _userFeeds) {
      if (f["id"] == feedId) {
        wasLiked = f["is_liked"] == true;
        originalCount = f["likes_count"] ?? 0;
        break;
      }
    }

    // If not in user feeds, try repost feeds
    if (wasLiked == null) {
      for (final r in _repostFeeds) {
        if (r["feed"]?["id"] == feedId) {
          wasLiked = r["feed"]["is_liked"] == true;
          originalCount = r["feed"]["likes_count"] ?? 0;
          break;
        }
      }
    }

    if (wasLiked == null || originalCount == null) return;

    final bool newLiked = !wasLiked;
    final int delta = newLiked ? 1 : -1;

    // 🚀 OPTIMISTIC UPDATE — USER FEEDS
    for (final f in _userFeeds) {
      if (f["id"] == feedId) {
        f["is_liked"] = newLiked;
        f["likes_count"] = (f["likes_count"] ?? 0) + delta;
      }
    }

    // 🚀 OPTIMISTIC UPDATE — REPOST FEEDS (NESTED FEED)
    for (final r in _repostFeeds) {
      if (r["feed"]?["id"] == feedId) {
        r["feed"]["is_liked"] = newLiked;
        r["feed"]["likes_count"] = (r["feed"]["likes_count"] ?? 0) + delta;
      }
    }

    notifyListeners(); // ✅ UI updates instantly everywhere

    try {
      final res = await http.post(
        Uri.parse("$api/api/myskates/feeds/$feedId/like/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode != 200) throw Exception();
    } catch (_) {
      // 🔙 ROLLBACK
      for (final f in _userFeeds) {
        if (f["id"] == feedId) {
          f["is_liked"] = wasLiked;
          f["likes_count"] = originalCount;
        }
      }

      for (final r in _repostFeeds) {
        if (r["feed"]?["id"] == feedId) {
          r["feed"]["is_liked"] = wasLiked;
          r["feed"]["likes_count"] = originalCount;
        }
      }

      notifyListeners();
    }
  }

  /* -----------------------------------------------------------
   * REPOST (NO COUNT MATHHHH)
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

  Future<List<Map<String, dynamic>>> fetchUserReposts(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return [];

    try {
      final res = await http.get(
        Uri.parse("$api/api/myskates/feeds/reposts/user/$userId/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode != 200) {
        print("❌ Reposts fetch failed: ${res.body}");
        return [];
      }

      final decoded = jsonDecode(res.body);
      final List data = decoded["data"] ?? [];

      return data.map<Map<String, dynamic>>((item) {
        final Map<String, dynamic> repostedBy = Map<String, dynamic>.from(
          item["reposted_by"] ?? {},
        );

        final Map<String, dynamic> originalFeed = Map<String, dynamic>.from(
          item["feed"] ?? {},
        );

        return {
          "id": "repost_${item["id"]}", // unique UI-safe ID
          "is_repost": true,
          "repost_id": item["id"],
          "created_at": item["created_at"],
          "reposted_by": repostedBy,

          // ✅ FIXED
          "repost_of": originalFeed,
        };
      }).toList();
    } catch (e) {
      print("❌ fetchUserReposts ERROR: $e");
      return [];
    }
  }

  // Future<void> repostWithText({
  //   required int feedId,
  //   String? text,
  // }) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString("access");
  //   if (token == null) return;

  //   // 1️⃣ Create repost
  //   final res = await http.post(
  //     Uri.parse("$api/api/myskates/feeds/repost/$feedId/"),
  //     headers: {"Authorization": "Bearer $token"},
  //   );

  //   if (res.statusCode != 201 && res.statusCode != 200) return;

  //   final decoded = jsonDecode(res.body);
  //   final int repostId = decoded["data"]["id"];

  //   if (text != null && text.isNotEmpty) {
  //     await http.patch(
  //       Uri.parse("$api/api/myskates/feeds/repost/$repostId/"),
  //       headers: {
  //         "Authorization": "Bearer $token",
  //         "Content-Type": "application/json",
  //       },
  //       body: jsonEncode({"text": text}),
  //     );

  //     print("✅ Repost text updated for repostId: $repostId");
  //     print("📦 Text: $text");

  //     print("📦 REPOST TEXT RESPONSE: ${res.body}");
  //   }

  //   await fetchFeeds();
  // }

  Future<void> repostWithText({required int feedId, String? text}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.post(
      Uri.parse("$api/api/myskates/feeds/repost/$feedId/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        if (text != null && text.trim().isNotEmpty) "text": text.trim(),
      }),
    );

    print("🔁 REPOST POST STATUS: ${res.statusCode}");
    print("📦 REPOST POST BODY: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) return;

    await fetchFeeds();
  }

  Future<void> removeRepost({
    required int feedId,
    required int repostId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.delete(
      Uri.parse("$api/api/myskates/feeds/repost/$repostId/"),
      headers: {"Authorization": "Bearer $token"},
    );

    print("🗑️ REMOVE REPOST STATUS: ${res.statusCode}");
    print("📦 REMOVE REPOST BODY: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 204) return;

    await fetchFeeds();
  }

  Future<void> updateRepostText({
    required int repostId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    if (token == null) return;

    final res = await http.patch(
      Uri.parse("$api/api/myskates/feeds/repost/text/$repostId/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"text": text.trim()}),
    );

    print("✏️ UPDATE REPOST TEXT STATUS: ${res.statusCode}");
    print("📦 UPDATE REPOST TEXT BODY: ${res.body}");

    if (res.statusCode != 200) return;

    await fetchFeeds(); // authoritative refresh
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

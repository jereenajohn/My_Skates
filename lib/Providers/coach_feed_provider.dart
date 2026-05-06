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
  // Future<void> fetchFeeds() async {
  //   loading = true;
  //   notifyListeners();

  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString("access");
  //     final id = prefs.getInt("id");
  //     if (token == null || id == null) return;

  //     final responses = await Future.wait([
  //       http.get(
  //         Uri.parse("$api/api/myskates/feeds/user/$id/"),
  //         headers: {"Authorization": "Bearer $token"},
  //       ),
  //       http.get(
  //         Uri.parse("$api/api/myskates/feeds/"),
  //         headers: {"Authorization": "Bearer $token"},
  //       ),
  //       http.get(
  //         Uri.parse("$api/api/myskates/feeds/reposts/user/$id/"),
  //         headers: {"Authorization": "Bearer $token"},
  //       ),
  //     ]);

  //     // USER FEEDS
  //     if (responses[0].statusCode == 200) {
  //       final decoded = jsonDecode(responses[0].body);
  //       _userFeeds = decoded is List ? decoded : decoded["data"] ?? [];
  //     }

  //     // GLOBAL FEEDS (COUNTS)
  //     if (responses[1].statusCode == 200) {
  //       final decoded = jsonDecode(responses[1].body);
  //       _allFeeds = decoded is List ? decoded : [];
  //     }

  //     // ✅ REPOST FEEDS
  //     if (responses[2].statusCode == 200) {
  //       final decoded = jsonDecode(responses[2].body);
  //       final List data = decoded["data"] ?? [];

  //       _repostFeeds = data.map((item) {
  //         final originalFeed = _userFeeds.firstWhere(
  //           (f) => f["id"] == item["feed_id"],
  //           orElse: () => {},
  //         );

  //         return {
  //           "id": "repost_${item["id"]}",
  //           "repost_id": item["id"],
  //           "text": item["text"],
  //           "created_at": item["created_at"],
  //           "reposted_by": item["reposted_by"],

  //           "feed": {
  //             "id": item["feed_id"],
  //             "description": item["feed_description"],
  //             "likes_count": item["likes_count"],
  //             "comments_count": item["comments_count"],
  //             "shares_count": item["reposts_count"],
  //             "is_liked": false,
  //             "is_reposted": true,

  //             // ✅ IMAGE RESTORED
  //             // "feed_image": originalFeed["feed_image"] ?? [],
  //             "feed_image":
  //                 (item["feed"] is Map &&
  //                     item["feed"]["feed_image"] is List &&
  //                     item["feed"]["feed_image"].isNotEmpty)
  //                 ? item["feed"]["feed_image"]
  //                 : (originalFeed["feed_image"] ?? []),
  //             "user_name":
  //                 originalFeed["user_name"] ??
  //                 item["feed"]?["user_name"] ??
  //                 "MySkates User",

  //             "profile":
  //                 originalFeed["profile"] ?? item["feed"]?["profile"] ?? "",

  //             "user": originalFeed["user"] ?? item["feed"]?["user"],
  //           },
  //         };
  //       }).toList();

  //       print("✅ Fetched ${_repostFeeds.length} repost feeds");
  //       print("📦 Repost Feeds Data: $_repostFeeds");
  //       print("📦 User Feeds Data: $_userFeeds");
  //     }
  //   } catch (e) {
  //     print("❌ fetchFeeds ERROR: $e");
  //   }

  //   loading = false;
  //   notifyListeners();
  // }

  Future<void> fetchFeeds() async {
    loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");
      final id = prefs.getInt("id") ?? prefs.getInt("user_id");

      if (token == null || id == null) {
        _userFeeds = [];
        _allFeeds = [];
        _repostFeeds = [];
        loading = false;
        notifyListeners();
        return;
      }

      final responses = await Future.wait([
        // My own feed posts
        http.get(
          Uri.parse("$api/api/myskates/feeds/user/$id/"),
          headers: {"Authorization": "Bearer $token"},
        ),

        // All feed posts - needed to get original repost image
        http.get(
          Uri.parse("$api/api/myskates/feeds/"),
          headers: {"Authorization": "Bearer $token"},
        ),

        // My reposted feed posts
        http.get(
          Uri.parse("$api/api/myskates/feeds/reposts/user/$id/"),
          headers: {"Authorization": "Bearer $token"},
        ),
      ]);

      print("👤 USER FEEDS STATUS: ${responses[0].statusCode}");
      print("👤 USER FEEDS BODY: ${responses[0].body}");

      print("🌍 ALL FEEDS STATUS: ${responses[1].statusCode}");
      print("🌍 ALL FEEDS BODY: ${responses[1].body}");

      print("🔁 REPOST FEEDS STATUS: ${responses[2].statusCode}");
      print("🔁 REPOST FEEDS BODY: ${responses[2].body}");

      // ---------------------------------------------------------
      // USER FEEDS
      // ---------------------------------------------------------
      if (responses[0].statusCode == 200) {
        final decoded = jsonDecode(responses[0].body);

        final List data = decoded is List
            ? decoded
            : decoded["data"] ?? decoded["results"] ?? [];

        _userFeeds = data
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      } else {
        _userFeeds = [];
      }

      // ---------------------------------------------------------
      // ALL FEEDS
      // ---------------------------------------------------------
      if (responses[1].statusCode == 200) {
        final decoded = jsonDecode(responses[1].body);

        final List data = decoded is List
            ? decoded
            : decoded["data"] ?? decoded["results"] ?? [];

        _allFeeds = data
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      } else {
        _allFeeds = [];
      }

      // ---------------------------------------------------------
      // REPOST FEEDS
      // ---------------------------------------------------------
      if (responses[2].statusCode == 200) {
        final decoded = jsonDecode(responses[2].body);

        final List data = decoded is List
            ? decoded
            : decoded["data"] ?? decoded["results"] ?? [];

        _repostFeeds = data.map<Map<String, dynamic>>((item) {
          final Map<String, dynamic> repostItem = Map<String, dynamic>.from(
            item,
          );

          final Map<String, dynamic> repostFeedObj = repostItem["feed"] is Map
              ? Map<String, dynamic>.from(repostItem["feed"])
              : {};

          int feedId = 0;

          if (repostItem["feed_id"] != null) {
            feedId = int.tryParse(repostItem["feed_id"].toString()) ?? 0;
          }

          if (feedId == 0 && repostFeedObj["id"] != null) {
            feedId = int.tryParse(repostFeedObj["id"].toString()) ?? 0;
          }

          // ✅ IMPORTANT:
          // Find original post from ALL feeds, not user feeds.
          // Because reposted post may belong to another user.
          final Map<String, dynamic> originalFeed = _allFeeds.firstWhere(
            (f) => f["id"].toString() == feedId.toString(),
            orElse: () => <String, dynamic>{},
          );

          final List repostImages = repostFeedObj["feed_image"] is List
              ? repostFeedObj["feed_image"]
              : [];

          final List originalImages = originalFeed["feed_image"] is List
              ? originalFeed["feed_image"]
              : [];

          print("🔁 REPOST ID: ${repostItem["id"]}");
          print("🔁 ORIGINAL FEED ID: $feedId");
          print("🔍 ORIGINAL FEED FOUND: $originalFeed");
          print("🖼 REPOST API IMAGES: $repostImages");
          print("🖼 ORIGINAL FEED IMAGES: $originalImages");

          return {
            "id": "repost_${repostItem["id"]}",
            "is_repost": true,
            "repost_id": repostItem["id"],
            "text": repostItem["text"],
            "created_at": repostItem["created_at"],
            "reposted_by": repostItem["reposted_by"],

            "feed": {
              "id": feedId,

              "description":
                  repostFeedObj["description"] ??
                  repostItem["feed_description"] ??
                  originalFeed["description"] ??
                  "",

              "likes_count":
                  repostFeedObj["likes_count"] ??
                  repostItem["likes_count"] ??
                  originalFeed["likes_count"] ??
                  0,

              "comments_count":
                  repostFeedObj["comments_count"] ??
                  repostItem["comments_count"] ??
                  originalFeed["comments_count"] ??
                  0,

              "shares_count":
                  repostFeedObj["shares_count"] ??
                  repostItem["reposts_count"] ??
                  originalFeed["shares_count"] ??
                  0,

              "is_liked":
                  repostFeedObj["is_liked"] ??
                  originalFeed["is_liked"] ??
                  false,

              "is_reposted": true,

              // ✅ MAIN IMAGE FIX
              "feed_image": repostImages.isNotEmpty
                  ? repostImages
                  : originalImages,

              // ✅ Original post owner details
              "user_name":
                  originalFeed["user_name"] ??
                  repostFeedObj["user_name"] ??
                  "MySkates User",

              "profile":
                  originalFeed["profile"] ?? repostFeedObj["profile"] ?? "",

              "user": originalFeed["user"] ?? repostFeedObj["user"],

              "created_at":
                  originalFeed["created_at"] ??
                  repostFeedObj["created_at"] ??
                  repostItem["created_at"],
            },
          };
        }).toList();
      } else {
        _repostFeeds = [];
      }

      print("✅ FINAL USER FEEDS COUNT: ${_userFeeds.length}");
      print("✅ FINAL ALL FEEDS COUNT: ${_allFeeds.length}");
      print("✅ FINAL REPOST FEEDS COUNT: ${_repostFeeds.length}");
      print("📦 FINAL REPOST FEEDS DATA: $_repostFeeds");
    } catch (e) {
      print("❌ fetchFeeds ERROR: $e");

      _userFeeds = [];
      _allFeeds = [];
      _repostFeeds = [];
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
          "id": "repost_${item["id"]}", 
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

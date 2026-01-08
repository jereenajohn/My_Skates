import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';

class FeedCommentsProvider extends ChangeNotifier {
  final int feedId;

  FeedCommentsProvider(this.feedId) {
    _init();
  }

  /* ───────────────────────── STATE ───────────────────────── */

  bool loading = true;
  bool posting = false;

  int? myUserId; // ✅ THIS WAS MISSING / NOT COMPILED
  List<dynamic> comments = [];

  /* ───────────────────────── INIT ───────────────────────── */

  Future<void> _init() async {
    await _loadUser();
    await fetchComments();
  }

  /* ───────────────────────── AUTH ───────────────────────── */

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    myUserId = prefs.getInt("id");
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  /* ───────────────────────── HELPERS ───────────────────────── */

  String getUserName(dynamic c) {
    final first = c["first_name"]?.toString().trim() ?? "";
    final last = c["last_name"]?.toString().trim() ?? "";
    if (first.isNotEmpty && last.isNotEmpty) return "$first $last";
    if (first.isNotEmpty) return first;
    if (last.isNotEmpty) return last;
    return "User";
  }

  /* ───────────────────────── FETCH ───────────────────────── */

  Future<void> fetchComments() async {
    try {
      loading = true;
      notifyListeners();

      final token = await _token();
      final res = await http.get(
        Uri.parse("$api/api/myskates/feeds/$feedId/comments/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        comments = decoded["data"] ?? [];
      }
    } catch (_) {
      // silent
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /* ───────────────────────── POST ───────────────────────── */

  Future<void> postComment(String text) async {
    if (text.trim().isEmpty || posting) return;

    posting = true;

    final optimistic = {
      "id": DateTime.now().millisecondsSinceEpoch,
      "user": myUserId, // ✅ REQUIRED
      "comment": text,
      "first_name": "You",
      "last_name": "",
      "profile_image": null,
      "created_at": DateTime.now().toIso8601String(),
    };

    comments.insert(0, optimistic);
    notifyListeners();

    try {
      final token = await _token();
      final res = await http.post(
        Uri.parse("$api/api/myskates/feeds/$feedId/comment/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"comment": text}),
      );

      if (res.statusCode == 201) {
        await fetchComments();
      } else {
        comments.removeWhere((c) => c["id"] == optimistic["id"]);
      }
    } catch (_) {
      comments.removeWhere((c) => c["id"] == optimistic["id"]);
    } finally {
      posting = false;
      notifyListeners();
    }
  }

  /* ───────────────────────── UPDATE ───────────────────────── */

  Future<void> updateComment({
    required int commentId,
    required String newText,
  }) async {
    if (newText.trim().isEmpty) return;

    final index = comments.indexWhere((c) => c["id"] == commentId);
    if (index == -1) return;

    final old = comments[index]["comment"];
    comments[index]["comment"] = newText;
    notifyListeners();

    try {
      final token = await _token();
      final res = await http.put(
        Uri.parse("$api/api/myskates/feeds/comments/$commentId/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"comment": newText}),
      );

      if (res.statusCode != 200) {
        comments[index]["comment"] = old;
        notifyListeners();
      }
    } catch (_) {
      comments[index]["comment"] = old;
      notifyListeners();
    }
  }

  /* ───────────────────────── DELETE ───────────────────────── */

  Future<void> deleteComment(int commentId) async {
    final index = comments.indexWhere((c) => c["id"] == commentId);
    if (index == -1) return;

    final removed = comments.removeAt(index);
    notifyListeners();

    try {
      final token = await _token();
      final res = await http.delete(
        Uri.parse("$api/api/myskates/feeds/comments/$commentId/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode != 200) {
        comments.insert(index, removed);
        notifyListeners();
      }
    } catch (_) {
      comments.insert(index, removed);
      notifyListeners();
    }
  }
}

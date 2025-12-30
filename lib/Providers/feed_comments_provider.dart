import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';

class FeedCommentsProvider extends ChangeNotifier {
  final int feedId;

  FeedCommentsProvider(this.feedId) {
    fetchComments();
  }

  bool loading = true;
  bool posting = false;
  List<dynamic> comments = [];

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  String getUserName(dynamic c) {
    final first = c["first_name"]?.toString().trim() ?? "";
    final last = c["last_name"]?.toString().trim() ?? "";

    if (first.isNotEmpty && last.isNotEmpty) return "$first $last";
    if (first.isNotEmpty) return first;
    if (last.isNotEmpty) return last;
    return "User";
  }

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
      // silent fail
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> postComment(String text) async {
    if (text.trim().isEmpty || posting) return;

    posting = true;

    final optimistic = {
      "id": DateTime.now().millisecondsSinceEpoch,
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
}

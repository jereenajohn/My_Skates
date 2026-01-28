import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:my_skates/api.dart';

class CoachClubRequests extends StatefulWidget {
  final int clubId;

  const CoachClubRequests({super.key, required this.clubId});

  @override
  State<CoachClubRequests> createState() => _CoachClubRequestsState();
}

class _CoachClubRequestsState extends State<CoachClubRequests> {
  bool isLoading = true;
  bool noData = false;

  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    fetchClubJoinRequests();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  Future<void> fetchClubJoinRequests() async {
    final token = await getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$api/api/myskates/club/${widget.clubId}/join/requests/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("JOIN REQUEST STATUS: ${response.statusCode}");
      debugPrint("JOIN REQUEST BODY: ${response.body}");

      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);

        setState(() {
          requests = decoded.map<Map<String, dynamic>>((e) {
            return {
              "id": e["id"],
              "userId": e["user"],
              "userName":
                  "${e["user_first_name"] ?? ""} ${e["user_last_name"] ?? ""}"
                      .trim(),
              "phone": e["user_phone"] ?? "",
              "status": e["status"],
              "createdAt": e["created_at"],
            };
          }).toList();

          noData = requests.isEmpty;
          isLoading = false;
        });
      } else {
        setState(() {
          noData = true;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("FETCH JOIN REQUEST ERROR: $e");
      setState(() {
        noData = true;
        isLoading = false;
      });
    }
  }

  String formatDate(String date) {
    final parsed = DateTime.parse(date).toLocal();
    return DateFormat("dd MMM yyyy, hh:mm a").format(parsed);
  }

  Future<void> approveOrRejectRequest({
    required int clubId,
    required int userId,
    required String status, // "approved" or "rejected"
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse("$api/api/myskates/club/join/approve/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "club_id": clubId,
          "user_id": userId,
          "status": status,
        }),
      );

      debugPrint("APPROVE/REJECT STATUS: ${response.statusCode}");
      debugPrint("APPROVE/REJECT BODY: ${response.body}");

      if (response.statusCode == 200) {
        //  REMOVE FROM LIST (optimistic + correct)
        setState(() {
          requests.removeWhere((r) => r["userId"] == userId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == "approved"
                  ? "Request approved successfully"
                  : "Request rejected successfully",
            ),
            backgroundColor: status == "approved"
                ? Colors.green
                : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("APPROVE/REJECT ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Club Join Requests"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : noData
          ? const Center(
              child: Text(
                "No join requests found",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return _buildRequestCard(req);
              },
            ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NAME + STATUS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req["userName"],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  req["status"].toString().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // PHONE
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: Colors.tealAccent),
              const SizedBox(width: 6),
              Text(req["phone"], style: const TextStyle(color: Colors.white70)),
            ],
          ),

          const SizedBox(height: 6),

          // DATE
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.tealAccent,
              ),
              const SizedBox(width: 6),
              Text(
                formatDate(req["createdAt"]),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ACTION BUTTONS (future ready)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  approveOrRejectRequest(
                    clubId: widget.clubId,
                    userId: req["userId"],
                    status: "rejected",
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                ),
                child: const Text(
                  "Reject",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  approveOrRejectRequest(
                    clubId: widget.clubId,
                    userId: req["userId"],
                    status: "approved",
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AFA5),
                ),
                child: const Text("Approve"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/club_detailed_view.dart';
import 'package:my_skates/COACH/coach_club_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class CoachClubsToApproveRequest extends StatefulWidget {
  const CoachClubsToApproveRequest({super.key});

  @override
  State<CoachClubsToApproveRequest> createState() =>
      _CoachClubsToApproveRequestState();
}

class _CoachClubsToApproveRequestState
    extends State<CoachClubsToApproveRequest> {
  List clubs = [];
  bool loading = true;
  bool noData = false;

  @override
  void initState() {
    super.initState();
    fetchClubs();
  }

  Future<void> fetchClubs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final response = await http.get(
        Uri.parse("$api/api/myskates/club/"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          clubs = decoded;
          loading = false;
          noData = clubs.isEmpty;
        });
      } else {
        setState(() {
          loading = false;
          noData = true;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        noData = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Clubs", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : noData
          ? const Center(
              child: Text(
                "No clubs found",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(14),
              child: GridView.builder(
                itemCount: clubs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  return ClubGridCard(club: clubs[index]);
                },
              ),
            ),
    );
  }
}

class ClubGridCard extends StatelessWidget {
  final Map club;

  const ClubGridCard({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    final String clubName = club["club_name"] ?? "Club";
    final String place = club["place"] ?? "";
    final String image = club["image"] ?? "";
    final String instagram = club["instagram"] ?? "";
    int id = club["id"] ?? 0;

    final String imageUrl = image.isNotEmpty ? "$api$image" : "";

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : const AssetImage("lib/assets/images.png") as ImageProvider,
          ),

          const SizedBox(height: 10),

          Text(
            clubName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            place,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AFA5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoachClubRequests(clubId: id),
                  ),
                );
              },
              child: const Text(
                "Requests",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),

          // if (instagram.isNotEmpty) ...[
          //   const SizedBox(height: 6),
          //   Text(
          //     "@$instagram",
          //     style: const TextStyle(
          //       color: Colors.tealAccent,
          //       fontSize: 11,
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }
}

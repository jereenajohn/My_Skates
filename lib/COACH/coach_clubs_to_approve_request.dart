import 'dart:convert';
import 'dart:ui';
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
  String userType = "";

  @override
  void initState() {
    super.initState();
    fetchUserType();
    fetchClubs();
  }

  Future<void> fetchUserType() async {
    final prefs = await SharedPreferences.getInstance();

    final active = prefs.getString("active") ?? "";
    final userTypeValue = prefs.getString("user_type") ?? "";
    final roleValue = prefs.getString("role") ?? "";

    final selectedType = active.isNotEmpty
        ? active
        : userTypeValue.isNotEmpty
        ? userTypeValue
        : roleValue;

    print("ACTIVE VALUE: $active");
    print("USER TYPE VALUE: $userTypeValue");
    print("ROLE VALUE: $roleValue");
    print("SELECTED USER TYPE: $selectedType");

    setState(() {
      userType = selectedType.trim().toLowerCase();
    });
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
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: userType.trim().toLowerCase() == "student"
                      ? 1.05
                      : 0.82,
                ),
                itemBuilder: (context, index) {
                  return ClubGridCard(club: clubs[index], userType: userType);
                },
              ),
            ),
    );
  }
}

class ClubGridCard extends StatelessWidget {
  final Map club;
  final String userType;

  const ClubGridCard({super.key, required this.club, this.userType = ""});

  @override
  Widget build(BuildContext context) {
    final String clubName = club["club_name"] ?? "Club";
    final String place = club["place"] ?? "";
    final String image = club["image"] ?? "";
    final String instagram = club["instagram"] ?? "";
    final int id = club["id"] ?? 0;

    final String imageUrl = image.isNotEmpty ? "$api$image" : "";

    final String currentUserType = userType.trim().toLowerCase();

    final bool canShowRequests =
        currentUserType.contains("coach") || currentUserType.contains("admin");

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClubView(clubid: club["id"]),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 36,
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : const AssetImage("lib/assets/images.png")
                            as ImageProvider,
                ),
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

              // const Spacer(),
              if (canShowRequests) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AFA5),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
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
        ),
      ),
    );
  }
}

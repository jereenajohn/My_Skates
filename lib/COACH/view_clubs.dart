import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class ViewClubs extends StatefulWidget {
  const ViewClubs({super.key});

  @override
  State<ViewClubs> createState() => _ViewClubsState();
}

class _ViewClubsState extends State<ViewClubs> {
  List clubs = [];
  bool isLoading = true;
  bool noData = false; // NEW FLAG FOR EMPTY DATA

  @override
  void initState() {
    super.initState();
    fetchClubs();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  Future<int?> getCoachId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt("id");
  }

  Future<void> fetchClubs() async {
    String? token = await getToken();
    int? coachId = await getCoachId();

    if (token == null || coachId == null) {
      print("TOKEN or COACH ID missing");
      return;
    }

    final url = Uri.parse("$api/api/myskates/club/coach/$coachId/");
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    print("CLUB API STATUS = ${response.statusCode}");
    print("CLUB API BODY = ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List && data.isNotEmpty) {
        setState(() {
          clubs = data;
          isLoading = false;
        });
      } else {
        setState(() {
          noData = true;
          isLoading = false;
        });
      }
    } else if (response.statusCode == 404) {
      // NO CLUBS FOUND
      setState(() {
        noData = true;
        isLoading = false;
      });
    } else {
      print("Error fetching clubs");
      setState(() {
        noData = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              )
            : noData
                ? buildEmptyState()
                : buildClubsGrid(),
      ),
    );
  }

  // ----------------------------------------------------------
  // PROFESSIONAL NO–DATA UI
  // ----------------------------------------------------------
  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ICON
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_off_rounded,
                color: Colors.tealAccent,
                size: 80,
              ),
            ),
            const SizedBox(height: 30),

            // MAIN TITLE
            const Text(
              "No Clubs Found",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // SUBTITLE
            const Text(
              "It seems you haven’t created or joined any clubs yet.\nStart growing your community today.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 30),

            // CREATE BUTTON
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: () {
                  // NAVIGATE TO CREATE CLUB PAGE
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D8CC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "Create a Club",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // CLUB GRID UI
  // ----------------------------------------------------------
  Widget buildClubsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Clubs",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: GridView.builder(
              itemCount: clubs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final club = clubs[index];

                return ClubCard(
                  name: club["club_name"] ?? "",
                  location:
                      "${club["place"] ?? ""}, ${club["district_name"] ?? ""}",
                  image: club["image"],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// CLUB CARD WIDGET
// --------------------------------------------------
class ClubCard extends StatelessWidget {
  final String name;
  final String location;
  final String? image;

  const ClubCard({
    super.key,
    required this.name,
    required this.location,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: image != null && image!.isNotEmpty
                ? Image.network(
                    "$api$image",
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    "lib/assets/placeholder.png",
                    height: 60,
                  ),
          ),

          const SizedBox(height: 12),

          // NAME
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          // LOCATION
          Text(
            location,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),

          const Spacer(),

          // FOLLOW BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D8CC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Follow",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

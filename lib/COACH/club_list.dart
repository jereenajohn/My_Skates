import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/club_detailed_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class ClubGridPage extends StatefulWidget {
  const ClubGridPage({super.key});

  @override
  State<ClubGridPage> createState() => _ClubGridPageState();
}

class _ClubGridPageState extends State<ClubGridPage> {
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
    final screen = MediaQuery.of(context).size;

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
          : RefreshIndicator(
              onRefresh: fetchClubs,
              color: Colors.tealAccent,
              backgroundColor: Colors.black,
              child: noData
                  ? ListView(
                      children: [
                        SizedBox(height: screen.height * 0.25),
                        const Center(
                          child: Text(
                            "No clubs found",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: EdgeInsets.all(screen.width * 0.035),
                      child: GridView.builder(
                        itemCount: clubs.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: screen.width * 0.035,
                          mainAxisSpacing: screen.height * 0.02,
                          childAspectRatio: 0.70, // stable ratio
                        ),
                        itemBuilder: (context, index) {
                          return ClubGridCard(club: clubs[index]);
                        },
                      ),
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
    final int id = club["id"] ?? 0;

    final String imageUrl = image.isNotEmpty ? "$api$image" : "";

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClubView(clubid: id)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            AspectRatio(
              aspectRatio: 1.2,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          "lib/assets/images.png",
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        "lib/assets/images.png",
                        fit: BoxFit.cover,
                      ),
              ),
            ),

            /// CONTENT (SAFE)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NAME (flexible)
                    Flexible(
                      child: Text(
                        clubName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// LOCATION
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 13,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    /// BUTTON (fixed but safe)
                    SizedBox(
                      height: 28,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00E0D3),
                              Color(0xFF00AFA5),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "View Club",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
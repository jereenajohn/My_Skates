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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Clubs",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
    ? const Center(
        child: CircularProgressIndicator(color: Colors.tealAccent),
      )
    : RefreshIndicator(
        color: Colors.tealAccent,
        backgroundColor: Colors.black,
        onRefresh: fetchClubs,
        child: noData
            ? ListView(
                
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      "No clubs found",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
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
          MaterialPageRoute(
            builder: (_) => ClubView(clubid: id),
          ),
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
          children: [
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        "lib/assets/images.png",
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),

            /// CONTENT
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// CLUB NAME
                    Text(
                      clubName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// LOCATION
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
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
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    /// BUTTON
                    Container(
                      height: 34,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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



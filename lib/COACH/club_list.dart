import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/COACH/club_detailed_view.dart';
import 'package:my_skates/COACH/coach_clubs_to_approve_request.dart';
import 'package:my_skates/bottomnavigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class ClubGridPage extends StatefulWidget {
  const ClubGridPage({super.key});

  @override
  State<ClubGridPage> createState() => _ClubGridPageState();
}

class _ClubGridPageState extends State<ClubGridPage> {
  List clubs = [];
  List filteredClubs = [];
  final TextEditingController searchController = TextEditingController();
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
          filteredClubs = decoded;
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

  void filterClubs(String query) {
    final results = clubs.where((club) {
      final clubName = (club["club_name"] ?? "").toString().toLowerCase();

      return clubName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredClubs = results;
    });
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
              child: Column(
                children: [
                  /// 🔍 SEARCH BAR
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: searchController,
                      onChanged: filterClubs,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search clubs",
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white54,
                        ),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(35),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: noData
                        ? ListView(
                            children: const [
                              SizedBox(height: 150),
                              Center(
                                child: Text(
                                  "No clubs found",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: GridView.builder(
                              itemCount: filteredClubs.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.70,
                                  ),
                              itemBuilder: (context, index) {
                                return ClubGridCard(club: filteredClubs[index]);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

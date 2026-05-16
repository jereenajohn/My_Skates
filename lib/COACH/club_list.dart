import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  String userType = "";
  List clubs = [];
  List filteredClubs = [];

  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  bool noData = false;

  @override
  void initState() {
    super.initState();
    fetchUserType();
    fetchClubs();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

    debugPrint("ACTIVE VALUE: $active");
    debugPrint("USER TYPE VALUE: $userTypeValue");
    debugPrint("ROLE VALUE: $roleValue");
    debugPrint("SELECTED USER TYPE: $selectedType");

    if (!mounted) return;

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
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("CLUB STATUS: ${response.statusCode}");
      debugPrint("CLUB BODY: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          setState(() {
            clubs = decoded;
            filteredClubs = decoded;
            loading = false;
            noData = decoded.isEmpty;
          });
        } else {
          setState(() {
            clubs = [];
            filteredClubs = [];
            loading = false;
            noData = true;
          });
        }
      } else {
        setState(() {
          loading = false;
          noData = true;
        });
      }
    } catch (e) {
      debugPrint("FETCH CLUBS ERROR: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
        noData = true;
      });
    }
  }

  void filterClubs(String query) {
    final searchText = query.trim().toLowerCase();

    final results = clubs.where((club) {
      final clubName = (club["club_name"] ?? "").toString().toLowerCase();
      return clubName.contains(searchText);
    }).toList();

    setState(() {
      filteredClubs = results;
      noData = filteredClubs.isEmpty;
    });
  }

  Future<void> refreshPage() async {
    await fetchClubs();

    if (searchController.text.trim().isNotEmpty) {
      filterClubs(searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserType = userType.trim().toLowerCase();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Clubs",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF001A18),
              Color(0xFF002F2B),
              Color(0xFF000C0B),
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.tealAccent,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: refreshPage,
                  color: Colors.tealAccent,
                  backgroundColor: Colors.black,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: TextField(
                          controller: searchController,
                          onChanged: filterClubs,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.tealAccent,
                          decoration: InputDecoration(
                            hintText: "Search clubs",
                            hintStyle: const TextStyle(color: Colors.white54),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white54,
                            ),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      searchController.clear();
                                      filterClubs("");
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white54,
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.4),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(35),
                              borderSide: const BorderSide(
                                color: Colors.white12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(35),
                              borderSide: const BorderSide(
                                color: Colors.white12,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(35),
                              borderSide: const BorderSide(
                                color: Colors.tealAccent,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: filteredClubs.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 150),
                                  Center(
                                    child: Text(
                                      "No clubs found",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: GridView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 24,
                                  ),
                                  itemCount: filteredClubs.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,

                                    /*
                                      IMPORTANT:
                                      Higher childAspectRatio = shorter card.
                                      Your old student ratio 1.05 made the card height too small.
                                      That caused:
                                      RenderFlex overflowed by 15 pixels on the bottom.
                                    */
                                    childAspectRatio:
                                        currentUserType == "student"
                                            ? 0.82
                                            : 0.72,
                                  ),
                                  itemBuilder: (context, index) {
                                    return ClubGridCard(
                                      club: filteredClubs[index],
                                      userType: userType,
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
        ),
      ),

      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}
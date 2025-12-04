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
  bool noData = false;

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

    if (token == null || coachId == null) return;

    final response = await http.get(
      Uri.parse("$api/api/myskates/club/coach/$coachId/"),
      headers: {"Authorization": "Bearer $token"},
    );

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
    } else {
      setState(() {
        noData = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  backgroundColor: Colors.black,
  elevation: 0,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
    onPressed: () {
      Navigator.pop(context);
    },
  ),
 
),

      backgroundColor: Colors.black,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : noData
            ? buildEmptyPage()
            : buildClubPage(),
      ),

      bottomNavigationBar: Container(
  decoration: const BoxDecoration(
    color: Colors.black,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(30),
      topRight: Radius.circular(30),
    ),
  ),
  child: ClipRRect(
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(30),
      topRight: Radius.circular(30),
    ),
    child: BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: const Color(0xFF00AFA5),
      unselectedItemColor: Colors.white70,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,

      // CHANGE THIS LATER if dynamic index is needed
      currentIndex: 3, // Clubs tab

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_rounded),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: '',
        ),
      ],
    ),
  ),
),

    );
  }

  // ---------------------------------------------------
  // TOP BANNER + CLUB LIST (MATCHES YOUR DESIGN)
  // ---------------------------------------------------
  Widget buildClubPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Handshake + Title
            Center(
              child: Column(
                children: const [
                  Text("🤝", style: TextStyle(fontSize: 35)),
                  SizedBox(height: 10),
                  Text(
                    "Create Your own",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "Myskate Club",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Create Club Button
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.tealAccent, width: 2),
                ),
                child: const Text(
                  "Create a Club",
                  style: TextStyle(color: Colors.tealAccent, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Section Title
            const Text(
              "Skating Clubs You May Like",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 18),

            // Grid View
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: clubs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 18,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final club = clubs[index];

                return ClubCard(
                  name: club["club_name"],
                  location:
                      "${club["place"] ?? ""}, ${club["district_name"] ?? ""}",
                  image: club["image"],
                );
              },
            ),

            

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // EMPTY PAGE UI
  Widget buildEmptyPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.group_off, color: Colors.white54, size: 80),
          SizedBox(height: 20),
          Text(
            "No clubs found",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

//
// ----------------------------------------------------------
//       UPDATED CLUB CARD — EXACT UI LIKE YOUR DESIGN
// ----------------------------------------------------------
//

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
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- IMAGE + NAME + PLACE -----------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: image != null && image!.isNotEmpty
                    ? Image.network(
                        "$api$image",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        "lib/assets/placeholder.png",
                        width: 50,
                        height: 50,
                      ),
              ),

              const SizedBox(width: 10),

              // TEXT CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CLUB NAME
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // LOCATION
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // STUDENTS TEXT
                    const Text(
                      "500+ students",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // ---------------- FOLLOW BUTTON -----------------
          Container(
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF00D8CC),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Text(
                "Follow",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

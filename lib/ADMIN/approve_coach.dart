import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class ApproveCoach extends StatefulWidget {
  const ApproveCoach({super.key});

  @override
  State<ApproveCoach> createState() => _ApproveCoachState();
}

class _ApproveCoachState extends State<ApproveCoach> {
  List<Map<String, dynamic>> coach = [];

  @override
  void initState() {
    super.initState();
    getcoach();
  }

  Future<void> getcoach() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    var response = await http.get(
      Uri.parse('$api/api/myskates/coaches/pending/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> parsed = jsonDecode(response.body);

      coach = parsed.map<Map<String, dynamic>>((c) {
        return {
          'id': c['id'],
          'full_name': "${c['first_name']} ${c['last_name']}",
          'location':"${c['district'] ?? ''}, ${c['state'] ?? ''}, ${c['country'] ?? ''}",
          'profile': c['profile'] != null ? '$api${c['profile']}' : "",
          'image': c['image'] != null ? '$api${c['image']}' : "",
        };
      }).toList();

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Approve Coaches"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: coach.length,
        itemBuilder: (context, index) {
          final c = coach[index];

          return Container(
  margin: const EdgeInsets.only(bottom: 15),
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  decoration: BoxDecoration(
    color: const Color.fromARGB(108, 35, 35, 35),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.grey.shade800),
  ),
  child: Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PROFILE PIC
          CircleAvatar(
            radius: 25,
            backgroundImage: c['profile'].isNotEmpty
                ? NetworkImage(c['profile'])
                : const AssetImage("lib/assets/img.jpg") as ImageProvider,
          ),
      
          const SizedBox(width: 12),
      
          // MIDDLE CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NAME
                Text(
                  c['full_name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      
                const SizedBox(height: 4),
      
                // NORMAL LOCATION LINE
                Text(
                  c['location'],
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
      
                const SizedBox(height: 4),
      
                // GREEN LOCATION LINE
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.teal, size: 18),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        c['location'],
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
      
                const SizedBox(height: 5),
      
                // BUTTON ROW
            
              ],
            ),
          ),
      
          const SizedBox(width: 10),
      
          // RIGHT-SIDE IMAGE (SMALLER LIKE YOUR FIRST SCREENSHOT)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: c['image'].isNotEmpty
                ? Image.network(
                    c['image'],
                    width: 60,      // FIXED EXACT SIZE
                    height: 60,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[900],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
        ],
        
      ),

         Row(
  children: [
    // IGNORE BUTTON
    Flexible(
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            "Ignore",
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ),
    ),

    const SizedBox(width: 8),

    // ACCEPT BUTTON
    Flexible(
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: Color(0xFF00CFC5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            "Accept",
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ),
    ),
  ],
)

    ],
  ),
);

        },
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:geocoding/geocoding.dart';

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

  Future<String> getAddressFromLatLng(String? lat, String? lng) async {
    if (lat == null || lng == null || lat.isEmpty || lng.isEmpty) {
      return "";
    }

    try {
      double latitude = double.parse(lat);
      double longitude = double.parse(lng);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark p = placemarks.first;

        return "${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.country ?? ''}";
      }
    } catch (e) {
      print("Reverse geocode error: $e");
    }

    return "";
  }

  Future<void> updatecoach(int id, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    print("$api/api/myskates/coach/approval/$id/");
    try {
      var response = await http.put(
        Uri.parse("$api/api/myskates/coach/approval/$id/"),
        headers: {"Authorization": "Bearer $token"},
        body: {"approval_status": status},
      );

      print("UPDATE status: ${response.statusCode}");
      print("UPDATE body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("State updated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {});
        getcoach();
      }
    } catch (e) {
      print(e);
    }
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

      coach = [];

      for (var c in parsed) {
        String finalLocation = await getAddressFromLatLng(
          c['latitude']?.toString(),
          c['longitude']?.toString(),
        );

        coach.add({
          'id': c['id'],
          'full_name': "${c['first_name']} ${c['last_name']}",
          'location': finalLocation,
          'profile': c['profile'] != null ? '$api${c['profile']}' : "",
          'image': c['image'] != null ? '$api${c['image']}' : "",
          'document': c['document'] != null ? '$api${c['document']}' : "",
        });
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: coach.length,
        itemBuilder: (context, index) {
          final c = coach[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(92, 35, 35, 35),
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
                      radius: 35,
                      backgroundImage: c['profile'].isNotEmpty
                          ? NetworkImage(c['profile'])
                          : const AssetImage("lib/assets/img.jpg")
                                as ImageProvider,
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
                              fontSize: 14,
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
                              const Icon(
                                Icons.location_on,
                                color: Colors.teal,
                                size: 18,
                              ),
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
                      child: c['document'].isNotEmpty
                          ? Image.network(
                              c['document'],
                              width: 60, // FIXED EXACT SIZE
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[900],
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    // IGNORE BUTTON
                    SizedBox(width: 25),
                    GestureDetector(
                      onTap: () {
                        updatecoach(c['id'], "disapproved");
                      },
                      child: Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width * 0.5 - 50,
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
                    GestureDetector(
                      onTap: () {
                        updatecoach(c['id'], "approved");
                      },
                      child: Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width * 0.5 - 50,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

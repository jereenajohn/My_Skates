import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:geocoding/geocoding.dart';

class ApprovedCoach extends StatefulWidget {
  const ApprovedCoach({super.key});

  @override
  State<ApprovedCoach> createState() => _ApprovedCoachState();
}

class _ApprovedCoachState extends State<ApprovedCoach> {
  List<Map<String, dynamic>> coach = [];
  bool isLoading = true;
  bool isRefreshing = false;
  
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

  Future<void> getcoach() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      var response = await http.get(
        Uri.parse('$api/api/myskates/coaches/approved/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> parsed = jsonDecode(response.body);
        
        // Process all coach data with addresses
        List<Map<String, dynamic>> tempCoach = [];
        
        for (var c in parsed) {
          String finalLocation = await getAddressFromLatLng(
            c['latitude']?.toString(),
            c['longitude']?.toString(),
          );

          tempCoach.add({
            'id': c['id'],
            'full_name': "${c['first_name']} ${c['last_name']}",
            'location': finalLocation,
            'profile': c['profile'] != null ? '$api${c['profile']}' : "",
            'image': c['image'] != null ? '$api${c['image']}' : "",
            'document': c['document'] != null ? '$api${c['document']}' : "",
          });
        }

        setState(() {
          coach = tempCoach;
          isLoading = false;
          isRefreshing = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    } catch (e) {
      print("Error fetching coaches: $e");
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => isRefreshing = true);
    await getcoach();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.tealAccent,
              backgroundColor: Colors.black,
              strokeWidth: 3.0,
              displacement: 40.0,
              child: coach.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.group_outlined,
                                color: Colors.white54,
                                size: 60,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No approved coaches found",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(10),
                      itemCount: coach.length,
                      itemBuilder: (context, index) {
                        final c = coach[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
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
                                        : const AssetImage(
                                                "lib/assets/img.jpg")
                                            as ImageProvider,
                                  ),

                                  const SizedBox(width: 12),

                                  // MIDDLE CONTENT
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // RIGHT-SIDE IMAGE
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: c['document'].isNotEmpty
                                        ? Image.network(
                                            c['document'],
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[900],
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                              ),
                                            ),
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
                              const SizedBox(height: 10),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
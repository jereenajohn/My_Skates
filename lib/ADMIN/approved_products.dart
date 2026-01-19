import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:geocoding/geocoding.dart';

class approvedProducts extends StatefulWidget {
  const approvedProducts({super.key});

  @override
  State<approvedProducts> createState() => _approvedProductsState();
}

class _approvedProductsState extends State<approvedProducts> {
  List<Map<String, dynamic>> coach = [];

  @override
  void initState() {
    super.initState();
    getproduct("approved");
  }
Future<String> getAddressFromLatLng(String? lat, String? lng) async {
  if (lat == null || lng == null || lat.isEmpty || lng.isEmpty) {
    return "";
  }

  try {
    double latitude = double.parse(lat);
    double longitude = double.parse(lng);

    List<Placemark> placemarks =
        await placemarkFromCoordinates(latitude, longitude);

    if (placemarks.isNotEmpty) {
      Placemark p = placemarks.first;

      return "${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.country ?? ''}";
    }
  } catch (e) {
    print("Reverse geocode error: $e");
  }

  return "";
}

 Future<void> getproduct(var status) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  final response = await http.get(
    Uri.parse('$api/api/myskates/products/status/view/$status/'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print("COACH STATUS: ${response.statusCode}");
  print("COACH BODY: ${response.body}");

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    // ✅ SAFETY CHECK
    final List<dynamic> parsed = decoded['data'] ?? [];

    coach = [];

    for (final c in parsed) {
      coach.add({
        'id': c['id'],
        'title': c['title'] ?? "",
        'image': c['image'] != null ? '$api${c['image']}' : "",
        'category_name': c['category_name'] ?? "",
        'price': c['base_price']?.toString() ?? "",
        'description': c['description'] ?? "",
        'user': c['user']?.toString() ?? "",
        'variants': c['variants'] ?? [], // keep for later use
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
            backgroundImage: c['image'].isNotEmpty
                ? NetworkImage(c['image'])
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
                  c['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      
                const SizedBox(height: 4),
      
                // NORMAL LOCATION LINE
                Text(
                  c['category_name'],
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
                     Text(
                  c['price'],
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                  ],
                ),
      
                const SizedBox(height: 5),
      
                // BUTTON ROW
            
              ],
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

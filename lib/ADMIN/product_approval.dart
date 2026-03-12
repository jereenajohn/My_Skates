import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart';

class Approveproduct extends StatefulWidget {
  const Approveproduct({super.key});

  @override
  State<Approveproduct> createState() => _ApproveproductState();
}

class _ApproveproductState extends State<Approveproduct> {
  List<Map<String, dynamic>> coach = [];
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    getproduct("pending");
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

  Future<void> updateproduct(int id, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    print("$api/api/myskates/products/approval/$id/");
    print("status: $status");
    try {
      var response = await http.patch(
        Uri.parse("$api/api/myskates/products/approval/$id/"),
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

        setState(() {});
        getproduct("pending");
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> getproduct(var status) async {
    try {
      setState(() {
        isLoading = true;
      });

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
            'variants': c['variants'] ?? [],
          });
        }
      }

      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => isRefreshing = true);
    await getproduct("pending");
  }

  Widget _buildGlassProductCard(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: c['image'].isNotEmpty
                          ? NetworkImage(c['image'])
                          : const AssetImage("lib/assets/img.jpg")
                                as ImageProvider,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

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
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const SizedBox(width: 25),
                    GestureDetector(
                      onTap: () {
                        updateproduct(c['id'], "disapproved");
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

                    GestureDetector(
                      onTap: () {
                        updateproduct(c['id'], "approved");
                      },
                      child: Container(
                        height: 30,
                        width: MediaQuery.of(context).size.width * 0.5 - 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00CFC5),
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
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFF1A2B2A),
              highlightColor: const Color(0xFF2F4F4D),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const SizedBox(width: 25),
                      Expanded(
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: isLoading
          ? _buildShimmerList()
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
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.white54,
                                size: 60,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No pending products",
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
                        return _buildGlassProductCard(c);
                      },
                    ),
            ),
    );
  }
}
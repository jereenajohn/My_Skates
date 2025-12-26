import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/add_product.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/update_product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

class UserProducts extends StatefulWidget {
  const UserProducts({super.key});

  @override
  State<UserProducts> createState() => _UserProductsState();
}

class _UserProductsState extends State<UserProducts> {
  List<Map<String, dynamic>> products = [];
bool pageLoading = true;      // initial screen load
bool productsLoading = false; // status switch loading
String selectedStatus = "approved";

final List<Map<String, String>> statusTabs = [
  {"label": "Approved", "value": "approved"},
  {"label": "Pending", "value": "pending"},
  {"label": "Disapproved", "value": "disapproved"},
];

 @override
void initState() {
  super.initState();
  loadInitialData();
}

Future<void> loadInitialData() async {
  await getbanner();
  await getproduct(selectedStatus);
  setState(() {
    pageLoading = false;
  });
}

 Future<void> delete(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  var response = await http.delete(
    Uri.parse("$api/api/myskates/products/update/${id}/"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );
print("DELETE RESPONSE STATUS: ${response.statusCode}");
print("DELETE RESPONSE BODY: ${response.body}");
  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Product Deleted"), backgroundColor: Colors.green),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Delete Failed"), backgroundColor: Colors.red),
    );
  }
}
List<Map<String, dynamic>> banner = [];

  Future<void> getbanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      var response = await http.get(
        Uri.parse('$api/api/myskates/banner/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> statelist = [];
      print("response.bodyyyyyyyyyyyyyyyyy:${response.body}");
      print(response.statusCode);
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed;

        for (var productData in productsData) {
          String imageUrl = "$api${productData['image']}";
          statelist.add({
            'id': productData['id'],
            'title': productData['title'],
            'image': imageUrl,
          });
        }
        setState(() {
          banner = statelist;
          print("statelistttttttttttttttttttt:$banner");
        });
      }
    } catch (error) {}
  }
Future<void> getproduct(String status) async {
  setState(() {
    productsLoading = true;
  });

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");
  final userId = prefs.getInt("id");

  final response = await http.get(
    Uri.parse('$api/api/myskates/products/status/$status/'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
print("response.body${response.body}");
  if (response.statusCode == 200) {
    final List<dynamic> parsed = jsonDecode(response.body);

    products = parsed.map((c) {
      return {
        'id': c['id'],
        'title': c['title'] ?? "",
        'image': c['image'] != null ? '$api${c['image']}' : "",
        'category_name': c['category_name'] ?? "",
        'price': c['price']?.toString() ?? "0",
      };
    }).toList();
  }

  setState(() {
    productsLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
       decoration: const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF00312D), // green at top-left
      Color(0xFF000000), // fades to black
    ],
    stops: [
      0.0, // start green
      0.35, // slope fade into black
    ],
  ),
),

        child: SafeArea(
          child: pageLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const SizedBox(height: 10),

                        // ---------------------------------------------
                        // TOP LEFT LOGO
                        // ---------------------------------------------
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            height: 50,
                            width: 68,
                            decoration: BoxDecoration(
                             
                             
                              
                            ),
                            child: Image.asset(
                              
                              "lib/assets/myskates.png", // YOUR LOGO HERE
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // SEARCH + ADD PRODUCT
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  border: Border.all(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 10),
                                    
                                      Text(
  "Search",
  style: TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    letterSpacing: 0.2,
  ),
),

                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          
                          ],
                        ),

                        const SizedBox(height: 15),

                       Column(
                         children: [
                           // MAIN BANNER
                           Container(
                             height: 160,
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(14),
                               boxShadow: [
                                 BoxShadow(
                                   color: Colors.black.withOpacity(0.25),
                                   blurRadius: 8,
                                   offset: Offset(0, 4),
                                 ),
                               ],
                             ),
                             child: ClipRRect(
                               borderRadius: BorderRadius.circular(14),
                               child: FlutterCarousel(
                                 options: CarouselOptions(
                                   height: 160,
                                   autoPlay: true,
                                   autoPlayInterval: Duration(seconds: 3),
                                   viewportFraction: 1,
                                   showIndicator: true,
                                   slideIndicator: CircularSlideIndicator(),
                                 ),
                                 items: banner.map((item) {
                                   return Stack(
                                     children: [
                                       // Background Image
                                       Positioned.fill(
                                         child: Image.network(
                                           item["image"] ?? "",
                                           fit: BoxFit.cover,
                                           loadingBuilder: (context, child, progress) {
                                             if (progress == null) return child;
                                             return Container(
                                               color: Colors.grey.shade900,
                                               alignment: Alignment.center,
                                               child:
                                                   const CircularProgressIndicator(),
                                             );
                                           },
                                           errorBuilder:
                                               (context, error, stackTrace) =>
                                                   Container(
                                                     color: Colors.black,
                                                     alignment: Alignment.center,
                                                     child: Icon(
                                                       Icons.broken_image,
                                                       color: Colors.white54,
                                                       size: 40,
                                                     ),
                                                   ),
                                         ),
                                       ),
                       
                                       // Gradient Overlay (bottom fade)
                                       Positioned.fill(
                                         child: Container(
                                           decoration: BoxDecoration(
                                             gradient: LinearGradient(
                                               begin: Alignment.topCenter,
                                               end: Alignment.bottomCenter,
                                               colors: [
                                                 Colors.transparent,
                                                 Colors.black.withOpacity(0.6),
                                               ],
                                             ),
                                           ),
                                         ),
                                       ),
                       
                                       // Banner Title (Optional)
                                       // Positioned(
                                       //   bottom: 12,
                                       //   left: 12,
                                       //   right: 12,
                                       //   child: Text(
                                       //     item["title"] ?? "",
                                       //     style: const TextStyle(
                                       //       color: Colors.white,
                                       //       fontSize: 18,
                                       //       fontWeight: FontWeight.bold,
                                       //       shadows: [
                                       //         Shadow(
                                       //           offset: Offset(0, 1),
                                       //           blurRadius: 4,
                                       //           color: Colors.black54,
                                       //         )
                                       //       ],
                                       //     ),
                                       //     maxLines: 1,
                                       //     overflow: TextOverflow.ellipsis,
                                       //   ),
                                       // ),
                                     ],
                                   );
                                 }).toList(),
                               ),
                             ),
                           ),
                         ],
                       ),

                        const SizedBox(height: 15),
Text(
  selectedStatus == "approved"
      ? "Approved Products"
      : selectedStatus == "pending"
          ? "Pending Products"
          : "Disapproved Products",
  style: const TextStyle(
    fontFamily: 'Poppins',
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  ),
),

                      

                       const SizedBox(height: 18),

SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: statusTabs.map((tab) {
      final bool isSelected = selectedStatus == tab["value"];

      return GestureDetector(
        onTap: () {
          setState(() {
  selectedStatus = tab["value"]!;
});
getproduct(selectedStatus);

        },
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.tealAccent
                : Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            tab["label"]!,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.black : Colors.white,
            ),
          ),
        ),
      );
    }).toList(),
  ),
),
                        const SizedBox(height: 20),
// ------------------------------------------------------------
// PRODUCTS GRID SECTION (NO FULL PAGE REFRESH)
// ------------------------------------------------------------
if (productsLoading)
  const Padding(
    padding: EdgeInsets.only(top: 40),
    child: Center(
      child: CircularProgressIndicator(
        color: Colors.tealAccent,
        strokeWidth: 2.5,
      ),
    ),
  )
else if (products.isEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 40),
    child: Center(
      child: Text(
        "No ${selectedStatus} products found",
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
      ),
    ),
  )
else
GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: products.length,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisExtent: 250,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  ),
  itemBuilder: (context, index) {
    final p = products[index];

    return Dismissible(
      key: ValueKey(p['id']),
      direction: DismissDirection.horizontal,

      confirmDismiss: (direction) async {
        // 👉 SWIPE RIGHT → UPDATE (NO UI)
        if (direction == DismissDirection.startToEnd) {
          _handleUpdateProduct(p);
          return false; // do NOT dismiss
        }

        // 👈 SWIPE LEFT → DELETE (RED UI SAME AS BEFORE)
        if (direction == DismissDirection.endToStart) {
          return await _confirmDelete(context, p);
        }

        return false;
      },

      // ❌ REMOVE BLUE UPDATE BACKGROUND
      background: const SizedBox.shrink(),

      // 🔴 KEEP DELETE BACKGROUND EXACTLY SAME
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Delete",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),

      child: _productCard(p),
    );
  },
),



const SizedBox(height: 40),


                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
Widget _productCard(Map<String, dynamic> p) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.20),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              p['image'],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image,
                color: Colors.grey,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            p['title'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),

        const SizedBox(height: 4),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            p['category_name'],
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ),

        const SizedBox(height: 4),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            "₹${p['price']}",
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    ),
  );
}
void _handleUpdateProduct(Map<String, dynamic> product) {
  print("UPDATE ${product['id']}");
 Navigator.push(
  context,
  slideRightToLeftRoute(
    UpdateProduct(productId: product['id']),
  ),
);

}
Future<bool> _confirmDelete(
  BuildContext context,
  Map<String, dynamic> product,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          title: const Text(
            "Delete Product",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Are you sure you want to delete \"${product['title']}\"?",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                print("DELETED ${product['id']}");
                delete(product['id']);
                Navigator.pop(context, true);

              
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ) ??
      false;
}

}

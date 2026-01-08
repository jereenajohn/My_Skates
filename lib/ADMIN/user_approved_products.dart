import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/add_product.dart';
import 'package:my_skates/ADMIN/cart_view.dart';
import 'package:my_skates/ADMIN/product_big%20_view.dart';
import 'package:my_skates/ADMIN/products_by_user.dart';
import 'package:my_skates/ADMIN/slideRightRoute.dart';
import 'package:my_skates/ADMIN/update_product.dart';
import 'package:my_skates/ADMIN/wishlist.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

class UserApprovedProducts extends StatefulWidget {
  const UserApprovedProducts({super.key});

  @override
  State<UserApprovedProducts> createState() => _UserApprovedProductsState();
}

class _UserApprovedProductsState extends State<UserApprovedProducts> {
  List<Map<String, dynamic>> products = [];
bool pageLoading = true;      // initial screen load
bool productsLoading = false; // status switch loading
int? selectedCategoryId;
String selectedCategoryName = "";

final List<Map<String, String>> statusTabs = [
  {"label": "Approved", "value": "approved"},
  {"label": "Pending", "value": "pending"},
  {"label": "Disapproved", "value": "disapproved"},
];

 @override
void initState() {
  super.initState();
  loadInitialData();
  getProductCategories();
}

Future<void> loadInitialData() async {
  await getbanner();
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


 Future<void> addwishlist(int id, BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");
  final userId = prefs.getInt("id");

  if (token == null || userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login expired. Please login again.")),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('$api/api/myskates/products/$id/wishlist/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        "user": userId.toString(),      // ✅ FIX
        "product": id.toString(),       // ✅ FIX
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
  final decoded = jsonDecode(response.body);
  final String message = decoded['message'] ?? "Added to wishlist";

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2F2B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.tealAccent.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.tealAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message, // ✅ BACKEND MESSAGE
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}
else {
    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A230F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.6)),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Failed to add wishlist",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    ),
    duration: const Duration(seconds: 2),
  ),
);

    }
  } catch (e) {
    print('Error: $e');
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A230F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.6)),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Failed to add wishlist",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    ),
    duration: const Duration(seconds: 2),
  ),
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
        });
      }
    } catch (error) {}
  }
  List<Map<String, dynamic>> categories = [];

  // FETCH CATEGORY LIST
  Future<void> getProductCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      var response = await http.get(
        Uri.parse("$api/api/myskates/products/category/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );



      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> list = [];

        for (var item in parsed) {
          list.add({
            "id": item["id"],
            "name": item["name"],
          });
        }

       setState(() {
  categories = list;
});

// 🔹 AUTO SELECT FIRST CATEGORY
if (categories.isNotEmpty) {
  selectedCategoryId = categories.first['id'];
  selectedCategoryName = categories.first['name'];
  getProductsByCategory(selectedCategoryId!);
}

      }
    } catch (e) {
    }
  }

Future<void> getProductsByCategory(int categoryId) async {
  setState(() {
    productsLoading = true;
  });

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access");

  try {
    final response = await http.get(
      Uri.parse('$api/api/myskates/products/by/category/$categoryId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Category Response status: ${response.statusCode}');
    print('Category Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> dataList = jsonDecode(response.body);

      products = dataList.map<Map<String, dynamic>>((c) {
        return {
          'id': c['id'],
          'title': c['title'] ?? "",
          'image': c['image'] != null ? '$api${c['image']}' : "",
          'category_name': c['category_name'] ?? "",
          'price': c['base_price']?.toString() ?? "0",
          'is_wishlisted': c['is_in_wishlist'] ?? false, // ✅ IMPORTANT
        };
      }).toList();
    }
  } catch (e) {
    print("Category fetch error: $e");
  }

  setState(() {
    productsLoading = false;
  });
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
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
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
                       // ---------------------------------------------
// TOP BAR : LOGO (LEFT) + CART ICON (RIGHT)
// ---------------------------------------------
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // LOGO
    SizedBox(
      height: 50,
      width: 68,
      child: Image.asset(
        "lib/assets/myskates.png",
        fit: BoxFit.cover,
      ),
    ),

    // RIGHT ACTION ICONS (FAVORITE + CART)
    Row(
      children: [
        // ❤️ FAVORITE ICON
        IconButton(
          onPressed: () {

_handleUpdateProduct();
          },
          icon: const Icon(
            Icons.favorite_border,
            color: Colors.white,
            size: 26,
          ),
        ),

        const SizedBox(width: 4),

        // 🛒 CART ICON
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              slideRightToLeftRoute(
                cart()
              ),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 26,
              ),

              // CART BADGE
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    "2",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ],
),



                        const SizedBox(height: 18),

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
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  slideRightToLeftRoute(
                                    ProductsByUser()
                                  ),
                                );
                              },
                              child: Container(
                                height: 40,
                                width: 110,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Products",
                                    style: TextStyle(
                                          fontFamily: 'Poppins',
                                         fontWeight: FontWeight.w400,
                                  
                                  letterSpacing: 0.2,
                              
                                        color: Colors.white, fontSize: 13),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 15),
                        banner.isEmpty
                        ? _bannerSkeleton()
                        :Column(
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
  selectedCategoryName.isEmpty
      ? "Products"
      : "$selectedCategoryName Products",
  style: const TextStyle(
    fontFamily: 'Poppins',
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  ),
),

                      

                   const SizedBox(height: 18),
categories.isEmpty
  ? _categorySkeleton()
  :
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: categories.map((cat) {
      final bool isSelected = selectedCategoryId == cat['id'];

      return GestureDetector(
        onTap: () {
          setState(() {
            selectedCategoryId = cat['id'];
            selectedCategoryName = cat['name'];
          });
          getProductsByCategory(cat['id']);
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
            cat['name'],
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
  _productGridSkeleton()
else if (products.isEmpty)
  Center(child: Text("No products found"))
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

    return _productCard(p);
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
  final bool isWishlisted = p['is_wishlisted'] == true;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        slideRightToLeftRoute(
          big_view(productId: p['id']),
        ),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
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
    
              /// ❤️ WISHLIST ICON
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    await addwishlist(p['id'], context);
    
                    // Toggle locally (VERY IMPORTANT)
                    setState(() {
                      p['is_wishlisted'] = !isWishlisted;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWishlisted
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isWishlisted
                          ? Colors.tealAccent
                          : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
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
    ),
  );
}

void _handleUpdateProduct() {
 Navigator.push(
  context,
  slideRightToLeftRoute(
    Wishlist(),
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
Widget _productGridSkeleton() {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 6,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisExtent: 250,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemBuilder: (_, __) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SKELETON
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(18),
              ),
            ),

            const SizedBox(height: 12),

            // TITLE LINE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // CATEGORY LINE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // PRICE LINE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                height: 14,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
Widget _categorySkeleton() {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: List.generate(5, (index) {
        return Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(30),
          ),
        );
      }),
    ),
  );
}
Widget _bannerSkeleton() {
  return Container(
    height: 160,
    decoration: BoxDecoration(
      color: Colors.grey.shade900,
      borderRadius: BorderRadius.circular(14),
    ),
  );
}

}

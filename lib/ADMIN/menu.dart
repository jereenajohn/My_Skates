import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/add_attributes.dart';
import 'package:my_skates/ADMIN/add_banner.dart';
import 'package:my_skates/ADMIN/add_category.dart';
import 'package:my_skates/ADMIN/add_country.dart';
import 'package:my_skates/ADMIN/add_coupon.dart';
import 'package:my_skates/ADMIN/add_district.dart';
import 'package:my_skates/ADMIN/add_product_banner.dart';
import 'package:my_skates/ADMIN/add_skaters_type.dart';
import 'package:my_skates/ADMIN/add_state.dart';
import 'package:my_skates/ADMIN/add_values.dart';
import 'package:my_skates/ADMIN/admin_orders_page.dart';
import 'package:my_skates/COACH/add_club.dart';
import 'package:my_skates/loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  
  TextEditingController _searchController=TextEditingController();
  String _searchQuery= "";


  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();

    // Debug check before logout
    print("Token BEFORE logout: ${prefs.getString('token')}");
    print("ID BEFORE logout: ${prefs.getInt('id')}");

    // Remove saved login data
    await prefs.remove('token');
    await prefs.remove('id');

    // Debug check after logout
    print("Token AFTER logout: ${prefs.getString('token')}");
    print("ID AFTER logout: ${prefs.getInt('id')}");

    // Snackbar message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Logout successfully",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );

    // Delay slightly so snackbar is visible before redirect
    await Future.delayed(const Duration(milliseconds: 600));

    // Navigate to Login Page & clear all previous screens
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const Loginpage(),
      ), // <-- your login page
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings and activity",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Search Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                  hintText: "Search",hintStyle: TextStyle(color: const Color.fromARGB(192, 255, 255, 255)),
                  icon: Icon(Icons.search,color:Colors.white60),
                  border: InputBorder.none
                    ),
                    onChanged: (value){
                      setState(() {
                        _searchQuery=value.toLowerCase();
                      });
                    }
                )
              ),

              const SizedBox(height: 12),
              if ("Country".toLowerCase().contains(_searchQuery))
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddCountry()),
                  );
                },
                
                child: _menuTile(icon: Icons.bookmark_outline, text: "Country"),
              ),
              if ("Country".toLowerCase().contains(_searchQuery))
              _divider(),
              if ("Orders".toLowerCase().contains(_searchQuery))
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Admin_order_page()),
                  );
                },
                child: _menuTile(icon: Icons.bookmark_outline, text: "Orders"),
              ),
              if ("Orders".toLowerCase().contains(_searchQuery))
              _divider(),
              if ("State".toLowerCase().contains(_searchQuery))
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const state()),
                  );
                },
                child: _menuTile(icon: Icons.bookmark_outline, text: "State"),
              ),
              if ("State".toLowerCase().contains(_searchQuery))
              _divider(),

              if ("District".toLowerCase().contains(_searchQuery))
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const district()),
                  );
                },
                child: _menuTile(icon: Icons.history, text: "District"),
              ),
              if ("District".toLowerCase().contains(_searchQuery))
              _divider(),

             if ("SkatersType".toLowerCase().contains(_searchQuery))
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddSkatersType(),
                    ),
                  );
                },
                child: _menuTile(
                  icon: Icons.bookmark_outline,
                  text: "Skaters Type",
                ),
              ),
              if ("Skaters Type".toLowerCase().contains(_searchQuery))
              _divider(),

             if ("Category".toLowerCase().contains(_searchQuery))
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddCategory(),
                    ),
                  );
                },
                child: _menuTile(icon: Icons.history, text: "Category"),
              ),
              if ("Category".toLowerCase().contains(_searchQuery))
              _divider(),

              if ("Attributes".toLowerCase().contains(_searchQuery))
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const attributes()),
                  );
                },
                child: _menuTile(icon: Icons.history, text: "Attributes"),
              ),
              if ("Attributes".toLowerCase().contains(_searchQuery))
              _divider(),

              if ("Values".toLowerCase().contains(_searchQuery))
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddValues()),
                  );
                },
                child: _menuTile(icon: Icons.history, text: "values"),
              ),
              if ("Values".toLowerCase().contains(_searchQuery))
              _divider(),

              if ("Add Coupon".toLowerCase().contains(_searchQuery))
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddCoupon()),
                  );
                },
                child: _menuTile(icon: Icons.show_chart_outlined, text: "Add Coupon"),),
                if ("Add Coupon".toLowerCase().contains(_searchQuery))
              _divider(),

              if ("Add Banners".toLowerCase().contains(_searchQuery))
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddBanner()),
                  );
                },
                child: _menuTile(
                  icon: Icons.notifications_outlined,
                  text: "Add Banners",
                ),
              ),
              if ("Add Banners".toLowerCase().contains(_searchQuery))
              _divider(),


              if ("Product Banners".toLowerCase().contains(_searchQuery))
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddproductBanner(),
                    ),
                  );
                },
                child: _menuTile(
                  icon: Icons.notifications_outlined,
                  text: "Product Banners",
                ),
              ),
              if ("Product Banners".toLowerCase().contains(_searchQuery))
              _divider(),
              // _menuTile(icon: Icons.access_time, text: "Time management"),
              // _divider(),

              if ("Logout".toLowerCase().contains(_searchQuery))
              _menuTile(
                icon: Icons.lock_outline,
                text: "Logout",
                onTap: logoutUser,
              ),

              const SizedBox(height: 25),

              // SECTION: WHO CAN SEE YOUR CONTENT
              // const Text(
              //   "Who can see your content",
              //   style: TextStyle(
              //     color: Colors.white70,
              //     fontSize: 15,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),

              // const SizedBox(height: 12),
              // _menuTile(
              //   icon: Icons.lock_outline,
              //   text: "Account privacy",
              //   trailingText: "Private",
              // ),
              // _divider(),
              // _menuTile(icon: Icons.star_outline, text: "Close Friends"),
            ],
          ),
        ),
      ),
    );
  }

  // MENU TILE WIDGET
  Widget _menuTile({
    required IconData icon,
    required String text,
    String? subtitle,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Colors.white, size: 26),
          title: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),

          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                )
              : null,

          onTap: onTap,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Text(
                  trailingText,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white38,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // DIVIDER
  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Divider(color: Colors.grey[800], thickness: 0.6),
    );
  }
}

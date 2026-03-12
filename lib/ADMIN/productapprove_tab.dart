import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/approved_products.dart';
import 'package:my_skates/ADMIN/disapproved_products.dart';
import 'package:my_skates/ADMIN/product_approval.dart';

class ProductapproveTab extends StatefulWidget {
  const ProductapproveTab({super.key});

  @override
  State<ProductapproveTab> createState() => _ProductapproveTabState();
}

class _ProductapproveTabState extends State<ProductapproveTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF001F1D),
              Color(0xFF003A36),
              Colors.black,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Product Approval",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: TabBar(
                  controller: _tab,
                  indicatorColor: Colors.transparent,
                  indicator: UnderlineTabIndicator(
                    borderSide: const BorderSide(
                      color: Colors.tealAccent,
                      width: 4,
                    ),
                    insets: const EdgeInsets.symmetric(horizontal: 40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: "Approved"),
                    Tab(text: "Pending"),
                    Tab(text: "Disapproved"),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: const [
                    approvedProducts(),
                    Approveproduct(),
                    DisapprovedProducts(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
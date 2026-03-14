import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/approved_coach.dart';
import 'package:my_skates/ADMIN/disapproved_coach.dart';
import 'approve_coach.dart';

class CoachApprovalTabs extends StatefulWidget {
  const CoachApprovalTabs({super.key});

  @override
  State<CoachApprovalTabs> createState() => _CoachApprovalTabsState();
}

class _CoachApprovalTabsState extends State<CoachApprovalTabs>
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
              Container(
                color: Colors.transparent,
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
                            "Coach Approval",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tab,
                      indicatorColor: Colors.transparent,
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(
                          color: Colors.tealAccent,
                          width: 4,
                        ),
                        insets: EdgeInsets.symmetric(horizontal: 55),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: TextStyle(fontSize: 15),
                      tabs: const [
                        Tab(text: "Approved"),
                        Tab(text: "Pending"),
                        Tab(text: "Disapproved"),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: const [
                    ApprovedCoach(),
                    ApproveCoach(),
                    DisapprovedCoach(),
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
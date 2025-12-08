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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(128, 45, 45, 45),
        elevation: 0,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Column(
            children: [
              TabBar(
                controller: _tab,

                // REMOVE WHITE DEFAULT LINE
                indicatorColor: Colors.transparent,

                // CUSTOM GREEN INDICATOR
                indicator: UnderlineTabIndicator(
                  borderSide: const BorderSide(
                    color: Colors.teal,
                    width: 4,      // THICKER LINE
                  ),
                  insets: const EdgeInsets.symmetric(
                    horizontal: 70,  // MAKES IT LONGER/WIDER
                  ),
                ),

                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,

                labelStyle: const TextStyle(
                  fontSize: 15,
                ),

                tabs: const [
                  Tab(text: "Approved"),
                  Tab(text: "Pending"),
                  Tab(text: "Disapproved"),
                ],
              ),

              const SizedBox(height: 5),
            ],
          ),
        ),
      ),

      body: TabBarView(
        controller: _tab,
        children: const [

         ApprovedCoach(),
          ApproveCoach(),

         DisapprovedCoach(),
        ],
      ),
    );
  }
}

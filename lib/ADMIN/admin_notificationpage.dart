import 'package:flutter/material.dart';
import 'package:my_skates/ADMIN/dashboard.dart';

class AdminNotificationpage extends StatefulWidget {
  const AdminNotificationpage({super.key});

  @override
  State<AdminNotificationpage> createState() => _AdminNotificationpageState();
}

class _AdminNotificationpageState extends State<AdminNotificationpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardPage()));
        }, icon: Icon(Icons.arrow_back)),
        title: Text("Notifications",style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
  

    );
  }
}
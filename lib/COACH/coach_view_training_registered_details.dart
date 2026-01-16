import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class CoachViewTrainingRegisteredDetails extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;
  const CoachViewTrainingRegisteredDetails({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  @override
  State<CoachViewTrainingRegisteredDetails> createState() =>
      _CoachViewTrainingRegisteredDetailsState();
}

class _CoachViewTrainingRegisteredDetailsState
    extends State<CoachViewTrainingRegisteredDetails> {
  bool loading = true;

  Map<String, dynamic>? training;
  int totalRegistrations = 0;
  List<Map<String, dynamic>> registrations = [];
  static const Color bgColor = Color(0xFF0F0F0F);        // App background
static const Color cardColor = Color(0xFF1A1A1A);      // Cards
static const Color accentColor = Color(0xFF2EE6A6);    // Primary accent
static const Color textPrimary = Colors.white;
static const Color textSecondary = Colors.white70;
static const Color borderColor = Color(0xFF2A2A2A);


  @override
  void initState() {
    super.initState();
    fetchRegisteredDetails();
    print("Fetching registrations for session ID: ${widget.sessionId}");
    print("Session Title: ${widget.sessionTitle}");
  }

  /* ================= FETCH FUNCTION (YOUR PATTERN) ================= */

  Future<void> fetchRegisteredDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");

    try {
      final response = await http.get(
        Uri.parse(
          "$api/api/myskates/training/${widget.sessionId}/registrations/",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> regList = [];

        for (var item in parsed['data']) {
          final user = item['user'];
          regList.add({
            'id': item['id'],
            'name': "${user['first_name']} ${user['last_name']}",
            'phone': user['phone'],
            'user_type': user['user_type'],
            'profile': user['profile'],
            'created_at': item['created_at'],
          });
        }

        setState(() {
          training = parsed['training'];
          totalRegistrations = parsed['total_registrations'];
          registrations = regList;
          loading = false;
        });
      }
    } catch (e) {
      loading = false;
    }
  }

  /* ================= UI ================= */

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: bgColor,
    appBar: AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      title: Text(
        widget.sessionTitle,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    body: loading
        ? const Center(
            child: CircularProgressIndicator(color: accentColor),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _countCard(),
                const SizedBox(height: 16),
                _registrationsList(),
              ],
            ),
          ),
  );
}

Widget _countCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: accentColor.withOpacity(0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.groups, color: accentColor),
        const SizedBox(width: 10),
        Text(
          "Total Registrations: $totalRegistrations",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    ),
  );
}

Widget _registrationsList() {
  if (registrations.isEmpty) {
    return const Center(
      child: Text(
        "No registrations found",
        style: TextStyle(color: textSecondary),
      ),
    );
  }

  return Column(
    children: registrations.map((item) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: accentColor.withOpacity(0.15),
            backgroundImage: item['profile'] != null
                ? NetworkImage("$api${item['profile']}")
                : null,
            child: item['profile'] == null
                ? const Icon(Icons.person, color: accentColor)
                : null,
          ),
          title: Text(
            item['name'],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Phone: ${item['phone']}",
                  style: const TextStyle(color: textSecondary),
                ),
                Text(
                  "Type: ${item['user_type']}",
                  style: const TextStyle(
                    color: accentColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}
    }
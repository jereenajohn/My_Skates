import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/dashboard.dart';
import 'package:my_skates/COACH/coach_homepage.dart';
import 'package:my_skates/STUDENTS/Home_Page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class CoachChatSupport extends StatefulWidget {
  final String from;

  const CoachChatSupport({
    super.key,
    required this.from,
  });

  @override
  State<CoachChatSupport> createState() => _CoachChatSupportState();
}

class _CoachChatSupportState extends State<CoachChatSupport> {
  List<Map<String, dynamic>> messages = [];
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool sending = false;

  @override
  void initState() {
    super.initState();

    messages.add({
      "type": "bot",
      "message": "Hi 👋 Welcome to MySkates Support. How can we help you?",
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<bool> _handleBack() async {
    if (!mounted) return false;

    if (widget.from == "coach") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CoachHomepage()),
      );
    } else if (widget.from == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else if (widget.from == "student") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      Navigator.pop(context);
    }

    return false;
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"type": "user", "message": text});
      sending = true;
    });

    messageController.clear();
    scrollToBottom();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      if (token == null) {
        setState(() {
          messages.add({
            "type": "bot",
            "message": "Session expired. Please login again.",
          });
          sending = false;
        });
        scrollToBottom();
        return;
      }

      final response = await http.post(
        Uri.parse("$api/api/myskates/support/chat/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"message": text}),
      );

      print("Chat support response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          messages.add({
            "type": "bot",
            "message":
                data["bot_reply"] ?? "Our support team will contact you shortly.",
          });
        });
      } else {
        setState(() {
          messages.add({
            "type": "bot",
            "message": "Unable to process request. Try again.",
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({
          "type": "bot",
          "message": "Server error. Please try later.",
        });
      });
    }

    setState(() => sending = false);
    scrollToBottom();
  }

  Widget buildMessageBubble(Map<String, dynamic> msg) {
    final bool isUser = msg["type"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF00312D)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          msg["message"] ?? "",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00312D),
                Color(0xFF000000),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          await _handleBack();
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(
                        Icons.support_agent,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "MySkates Support",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return buildMessageBubble(messages[index]);
                    },
                  ),
                ),

                if (sending)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Ask something...",
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => sendMessage(),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00312D),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                            onPressed: sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_skates/ADMIN/menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_skates/api.dart';

class AddChatSupportQuestions extends StatefulWidget {
  const AddChatSupportQuestions({super.key});

  @override
  State<AddChatSupportQuestions> createState() =>
      _AddChatSupportQuestionsState();
}

class _AddChatSupportQuestionsState extends State<AddChatSupportQuestions> {
  TextEditingController questionController = TextEditingController();
  TextEditingController answerController = TextEditingController();
  TextEditingController keywordsController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredFaqList = [];

  List<Map<String, dynamic>> faqList = [];
  bool loading = false;
  bool submitting = false;
  bool isEditing = false;
  int? editingId;

  @override
  void initState() {
    super.initState();
    fetchFAQs();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  Future<void> fetchFAQs() async {
    setState(() => loading = true);

    final token = await getToken();
    if (token == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("$api/api/myskates/support/faq/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("Fetch FAQ response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] == "success") {
          setState(() {
            faqList = List<Map<String, dynamic>>.from(decoded["data"]);
            filteredFaqList = faqList;
          });
        }
      }
    } catch (e) {
      print("FAQ fetch error: $e");
    }

    setState(() => loading = false);
  }

  void applySearch(String query) {
    final search = query.toLowerCase();

    setState(() {
      filteredFaqList = faqList.where((faq) {
        final question = (faq["question"] ?? "").toLowerCase();
        final answer = (faq["answer"] ?? "").toLowerCase();
        final keywords = (faq["keywords"] ?? "").toLowerCase();

        return question.contains(search) ||
            answer.contains(search) ||
            keywords.contains(search);
      }).toList();
    });
  }

  /// ADD FAQ
  Future<void> addFAQ() async {
    final question = questionController.text.trim();
    final answer = answerController.text.trim();
    final keywords = keywordsController.text.trim();

    if (question.isEmpty || answer.isEmpty || keywords.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields are required")));
      return;
    }

    setState(() => submitting = true);

    final token = await getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse("$api/api/myskates/support/faq/create/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "question": question,
          "answer": answer,
          "keywords": keywords,
        }),
      );

      print("Add FAQ response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 201) {
        questionController.clear();
        answerController.clear();
        keywordsController.clear();

        fetchFAQs();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("FAQ Added Successfully")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to add FAQ")));
      }
    } catch (e) {
      print("FAQ add error: $e");
    }

    setState(() => submitting = false);
  }

  Future<void> updateFAQ(int id) async {
    final question = questionController.text.trim();
    final answer = answerController.text.trim();
    final keywords = keywordsController.text.trim();

    final token = await getToken();
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse("$api/api/myskates/support/faq/$id/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "question": question,
          "answer": answer,
          "keywords": keywords,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          isEditing = false;
          editingId = null;
        });

        questionController.clear();
        answerController.clear();
        keywordsController.clear();

        fetchFAQs();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("FAQ Updated Successfully")),
        );
      }
    } catch (e) {
      print("Update error: $e");
    }
  }

  Future<void> deleteFAQ(int id) async {
    final token = await getToken();
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse("$api/api/myskates/support/faq/$id/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("Delete FAQ response: ${response.statusCode}");

      if (response.statusCode == 204) {
        setState(() {
          faqList.removeWhere((faq) => faq["id"] == id);
          filteredFaqList.removeWhere((faq) => faq["id"] == id);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("FAQ Deleted")));
      }
    } catch (e) {
      print("Delete error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00312D), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              /// HEADER
               Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MenuPage()));
                    }, icon: Icon(Icons.arrow_back,color: Colors.white,)),
                    Text(
                    "Manage Support FAQs",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ]
                ),
              ),

              const SizedBox(height: 20),

              /// FORM
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    buildField(questionController, "Question"),
                    const SizedBox(height: 10),
                    buildField(answerController, "Answer", maxLines: 3),
                    const SizedBox(height: 10),
                    buildField(
                      keywordsController,
                      "Keywords (comma separated)",
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00312D),
                      ),
                      onPressed: submitting
                          ? null
                          : () {
                              if (isEditing) {
                                updateFAQ(editingId!);
                              } else {
                                addFAQ();
                              }
                            },
                      child: submitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEditing ? "Update FAQ" : "Add FAQ",
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),

                    if (isEditing)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isEditing = false;
                            editingId = null;
                          });

                          questionController.clear();
                          answerController.clear();
                          keywordsController.clear();
                        },
                        child: const Text(
                          "Cancel Edit",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// SEARCH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  onChanged: applySearch,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    hintText: "Search FAQs...",
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// LOADING
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),

              /// FAQ LIST
              ...filteredFaqList.map((faq) {
                return Card(
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                faq["question"] ?? "",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.yellow,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isEditing = true;
                                      editingId = faq["id"];
                                      questionController.text =
                                          faq["question"] ?? "";
                                      answerController.text =
                                          faq["answer"] ?? "";
                                      keywordsController.text =
                                          faq["keywords"] ?? "";
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) {
                                        return Dialog(
                                          backgroundColor: Colors.transparent,
                                          child: Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF00312D),
                                                  Color(0xFF000000),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  "Delete FAQ?",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                const Text(
                                                  "This action cannot be undone.",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                      child: const Text(
                                                        "Cancel",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      // style:
                                                      //     ElevatedButton.styleFrom(
                                                      //       backgroundColor:
                                                      //           Colors.red,
                                                      //     ),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        deleteFAQ(faq["id"]);
                                                      },
                                                      child: const Text(
                                                        "Delete",
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          faq["answer"] ?? "",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
      ),
    );
  }
}

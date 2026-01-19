import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_skates/COACH/add_coach_achievements.dart';
import 'package:my_skates/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'coach_achievements_update.dart';

const Color accentColor = Color(0xFF2EE6A6);

class CoachViewAchievementsPage extends StatefulWidget {
  const CoachViewAchievementsPage({super.key});

  @override
  State<CoachViewAchievementsPage> createState() =>
      _CoachViewAchievementsPageState();
}

class _CoachViewAchievementsPageState extends State<CoachViewAchievementsPage> {
  late Future<List<Map<String, dynamic>>> achievementsFuture;

  @override
  void initState() {
    super.initState();
    achievementsFuture = fetchAchievements();
  }

  Future<List<Map<String, dynamic>>> fetchAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.get(
        Uri.parse("$api/api/myskates/achievements/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("FETCH ACHIEVEMENTS ERROR: $e");
    }
    return [];
  }

  Future<void> deleteAchievement(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access");

      final res = await http.delete(
        Uri.parse("$api/api/myskates/achievements/$id/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() {
          achievementsFuture = fetchAchievements();
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Achievement deleted")));
      } else {
        debugPrint(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete achievement")),
        );
      }
    } catch (e) {
      debugPrint("DELETE ACHIEVEMENT ERROR: $e");
    }
  }

  Future<void> confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A332E),
        title: const Text(
          "Delete Achievement?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "This action cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteAchievement(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Edit Achievements",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF0A332E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF2EE6A6), // accent color
              size: 24,
            ),
            tooltip: "Add Achievement",
            onPressed: () async {
              final added = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCoachAchievements()),
              );

              /// 🔄 Refresh list after add
              if (added == true) {
                setState(() {
                  achievementsFuture = fetchAchievements();
                });
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A332E), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: achievementsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _AchievementsSkeleton();
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const _EmptyAchievementsState();
            }

            final achievements = snapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: achievements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final a = achievements[index];

                return _AchievementCard(
                  achievement: a,
                  onEdit: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CoachAchievementsUpdate(achievement: a),
                      ),
                    );

                    if (updated == true) {
                      setState(() {
                        achievementsFuture = fetchAchievements();
                      });
                    }
                  },
                  onDelete: () {
                    confirmDelete(a["id"]);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/* ───────────────────────── CARD ───────────────────────── */

class _AchievementCard extends StatelessWidget {
  final Map<String, dynamic> achievement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AchievementCard({
    required this.achievement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final image = achievement["image"];
    final title = achievement["title"] ?? "";
    final org = achievement["organization"] ?? "";
    final date = achievement["date"] ?? "";
    final location = achievement["location"] ?? "";

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF00312D), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: accentColor.withOpacity(0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.08),
                image: image != null
                    ? DecorationImage(
                        image: NetworkImage("$api$image"),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: image == null
                  ? const Icon(Icons.emoji_events, color: accentColor, size: 22)
                  : null,
            ),

            const SizedBox(width: 14),

            /// DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (org.isNotEmpty)
                    Text(
                      org,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  if (location.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 13,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: accentColor, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ───────────────────────── EMPTY STATE ───────────────────────── */

class _EmptyAchievementsState extends StatelessWidget {
  const _EmptyAchievementsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 48, color: accentColor),
          SizedBox(height: 12),
          Text(
            "No achievements added yet",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Your awards and milestones will appear here",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── SKELETON ───────────────────────── */

class _AchievementsSkeleton extends StatelessWidget {
  const _AchievementsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.08),
        ),
      ),
    );
  }
}

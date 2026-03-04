import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ride_provider.dart';
import 'ride_models.dart';

class SaveActivityScreen extends StatefulWidget {
  const SaveActivityScreen({super.key});

  @override
  State<SaveActivityScreen> createState() => _SaveActivityScreenState();
}

class _SaveActivityScreenState extends State<SaveActivityScreen> {
  final title = TextEditingController(text: "Afternoon Ride");
  final desc = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Save Activity", style: TextStyle(fontWeight: FontWeight.w900)),
        leading: TextButton(
          onPressed: () {
            // resume -> go back to tracking
            ride.uiState = RideUIState.tracking;
            ride.notifyListeners();
            Navigator.pop(context);
          },
          child: const Text("Resume"),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(
            controller: title,
            hint: "Activity Title",
            maxLines: 1,
          ),
          const SizedBox(height: 12),
          _field(
            controller: desc,
            hint: "How'd it go? Share more about your activity and use @ to tag someone.",
            maxLines: 4,
          ),
          const SizedBox(height: 12),

          // sport dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF151517),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SportType>(
                value: ride.selectedSport,
                isExpanded: true,
                items: SportType.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (s) {
                  if (s != null) {
                    ride.selectedSport = s;
                    ride.notifyListeners();
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // map + photo placeholders like screenshot
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151517),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Center(
                    child: Text(
                      "This is a sample map.\nYou'll see your activity map after saving.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151517),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFF5A00), width: 1, style: BorderStyle.solid),
                  ),
                  child: const Center(
                    child: Text(
                      "Add Photos/Video",
                      style: TextStyle(color: Color(0xFFFF5A00), fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF5A00),
              side: const BorderSide(color: Color(0xFFFF5A00)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("Change Map Type", style: TextStyle(fontWeight: FontWeight.w900)),
          ),

          const SizedBox(height: 22),
          const Text("Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),

          _dropdownTile("Activity Tag"),
          _dropdownTile("How did that activity feel?"),
          _noteTile(),

          const SizedBox(height: 18),

          SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                // TODO: persist to DB + upload to backend
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text("Save Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
          )
        ],
      ),
    );
  }

  Widget _field({required TextEditingController controller, required String hint, required int maxLines}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF151517),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white12)),
      ),
    );
  }

  Widget _dropdownTile(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151517),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
        trailing: const Icon(Icons.keyboard_arrow_down),
        onTap: () {},
      ),
    );
  }

  Widget _noteTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151517),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: const ListTile(
        leading: Icon(Icons.lock, color: Colors.white70),
        title: Text(
          "Jot down private notes here. Only you can\nsee these.",
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
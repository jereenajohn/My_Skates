import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fl_chart/fl_chart.dart';

class ActivityTrackerPage extends StatefulWidget {
  const ActivityTrackerPage({super.key});

  @override
  State<ActivityTrackerPage> createState() => _ActivityTrackerPageState();
}

class _ActivityTrackerPageState extends State<ActivityTrackerPage> {
  StreamSubscription<Position>? _positionStream;

  DateTime? startTime;
  DateTime? endTime;
  Position? lastPosition;

  double totalDistance = 0;
  bool tracking = false;

  final double userWeightKg = 65;
  final double metValue = 8.0;

  final List<FlSpot> distanceSpots = [];

  Future<void> _checkPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception("Location disabled");
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Permission denied forever");
    }
  }

  void startTracking() async {
    await _checkPermission();

    setState(() {
      startTime = DateTime.now();
      endTime = null;
      totalDistance = 0;
      lastPosition = null;
      distanceSpots.clear();
      tracking = true;
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((position) {
      if (lastPosition != null) {
        totalDistance += Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        distanceSpots.add(
          FlSpot(timeSeconds / 60, totalDistance / 1000),
        );
      }
      lastPosition = position;
      setState(() {});
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;

    setState(() {
      endTime = DateTime.now();
      tracking = false;
    });
  }

  double get timeSeconds {
    if (startTime == null) return 0;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!).inSeconds.toDouble();
  }

  double get distanceKm => totalDistance / 1000;

  double get avgSpeedKmph =>
      timeSeconds == 0 ? 0 : distanceKm / (timeSeconds / 3600);

  double get caloriesBurned =>
      metValue * userWeightKg * (timeSeconds / 3600);

  double get powerWatts =>
      timeSeconds == 0 ? 0 : (caloriesBurned * 4184) / timeSeconds;

  String formatTime(double seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds.toInt() % 60;
    return "${h.toString().padLeft(2, '0')}:"
        "${m.toString().padLeft(2, '0')}:"
        "${s.toString().padLeft(2, '0')}";
  }

  Widget statCard(String title, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 190, 188, 188),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withOpacity(.15),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 11,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          Text(unit, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget distanceChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 214, 162, 162),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, _) =>
                    Text("${value.toStringAsFixed(1)} km",
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) =>
                    Text("${value.toInt()} min",
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 10)),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: distanceSpots,
              isCurved: true,
              color: Colors.tealAccent,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.tealAccent.withOpacity(.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Activity Tracker"),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            distanceChart(),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                statCard("DISTANCE",
                    distanceKm.toStringAsFixed(2), "km"),
                statCard("TIME",
                    formatTime(timeSeconds), ""),
                statCard("AVG SPEED",
                    avgSpeedKmph.toStringAsFixed(1), "km/h"),
                statCard("CALORIES",
                    caloriesBurned.toStringAsFixed(0), "kcal"),
                statCard("POWER",
                    powerWatts.toStringAsFixed(0), "W"),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      tracking ? Colors.redAccent : Colors.tealAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: tracking ? stopTracking : startTracking,
                child: Text(
                  tracking ? "STOP ACTIVITY" : "START ACTIVITY",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

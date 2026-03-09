enum RideUIState {
  initialMap,        // screenshot 1
  chooseSport,       // screenshot 2
  readyCompact,      // screenshot 1 after selecting ride
  readyExpanded,     // screenshot 3
  tracking,          // screenshot 4
  autoPaused, 
   paused,       // screenshot 5
  stopped,           // screenshot 6/7 (same layout, different primary button)
  saveActivity,      // screenshot 8
}

enum SportType {
  run,
  trailRun,
  walk,
  hike,
  ride,
  mtb,
  gravel,
}

extension SportTypeX on SportType {
  String get label {
    switch (this) {
      case SportType.run: return "Run";
      case SportType.trailRun: return "Trail Run";
      case SportType.walk: return "Walk";
      case SportType.hike: return "Hike";
      case SportType.ride: return "Ride";
      case SportType.mtb: return "Mountain Bike Ride";
      case SportType.gravel: return "Gravel Ride";
    }
  }

  bool get isCycle =>
      this == SportType.ride || this == SportType.mtb || this == SportType.gravel;
}
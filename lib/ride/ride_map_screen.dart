import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'ride_provider.dart';
import 'ride_models.dart';
import 'ride_math.dart';
import 'save_activity_screen.dart';
import 'widgets.dart';

class RideMapScreen extends StatefulWidget {
  const RideMapScreen({super.key});

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {
  GoogleMapController? _map;

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();

    // Navigate to Save screen when state becomes saveActivity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ride.uiState == RideUIState.saveActivity) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SaveActivityScreen()))
            .then((_) {
              // when back, go to initial map
              ride.stopAll();
              ride.uiState = RideUIState.initialMap;
              ride.notifyListeners();
            });
      }
    });

    final polyline = Polyline(
      polylineId: const PolylineId("route"),
      width: 7,
      color: const Color(0xFF7A5CFF),
      points: ride.route.map((p) => LatLng(p.latitude, p.longitude)).toList(),
    );

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(9.9312, 76.2673),
              zoom: 16,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            polylines: {polyline},
            onMapCreated: (c) => _map = c,
          ),

          // top-left back arrow circle
          // Positioned(
          //   top: 48,
          //   left: 16,
          //   child: _CircleIcon(
          //     icon: Icons.keyboard_arrow_down,
          //     onTap: () {
          //       // you can pop screen if needed
          //     },
          //   ),
          // ),

          // right side controls (layers + 3D + locate)
          // Positioned(
          //   top: 320,
          //   right: 14,
          //   child: Column(
          //     children: [
          //       _CircleIcon(icon: Icons.layers, badge: "4", onTap: () {}),
          //       const SizedBox(height: 12),
          //       _CircleIcon(icon: Icons.threed_rotation, label: "3D", onTap: () {}),
          //       const SizedBox(height: 12),
          //       _CircleIcon(
          //         icon: Icons.gps_fixed,
          //         onTap: () async {
          //           // center map to current location if available
          //           if (ride.route.isNotEmpty) {
          //             final last = ride.route.last;
          //             await _map?.animateCamera(
          //               CameraUpdate.newLatLng(LatLng(last.latitude, last.longitude)),
          //             );
          //           }
          //         },
          //       ),
          //     ],
          //   ),
          // ),

          // Heatmap banner (dummy UI like screenshot)
          // Positioned(
          //   top: 54,
          //   left: 75,
          //   right: 20,
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          //     decoration: BoxDecoration(
          //       color: const Color(0xFF141416),
          //       borderRadius: BorderRadius.circular(18),
          //       border: Border.all(color: Colors.orange.withOpacity(0.5)),
          //     ),
          //     child: Row(
          //       children: const [
          //         Icon(Icons.lock, color: Colors.white70, size: 18),
          //         SizedBox(width: 10),
          //         Expanded(
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               Text("See what’s popular", style: TextStyle(fontWeight: FontWeight.w800)),
          //               SizedBox(height: 2),
          //               Text("Tap to add weekly Heatmap", style: TextStyle(color: Colors.white70)),
          //             ],
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          // bottom panel
          Align(
            alignment: Alignment.bottomCenter,
            child: _bottomPanel(context, ride),
          ),
        ],
      ),
    );
  }

  Widget _bottomPanel(BuildContext context, RideProvider ride) {
    // Screen 1 base and Screen 1 after choosing ride share similar UI
    if (ride.uiState == RideUIState.chooseSport) {
      return _chooseSportSheet(context, ride);
    }

    if (ride.uiState == RideUIState.readyExpanded) {
      return _expandedStatsPanel(context, ride);
    }

    if (ride.uiState == RideUIState.tracking) {
      return _trackingPanel(context, ride);
    }

    if (ride.uiState == RideUIState.autoPaused) {
      return _autoPausedPanel(context, ride);
    }

    if (ride.uiState == RideUIState.stopped) {
      return _stoppedPanel(context, ride);
    }

    // initialMap OR readyCompact
    return _initialOrReadyPanel(context, ride);
  }

  // Screenshot 1 panel
  Widget _initialOrReadyPanel(BuildContext context, RideProvider ride) {
    return PanelContainer(
      padding: const EdgeInsets.symmetric(vertical: 8), // ↓ reduced
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// STAT CARD
          StatTripletCard(
            title: ride.selectedSport.isCycle
                ? "Ride"
                : ride.selectedSport.label,
            leftValue: RideMath.formatDuration(ride.moving).substring(3),
            leftLabel: "Time",
            midValue: ride.avgSpeedKmh.toStringAsFixed(1),
            midLabel: "Avg. speed",
            rightValue: ride.distanceKm.toStringAsFixed(2),
            rightLabel: "Distance",
            onExpand: ride.uiState == RideUIState.readyCompact
                ? ride.toggleExpandReady
                : null,
          ),

          const SizedBox(height: 8), // ↓ reduced from 14
          /// BUTTON ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SmallModeButton(
                selected: true,
                icon: Icons.directions_bike,

                label: ride.selectedSport.isCycle
                    ? "Ride"
                    : ride.selectedSport.label,
                onTap: () => ride.openChooseSport(),
              ),

              _BigStartButton(
                label: "Start",
                onTap: () async {
                  await ride.startPressed();
                },
              ),

              _SmallModeButton(
                selected: false,
                icon: Icons.alt_route,
                label: "Add Route",
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 50), // ↓ reduced from 30
        ],
      ),
    );
  }

  // Screenshot 2
  Widget _chooseSportSheet(BuildContext context, RideProvider ride) {
    return PanelContainer(
      child: SizedBox(
        height: 520,
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Choose a Sport",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,color: Colors.white),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ride.uiState = RideUIState.readyCompact;
                    ride.notifyListeners();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "Foot Sports",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _sportRow(ride, SportType.run, Icons.directions_run),
                  _sportRow(ride, SportType.trailRun, Icons.terrain),
                  _sportRow(ride, SportType.walk, Icons.directions_walk),
                  _sportRow(ride, SportType.hike, Icons.hiking),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "Cycle Sports",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _sportRow(ride, SportType.ride, Icons.directions_bike),
                  _sportRow(ride, SportType.mtb, Icons.pedal_bike),
                  _sportRow(
                    ride,
                    SportType.gravel,
                    Icons.directions_bike_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sportRow(RideProvider ride, SportType s, IconData icon) {
    final selected = ride.selectedSport == s;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Colors.teal : Colors.white,
      ),
      title: Text(
        s.label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: selected ? Colors.teal : Colors.white,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: Colors.teal)
          : null,
      onTap: () => ride.selectSport(s),
    );
  }

  // Screenshot 3
  Widget _expandedStatsPanel(BuildContext context, RideProvider ride) {
    return PanelContainer(
      child: SizedBox(
        height: 520,
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  onPressed: ride.toggleExpandReady,
                  icon: const Icon(Icons.open_in_full, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              RideMath.formatDuration(ride.moving),
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 30),
            Text(
              ride.avgSpeedKmh.toStringAsFixed(1),
              style: const TextStyle(fontSize: 92, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              "Avg. speed (km/h)",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              ride.distanceKm.toStringAsFixed(2),
              style: const TextStyle(fontSize: 92, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              "Distance (km)",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),

            // bottom like screenshot 3
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SmallModeButton(
                  selected: true,
                  icon: Icons.directions_bike,
                  label: ride.selectedSport.isCycle
                      ? "Ride"
                      : ride.selectedSport.label,
                  onTap: ride.openChooseSport,
                ),
                _BigStartButton(
                  label: "Start",
                  onTap: () => ride.startPressed(),
                ),
                _SmallModeButton(
                  selected: false,
                  icon: Icons.alt_route,
                  label: "Add Route",
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Stay safe and send a text to start\nsharing your location.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text("Send Beacon Text"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Screenshot 4
  Widget _trackingPanel(BuildContext context, RideProvider ride) {
    return PanelContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatTripletCard(
            title: ride.selectedSport.isCycle
                ? "Ride"
                : ride.selectedSport.label,
            leftValue: _mmss(ride.moving),
            leftLabel: "Time",
            midValue: ride.currentSpeedKmh.toStringAsFixed(1),
            midLabel: "Speed (km/h)",
            rightValue: ride.distanceKm.toStringAsFixed(2),
            rightLabel: "Distance (km)",
            onExpand: () {}, // Strava shows expand on tracking too; optional
          ),
          const SizedBox(height: 14),
          OrangePrimaryButton(
            text: "Pause",
            icon: Icons.pause,
            onTap: ride.pausePressed,
          ),
        ],
      ),
    );
  }

  // Screenshot 5 (Auto-paused + Stop/Finish)
  Widget _autoPausedPanel(BuildContext context, RideProvider ride) {
    return PanelContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // yellow header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3B100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "Auto-paused",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          StatTripletCard(
            title: ride.selectedSport.isCycle
                ? "Ride"
                : ride.selectedSport.label,
            leftValue: _mmss(ride.moving),
            leftLabel: "Time",
            midValue: ride.avgSpeedKmh.toStringAsFixed(1),
            midLabel: "Avg. speed (km/h)",
            rightValue: ride.distanceKm.toStringAsFixed(2),
            rightLabel: "Distance (km)",
          ),
          const SizedBox(height: 14),

          DualButtons(
            leftText: "Stop",
            leftIcon: Icons.stop,
            onLeft: ride.pausePressed, // same as stopped
            rightText: "Finish",
            rightIcon: Icons.flag,
            onRight: ride.finishPressed,
          ),
        ],
      ),
    );
  }

  // Screenshot 6/7 (Stopped/Resume/Finish)
  Widget _stoppedPanel(BuildContext context, RideProvider ride) {
    final title = ride.isAutoPaused ? "Auto-paused" : "Stopped";

    return PanelContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3B100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          StatTripletCard(
            title: ride.selectedSport.isCycle
                ? "Ride"
                : ride.selectedSport.label,
            leftValue: _mmss(ride.moving),
            leftLabel: "Time",
            midValue: ride.avgSpeedKmh.toStringAsFixed(1),
            midLabel: "Avg. speed (km/h)",
            rightValue: ride.distanceKm.toStringAsFixed(2),
            rightLabel: "Distance (km)",
          ),
          const SizedBox(height: 14),

          DualButtons(
            leftText: "Resume",
            leftIcon: Icons.play_arrow,
            onLeft: ride.resumePressed,
            rightText: "Finish",
            rightIcon: Icons.flag,
            onRight: ride.finishPressed,
          ),
        ],
      ),
    );
  }

  static String _mmss(Duration d) {
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$mm:$ss";
  }
}

// ---------- small ui widgets ----------
class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? badge;
  final VoidCallback onTap;
  const _CircleIcon({
    required this.icon,
    required this.onTap,
    this.label,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: label != null
                  ? Text(
                      label!,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    )
                  : Icon(icon, color: Colors.white),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SmallModeButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 110,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF232325)
                    : const Color(0xFF232325),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.teal : Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.teal : Colors.teal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigStartButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BigStartButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.play_arrow, size: 38, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

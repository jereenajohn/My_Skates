import 'package:flutter/material.dart';

class WaitingPage extends StatefulWidget {
  const WaitingPage({super.key});

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // BLACK BACKGROUND
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // // LOTTIE ANIMATION (GLOW EFFECT)
              // SizedBox(
              //   height: 260,
              //   child: Lottie.asset(
              //     "assets/animations/waiting.json",
              //     fit: BoxFit.contain,
              //   ),
              // ),
              const SizedBox(height: 30),

              // GLOWING TITLE TEXT
              Text(
                "Your Account is Under Review",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 18, color: Colors.blueAccent)],
                ),
              ),

              const SizedBox(height: 15),

              // LIGHT DESCRIPTION
              const Text(
                "Our admin team is verifying your profile.\n"
                "You will be notified once approval is complete.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              // CUSTOM ANIMATED GRADIENT LOADER
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 68, 255, 205),
                          Color.fromARGB(255, 192, 251, 64),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcATop,
                    child: const LinearProgressIndicator(
                      minHeight: 6,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // SMALL LIGHT TEXT
              const Text(
                "Thank you for your patience",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

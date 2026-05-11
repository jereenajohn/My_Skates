import 'package:flutter/material.dart';

Route slideRightToLeftRoute(Widget page) {
  return PageRouteBuilder(
    opaque: true,
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Container(
        color: Colors.black,
        child: page,
      );
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
      );

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}


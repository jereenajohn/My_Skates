import 'package:flutter/material.dart';

class PanelContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  const PanelContainer({
    super.key,
    required this.child,
    this.radius = 26,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF101011),
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 25, offset: Offset(0, -10)),
        ],
      ),
      child: child,
    );
  }
}

class StatTripletCard extends StatelessWidget {
  final String title;
  final String leftValue;
  final String leftLabel;
  final String midValue;
  final String midLabel;
  final String rightValue;
  final String rightLabel;
  final VoidCallback? onExpand;

  const StatTripletCard({
    super.key,
    required this.title,
    required this.leftValue,
    required this.leftLabel,
    required this.midValue,
    required this.midLabel,
    required this.rightValue,
    required this.rightLabel,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,color: Colors.white),
                  ),
                ),
              ),
              if (onExpand != null)
                InkWell(
                  onTap: onExpand,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.open_in_full, size: 18, color: Colors.white),
                  ),
                )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatBlock(value: leftValue, label: leftLabel)),
              Expanded(child: _StatBlock(value: midValue, label: midLabel)),
              Expanded(child: _StatBlock(value: rightValue, label: rightLabel)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  const _StatBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class OrangePrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  const OrangePrimaryButton({super.key, required this.text, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

class DualButtons extends StatelessWidget {
  final String leftText;
  final IconData leftIcon;
  final VoidCallback? onLeft;
  final String rightText;
  final IconData rightIcon;
  final VoidCallback? onRight;

  const DualButtons({
    super.key,
    required this.leftText,
    required this.leftIcon,
    required this.onLeft,
    required this.rightText,
    required this.rightIcon,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              onPressed: onLeft,
              icon: Icon(leftIcon),
              label: Text(leftText, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              onPressed: onRight,
              icon: Icon(rightIcon),
              label: Text(rightText, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
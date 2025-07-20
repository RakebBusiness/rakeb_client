import 'package:flutter/material.dart';
import 'welcome_header_clipper.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final double heightPercentage;

  const AppHeader({
    super.key,
    required this.title,
    this.icon = Icons.pedal_bike,
    this.heightPercentage = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        height: MediaQuery.of(context).size.height * heightPercentage,
        color: const Color(0xFF32C156),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 48),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

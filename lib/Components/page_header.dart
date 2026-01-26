import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? extra;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background Shapes
          Positioned(
            top: -50,
            right: -50,
            child: _buildShape(200, isRing: true),
          ),
          Positioned(bottom: -30, left: -20, child: _buildShape(150)),
          Positioned(top: 20, left: 100, child: _buildShape(80, isRing: true)),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (extra != null) ...[const SizedBox(height: 15), extra!],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShape(double size, {bool isRing = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isRing
            ? Border.all(color: Colors.white.withOpacity(0.08), width: 10.0)
            : null,
        color: isRing ? Colors.transparent : Colors.white.withOpacity(0.05),
      ),
    );
  }
}

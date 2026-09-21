import 'dart:math' as math;
import 'package:flutter/material.dart';

class FoilShimmerEffect extends StatefulWidget {
  final Widget child;
  final bool isFoil;
  final BorderRadius? borderRadius;

  const FoilShimmerEffect({
    super.key,
    required this.child,
    required this.isFoil,
    this.borderRadius,
  });

  @override
  State<FoilShimmerEffect> createState() => _FoilShimmerEffectState();
}

class _FoilShimmerEffectState extends State<FoilShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFoil) {
      return widget.child;
    }

    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          widget.child,
          // Holographic foil sheen overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final angle = _controller.value * 2 * math.pi;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment(
                        math.cos(angle) * 1.5,
                        math.sin(angle) * 1.5,
                      ),
                      end: Alignment(
                        math.cos(angle + math.pi) * 1.5,
                        math.sin(angle + math.pi) * 1.5,
                      ),
                      colors: [
                        Colors.transparent,
                        const Color(0xFFFF80BF).withOpacity(0.18),
                        const Color(0xFF9580FF).withOpacity(0.22),
                        const Color(0xFF80FFEA).withOpacity(0.20),
                        const Color(0xFFFFCA80).withOpacity(0.24),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 0.45, 0.65, 0.85, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),
          // Subtle sparkling border
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: const Color(0xFFFBBF24).withOpacity(0.65),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Foil badge indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 6,
                  )
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                  SizedBox(width: 3),
                  Text(
                    'FOIL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

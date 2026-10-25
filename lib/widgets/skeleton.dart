import 'package:flutter/material.dart';

import '../theme.dart';

/// Silhouette de la une pendant le premier chargement, qui « respire » doucement.
class UneSkeleton extends StatefulWidget {
  const UneSkeleton({super.key});

  @override
  State<UneSkeleton> createState() => _UneSkeletonState();
}

class _UneSkeletonState extends State<UneSkeleton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chargement du journal',
      child: FadeTransition(
        opacity: Tween(
          begin: 0.45,
          end: 1.0,
        ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const AspectRatio(aspectRatio: 3 / 2, child: _Block()),
            const SizedBox(height: 16),
            const _Line(widthFactor: 0.95, height: 22),
            const _Line(widthFactor: 0.7, height: 22),
            const SizedBox(height: 10),
            const _Line(widthFactor: 0.45, height: 12),
            const SizedBox(height: 14),
            for (var i = 0; i < 3; i++) ...[
              const _Line(widthFactor: 1, height: 13),
              const _Line(widthFactor: 0.9, height: 13),
              const SizedBox(height: 22),
            ],
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block();

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: Palette.papierCreux);
}

class _Line extends StatelessWidget {
  const _Line({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: SizedBox(height: height, child: const _Block()),
    ),
  );
}

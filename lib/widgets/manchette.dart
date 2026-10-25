import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';

/// Le titre du journal : capybara, « Le Bien Heureux » en rouge et le tampon
/// « .be » noir et jaune, posé de travers comme sur le site.
class Manchette extends StatelessWidget {
  const Manchette({super.key, this.size = 30, this.logo = true});

  final double size;
  final bool logo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppConfig.appName,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (logo) ...[
              Image.asset(
                'assets/brand/capybara.png',
                width: size * 1.05,
                height: size * 1.05,
                filterQuality: FilterQuality.medium,
              ),
              SizedBox(width: size * 0.12),
            ],
            Text(
              AppConfig.appName,
              maxLines: 1,
              style: TextStyle(
                fontFamily: Fonts.manchette,
                fontSize: size,
                height: 1,
                letterSpacing: -0.02 * size,
                color: Palette.rouge,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: size * 0.12, bottom: size * 0.02),
              child: _Tampon(size: size * 0.36),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tampon extends StatelessWidget {
  const _Tampon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 20 * math.pi / 180,
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          size * 0.5,
          size * 0.3,
          size * 0.45,
          size * 0.28,
        ),
        decoration: BoxDecoration(
          color: Palette.encre,
          borderRadius: BorderRadius.circular(size * 0.12),
        ),
        foregroundDecoration: BoxDecoration(
          border: Border.all(
            color: Palette.jaune.withValues(alpha: 0.8),
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(size * 0.08),
        ),
        margin: EdgeInsets.zero,
        child: Text(
          '.be',
          style: TextStyle(
            fontFamily: Fonts.tampon,
            fontWeight: FontWeight.w700,
            fontSize: size,
            height: 1,
            letterSpacing: 0.1 * size,
            color: Palette.jaune,
          ),
        ),
      ),
    );
  }
}

/// Barre du haut : menu, manchette, recherche — fine ligne grise dessous.
class JournalTopBar extends StatelessWidget implements PreferredSizeWidget {
  const JournalTopBar({
    super.key,
    required this.onMenu,
    required this.onSearch,
  });

  final VoidCallback onMenu;
  final VoidCallback onSearch;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.papier,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: preferredSize.height,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Palette.filet)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu_rounded, size: 28),
                onPressed: onMenu,
              ),
              const Expanded(child: Center(child: Manchette(size: 26))),
              IconButton(
                tooltip: 'Chercher dans le journal',
                icon: const Icon(Icons.search_rounded, size: 28),
                onPressed: onSearch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

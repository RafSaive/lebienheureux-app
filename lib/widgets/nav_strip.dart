import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Bandeau des rubriques entre deux filets noirs :
/// « À LA UNE • ACTUALITÉS • BIEN EXPLIQUÉ • … »
class NavStrip extends StatefulWidget {
  const NavStrip({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  /// (clé, libellé)
  final List<(String, String)> items;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  State<NavStrip> createState() => _NavStripState();
}

class _NavStripState extends State<NavStrip> {
  final _keys = <String, GlobalKey>{};

  @override
  void didUpdateWidget(NavStrip old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      // Amène la rubrique choisie dans le champ, en douceur.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[widget.selected]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Palette.papier,
        border: Border(
          top: BorderSide(color: Palette.encre),
          bottom: BorderSide(color: Palette.encre),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: widget.items.length,
        separatorBuilder: (_, _) => const Center(
          child: Text(
            '•',
            style: TextStyle(fontSize: 10, color: Palette.encre),
          ),
        ),
        itemBuilder: (context, i) {
          final (key, label) = widget.items[i];
          final active = key == widget.selected;
          return InkWell(
            key: _keys.putIfAbsent(key, GlobalKey.new),
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onSelect(key);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Semantics(
                  selected: active,
                  button: true,
                  child: Text(
                    label.toUpperCase(),
                    style: Typo.nav.copyWith(
                      color: active ? Palette.rouge : Palette.encre,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

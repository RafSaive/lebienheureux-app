import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/wp_page.dart';
import '../services/wp_api.dart';
import '../theme.dart';
import '../widgets/article_html.dart';
import '../widgets/journal_bits.dart';

/// Page statique du site (« Le Bien Heureux ? », « À propos »…).
class PageScreen extends StatefulWidget {
  const PageScreen({super.key, required this.slug, required this.title});

  final String slug;
  final String title;

  @override
  State<PageScreen> createState() => _PageScreenState();
}

class _PageScreenState extends State<PageScreen> {
  late Future<WpPage> _page;

  @override
  void initState() {
    super.initState();
    _page = _load();
  }

  Future<WpPage> _load() => context.read<WpApi>().fetchPage(widget.slug);

  @override
  Widget build(BuildContext context) {
    final side = math.max(20.0, (MediaQuery.sizeOf(context).width - 680) / 2);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title.toUpperCase(), style: Typo.etiquette),
        shape: const Border(bottom: BorderSide(color: Palette.filet)),
      ),
      body: FutureBuilder<WpPage>(
        future: _page,
        builder: (context, snap) {
          if (snap.hasError) {
            return ListView(
              children: [
                CapybaraMessage(
                  title: 'Pas de réseau dans la pièce ?',
                  text: '${snap.error}',
                  action: 'Réessayer',
                  onAction: () => setState(() => _page = _load()),
                ),
              ],
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final page = snap.data!;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, 24, side, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(page.title, style: Typo.titreArticle),
                      const Filet(margin: 16),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, 8, side, 48),
                sliver: ArticleHtml(page.contentHtml, sliver: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

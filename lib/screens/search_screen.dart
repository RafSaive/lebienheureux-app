import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/local_store.dart';
import '../services/wp_api.dart';
import '../state/feed_controller.dart';
import '../theme.dart';
import '../widgets/feed_list.dart';
import '../widgets/journal_bits.dart';
import '../widgets/tiles.dart';

/// « Chercher dans le journal ».
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final FeedController _feed;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _feed = FeedController(context.read<WpApi>(), context.read<LocalStore>());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _feed.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _feed.search(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _feed,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          shape: const Border(bottom: BorderSide(color: Palette.filet)),
          title: TextField(
            autofocus: true,
            textInputAction: TextInputAction.search,
            style: Typo.resume.copyWith(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Chercher dans le journal',
              hintStyle: Typo.resume.copyWith(
                fontSize: 18,
                color: Palette.encrePale,
              ),
              border: InputBorder.none,
            ),
            onChanged: _onChanged,
            onSubmitted: (v) {
              _debounce?.cancel();
              _feed.search(v);
            },
          ),
        ),
        body: Consumer<FeedController>(
          builder: (context, feed, _) {
            if (feed.query.isEmpty) {
              return ListView(
                children: const [
                  CapybaraMessage(
                    title: 'Que cherche-t-on ?',
                    text:
                        'Un sujet, une marque, un mot du titre… '
                        'Le capybara fouille les archives.',
                  ),
                ],
              );
            }
            return FeedList(
              controller: feed,
              storageKey: 'search',
              emptyTitle: 'Rien trouvé pour « ${feed.query} »',
              emptyText:
                  'Le capybara a pourtant bien cherché. '
                  'Essayez un autre mot ?',
              rows: (context) {
                final items = feed.articles;
                return [
                  (_) => const SizedBox(height: 12),
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) (_) => const Filet(),
                    (_) =>
                        TitreTile(article: items[i], list: items, resume: true),
                  ],
                ];
              },
            );
          },
        ),
      ),
    );
  }
}

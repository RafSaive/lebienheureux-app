import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'screens/home_shell.dart';
import 'services/local_store.dart';
import 'services/wp_api.dart';
import 'state/favorites_controller.dart';
import 'state/feed_controller.dart';
import 'state/journal_controller.dart';
import 'state/reading_prefs.dart';
import 'state/speech_controller.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  _registerFontLicenses();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  runApp(LebienheureuxApp(api: WpApi(), prefs: prefs));
}

/// Les polices embarquées sont sous licence SIL OFL : on les liste dans
/// l'écran des licences.
void _registerFontLicenses() {
  const fonts = {
    'archivonarrow': 'Archivo Narrow',
    'baskervville': 'Baskervville',
    'crimsontext': 'Crimson Text',
    'gelasio': 'Gelasio',
    'opensans': 'Open Sans',
  };
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: file, value: name) in fonts.entries) {
      final text = await rootBundle.loadString('assets/fonts/OFL-$file.txt');
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}

class LebienheureuxApp extends StatelessWidget {
  const LebienheureuxApp({super.key, required this.api, required this.prefs});

  final WpApi api;
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final store = LocalStore(prefs);
    return MultiProvider(
      providers: [
        Provider.value(value: api),
        Provider.value(value: store),
        ChangeNotifierProvider(
          create: (_) => FeedController(api, store, cacheKey: 'home')..start(),
        ),
        ChangeNotifierProvider(
          create: (_) => JournalController(api, store)..init(),
        ),
        ChangeNotifierProvider(create: (_) => FavoritesController(store)),
        ChangeNotifierProvider(create: (_) => SpeechController()),
        ChangeNotifierProvider(create: (_) => ReadingPrefs(prefs)),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeShell(),
      ),
    );
  }
}

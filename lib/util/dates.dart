import 'package:intl/intl.dart';

/// « 25 OCTOBRE 2026 », comme sous les titres du site.
String signeDate(DateTime d) =>
    DateFormat('d MMMM y', 'fr_FR').format(d.toLocal()).toUpperCase();

/// « DIMANCHE 25 OCTOBRE », en tête des articles.
String kickerDate(DateTime d) =>
    DateFormat('EEEE d MMMM', 'fr_FR').format(d.toLocal()).toUpperCase();

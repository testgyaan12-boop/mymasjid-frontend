import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/masjid_provider.dart';
import 'providers/theme_provider.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();
  final authProvider = AuthProvider();
  final masjidProvider = MasjidProvider();

  // Read the saved session BEFORE launching so the first screen is correct.
  final prefs = await SharedPreferences.getInstance();
  final savedSession = prefs.getString('access_token') != null;

  // If a saved session exists, auto-login (background) and open Home directly.
  // Otherwise, show the Sign-In page.
  final String initialLocation;
  if (savedSession) {
    unawaited(authProvider.tryAutoLogin());
    unawaited(masjidProvider.loadSavedMasjid());
    unawaited(themeProvider.loadTheme());
    initialLocation = '/';
  } else {
    unawaited(themeProvider.loadTheme());
    initialLocation = '/login';
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: masjidProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: NoorAlMasjidApp(initialLocation: initialLocation, router: buildRouter(initialLocation)),
    ),
  );
}

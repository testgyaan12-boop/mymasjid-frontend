import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/masjid_provider.dart';
import 'providers/theme_provider.dart';
import 'services/push_service.dart';
import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  // Push notifications service initialization (fire-and-forget).
  unawaited(_initPush());

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

Future<void> _initPush() async {
  try {
    PushService.instance.onOpen = (type) {
      NoorAlMasjidApp.navigatorKey.currentState?.pushNamed('/alerts');
    };
    await PushService.instance.init();
  } catch (_) {}
}

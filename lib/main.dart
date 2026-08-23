import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  // Always start at login - no auto-login. Show fingerprint if session exists.
  final String initialLocation = '/login';
  unawaited(themeProvider.loadTheme());
  // Do not auto-login; let LoginPage handle fingerprint auto if session available.
  // Preload masjid for guest browsing if needed but not required for auth.
  unawaited(masjidProvider.loadSavedMasjid());

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
      NoorAlMasjidApp.navigatorKey.currentState?.pushNamed('/notifications');
    };
    await PushService.instance.init();
  } catch (_) {}
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/common/bottom_nav_shell.dart';
import 'widgets/common/splash_screen.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/masjid_select_page.dart';
import 'pages/quran_page.dart';
import 'pages/tasbih_page.dart';
import 'pages/saved_tasbihs_page.dart';
import 'pages/donations_page.dart';
import 'pages/alerts_page.dart';
import 'pages/notifications_page.dart';
import 'pages/events_page.dart';
import 'pages/zakat_page.dart';
import 'pages/about_page.dart';
import 'pages/profile_page.dart';
import 'pages/sunnah_library_page.dart';
import 'pages/admin_page.dart';
import 'pages/tools/noor_ai_page.dart';
import 'pages/tools/summarizer_page.dart';

class NoorAlMasjidApp extends StatelessWidget {
  final String initialLocation;
  final GoRouter router;
  const NoorAlMasjidApp({super.key, required this.initialLocation, required this.router});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'Noor Al Masjid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(
        primary: themeProvider.primaryColor,
        secondary: themeProvider.secondaryColor,
      ),
      darkTheme: AppTheme.dark(
        primary: themeProvider.primaryColor,
        secondary: themeProvider.secondaryColor,
      ),
      themeMode: themeProvider.themeMode,
      routerConfig: router,
      builder: (context, child) => _AppWithSplash(child: child!),
    );
  }
}

class _AppWithSplash extends StatefulWidget {
  final Widget child;
  const _AppWithSplash({required this.child});

  @override
  State<_AppWithSplash> createState() => _AppWithSplashState();
}

class _AppWithSplashState extends State<_AppWithSplash> {
  @override
  Widget build(BuildContext context) {
    return MobileSplash(child: widget.child);
  }
}

GoRouter buildRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    navigatorKey: NoorAlMasjidApp.navigatorKey,
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupPage()),
      GoRoute(path: '/masjid-select', builder: (_, __) => const MasjidSelectPage()),
      ShellRoute(
        builder: (context, state, child) => BottomNavShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomePage()),
          GoRoute(path: '/quran', builder: (_, __) => const QuranPage()),
          GoRoute(path: '/tasbih', builder: (_, __) => const TasbihPage()),
          GoRoute(path: '/saved-tasbihs', builder: (_, __) => const SavedTasbihsPage()),
          GoRoute(path: '/donations', builder: (_, __) => const DonationsPage()),
          GoRoute(path: '/alerts', builder: (_, __) => const AlertsPage()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
          GoRoute(path: '/events', builder: (_, __) => const EventsPage()),
          GoRoute(path: '/zakat', builder: (_, __) => const ZakatPage()),
          GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminPage()),
          GoRoute(path: '/sunnah-library', builder: (_, __) => const SunnahLibraryPage()),
          GoRoute(path: '/tools/noor-ai', builder: (_, __) => const NoorAIPage()),
          GoRoute(path: '/tools/summarizer', builder: (_, __) => const SummarizerPage()),
        ],
      ),
    ],
  );
}

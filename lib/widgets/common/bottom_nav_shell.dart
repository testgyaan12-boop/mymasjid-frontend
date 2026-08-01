import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_header.dart';
import 'splash_screen.dart';
import 'sunnah_popup.dart';

class BottomNavShell extends StatefulWidget {
  final Widget child;
  const BottomNavShell({super.key, required this.child});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _currentIndex = 0;

  static const _navItems = [
    ('/', Icons.home, 'Home'),
    ('/quran', Icons.menu_book, 'Quran'),
    ('/tasbih', Icons.touch_app, 'Tasbih'),
    ('/donations', Icons.favorite, 'Donate'),
  ];

  static const _moreRoutes = ['/alerts', '/events', '/zakat', '/about', '/admin'];

  @override
  void initState() {
    super.initState();
    // Show sunnah popup after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSunnahPopup();
    });
  }

  void _showSunnahPopup() {
    showDialog(
      context: context,
      builder: (_) => const SunnahPopup(),
    );
  }

  void _onNavTap(int index) {
    if (index < _navItems.length) {
      setState(() => _currentIndex = index);
      context.go(_navItems[index].$1);
    } else {
      _showMoreSheet();
    }
  }

  void _showMoreSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.red),
                title: const Text('Community Alerts'),
                onTap: () { Navigator.pop(ctx); context.push('/alerts'); },
              ),
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Upcoming Events'),
                onTap: () { Navigator.pop(ctx); context.push('/events'); },
              ),
              ListTile(
                leading: const Icon(Icons.calculate),
                title: const Text('Zakat Calculator'),
                onTap: () { Navigator.pop(ctx); context.push('/zakat'); },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About Us'),
                onTap: () { Navigator.pop(ctx); context.push('/about'); },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share App'),
                onTap: () { Navigator.pop(ctx); _shareApp(); },
              ),
              ListTile(
                leading: const Icon(Icons.shield),
                title: const Text('Management Portal'),
                onTap: () { Navigator.pop(ctx); context.push('/admin'); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareApp() {
    // Will use share_plus package
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentIndex == index;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: active
              ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.45)),
            const SizedBox(height: 2),
            Text(label,
              style: TextStyle(
                fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: active ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItemMore(IconData icon, String label) {
    final active = _currentIndex >= 4;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showMoreSheet(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: active
              ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.45)),
            const SizedBox(height: 2),
            Text(label,
              style: TextStyle(
                fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: active ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sync current index with route
    final location = GoRouterState.of(context).uri.toString();
    final idx = _navItems.indexWhere((item) => item.$1 == location);
    if (idx >= 0 && idx != _currentIndex) {
      _currentIndex = idx;
    } else if (_moreRoutes.contains(location) && _currentIndex < 4) {
      _currentIndex = 4;
    } else if (!_moreRoutes.contains(location) && idx < 0 && _currentIndex != 4) {
      _currentIndex = _currentIndex < 4 ? _currentIndex : 0;
    }

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, 'Home'),
              _navItem(1, Icons.menu_book_rounded, 'Quran'),
              _navItem(2, Icons.touch_app_rounded, 'Tasbih'),
              _navItem(3, Icons.favorite_rounded, 'Donate'),
              _navItemMore(Icons.grid_view_rounded, 'More'),
            ],
          ),
        ),
      ),
    );
  }
}

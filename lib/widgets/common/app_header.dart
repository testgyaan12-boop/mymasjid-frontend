import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/masjid_provider.dart';
import '../../providers/theme_provider.dart';
import 'masjid_switcher_sheet.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final masjid = context.watch<MasjidProvider>();
    final theme = context.watch<ThemeProvider>();
    final masjidName = masjid.currentMasjid?['name'] as String? ?? 'Noor Al Masjid';
    final logo = (masjid.allCmsData['branding'] as Map<String, dynamic>?)?['logo'] as String?;

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (logo != null && logo.isNotEmpty) ...[
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: logo,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(width: 32, height: 32, color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  if (auth.isAuthenticated) {
                    await masjid.loadJoinedMasjids();
                  }
                  if (context.mounted) await showMasjidSwitcherSheet(context);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            masjidName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (auth.isAuthenticated) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.swap_horiz_rounded, size: 14, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildThemeToggle(context, theme),
            const SizedBox(width: 8),
            _buildAvatar(context, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, ThemeProvider theme) {
    return IconButton(
      icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
      onPressed: theme.toggleTheme,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, AuthProvider auth) {
    return GestureDetector(
      onTap: () => _showMenu(context, auth),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.person, size: 20, color: Theme.of(context).colorScheme.onSecondary),
      ),
    );
  }

  void _showMenu(BuildContext context, AuthProvider auth) {
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
              if (auth.isAuthenticated) ...[
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('My Profile'),
                  onTap: () { Navigator.pop(ctx); context.push('/profile'); },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () { Navigator.pop(ctx); auth.logout(); },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('My Profile'),
                  onTap: () { Navigator.pop(ctx); context.push('/profile'); },
                ),
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Sign In'),
                  onTap: () { Navigator.pop(ctx); context.push('/login'); },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Join Us'),
                  onTap: () { Navigator.pop(ctx); context.push('/signup'); },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

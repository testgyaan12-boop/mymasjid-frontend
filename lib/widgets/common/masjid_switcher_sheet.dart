import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/masjid_provider.dart';

Future<void> showMasjidSwitcherSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _MasjidSwitcherSheet(),
  );
}

class _MasjidSwitcherSheet extends StatefulWidget {
  const _MasjidSwitcherSheet();

  @override
  State<_MasjidSwitcherSheet> createState() => _MasjidSwitcherSheetState();
}

class _MasjidSwitcherSheetState extends State<_MasjidSwitcherSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loadingJoined = true;
  bool _searching = false;
  int _switchingId = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadJoined();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadJoined() async {
    final masjid = context.read<MasjidProvider>();
    await masjid.loadJoinedMasjids();
    if (mounted) setState(() => _loadingJoined = false);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchCtrl.text;
    if (query.trim().isEmpty) {
      setState(() => _searching = false);
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<MasjidProvider>().searchMasjids(query);
    });
  }

  Future<void> _confirmAndSwitch(Map<String, dynamic> masjid) async {
    final id = masjid['id'] as int;
    final name = masjid['name'] as String? ?? 'Masjid';
    final auth = context.read<AuthProvider>();
    final masjidProvider = context.read<MasjidProvider>();
    final current = masjidProvider.currentMasjid;
    if (current != null && current['id'] == id) {
      Navigator.pop(context);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Masjid?'),
        content: Text('Switch to "$name"? Home content, prayer times and alerts will update to this masjid.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Switch')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _switchingId = id);
    if (!auth.isAuthenticated) {
      await masjidProvider.selectMasjid(id, name);
      if (!mounted) return;
      setState(() => _switchingId = 0);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Viewing $name'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final error = await masjidProvider.changeMasjid(id, name);
    if (!mounted) return;
    setState(() => _switchingId = 0);
    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to $name'), behavior: SnackBarBehavior.floating),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final masjid = context.watch<MasjidProvider>();
    final theme = Theme.of(context);
    final current = masjid.currentMasjid;
    final currentId = current?['id'] as int?;
    final searchQuery = _searchCtrl.text.trim();
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.mosque_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Change Masjid', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by name or pincode...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: searchQuery.isNotEmpty
                    ? _buildSearchResults(theme, masjid.masjidSearchResults)
                    : (isAuthenticated
                        ? _buildJoinedList(theme, masjid.joinedMasjids, currentId)
                        : _buildGuestHint(theme)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestHint(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.visibility_outlined, size: 40, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Text('Browsing as guest', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Search above to view any masjid. Sign in to join masjids and save your progress.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinedList(ThemeData theme, List<Map<String, dynamic>> joined, int? currentId) {
    if (_loadingJoined) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (joined.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.search, size: 40, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Text('No masjid joined yet', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 4),
            Text('Search above to find and join your masjid.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR MASJIDS', style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w800, letterSpacing: 0.8,
        )),
        const SizedBox(height: 8),
        ...joined.map((m) => _buildMasjidTile(theme, m, currentId, joined: true)),
      ],
    );
  }

  Widget _buildSearchResults(ThemeData theme, List<Map<String, dynamic>> results) {
    if (_searching && results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 40, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Text('No masjid found', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SEARCH RESULTS', style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w800, letterSpacing: 0.8,
        )),
        const SizedBox(height: 8),
        ...results.map((m) {
          final currentId = context.read<MasjidProvider>().currentMasjid?['id'] as int?;
          final isGuest = !context.read<AuthProvider>().isAuthenticated;
          return _buildMasjidTile(theme, m, currentId, joined: false, isGuest: isGuest);
        }),
      ],
    );
  }

  Widget _buildMasjidTile(ThemeData theme, Map<String, dynamic> m, int? currentId, {required bool joined, bool isGuest = false}) {
    final id = m['id'] as int;
    final name = m['name'] as String? ?? 'Masjid';
    final isCurrent = id == currentId;
    final isSwitching = _switchingId == id;
    final role = m['userRole'] as String?;

    final subtitleParts = [
      if (m['city'] != null) m['city'] as String,
      if (m['state'] != null) m['state'] as String,
      if (m['pincode'] != null) m['pincode'] as String,
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _switchingId != 0 ? null : () => _confirmAndSwitch(m),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrent
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent ? theme.colorScheme.primary.withValues(alpha: 0.3) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(Icons.mosque_rounded, size: 20, color: theme.colorScheme.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('CURRENT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ],
                        if (role != null && !isCurrent) ...[
                          const SizedBox(width: 6),
                          Text(role, style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9, fontWeight: FontWeight.w700, color: theme.colorScheme.secondary,
                          )),
                        ],
                      ],
                    ),
                    if (subtitleParts.isNotEmpty)
                      Text(subtitleParts, style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSwitching)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              else if (isCurrent)
                Icon(Icons.check_circle_rounded, size: 20, color: theme.colorScheme.primary)
              else if (!joined)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(isGuest ? 'Select' : 'Switch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                )
              else
                Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

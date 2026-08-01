import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/masjid_provider.dart';

class MasjidSelectPage extends StatefulWidget {
  const MasjidSelectPage({super.key});

  @override
  State<MasjidSelectPage> createState() => _MasjidSelectPageState();
}

class _MasjidSelectPageState extends State<MasjidSelectPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final masjid = context.read<MasjidProvider>();
    await masjid.searchMasjids('');
    if (mounted) setState(() => _loading = false);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final query = _searchCtrl.text.trim();
      context.read<MasjidProvider>().searchMasjids(query);
    });
  }

  Future<void> _selectMasjid(Map<String, dynamic> masjid) async {
    final id = masjid['id'] as int;
    final name = masjid['name'] as String? ?? 'Masjid';
    if (_selecting) return;
    setState(() => _selecting = true);

    final auth = context.read<AuthProvider>();
    final masjidProvider = context.read<MasjidProvider>();
    if (auth.isAuthenticated) {
      final error = await masjidProvider.changeMasjid(id, name);
      if (error != null) {
        await masjidProvider.selectMasjid(id, name);
      }
    } else {
      await masjidProvider.selectMasjid(id, name);
    }

    if (!mounted) return;
    setState(() => _selecting = false);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masjid = context.watch<MasjidProvider>();
    final auth = context.watch<AuthProvider>();
    final results = masjid.masjidSearchResults;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mosque_rounded, size: 28, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text('Select Your Masjid', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'See prayer times & updates for your masjid. Guests browse freely — sign in to save your progress.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            Expanded(
              child: _buildList(theme, results, auth.isAuthenticated),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ThemeData theme, List<Map<String, dynamic>> results, bool isAuthenticated) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 40, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Text('No masjid found', style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            )),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        if (_searchCtrl.text.trim().isEmpty) ...[
          _buildDefaultCard(theme),
          const SizedBox(height: 16),
          Text('ALL MASJIDS', style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          )),
          const SizedBox(height: 8),
        ],
        ...results.map((m) => _buildMasjidTile(theme, m)),
        const SizedBox(height: 12),
        if (!isAuthenticated)
          _buildAuthOptions(theme),
      ],
    );
  }

  Widget _buildDefaultCard(ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _selecting
            ? null
            : () => _selectMasjid({'id': 1, 'name': 'Noor Al Masjid'}),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home_rounded, color: theme.colorScheme.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Continue with default', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Noor Al Masjid', style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    )),
                  ],
                ),
              ),
              if (_selecting)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasjidTile(ThemeData theme, Map<String, dynamic> m) {
    final name = m['name'] as String? ?? 'Masjid';
    final subtitle = [
      if (m['city'] != null) m['city'] as String,
      if (m['state'] != null) m['state'] as String,
      if (m['pincode'] != null) m['pincode'] as String,
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _selecting ? null : () => _selectMasjid(m),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
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
                    Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Select', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Want to save your progress & join your masjid?',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/signup'),
                child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => context.push('/login'),
                child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

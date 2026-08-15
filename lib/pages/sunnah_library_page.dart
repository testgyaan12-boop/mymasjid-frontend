import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/cms_service.dart';
import '../services/user_service.dart';

class SunnahLibraryPage extends StatefulWidget {
  const SunnahLibraryPage({super.key});

  @override
  State<SunnahLibraryPage> createState() => _SunnahLibraryPageState();
}

class _SunnahLibraryPageState extends State<SunnahLibraryPage> {
  List<Map<String, dynamic>> _savedSunnahs = [];
  List<Map<String, dynamic>> _librarySunnahs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSunnahs();
  }

  Future<void> _loadSunnahs() async {
    try {
      final data = await UserService().getSavedSunnahs();
      setState(() => _savedSunnahs = data.cast<Map<String, dynamic>>());
    } catch (_) {}
    try {
      final data = await CmsService().getSunnahs();
      setState(() => _librarySunnahs = data.cast<Map<String, dynamic>>());
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  bool _isSaved(int sunnahId) => _savedSunnahs.any(
        (s) => (s['sunnah']?['id'] ?? s['id']) == sunnahId,
      );

  Future<void> _toggleSave(Map<String, dynamic> sunnah) async {
    final sunnahId = sunnah['id'] as int?;
    if (sunnahId == null) return;
    try {
      if (_isSaved(sunnahId)) {
        final savedEntry = _savedSunnahs.firstWhere(
          (s) => (s['sunnah']?['id'] ?? s['id']) == sunnahId,
          orElse: () => <String, dynamic>{},
        );
        final entryId = savedEntry['id'] as int?;
        if (entryId != null) await UserService().removeSunnah(entryId);
      } else {
        await UserService().saveSunnah(sunnahId);
      }
      await _loadSunnahs();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGuest = context.watch<AuthProvider>().user == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sunnah Library'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_librarySunnahs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.menu_book_outlined, size: 40, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 10),
                        Text(
                          'No sunnahs published yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ..._librarySunnahs.map((s) {
                    final sid = s['id'] as int?;
                    final saved = sid != null && _isSaved(sid);
                    final image = s['image'] as String? ?? '';
                    final title = s['title'] as String? ?? '';
                    final text = s['text'] as String? ?? '';
                    final reference = s['reference'] as String? ?? '';
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (image.isNotEmpty)
                            Image.network(
                              image,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ListTile(
                            leading: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: 19, color: theme.colorScheme.secondary),
                            ),
                            title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            subtitle: (text.isNotEmpty || reference.isNotEmpty)
                                ? Text(
                                    text.isNotEmpty ? text : reference,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  )
                                : null,
                            trailing: isGuest
                                ? const Tooltip(
                                    message: 'Sign in to save Sunnahs',
                                    child: Icon(Icons.lock_outline_rounded, size: 20),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                                      color: saved ? theme.colorScheme.secondary : theme.colorScheme.primary,
                                    ),
                                    onPressed: sid == null ? null : () => _toggleSave(s),
                                  ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
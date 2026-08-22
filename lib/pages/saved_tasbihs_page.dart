import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/constants.dart';
import '../services/user_service.dart';

class SavedTasbihsPage extends StatefulWidget {
  const SavedTasbihsPage({super.key});

  @override
  State<SavedTasbihsPage> createState() => _SavedTasbihsPageState();
}

class _SavedTasbihsPageState extends State<SavedTasbihsPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final logs = await UserService().getTasbihLogs();
      _logs = logs.cast<Map<String, dynamic>>();
    } catch (_) {
      _logs = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  String _arabicFor(String title) {
    for (final a in AppConstants.commonAdhkars) {
      if (a['title'] == title) return a['arabic'] ?? '';
    }
    return '';
  }

  String _formatCreatedAt(String ts) {
    // ts is LocalDate like "2026-05-13" from BaseEntity.createdAt
    try {
      // Try ISO date first (LocalDate -> 2026-05-13), fallback to DateTime parse
      DateTime dt;
      if (ts.length == 10 && ts.contains('-')) {
        dt = DateTime.parse('${ts}T00:00:00');
      } else {
        dt = DateTime.parse(ts);
      }
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final dateStr = '${dt.day.toString().padLeft(2,'0')} ${months[dt.month-1]} ${dt.year}';
      final now = DateTime.now();
      final diff = now.difference(dt);
      String rel;
      if (diff.inMinutes < 60 && ts.contains('T')) {
        rel = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24 && diff.inDays == 0 && ts.contains('T')) {
        rel = '${diff.inHours}h ago';
      } else if (diff.inDays == 0) {
        rel = 'Today';
      } else if (diff.inDays == 1) {
        rel = 'Yesterday';
      } else {
        rel = '${diff.inDays}d ago';
      }
      return '$dateStr • $rel';
    } catch (_) {
      return ts;
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> log) async {
    final title = log['dhikr'] as String? ?? 'Tasbih';
    final count = log['count'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tasbih?'),
        content: Text('Delete "$title" • $count bar? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final id = log['id'];
    if (id == null) return;
    try {
      await UserService().deleteTasbihLog(id as int);
      if (!mounted) return;
      setState(() => _logs.removeWhere((e) => e['id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete — check your connection')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Saved Tasbihs', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tasbih'),
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('New Dhikr', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 12),
        extendedIconLabelSpacing: 6,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? _buildEmpty(theme)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (context, i) {
                    final log = _logs[i];
                    final primary = theme.colorScheme.primary;
                    final title = log['dhikr'] as String? ?? '';
                    final count = log['count'] as int? ?? 0;
                    final sets = count ~/ 33;
                    final arabic = _arabicFor(title);
                    final createdAt = log['createdAt'] as String? ?? log['timestamp'] as String? ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Icon(Icons.spa_rounded, size: 18, color: primary)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                  if (arabic.isNotEmpty)
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Text(arabic, style: TextStyle(fontFamily: 'Alegreya', fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                                    ),
                                  const SizedBox(height: 2),
                                  Text('$count bar • $sets sets', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: primary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatCreatedAt(createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('$count',
                                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: primary),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _confirmDelete(log),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mosque_outlined, size: 56, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 14),
            Text('No saved tasbihs yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Complete a set on the Tasbih page and it will be saved here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

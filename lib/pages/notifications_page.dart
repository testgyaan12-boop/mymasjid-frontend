import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/masjid_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const _prefsKey = 'dismissed_notifications';
  Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    _loadDismissed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final masjid = context.read<MasjidProvider>();
      masjid.loadNotifications();
      masjid.markAllNotificationsRead();
    });
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _dismissed = (prefs.getStringList(_prefsKey) ?? []).toSet());
  }

  Future<void> _saveDismissed(Set<String> updated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, updated.toList());
  }

  void _dismissOne(String id) {
    setState(() {
      _dismissed.add(id);
      _saveDismissed(_dismissed);
    });
  }

  void _clearAll(List<Map<String, dynamic>> notes) {
    setState(() {
      _dismissed.addAll(notes.map((n) => (n['id'] ?? '').toString()));
      _saveDismissed(_dismissed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final masjid = context.watch<MasjidProvider>();
    final allNotes = masjid.notifications;
    final notes = allNotes.where((n) => !_dismissed.contains((n['id'] ?? '').toString())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
            Text('Masjid updates & alerts', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (notes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear All',
              onPressed: () => _clearAll(notes),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: masjid.loadNotifications,
        child: notes.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text('No notifications yet.')),
                  if (_dismissed.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('Restore cleared notifications'),
                        onPressed: () {
                          setState(() => _dismissed = {});
                          _saveDismissed({});
                        },
                      ),
                    ),
                  ],
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: notes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => Dismissible(
                  key: ValueKey('note_${notes[i]['id'] ?? i}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  onDismissed: (_) => _dismissOne((notes[i]['id'] ?? '').toString()),
                  child: Stack(
                    children: [
                      _buildCard(context, notes[i]),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          tooltip: 'Dismiss',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _dismissOne((notes[i]['id'] ?? '').toString()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> n) {
    final title = n['title'] as String? ?? '';
    final message = n['message'] as String? ?? '';
    final isRead = n['isRead'] == true;
    final type = n['type'] as String? ?? 'alert';
    final createdAt = n['createdAt'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(_iconFor(type), size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (!isRead) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (createdAt.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(createdAt, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'janazah':
        return Icons.info_outline;
      case 'missing':
        return Icons.person_search;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'prayer-times':
      case 'jumuah':
        return Icons.access_time;
      default:
        return Icons.notifications_none;
    }
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/masjid_provider.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final masjid = context.watch<MasjidProvider>();
    final cms = masjid.allCmsData;
    final janazahs = (cms['janazahs'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).where((e) => e['active'] != false).toList() ?? [];
    final gumshudas = (cms['gumshudas'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).where((e) => e['active'] != false).toList() ?? [];
    final announcements = (cms['announcements'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).where((e) => e['active'] != false).toList() ?? [];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Community Alerts', style: Theme.of(context).textTheme.titleLarge),
              Text('Emergency Archives & News', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info), text: 'Janazah'),
              Tab(icon: Icon(Icons.person_search), text: 'Missing'),
              Tab(icon: Icon(Icons.campaign), text: 'News'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(context, janazahs, (item) => _buildJanazahCard(context, item), 'No Janazah records found.'),
            _buildList(context, gumshudas, (item) => _buildGumshudaCard(context, item), 'No missing person reports found.'),
            _buildList(context, announcements, (item) => _buildAnnouncementCard(context, item), 'No news or announcements found.'),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> items, Widget Function(Map<String, dynamic>) builder, String emptyMsg) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(emptyMsg, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: builder(items[i]),
      ),
    );
  }

  Widget _buildJanazahCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (item['active'] == true ? Theme.of(context).colorScheme.error : Colors.grey).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['active'] == true ? 'ACTIVE' : 'ARCHIVED',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: item['active'] == true ? Theme.of(context).colorScheme.error : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item['title'] as String? ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14),
                const SizedBox(width: 4),
                Text(item['time'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 14),
                const SizedBox(width: 4),
                Text(item['location'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGumshudaCard(BuildContext context, Map<String, dynamic> item) {
    final found = item['found'] == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                image: item['image'] != null && (item['image'] as String).isNotEmpty
                    ? DecorationImage(image: (item['image'] as String).startsWith('http') ? NetworkImage(item['image'] as String) : MemoryImage(base64Decode(item['image'] as String)), fit: BoxFit.cover)
                    : null,
              ),
              child: found ? const Icon(Icons.check_circle, color: Colors.green, size: 32) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: found ? Colors.green.withValues(alpha: 0.2) : (item['active'] == true ? Colors.amber.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      found ? 'RESOLVED / FOUND' : (item['active'] == true ? 'Active Alert' : 'Archived'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: found ? Colors.green : (item['active'] == true ? Colors.amber : Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(item['title'] as String? ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: found ? TextDecoration.lineThrough : null,
                  )),
                  const SizedBox(height: 4),
                  Text(item['details'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 2),
                  const SizedBox(height: 8),
                  if (found)
                    Text('Alhamdulillah, person has been found.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.w600))
                  else
                    Text('Call: ${item['contact'] as String? ?? ''}', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w600,
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(item['icon'] as String?), size: 18, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (item['active'] == true ? Colors.green : Colors.grey).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['active'] == true ? 'LIVE' : 'ARCHIVED',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: item['active'] == true ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item['title'] as String? ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(item['description'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String? icon) {
    switch (icon) {
      case 'Megaphone': return Icons.campaign;
      case 'Heart': return Icons.favorite;
      case 'Sparkles': return Icons.auto_awesome;
      case 'Users': return Icons.people;
      default: return Icons.info;
    }
  }
}

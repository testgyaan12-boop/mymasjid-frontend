import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/masjid_provider.dart';
import '../widgets/cards/prayer_times_card.dart';
import '../widgets/cards/ramadan_schedule_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final masjid = context.watch<MasjidProvider>();
    final cms = masjid.allCmsData;
    final janazahs = (cms['janazahs'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).where((e) => e['active'] != false).toList() ?? [];
    final gumshudas = (cms['gumshudas'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).where((e) => e['active'] != false).toList() ?? [];

    final alerts = _buildAlerts(context, janazahs, gumshudas);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alerts.isNotEmpty) ...[
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => alerts[i],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const PrayerTimesCard(),
          const SizedBox(height: 14),
          const RamadanScheduleCard(),
        ],
      ),
    );
  }

  List<Widget> _buildAlerts(BuildContext context, List<Map<String, dynamic>> janazahs, List<Map<String, dynamic>> gumshudas) {
    final items = <_AlertItem>[];

    for (final j in janazahs) {
      if (j['active'] == true) {
        items.add(_AlertItem(type: 'janazah', data: j, icon: Icons.info, color: Theme.of(context).colorScheme.error, label: 'Janazah'));
      }
    }
    for (final g in gumshudas) {
      if (g['active'] == true && g['found'] != true) {
        items.add(_AlertItem(type: 'gumshuda', data: g, icon: Icons.person_search, color: Colors.amber.shade700, label: 'Missing'));
      }
    }

    items.sort((a, b) => ((b.data['id'] as int?) ?? 0).compareTo((a.data['id'] as int?) ?? 0));
    final top5 = items.take(5).toList();

    return top5.map((item) {
      final img = item.data['image'] as String?;
      final title = item.data['title'] as String? ?? (item.type == 'janazah' ? 'Janazah Prayer' : 'Missing Person');
      final subtitle = item.type == 'janazah'
          ? '${item.data['time'] as String? ?? ''}  •  ${item.data['location'] as String? ?? ''}'
          : 'Contact: ${item.data['contact'] as String? ?? ''}';

      return SizedBox(
        width: 280,
        child: InkWell(
          onTap: () => context.go('/alerts'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.color.withValues(alpha: 0.12), item.color.withValues(alpha: 0.03)],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: item.color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                img != null && img.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(width: 40, height: 40,
                          child: img.startsWith('http')
                              ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(item.icon, size: 20, color: item.color))
                              : Image.memory(base64Decode(img), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(item.icon, size: 20, color: item.color)),
                        ),
                      )
                    : Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: item.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11, color: item.color), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: item.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(item.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: item.color, fontWeight: FontWeight.w700, fontSize: 9)),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _AlertItem {
  final String type;
  final Map<String, dynamic> data;
  final IconData icon;
  final Color color;
  final String label;
  const _AlertItem({required this.type, required this.data, required this.icon, required this.color, required this.label});
}

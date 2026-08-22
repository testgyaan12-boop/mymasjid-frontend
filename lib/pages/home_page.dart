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
    final announcements = (cms['announcements'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).where((e) => e['active'] != false).toList() ?? [];

    final alerts = _buildAlerts(context, janazahs, gumshudas, announcements);

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
          const SizedBox(height: 12),
          _QuickActionsRow(),
          const SizedBox(height: 14),
          const RamadanScheduleCard(),
        ],
      ),
    );
  }

  List<Widget> _buildAlerts(BuildContext context, List<Map<String, dynamic>> janazahs, List<Map<String, dynamic>> gumshudas, List<Map<String, dynamic>> announcements) {
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
    for (final a in announcements) {
      if (a['active'] == true) {
        items.add(_AlertItem(type: 'announcement', data: a, icon: Icons.campaign, color: Colors.green, label: 'News'));
      }
    }

    items.sort((a, b) {
      final aId = int.tryParse('${a.data['id']}') ?? 0;
      final bId = int.tryParse('${b.data['id']}') ?? 0;
      return bId.compareTo(aId);
    });
    final top5 = items.take(5).toList();

    return top5.map((item) {
      final img = item.data['image'] as String?;
      final title = item.data['title'] as String? ?? (item.type == 'janazah' ? 'Janazah Prayer' : item.type == 'gumshuda' ? 'Missing Person' : 'News');
      final subtitle = item.type == 'janazah'
          ? '${item.data['time'] as String? ?? ''}  •  ${item.data['location'] as String? ?? ''}'
          : item.type == 'gumshuda'
              ? 'Contact: ${item.data['contact'] as String? ?? ''}'
              : (item.data['description'] as String? ?? '');

      return SizedBox(
        width: 280,
        child: InkWell(
          onTap: () {
            final route = item.type == 'janazah'
                ? '/alerts?tab=janazah'
                : item.type == 'gumshuda'
                    ? '/alerts?tab=missing'
                    : '/alerts?tab=news';
            context.go(route);
          },
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

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget item(IconData icon, String label, String route, List<Color> grad, Color iconBg) {
      return Expanded(
        child: InkWell(
          onTap: () => context.push(route),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: grad.first.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Row(
            children: [
              Container(width: 3, height: 16, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text('Quick Actions', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.3)),
            ],
          ),
        ),
        Row(
          children: [
            item(Icons.campaign_rounded, 'Alert', '/alerts', [const Color(0xFFD4AF37), const Color(0xFFB8941F)], const Color(0xFFD4AF37)),
            const SizedBox(width: 8),
            item(Icons.calculate_rounded, 'Zakaat', '/zakat', [const Color(0xFF10B981), const Color(0xFF059669)], const Color(0xFF10B981)),
            const SizedBox(width: 8),
            item(Icons.event_rounded, 'Event', '/events', [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], const Color(0xFF8B5CF6)),
          ],
        ),
      ],
    );
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

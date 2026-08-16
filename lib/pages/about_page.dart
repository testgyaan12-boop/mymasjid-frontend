import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/masjid_provider.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final masjid = context.watch<MasjidProvider>();
    final cms = masjid.allCmsData;
    final current = masjid.currentMasjid ?? {};
    final masjidName = current['name'] as String? ?? 'Our Masjid';
    final aboutText = current['about'] as String? ?? '';
    final visionText = current['vision'] as String? ?? '';
    final team = (cms['teamMembers'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final services = (cms['services'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];

    final sadr = _byRole(team, ['Sadr']);
    final imamMuzzinTeachers = team.where((m) {
      final r = (m['role'] as String? ?? '').toLowerCase();
      return r.contains('imam') || r.contains('muzzin') || r.contains('teacher') || r.contains('secretary');
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text('About Us', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 4),
                Text(masjidName, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), Theme.of(context).cardColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(child: Icon(Icons.mosque, size: 64)),
          ),
          const SizedBox(height: 20),

          if (aboutText.isNotEmpty) ...[
            Text(aboutText, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(child: _buildInfoCard(context, 'Our Vision', visionText.isEmpty ? 'Serving the community with faith, knowledge, and compassion.' : visionText, Theme.of(context).colorScheme.secondary)),
              const SizedBox(width: 12),
              Expanded(child: _buildInfoCard(context, 'Our Values', 'Rooted in the Quran and Sunnah, we prioritize excellence (Ihsan), inclusivity, and compassion.', Theme.of(context).colorScheme.primary)),
            ],
          ),

          const SizedBox(height: 24),

          if (services.isNotEmpty) ...[
            Center(
              child: Column(
                children: [
                  Text('Our Services', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  Text('Community Facilities', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: services.length,
              itemBuilder: (_, i) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary, size: 32),
                      const SizedBox(height: 8),
                      Text(services[i]['title'] as String? ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(services[i]['description'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 2),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          if (team.isNotEmpty) ...[
            Center(
              child: Column(
                children: [
                  Text('Masjid Management', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  Text('Leadership Team', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (sadr.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(child: _buildTeamCard(context, sadr[0])),
                  if (sadr.length > 1) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _buildTeamCard(context, sadr[1])),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (imamMuzzinTeachers.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: imamMuzzinTeachers.length,
                itemBuilder: (_, i) => _buildTeamCard(context, imamMuzzinTeachers[i]),
              ),
          ],

          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Text('Get in Touch', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                Text('Reach out to us', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildContactCard(context, Icons.location_on, 'Visit Us', current['address'] as String? ?? '123 Peace Avenue, Serenity City', Theme.of(context).colorScheme.primary)),
              const SizedBox(width: 8),
              Expanded(child: _buildContactCard(context, Icons.phone, 'Call Us', current['phone'] as String? ?? '+91 98450 12345', Theme.of(context).colorScheme.secondary)),
              const SizedBox(width: 8),
              Expanded(child: _buildContactCard(context, Icons.email, 'Email Us', current['email'] as String? ?? 'info@nooralmasjid.com', Theme.of(context).colorScheme.primary)),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Share.share(
                'Assalamu Alaykum! Join our community portal for Quran reading, Tasbih, Prayer times, and more.\n${GoRouterState.of(context).uri}',
              ),
              icon: const Icon(Icons.share),
              label: const Text('Share the App Link', style: TextStyle(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _byRole(List<Map<String, dynamic>> team, List<String> keywords) {
    return team.where((m) {
      final r = (m['role'] as String? ?? '').toLowerCase();
      return keywords.any((k) => r.contains(k.toLowerCase()));
    }).toList();
  }

  Widget _buildInfoCard(BuildContext context, String title, String desc, Color accent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: accent, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(desc, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, Map<String, dynamic> member) {
    final image = member['image'] as String? ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            GestureDetector(
              onTap: image.isNotEmpty ? () => _showImageZoom(context, image, member['name'] as String? ?? '') : null,
              child: CircleAvatar(
                radius: 34,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                backgroundImage: image.isNotEmpty
                    ? (image.startsWith('http') ? NetworkImage(image) : MemoryImage(base64Decode(image)))
                    : null,
                child: image.isEmpty ? Icon(Icons.person, color: Theme.of(context).colorScheme.secondary, size: 34) : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(member['name'] as String? ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(member['role'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.secondary), textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }

  void _showImageZoom(BuildContext context, String image, String title) {
    final Widget img = image.startsWith('http')
        ? Image.network(image, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60))
        : Image.memory(base64Decode(image), fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60));
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: img,
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.primary),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
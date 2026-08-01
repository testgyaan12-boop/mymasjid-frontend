import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../providers/masjid_provider.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final masjid = context.watch<MasjidProvider>();
    final cms = masjid.allCmsData;
    final team = (cms['teamMembers'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final services = (cms['services'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text('About Us', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 4),
                Text('Our Journey & Mission', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hero
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

          // Vision & Values
          Text(
            'Noor Al Masjid was established with the vision of creating a lighthouse for the community—a place where spiritual growth, intellectual enlightenment, and communal harmony converge.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildInfoCard(context, 'Our Vision', 'To be a leading center for Islamic learning and practice.', Theme.of(context).colorScheme.secondary)),
              const SizedBox(width: 12),
              Expanded(child: _buildInfoCard(context, 'Our Values', 'Rooted in the Quran and Sunnah, we prioritize excellence (Ihsan), inclusivity, and compassion.', Theme.of(context).colorScheme.primary)),
            ],
          ),

          const SizedBox(height: 24),

          // Services
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

          // Team
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
            ...team.map((m) => _buildTeamMember(context, m)),
          ],

          const SizedBox(height: 24),

          // Contact
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
              Expanded(child: _buildContactCard(context, Icons.location_on, 'Visit Us', '123 Peace Avenue, Serenity City', Theme.of(context).colorScheme.primary)),
              const SizedBox(width: 8),
              Expanded(child: _buildContactCard(context, Icons.phone, 'Call Us', '+91 98450 12345', Theme.of(context).colorScheme.secondary)),
              const SizedBox(width: 8),
              Expanded(child: _buildContactCard(context, Icons.email, 'Email Us', 'info@nooralmasjid.com', Theme.of(context).colorScheme.primary)),
            ],
          ),

          const SizedBox(height: 24),

          // Share
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

  Widget _buildTeamMember(BuildContext context, Map<String, dynamic> member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(Icons.person, color: Theme.of(context).colorScheme.secondary),
        ),
        title: Text(member['name'] as String? ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(member['role'] as String? ?? ''),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showMemberDetail(context, member),
      ),
    );
  }

  void _showMemberDetail(BuildContext context, Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member['name'] as String? ?? '', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(member['role'] as String? ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.email, size: 16),
                const SizedBox(width: 8),
                Text(member['email'] as String? ?? ''),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 8),
                Text(member['mobile'] as String? ?? ''),
              ],
            ),
            if (member['responsibilities'] != null) ...[
              const SizedBox(height: 16),
              Text('Responsibilities', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...(member['responsibilities'] as List<dynamic>).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(r as String? ?? ''),
                  ],
                ),
              )),
            ],
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

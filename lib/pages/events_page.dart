import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _events = [
  {
    'id': '1',
    'title': 'Youth Islamic Workshop',
    'date': 'Sunday, March 15, 2025',
    'time': '10:30 AM - 01:00 PM',
    'location': 'Main Assembly Hall',
    'organizer': 'Noor Youth Committee',
    'category': 'Education',
    'image': 'https://picsum.photos/seed/event1/800/400',
  },
  {
    'id': '2',
    'title': 'Community Health Camp',
    'date': 'Saturday, March 21, 2025',
    'time': '09:00 AM - 04:00 PM',
    'location': 'Masjid Basement Clinic',
    'organizer': 'Welfare Department',
    'category': 'Community',
    'image': 'https://picsum.photos/seed/event2/800/400',
  },
  {
    'id': '3',
    'title': 'Ramadan Prep Lecture',
    'date': 'Friday, March 27, 2025',
    'time': 'After Isha',
    'location': 'Main Hall',
    'organizer': 'Dawah Office',
    'category': 'Religious',
    'image': 'https://picsum.photos/seed/event3/800/400',
  },
];

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upcoming Events', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  Text('Community Programs', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._events.map((e) => _buildEventCard(context, e)),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '"The best of people are those that bring most benefit to the rest of mankind."\n— Prophet Muhammad (PBUH)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                event['image'] as String? ?? '',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 160, color: Theme.of(context).colorScheme.surfaceContainerHighest),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(event['category'] as String? ?? '', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                  )),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['title'] as String? ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.calendar_today, event['date'] as String? ?? ''),
                        const SizedBox(height: 8),
                        _buildInfoRow(context, Icons.access_time, event['time'] as String? ?? ''),
                        const SizedBox(height: 8),
                        _buildInfoRow(context, Icons.location_on, event['location'] as String? ?? ''),
                        const SizedBox(height: 8),
                        _buildInfoRow(context, Icons.person, 'By: ${event['organizer'] as String? ?? ''}'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    ),
                    child: const Text('Remind Me', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
      ],
    );
  }
}

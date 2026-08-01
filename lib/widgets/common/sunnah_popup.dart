import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../services/cms_service.dart';
import '../../services/user_service.dart';
import 'sign_in_popup.dart';

class SunnahPopup extends StatefulWidget {
  const SunnahPopup({super.key});

  @override
  State<SunnahPopup> createState() => _SunnahPopupState();
}

class _SunnahPopupState extends State<SunnahPopup> {
  Map<String, dynamic>? _sunnah;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkBroadcast();
  }

  Future<void> _checkBroadcast() async {
    try {
      final cms = CmsService();
      final broadcast = await cms.getSunnahBroadcast();
      final sunnah = broadcast['sunnah'] as Map<String, dynamic>?;
      if (sunnah != null) {
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getBool('sunnah_seen_${sunnah['id']}') ?? false;
        if (!seen) {
          setState(() { _sunnah = sunnah; _loading = false; });
          return;
        }
      }
    } catch (_) {
      // Fallback: check localStorage equivalent
      // Not available in web fallback, skip
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveSunnah() async {
    if (_sunnah == null) return;
    if (!context.read<AuthProvider>().isAuthenticated) {
      final ok = await ensureSignedIn(context, action: 'sunnahs');
      if (!ok) {
        _dismiss();
        return;
      }
      return;
    }
    try {
      await UserService().saveSunnah(_sunnah!['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to profile!')),
        );
      }
    } catch (_) {
      // Fallback via localStorage
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('user_saved_sunnahs') ?? [];
      saved.add(_sunnah!.toString());
      await prefs.setStringList('user_saved_sunnahs', saved);
    }
    _dismiss();
  }

  void _dismiss() async {
    if (_sunnah != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sunnah_seen_${_sunnah!['id']}', true);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _sunnah == null) return const SizedBox.shrink();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Daily Sunnah Broadcast',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _sunnah!['title'] as String? ?? '',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '"${_sunnah!['text'] as String? ?? ''}"',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (_sunnah!['reference'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Source: ${_sunnah!['reference']}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSunnah,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save to My Profile', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            TextButton(
              onPressed: _dismiss,
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

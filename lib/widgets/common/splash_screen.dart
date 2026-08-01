import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileSplash extends StatefulWidget {
  final Widget child;
  const MobileSplash({super.key, required this.child});

  @override
  State<MobileSplash> createState() => _MobileSplashState();
}

class _MobileSplashState extends State<MobileSplash> with SingleTickerProviderStateMixin {
  bool _showSplash = false;

  @override
  void initState() {
    super.initState();
    _checkSplash();
  }

  Future<void> _checkSplash() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('splash_seen') ?? false;
    if (!seen) {
      setState(() => _showSplash = true);
      await prefs.setBool('splash_seen', true);
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) setState(() => _showSplash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showSplash)
          Container(
            color: const Color(0xFF0A1A0A),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'لا إله إلا الله محمد رسول الله',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      fontFamily: 'Alegreya',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Noor Al Masjid',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'REFINING THE SOUL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white60,
                      letterSpacing: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_constants.dart';
import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);
  String _status = 'Bootstrapping workbench';

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      setState(() => _status = 'Preparing storage');
      await ref.read(storageServiceProvider).initialize();

      setState(() => _status = 'Loading settings');
      await ref.read(settingsControllerProvider).initialize();

      setState(() => _status = 'Bringing up BLE runtime');
      await ref.read(bleControllerProvider).initialize();

      setState(() => _status = 'Loading session archive');
      await ref.read(sessionControllerProvider).loadSessions();

      await Future<void>.delayed(const Duration(milliseconds: AppConstants.splashDelayMs));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _status = error.toString());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.background, AppTheme.backgroundAlt],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.92 + (_controller.value * 0.08),
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [AppTheme.neonGreen, AppTheme.panelAlt],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonGreen.withValues(alpha: 0.35),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.watch_rounded, size: 54, color: AppTheme.background),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appTagline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    _status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

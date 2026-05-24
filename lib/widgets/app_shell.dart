import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
    this.floatingActionButton,
  });

  final String currentRoute;
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  static const _destinations = [
    _ShellDestination(AppRoutes.dashboard, 'Dashboard', Icons.grid_view_rounded),
    _ShellDestination(AppRoutes.scanner, 'Scanner', Icons.radar_rounded),
    _ShellDestination(AppRoutes.connectedDevice, 'Device', Icons.watch_rounded),
    _ShellDestination(AppRoutes.services, 'Services', Icons.hub_rounded),
    _ShellDestination(AppRoutes.packetLogger, 'Packets', Icons.memory_rounded),
    _ShellDestination(AppRoutes.otaUpload, 'OTA', Icons.system_update_alt_rounded),
    _ShellDestination(AppRoutes.watchFaceUpload, 'Watch Face', Icons.palette_rounded),
    _ShellDestination(AppRoutes.firmwareAnalyzer, 'Analyzer', Icons.analytics_rounded),
    _ShellDestination(AppRoutes.bleConsole, 'Console', Icons.terminal_rounded),
    _ShellDestination(AppRoutes.savedSessions, 'Sessions', Icons.save_rounded),
    _ShellDestination(AppRoutes.logs, 'Logs', Icons.receipt_long_rounded),
    _ShellDestination(AppRoutes.settings, 'Settings', Icons.tune_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _destinations.indexWhere((destination) => destination.route == currentRoute);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final wideLayout = screenWidth >= 1160;
    final compactHeader = screenWidth < 720;
    final contentPadding = screenWidth >= 1400 ? 28.0 : screenWidth >= 860 ? 22.0 : 16.0;
    final content = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.background, AppTheme.backgroundAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: _ShellBackdropPainter(),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(contentPadding, 14, contentPadding, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.panel.withValues(alpha: 0.95),
                      AppTheme.panelAlt.withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderStrong.withValues(alpha: 0.26)),
                  ),
                ),
                child: compactHeader
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!wideLayout)
                                Builder(
                                  builder: (innerContext) => IconButton(
                                    onPressed: () => Scaffold.of(innerContext).openDrawer(),
                                    icon: const Icon(Icons.menu_rounded),
                                  ),
                                ),
                              Expanded(child: _ShellTitle(title: title, subtitle: subtitle)),
                            ],
                          ),
                          if (actions.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(spacing: 8, runSpacing: 8, children: actions),
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          if (!wideLayout)
                            Builder(
                              builder: (innerContext) => IconButton(
                                onPressed: () => Scaffold.of(innerContext).openDrawer(),
                                icon: const Icon(Icons.menu_rounded),
                              ),
                            ),
                          Expanded(child: _ShellTitle(title: title, subtitle: subtitle)),
                          if (actions.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: actions),
                          ],
                        ],
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(contentPadding, 18, contentPadding, 12),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (wideLayout) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundAlt,
                border: Border(
                  right: BorderSide(color: AppTheme.borderStrong.withValues(alpha: 0.2)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonGreen.withValues(alpha: 0.08),
                    blurRadius: 24,
                    spreadRadius: -16,
                    offset: const Offset(8, 0),
                  ),
                ],
              ),
              child: NavigationRail(
                selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (index) => _navigate(context, _destinations[index].route),
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppTheme.panelRaised,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderStrong.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.watch_rounded, color: AppTheme.neonGreen),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'OTA\nLAB',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.neonGreen),
                      ),
                    ],
                  ),
                ),
                destinations: _destinations
                    .map(
                      (destination) => NavigationRailDestination(
                        icon: Icon(destination.icon),
                        label: Text(destination.label),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(child: content),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.panelRaised.withValues(alpha: 0.96),
                    AppTheme.backgroundAlt,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderStrong.withValues(alpha: 0.18)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'OTACracker',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'BLE smartwatch OTA workbench',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            for (final destination in _destinations)
              ListTile(
                leading: Icon(destination.icon),
                title: Text(destination.label),
                selected: destination.route == currentRoute,
                onTap: () {
                  Navigator.of(context).pop();
                  _navigate(context, destination.route);
                },
              ),
          ],
        ),
      ),
      body: Builder(builder: (context) => content),
      floatingActionButton: floatingActionButton,
    );
  }

  void _navigate(BuildContext context, String route) {
    if (route == currentRoute) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }
}

class _ShellDestination {
  const _ShellDestination(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}

class _ShellTitle extends StatelessWidget {
  const _ShellTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _ShellBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppTheme.border.withValues(alpha: 0.18);
    const step = 36.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x332BFF7A),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.82, size.height * 0.12),
          radius: size.shortestSide * 0.34,
        ),
      );
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

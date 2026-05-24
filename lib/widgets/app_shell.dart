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
    final wideLayout = MediaQuery.sizeOf(context).width >= 1120;
    final content = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.background, AppTheme.backgroundAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  if (!wideLayout)
                    Builder(
                      builder: (innerContext) => IconButton(
                        onPressed: () => Scaffold.of(innerContext).openDrawer(),
                        icon: const Icon(Icons.menu_rounded),
                      ),
                    ),
                  Expanded(
                    child: Column(
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
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );

    if (wideLayout) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (index) => _navigate(context, _destinations[index].route),
              destinations: _destinations
                  .map(
                    (destination) => NavigationRailDestination(
                      icon: Icon(destination.icon),
                      label: Text(destination.label),
                    ),
                  )
                  .toList(),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.panelAlt, AppTheme.backgroundAlt],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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

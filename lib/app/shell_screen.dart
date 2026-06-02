import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:upgrader/upgrader.dart';

import '../core/l10n/app_localizations.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late final Upgrader _upgrader;

  @override
  void initState() {
    super.initState();
    _upgrader = Upgrader(
      storeController: UpgraderStoreController(
        onAndroid: () => UpgraderPlayStore(),
        oniOS: () => UpgraderAppStore(),
      ),
      durationUntilAlertAgain: const Duration(days: 1),
      willDisplayUpgrade: ({
        required display,
        installedVersion,
        versionInfo,
      }) {
        debugPrint('Update available: $versionInfo');
      },
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/timer')) return 2;
    if (location.startsWith('/progress')) return 3;
    if (location.startsWith('/body')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/history');
        break;
      case 2:
        context.go('/timer');
        break;
      case 3:
        context.go('/progress');
        break;
      case 4:
        context.go('/body');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return UpgradeAlert(
      upgrader: _upgrader,
      dialogStyle: UpgradeDialogStyle.cupertino,
      showIgnore: true,
      showLater: true,
      cupertinoButtonTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _calculateSelectedIndex(context),
          onTap: (index) => _onItemTapped(context, index),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_month),
              label: l10n.navHistory,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.timer),
              label: l10n.navTimer,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart),
              label: l10n.navProgress,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: l10n.navBody,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/workout/presentation/home_screen.dart';
import '../features/workout/presentation/history_screen.dart';
import '../features/workout/presentation/session_screen.dart';
import '../features/timer/presentation/timer_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/body/presentation/body_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'shell_screen.dart';
import 'splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryScreen(),
          ),
        ),
        GoRoute(
          path: '/timer',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TimerScreen(),
          ),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProgressScreen(),
          ),
        ),
        GoRoute(
          path: '/body',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BodyScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/session/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final sessionId = state.pathParameters['id']!;
        return SessionScreen(sessionId: sessionId);
      },
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

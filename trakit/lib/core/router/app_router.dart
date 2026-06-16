import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/providers.dart';
import '../../features/add_expense/add_expense_screen.dart';
import '../../features/add_expense/quick_add_screen.dart';
import '../../features/detail/transaction_detail_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/scanner/screenshot_scanner_screen.dart';
import '../../features/scanner/gmail_sync_screen.dart';
import '../../features/scanner/receipt_scanner_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/timeline/timeline_screen.dart';
import '../../features/home/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(storageProvider);
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/timeline',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: TimelineScreen()),
          ),
          GoRoute(
            path: '/insights',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: InsightsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/add',
        builder: (_, __) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: '/add/quick',
        builder: (_, __) => const QuickAddScreen(),
      ),
      GoRoute(
        path: '/add/screenshot',
        builder: (_, __) => const ScreenshotScannerScreen(),
      ),
      GoRoute(
        path: '/add/gmail',
        builder: (_, __) => const GmailSyncScreen(),
      ),
      GoRoute(
        path: '/add/receipt',
        builder: (_, __) => const ReceiptScannerScreen(),
      ),
      GoRoute(
        path: '/transaction/:id',
        builder: (_, state) =>
            TransactionDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;
      if (loc == '/onboarding') return null;
      if (!storage.hasOnboarded) return '/onboarding';
      return null;
    },
  );
});

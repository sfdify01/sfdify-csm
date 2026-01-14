import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/core/router/route_names.dart';
import 'package:sfdify_scm/features/dispute/presentation/pages/dispute_overview_page.dart';
import 'package:sfdify_scm/features/home/presentation/pages/home_page.dart';
import 'package:sfdify_scm/shared/presentation/layout/main_layout.dart';

class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,
    routes: _routes,
    errorBuilder: _errorBuilder,
  );

  List<RouteBase> get _routes => [
        // Shell route wraps all pages with MainLayout (includes sidebar)
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: RoutePaths.home,
              name: RouteNames.home,
              pageBuilder: (context, state) => NoTransitionPage(
                child: const HomePage(),
              ),
            ),
            GoRoute(
              path: RoutePaths.disputeOverview,
              name: RouteNames.disputeOverview,
              pageBuilder: (context, state) => NoTransitionPage(
                child: const DisputeOverviewPage(),
              ),
            ),
          ],
        ),
      ];

  Widget _errorBuilder(BuildContext context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

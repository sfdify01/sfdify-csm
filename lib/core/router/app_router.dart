import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/core/router/route_names.dart';
import 'package:sfdify_scm/features/home/presentation/pages/home_page.dart';

class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,
    routes: _routes,
    errorBuilder: _errorBuilder,
  );

  List<RouteBase> get _routes => [
        GoRoute(
          path: RoutePaths.home,
          name: RouteNames.home,
          builder: (context, state) => const HomePage(),
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

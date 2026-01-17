import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/core/router/route_names.dart';
import 'package:sfdify_scm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sfdify_scm/features/auth/presentation/pages/login_page.dart';
import 'package:sfdify_scm/features/auth/presentation/pages/register_page.dart';
import 'package:sfdify_scm/features/dispute/presentation/pages/dispute_overview_page.dart';
import 'package:sfdify_scm/features/home/presentation/pages/home_page.dart';
import 'package:sfdify_scm/injection/injection.dart';
import 'package:sfdify_scm/shared/presentation/layout/main_layout.dart';

/// Listenable that triggers router refresh when stream emits
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: RoutePaths.login,
    debugLogDiagnostics: true,
    routes: _routes,
    errorBuilder: _errorBuilder,
    redirect: _authRedirect,
    refreshListenable: GoRouterRefreshStream(
      getIt<AuthBloc>().stream.map((state) => state.status),
    ),
  );

  /// Public routes that don't require authentication
  static const _publicRoutes = [
    RoutePaths.login,
    RoutePaths.register,
  ];

  /// Redirect based on authentication state
  String? _authRedirect(BuildContext context, GoRouterState state) {
    final authBloc = getIt<AuthBloc>();
    final authState = authBloc.state;
    final currentPath = state.matchedLocation;
    final isPublicRoute = _publicRoutes.contains(currentPath);
    final isAuthenticated = authState.status == AuthStatus.authenticated;

    // If not authenticated and not on a public route, redirect to login
    if (!isAuthenticated && !isPublicRoute) {
      return RoutePaths.login;
    }

    // If authenticated and on login/register page, redirect to home
    if (isAuthenticated &&
        (currentPath == RoutePaths.login ||
            currentPath == RoutePaths.register)) {
      return RoutePaths.home;
    }

    return null;
  }

  List<RouteBase> get _routes => [
        // Auth routes (outside shell - no sidebar)
        GoRoute(
          path: RoutePaths.login,
          name: RouteNames.login,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LoginPage(),
          ),
        ),
        GoRoute(
          path: RoutePaths.register,
          name: RouteNames.register,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RegisterPage(),
          ),
        ),

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

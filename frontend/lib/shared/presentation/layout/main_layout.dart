import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustaxx_csm/shared/presentation/widgets/app_navigation_sidebar.dart';

/// Main layout wrapper that adds the navigation sidebar to pages
///
/// This creates a 3-column layout: sidebar | content | (optional right sidebar in page)
class MainLayout extends StatelessWidget {
  const MainLayout({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Get current route for sidebar active state
    final currentRoute = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Row(
        children: [
          // Left Navigation Sidebar
          AppNavigationSidebar(currentRoute: currentRoute),

          // Main content area
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}

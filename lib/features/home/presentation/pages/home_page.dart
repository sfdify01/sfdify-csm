import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sfdify_scm/core/constants/app_constants.dart';
import 'package:sfdify_scm/core/router/route_names.dart';
import 'package:sfdify_scm/features/home/presentation/bloc/home_bloc.dart';
import 'package:sfdify_scm/features/home/presentation/widgets/home_card.dart';
import 'package:sfdify_scm/injection/injection.dart';
import 'package:sfdify_scm/shared/presentation/bloc/theme/theme_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeBloc>()..add(const HomeLoadRequested()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  switch (state.themeMode) {
                    ThemeMode.light => Icons.light_mode,
                    ThemeMode.dark => Icons.dark_mode,
                    ThemeMode.system => Icons.brightness_auto,
                  },
                ),
                onPressed: () {
                  context.read<ThemeBloc>().add(const ThemeToggled());
                },
                tooltip: 'Toggle theme',
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return switch (state.status) {
            HomeStatus.initial || HomeStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
            HomeStatus.failure => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const Gap(16),
                    Text(
                      state.errorMessage ?? 'Something went wrong',
                      textAlign: TextAlign.center,
                    ),
                    const Gap(16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<HomeBloc>()
                            .add(const HomeLoadRequested());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            HomeStatus.success => RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeBloc>().add(const HomeRefreshRequested());
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.data.length + 1, // +1 for dispute card
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (context, index) {
                    // Show dispute navigation card first
                    if (index == 0) {
                      return HomeCard(
                        title: '🔥 Dispute Overview Dashboard',
                        description:
                            'View all disputes, metrics, and recent activity. Click to open the new Dispute Overview page!',
                        onTap: () => context.go(RoutePaths.disputeOverview),
                      );
                    }

                    final item = state.data[index - 1];
                    return HomeCard(
                      title: item.title,
                      description: item.description,
                    );
                  },
                ),
              ),
          };
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustaxx_csm/core/constants/app_constants.dart';
import 'package:ustaxx_csm/core/router/app_router.dart';
import 'package:ustaxx_csm/core/theme/app_theme.dart';
import 'package:ustaxx_csm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ustaxx_csm/injection/injection.dart';
import 'package:ustaxx_csm/shared/presentation/bloc/theme/theme_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<ThemeBloc>(),
        ),
        BlocProvider(
          create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: state.themeMode,
            routerConfig: getIt<AppRouter>().router,
          );
        },
      ),
    );
  }
}

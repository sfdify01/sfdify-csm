import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sfdify_scm/core/constants/app_constants.dart';
import 'package:sfdify_scm/core/router/app_router.dart';
import 'package:sfdify_scm/core/theme/app_theme.dart';
import 'package:sfdify_scm/injection/injection.dart';
import 'package:sfdify_scm/shared/presentation/bloc/theme/theme_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<ThemeBloc>(),
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

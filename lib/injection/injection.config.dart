// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logger/logger.dart' as _i974;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../core/network/dio_client.dart' as _i393;
import '../core/router/app_router.dart' as _i877;
import '../features/home/data/datasources/home_remote_datasource.dart' as _i75;
import '../features/home/data/repositories/home_repository_impl.dart' as _i6;
import '../features/home/domain/repositories/home_repository.dart' as _i66;
import '../features/home/domain/usecases/get_home_data.dart' as _i489;
import '../features/home/presentation/bloc/home_bloc.dart' as _i824;
import '../shared/presentation/bloc/theme/theme_bloc.dart' as _i354;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.singleton<_i974.Logger>(() => registerModule.logger);
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.singleton<_i877.AppRouter>(() => registerModule.appRouter);
    gh.singleton<_i354.ThemeBloc>(() => _i354.ThemeBloc());
    gh.factory<_i75.HomeRemoteDataSource>(
      () => const _i75.HomeRemoteDataSourceImpl(),
    );
    gh.singleton<_i361.Dio>(() => registerModule.dio(gh<_i974.Logger>()));
    gh.factory<_i66.HomeRepository>(
      () => _i6.HomeRepositoryImpl(gh<_i75.HomeRemoteDataSource>()),
    );
    gh.factory<_i489.GetHomeData>(
      () => _i489.GetHomeData(gh<_i66.HomeRepository>()),
    );
    gh.singleton<_i393.DioClient>(
      () => registerModule.dioClient(gh<_i361.Dio>()),
    );
    gh.factory<_i824.HomeBloc>(() => _i824.HomeBloc(gh<_i489.GetHomeData>()));
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_functions/cloud_functions.dart' as _i809;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_analytics/firebase_analytics.dart' as _i398;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_crashlytics/firebase_crashlytics.dart' as _i141;
import 'package:firebase_remote_config/firebase_remote_config.dart' as _i627;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logger/logger.dart' as _i974;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../core/config/feature_flags.dart' as _i316;
import '../core/monitoring/analytics_service.dart' as _i423;
import '../core/monitoring/error_tracker.dart' as _i161;
import '../core/network/dio_client.dart' as _i393;
import '../core/network/network_info.dart' as _i6;
import '../core/router/app_router.dart' as _i877;
import '../core/services/cloud_functions_service.dart' as _i816;
import '../core/services/firebase_auth_service.dart' as _i781;
import '../features/auth/presentation/bloc/auth_bloc.dart' as _i59;
import '../features/consumer/data/datasources/consumer_remote_datasource.dart'
    as _i391;
import '../features/consumer/data/repositories/consumer_repository_impl.dart'
    as _i677;
import '../features/consumer/domain/repositories/consumer_repository.dart'
    as _i236;
import '../features/consumer/domain/usecases/get_consumer.dart' as _i702;
import '../features/consumer/domain/usecases/get_consumers.dart' as _i130;
import '../features/consumer/presentation/bloc/consumer_detail_bloc.dart'
    as _i669;
import '../features/consumer/presentation/bloc/consumer_form_bloc.dart'
    as _i487;
import '../features/consumer/presentation/bloc/consumer_list_bloc.dart'
    as _i219;
import '../features/dispute/data/datasources/dispute_remote_datasource.dart'
    as _i717;
import '../features/dispute/data/repositories/dispute_repository_impl.dart'
    as _i1061;
import '../features/dispute/domain/repositories/dispute_repository.dart'
    as _i328;
import '../features/dispute/domain/usecases/get_dispute.dart' as _i500;
import '../features/dispute/domain/usecases/get_dispute_metrics.dart' as _i620;
import '../features/dispute/domain/usecases/get_disputes.dart' as _i627;
import '../features/dispute/presentation/bloc/dispute_create_bloc.dart'
    as _i793;
import '../features/dispute/presentation/bloc/dispute_detail_bloc.dart' as _i66;
import '../features/dispute/presentation/bloc/dispute_overview_bloc.dart'
    as _i689;
import '../features/evidence/data/datasources/evidence_remote_datasource.dart'
    as _i1023;
import '../features/evidence/data/repositories/evidence_repository_impl.dart'
    as _i282;
import '../features/evidence/domain/repositories/evidence_repository.dart'
    as _i211;
import '../features/evidence/presentation/bloc/evidence_upload_bloc.dart'
    as _i434;
import '../features/home/data/datasources/home_remote_datasource.dart' as _i75;
import '../features/home/data/repositories/home_repository_impl.dart' as _i6;
import '../features/home/domain/repositories/home_repository.dart' as _i66;
import '../features/home/domain/usecases/get_home_data.dart' as _i489;
import '../features/home/presentation/bloc/home_bloc.dart' as _i824;
import '../features/letter/data/datasources/letter_remote_datasource.dart'
    as _i869;
import '../features/letter/data/repositories/letter_repository_impl.dart'
    as _i639;
import '../features/letter/domain/repositories/letter_repository.dart' as _i887;
import '../features/letter/presentation/bloc/letter_detail_bloc.dart' as _i879;
import '../features/letter/presentation/bloc/letter_generate_bloc.dart' as _i53;
import '../features/letter/presentation/bloc/letter_list_bloc.dart' as _i474;
import '../features/tenant/data/datasources/tenant_remote_datasource.dart'
    as _i718;
import '../features/tenant/data/repositories/tenant_repository_impl.dart'
    as _i878;
import '../features/tenant/domain/repositories/tenant_repository.dart' as _i597;
import '../features/users/data/datasources/user_remote_datasource.dart'
    as _i466;
import '../features/users/data/repositories/user_repository_impl.dart' as _i712;
import '../features/users/domain/repositories/user_repository.dart' as _i572;
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
    gh.singleton<_i59.FirebaseAuth>(() => registerModule.firebaseAuth);
    gh.singleton<_i809.FirebaseFunctions>(
      () => registerModule.firebaseFunctions,
    );
    gh.singleton<_i457.FirebaseStorage>(() => registerModule.firebaseStorage);
    gh.singleton<_i398.FirebaseAnalytics>(
      () => registerModule.firebaseAnalytics,
    );
    gh.singleton<_i141.FirebaseCrashlytics>(() => registerModule.crashlytics);
    gh.singleton<_i627.FirebaseRemoteConfig>(() => registerModule.remoteConfig);
    gh.singleton<_i354.ThemeBloc>(() => _i354.ThemeBloc());
    gh.singleton<_i423.AnalyticsService>(
      () => _i423.AnalyticsService(
        gh<_i398.FirebaseAnalytics>(),
        gh<_i974.Logger>(),
      ),
    );
    gh.singleton<_i316.FeatureFlags>(
      () => _i316.FeatureFlags(
        gh<_i627.FirebaseRemoteConfig>(),
        gh<_i974.Logger>(),
      ),
    );
    gh.factory<_i6.NetworkInfo>(() => _i6.NetworkInfoImpl());
    gh.singleton<_i361.Dio>(() => registerModule.dio(gh<_i974.Logger>()));
    gh.singleton<_i816.CloudFunctionsService>(
      () => _i816.CloudFunctionsService(gh<_i809.FirebaseFunctions>()),
    );
    gh.singleton<_i781.FirebaseAuthService>(
      () => _i781.FirebaseAuthService(
        gh<_i59.FirebaseAuth>(),
        gh<_i816.CloudFunctionsService>(),
      ),
    );
    gh.singleton<_i161.ErrorTracker>(
      () => _i161.ErrorTracker(
        gh<_i141.FirebaseCrashlytics>(),
        gh<_i974.Logger>(),
      ),
    );
    gh.factory<_i717.DisputeRemoteDataSource>(
      () =>
          _i717.DisputeRemoteDataSourceImpl(gh<_i816.CloudFunctionsService>()),
    );
    gh.factory<_i466.UserRemoteDataSource>(
      () => _i466.UserRemoteDataSourceImpl(gh<_i816.CloudFunctionsService>()),
    );
    gh.factory<_i75.HomeRemoteDataSource>(
      () => _i75.HomeRemoteDataSourceImpl(gh<_i816.CloudFunctionsService>()),
    );
    gh.singleton<_i393.DioClient>(
      () => registerModule.dioClient(gh<_i361.Dio>()),
    );
    gh.factory<_i869.LetterRemoteDataSource>(
      () => _i869.LetterRemoteDataSourceImpl(gh<_i816.CloudFunctionsService>()),
    );
    gh.factory<_i718.TenantRemoteDataSource>(
      () => _i718.TenantRemoteDataSourceImpl(gh<_i816.CloudFunctionsService>()),
    );
    gh.factory<_i1023.EvidenceRemoteDataSource>(
      () => _i1023.EvidenceRemoteDataSourceImpl(
        gh<_i816.CloudFunctionsService>(),
      ),
    );
    gh.factory<_i391.ConsumerRemoteDataSource>(
      () =>
          _i391.ConsumerRemoteDataSourceImpl(gh<_i816.CloudFunctionsService>()),
    );
    gh.singleton<_i59.AuthBloc>(
      () => _i59.AuthBloc(gh<_i781.FirebaseAuthService>()),
    );
    gh.factory<_i66.HomeRepository>(
      () => _i6.HomeRepositoryImpl(gh<_i75.HomeRemoteDataSource>()),
    );
    gh.factory<_i597.TenantRepository>(
      () => _i878.TenantRepositoryImpl(
        gh<_i718.TenantRemoteDataSource>(),
        gh<_i6.NetworkInfo>(),
      ),
    );
    gh.factory<_i572.UserRepository>(
      () => _i712.UserRepositoryImpl(
        gh<_i466.UserRemoteDataSource>(),
        gh<_i6.NetworkInfo>(),
      ),
    );
    gh.factory<_i328.DisputeRepository>(
      () => _i1061.DisputeRepositoryImpl(
        gh<_i717.DisputeRemoteDataSource>(),
        gh<_i6.NetworkInfo>(),
      ),
    );
    gh.factory<_i500.GetDispute>(
      () => _i500.GetDispute(gh<_i328.DisputeRepository>()),
    );
    gh.factory<_i620.GetDisputeMetrics>(
      () => _i620.GetDisputeMetrics(gh<_i328.DisputeRepository>()),
    );
    gh.factory<_i627.GetDisputes>(
      () => _i627.GetDisputes(gh<_i328.DisputeRepository>()),
    );
    gh.factory<_i489.GetHomeData>(
      () => _i489.GetHomeData(gh<_i66.HomeRepository>()),
    );
    gh.factory<_i236.ConsumerRepository>(
      () => _i677.ConsumerRepositoryImpl(
        gh<_i391.ConsumerRemoteDataSource>(),
        gh<_i6.NetworkInfo>(),
      ),
    );
    gh.factory<_i887.LetterRepository>(
      () => _i639.LetterRepositoryImpl(
        gh<_i869.LetterRemoteDataSource>(),
        gh<_i6.NetworkInfo>(),
      ),
    );
    gh.factory<_i211.EvidenceRepository>(
      () => _i282.EvidenceRepositoryImpl(
        gh<_i1023.EvidenceRemoteDataSource>(),
        gh<_i6.NetworkInfo>(),
      ),
    );
    gh.factory<_i66.DisputeDetailBloc>(
      () => _i66.DisputeDetailBloc(
        gh<_i500.GetDispute>(),
        gh<_i328.DisputeRepository>(),
      ),
    );
    gh.factory<_i702.GetConsumer>(
      () => _i702.GetConsumer(gh<_i236.ConsumerRepository>()),
    );
    gh.factory<_i130.GetConsumers>(
      () => _i130.GetConsumers(gh<_i236.ConsumerRepository>()),
    );
    gh.factory<_i487.ConsumerFormBloc>(
      () => _i487.ConsumerFormBloc(gh<_i236.ConsumerRepository>()),
    );
    gh.factory<_i824.HomeBloc>(() => _i824.HomeBloc(gh<_i489.GetHomeData>()));
    gh.factory<_i879.LetterDetailBloc>(
      () => _i879.LetterDetailBloc(gh<_i887.LetterRepository>()),
    );
    gh.factory<_i474.LetterListBloc>(
      () => _i474.LetterListBloc(gh<_i887.LetterRepository>()),
    );
    gh.factory<_i219.ConsumerListBloc>(
      () => _i219.ConsumerListBloc(gh<_i130.GetConsumers>()),
    );
    gh.factory<_i689.DisputeOverviewBloc>(
      () => _i689.DisputeOverviewBloc(
        gh<_i620.GetDisputeMetrics>(),
        gh<_i627.GetDisputes>(),
      ),
    );
    gh.factory<_i53.LetterGenerateBloc>(
      () => _i53.LetterGenerateBloc(
        gh<_i887.LetterRepository>(),
        gh<_i328.DisputeRepository>(),
      ),
    );
    gh.factory<_i669.ConsumerDetailBloc>(
      () => _i669.ConsumerDetailBloc(gh<_i702.GetConsumer>()),
    );
    gh.factory<_i434.EvidenceUploadBloc>(
      () => _i434.EvidenceUploadBloc(gh<_i211.EvidenceRepository>()),
    );
    gh.factory<_i793.DisputeCreateBloc>(
      () => _i793.DisputeCreateBloc(
        gh<_i130.GetConsumers>(),
        gh<_i328.DisputeRepository>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

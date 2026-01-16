import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/error/exceptions.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/core/network/network_info.dart';
import 'package:sfdify_scm/features/tenant/data/datasources/tenant_remote_datasource.dart';
import 'package:sfdify_scm/features/tenant/domain/entities/tenant_entity.dart';
import 'package:sfdify_scm/features/tenant/domain/repositories/tenant_repository.dart';

@Injectable(as: TenantRepository)
class TenantRepositoryImpl implements TenantRepository {
  final TenantRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  TenantRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, TenantEntity>> getTenant() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final tenant = await _remoteDataSource.getTenant();
      return Right(tenant);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TenantEntity>> updateTenant(
    Map<String, dynamic> updates,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final tenant = await _remoteDataSource.updateTenant(updates);
      return Right(tenant);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TenantEntity>> updateBranding({
    String? logoUrl,
    String? primaryColor,
    String? companyName,
    String? tagline,
  }) async {
    final updates = <String, dynamic>{
      'branding': {
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (primaryColor != null) 'primaryColor': primaryColor,
        if (companyName != null) 'companyName': companyName,
        if (tagline != null) 'tagline': tagline,
      },
    };

    return updateTenant(updates);
  }
}

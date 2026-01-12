import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/error/exceptions.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/core/network/network_info.dart';
import 'package:sfdify_scm/features/dispute/data/datasources/dispute_remote_datasource.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:sfdify_scm/features/dispute/domain/repositories/dispute_repository.dart';
import 'package:sfdify_scm/shared/domain/entities/dispute_metrics_entity.dart';

@Injectable(as: DisputeRepository)
class DisputeRepositoryImpl implements DisputeRepository {
  final DisputeRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  DisputeRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, DisputeMetricsEntity>> getMetrics() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final metrics = await _remoteDataSource.getMetrics();
      return Right(metrics);
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
  Future<Either<Failure, List<DisputeEntity>>> getDisputes({
    String? bureau,
    String? status,
    int page = 1,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final disputes = await _remoteDataSource.getDisputes(
        bureau: bureau,
        status: status,
        page: page,
      );
      return Right(disputes);
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
}

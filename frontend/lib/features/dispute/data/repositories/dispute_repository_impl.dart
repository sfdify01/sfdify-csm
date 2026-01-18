import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/error/exceptions.dart';
import 'package:ustaxx_csm/core/error/failures.dart';
import 'package:ustaxx_csm/core/network/network_info.dart';
import 'package:ustaxx_csm/features/dispute/data/datasources/dispute_remote_datasource.dart';
import 'package:ustaxx_csm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:ustaxx_csm/features/dispute/domain/repositories/dispute_repository.dart';
import 'package:ustaxx_csm/shared/domain/entities/dispute_metrics_entity.dart';

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
    int? limit,
    String? cursor,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final disputes = await _remoteDataSource.getDisputes(
        bureau: bureau,
        status: status,
        limit: limit,
        cursor: cursor,
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

  @override
  Future<Either<Failure, DisputeEntity>> getDispute(String disputeId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final dispute = await _remoteDataSource.getDispute(disputeId);
      return Right(dispute);
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
  Future<Either<Failure, DisputeEntity>> createDispute(
    Map<String, dynamic> data,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final dispute = await _remoteDataSource.createDispute(data);
      return Right(dispute);
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
  Future<Either<Failure, DisputeEntity>> updateDispute(
    String disputeId,
    Map<String, dynamic> updates,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final dispute = await _remoteDataSource.updateDispute(disputeId, updates);
      return Right(dispute);
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
  Future<Either<Failure, DisputeEntity>> submitDispute(String disputeId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final dispute = await _remoteDataSource.submitDispute(disputeId);
      return Right(dispute);
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
  Future<Either<Failure, DisputeEntity>> approveDispute(String disputeId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final dispute = await _remoteDataSource.approveDispute(disputeId);
      return Right(dispute);
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
  Future<Either<Failure, DisputeEntity>> closeDispute(
    String disputeId,
    String resolution,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final dispute = await _remoteDataSource.closeDispute(disputeId, resolution);
      return Right(dispute);
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

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/error/exceptions.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/core/network/network_info.dart';
import 'package:sfdify_scm/features/consumer/data/datasources/consumer_remote_datasource.dart';
import 'package:sfdify_scm/features/consumer/domain/entities/consumer_entity.dart';
import 'package:sfdify_scm/features/consumer/domain/repositories/consumer_repository.dart';

@Injectable(as: ConsumerRepository)
class ConsumerRepositoryImpl implements ConsumerRepository {
  final ConsumerRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  ConsumerRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, List<ConsumerEntity>>> getConsumers({
    int? limit,
    String? cursor,
    String? search,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final consumers = await _remoteDataSource.getConsumers(
        limit: limit,
        cursor: cursor,
        search: search,
      );
      return Right(consumers);
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
  Future<Either<Failure, ConsumerEntity>> getConsumer(String consumerId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final consumer = await _remoteDataSource.getConsumer(consumerId);
      return Right(consumer);
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
  Future<Either<Failure, ConsumerEntity>> createConsumer(
    Map<String, dynamic> data,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final consumer = await _remoteDataSource.createConsumer(data);
      return Right(consumer);
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
  Future<Either<Failure, ConsumerEntity>> updateConsumer(
    String consumerId,
    Map<String, dynamic> updates,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final consumer = await _remoteDataSource.updateConsumer(consumerId, updates);
      return Right(consumer);
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

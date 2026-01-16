import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/error/exceptions.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/core/network/network_info.dart';
import 'package:sfdify_scm/features/letter/data/datasources/letter_remote_datasource.dart';
import 'package:sfdify_scm/features/letter/domain/entities/letter_entity.dart';
import 'package:sfdify_scm/features/letter/domain/repositories/letter_repository.dart';

@Injectable(as: LetterRepository)
class LetterRepositoryImpl implements LetterRepository {
  final LetterRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  LetterRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, List<LetterEntity>>> getLetters({
    int? limit,
    String? cursor,
    String? disputeId,
    String? status,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final letters = await _remoteDataSource.getLetters(
        limit: limit,
        cursor: cursor,
        disputeId: disputeId,
        status: status,
      );
      return Right(letters);
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
  Future<Either<Failure, LetterEntity>> getLetter(String letterId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final letter = await _remoteDataSource.getLetter(letterId);
      return Right(letter);
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
  Future<Either<Failure, LetterEntity>> generateLetter(String disputeId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final letter = await _remoteDataSource.generateLetter(disputeId);
      return Right(letter);
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
  Future<Either<Failure, LetterEntity>> approveLetter(String letterId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final letter = await _remoteDataSource.approveLetter(letterId);
      return Right(letter);
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
  Future<Either<Failure, LetterEntity>> sendLetter(String letterId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final letter = await _remoteDataSource.sendLetter(letterId);
      return Right(letter);
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

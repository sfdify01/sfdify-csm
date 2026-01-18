import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/error/exceptions.dart';
import 'package:ustaxx_csm/core/error/failures.dart';
import 'package:ustaxx_csm/core/network/network_info.dart';
import 'package:ustaxx_csm/features/evidence/data/datasources/evidence_remote_datasource.dart';
import 'package:ustaxx_csm/features/evidence/domain/repositories/evidence_repository.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/evidence_entity.dart';

@Injectable(as: EvidenceRepository)
class EvidenceRepositoryImpl implements EvidenceRepository {
  final EvidenceRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  EvidenceRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, List<EvidenceEntity>>> getEvidenceList({
    int? limit,
    String? cursor,
    String? consumerId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final evidenceList = await _remoteDataSource.getEvidenceList(
        limit: limit,
        cursor: cursor,
        consumerId: consumerId,
      );
      return Right(evidenceList);
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
  Future<Either<Failure, EvidenceEntity>> getEvidence(String evidenceId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final evidence = await _remoteDataSource.getEvidence(evidenceId);
      return Right(evidence);
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
  Future<Either<Failure, EvidenceEntity>> uploadEvidence(
    Map<String, dynamic> data,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final evidence = await _remoteDataSource.uploadEvidence(data);
      return Right(evidence);
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

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/error/exceptions.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/features/home/data/datasources/home_remote_datasource.dart';
import 'package:sfdify_scm/features/home/domain/entities/home_entity.dart';
import 'package:sfdify_scm/features/home/domain/repositories/home_repository.dart';

@Injectable(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<HomeEntity>>> getHomeData() async {
    try {
      final result = await _remoteDataSource.getHomeData();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

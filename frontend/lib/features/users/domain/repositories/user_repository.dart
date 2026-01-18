import 'package:fpdart/fpdart.dart';
import 'package:ustaxx_csm/core/error/failures.dart';
import 'package:ustaxx_csm/features/users/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<Either<Failure, List<UserEntity>>> getUsers({
    int? limit,
    String? cursor,
  });

  Future<Either<Failure, UserEntity>> getUser(String userId);

  Future<Either<Failure, UserEntity>> createUser(Map<String, dynamic> data);
}

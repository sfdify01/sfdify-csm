import 'package:fpdart/fpdart.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/features/users/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<Either<Failure, List<UserEntity>>> getUsers({
    int? limit,
    String? cursor,
  });

  Future<Either<Failure, UserEntity>> getUser(String userId);

  Future<Either<Failure, UserEntity>> createUser(Map<String, dynamic> data);
}

import 'package:fpdart/fpdart.dart';
import 'package:ustaxx_csm/core/error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

abstract class UseCaseSync<Type, Params> {
  Either<Failure, Type> call(Params params);
}

class NoParams {
  const NoParams();
}

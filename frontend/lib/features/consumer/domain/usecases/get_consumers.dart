import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/features/consumer/domain/entities/consumer_entity.dart';
import 'package:sfdify_scm/features/consumer/domain/repositories/consumer_repository.dart';

@injectable
class GetConsumers {
  final ConsumerRepository _repository;

  GetConsumers(this._repository);

  Future<Either<Failure, List<ConsumerEntity>>> call({
    int? limit,
    String? cursor,
    String? search,
  }) {
    return _repository.getConsumers(
      limit: limit,
      cursor: cursor,
      search: search,
    );
  }
}

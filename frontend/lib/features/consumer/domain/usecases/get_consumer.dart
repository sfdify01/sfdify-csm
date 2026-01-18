import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/error/failures.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/consumer_entity.dart';
import 'package:ustaxx_csm/features/consumer/domain/repositories/consumer_repository.dart';

@injectable
class GetConsumer {
  final ConsumerRepository _repository;

  GetConsumer(this._repository);

  Future<Either<Failure, ConsumerEntity>> call(String consumerId) {
    return _repository.getConsumer(consumerId);
  }
}

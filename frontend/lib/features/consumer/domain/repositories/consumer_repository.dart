import 'package:fpdart/fpdart.dart';
import 'package:ustaxx_csm/core/error/failures.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/consumer_entity.dart';

abstract class ConsumerRepository {
  Future<Either<Failure, List<ConsumerEntity>>> getConsumers({
    int? limit,
    String? cursor,
    String? search,
  });

  Future<Either<Failure, ConsumerEntity>> getConsumer(String consumerId);

  Future<Either<Failure, ConsumerEntity>> createConsumer(Map<String, dynamic> data);

  Future<Either<Failure, ConsumerEntity>> updateConsumer(
    String consumerId,
    Map<String, dynamic> updates,
  );
}

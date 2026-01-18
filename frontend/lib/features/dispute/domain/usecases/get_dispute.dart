import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/error/failures.dart';
import 'package:ustaxx_csm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:ustaxx_csm/features/dispute/domain/repositories/dispute_repository.dart';

@injectable
class GetDispute {
  final DisputeRepository _repository;

  GetDispute(this._repository);

  Future<Either<Failure, DisputeEntity>> call(String disputeId) {
    return _repository.getDispute(disputeId);
  }
}

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:sfdify_scm/features/dispute/domain/repositories/dispute_repository.dart';

@injectable
class GetDispute {
  final DisputeRepository _repository;

  GetDispute(this._repository);

  Future<Either<Failure, DisputeEntity>> call(String disputeId) {
    return _repository.getDispute(disputeId);
  }
}

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/core/usecase/usecase.dart';
import 'package:sfdify_scm/features/dispute/domain/repositories/dispute_repository.dart';
import 'package:sfdify_scm/shared/domain/entities/dispute_metrics_entity.dart';

@injectable
class GetDisputeMetrics
    implements UseCase<DisputeMetricsEntity, NoParams> {
  final DisputeRepository _repository;

  GetDisputeMetrics(this._repository);

  @override
  Future<Either<Failure, DisputeMetricsEntity>> call(NoParams params) {
    return _repository.getMetrics();
  }
}

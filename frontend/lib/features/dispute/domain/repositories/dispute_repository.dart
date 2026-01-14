import 'package:fpdart/fpdart.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:sfdify_scm/shared/domain/entities/dispute_metrics_entity.dart';

abstract class DisputeRepository {
  Future<Either<Failure, DisputeMetricsEntity>> getMetrics();

  Future<Either<Failure, List<DisputeEntity>>> getDisputes({
    String? bureau,
    String? status,
    int page = 1,
  });
}

import 'package:fpdart/fpdart.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:sfdify_scm/shared/domain/entities/dispute_metrics_entity.dart';

abstract class DisputeRepository {
  Future<Either<Failure, DisputeMetricsEntity>> getMetrics();

  Future<Either<Failure, List<DisputeEntity>>> getDisputes({
    String? bureau,
    String? status,
    int? limit,
    String? cursor,
  });

  Future<Either<Failure, DisputeEntity>> getDispute(String disputeId);

  Future<Either<Failure, DisputeEntity>> createDispute(Map<String, dynamic> data);

  Future<Either<Failure, DisputeEntity>> updateDispute(
    String disputeId,
    Map<String, dynamic> updates,
  );

  Future<Either<Failure, DisputeEntity>> submitDispute(String disputeId);

  Future<Either<Failure, DisputeEntity>> approveDispute(String disputeId);

  Future<Either<Failure, DisputeEntity>> closeDispute(
    String disputeId,
    String resolution,
  );
}

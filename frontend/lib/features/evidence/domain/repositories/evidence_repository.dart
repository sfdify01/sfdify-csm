import 'package:fpdart/fpdart.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/features/letter/domain/entities/evidence_entity.dart';

abstract class EvidenceRepository {
  Future<Either<Failure, List<EvidenceEntity>>> getEvidenceList({
    int? limit,
    String? cursor,
    String? consumerId,
  });

  Future<Either<Failure, EvidenceEntity>> getEvidence(String evidenceId);

  Future<Either<Failure, EvidenceEntity>> uploadEvidence(Map<String, dynamic> data);
}

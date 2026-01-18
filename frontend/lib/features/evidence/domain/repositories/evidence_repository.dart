import 'package:fpdart/fpdart.dart';
import 'package:ustaxx_csm/core/error/failures.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/evidence_entity.dart';

abstract class EvidenceRepository {
  Future<Either<Failure, List<EvidenceEntity>>> getEvidenceList({
    int? limit,
    String? cursor,
    String? consumerId,
  });

  Future<Either<Failure, EvidenceEntity>> getEvidence(String evidenceId);

  Future<Either<Failure, EvidenceEntity>> uploadEvidence(Map<String, dynamic> data);
}

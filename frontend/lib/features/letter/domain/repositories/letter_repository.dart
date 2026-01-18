import 'package:fpdart/fpdart.dart';
import 'package:ustaxx_csm/core/error/failures.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/letter_entity.dart';

abstract class LetterRepository {
  Future<Either<Failure, List<LetterEntity>>> getLetters({
    int? limit,
    String? cursor,
    String? disputeId,
    String? status,
  });

  Future<Either<Failure, LetterEntity>> getLetter(String letterId);

  Future<Either<Failure, LetterEntity>> generateLetter(String disputeId);

  Future<Either<Failure, LetterEntity>> approveLetter(String letterId);

  Future<Either<Failure, LetterEntity>> sendLetter(String letterId);
}

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/error/failures.dart';
import 'package:ustaxx_csm/core/usecase/usecase.dart';
import 'package:ustaxx_csm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:ustaxx_csm/features/dispute/domain/repositories/dispute_repository.dart';

@injectable
class GetDisputes implements UseCase<List<DisputeEntity>, GetDisputesParams> {
  final DisputeRepository _repository;

  GetDisputes(this._repository);

  @override
  Future<Either<Failure, List<DisputeEntity>>> call(
    GetDisputesParams params,
  ) {
    return _repository.getDisputes(
      bureau: params.bureau,
      status: params.status,
      limit: params.limit,
      cursor: params.cursor,
    );
  }
}

class GetDisputesParams extends Equatable {
  final String? bureau;
  final String? status;
  final int? limit;
  final String? cursor;

  const GetDisputesParams({
    this.bureau,
    this.status,
    this.limit,
    this.cursor,
  });

  @override
  List<Object?> get props => [bureau, status, limit, cursor];
}

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/core/usecase/usecase.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:sfdify_scm/features/dispute/domain/repositories/dispute_repository.dart';

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
      page: params.page,
    );
  }
}

class GetDisputesParams extends Equatable {
  final String? bureau;
  final String? status;
  final int page;

  const GetDisputesParams({
    this.bureau,
    this.status,
    this.page = 1,
  });

  @override
  List<Object?> get props => [bureau, status, page];
}

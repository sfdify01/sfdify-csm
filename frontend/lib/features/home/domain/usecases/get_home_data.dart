import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/error/failures.dart';
import 'package:ustaxx_csm/core/usecase/usecase.dart';
import 'package:ustaxx_csm/features/home/domain/entities/home_entity.dart';
import 'package:ustaxx_csm/features/home/domain/repositories/home_repository.dart';

@injectable
class GetHomeData implements UseCase<List<HomeEntity>, NoParams> {
  const GetHomeData(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, List<HomeEntity>>> call(NoParams params) {
    return _repository.getHomeData();
  }
}

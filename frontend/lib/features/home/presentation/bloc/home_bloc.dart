import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/usecase/usecase.dart';
import 'package:sfdify_scm/features/home/domain/entities/home_entity.dart';
import 'package:sfdify_scm/features/home/domain/usecases/get_home_data.dart';

part 'home_event.dart';
part 'home_state.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._getHomeData) : super(const HomeState()) {
    on<HomeLoadRequested>(_onLoadRequested, transformer: droppable());
    on<HomeRefreshRequested>(_onRefreshRequested, transformer: droppable());
  }

  final GetHomeData _getHomeData;

  Future<void> _onLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    final result = await _getHomeData(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (data) => emit(
        state.copyWith(
          status: HomeStatus.success,
          data: data,
        ),
      ),
    );
  }

  Future<void> _onRefreshRequested(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    final result = await _getHomeData(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: failure.message),
      ),
      (data) => emit(
        state.copyWith(
          status: HomeStatus.success,
          data: data,
        ),
      ),
    );
  }
}

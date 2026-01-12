import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/error/failures.dart';
import 'package:sfdify_scm/core/usecase/usecase.dart';
import 'package:sfdify_scm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:sfdify_scm/features/dispute/domain/usecases/get_dispute_metrics.dart';
import 'package:sfdify_scm/features/dispute/domain/usecases/get_disputes.dart';
import 'package:sfdify_scm/features/dispute/presentation/bloc/dispute_overview_event.dart';
import 'package:sfdify_scm/features/dispute/presentation/bloc/dispute_overview_state.dart';
import 'package:sfdify_scm/shared/domain/entities/dispute_metrics_entity.dart';

@injectable
class DisputeOverviewBloc
    extends Bloc<DisputeOverviewEvent, DisputeOverviewState> {
  DisputeOverviewBloc(
    this._getDisputeMetrics,
    this._getDisputes,
  ) : super(const DisputeOverviewState()) {
    on<DisputeOverviewLoadRequested>(
      _onLoadRequested,
      transformer: droppable(),
    );
    on<DisputeOverviewRefreshRequested>(
      _onRefreshRequested,
      transformer: droppable(),
    );
    on<DisputeOverviewBureauFilterChanged>(_onBureauFilterChanged);
    on<DisputeOverviewPageChanged>(_onPageChanged);
  }

  final GetDisputeMetrics _getDisputeMetrics;
  final GetDisputes _getDisputes;

  Future<void> _onLoadRequested(
    DisputeOverviewLoadRequested event,
    Emitter<DisputeOverviewState> emit,
  ) async {
    emit(state.copyWith(status: DisputeOverviewStatus.loading));

    // Load metrics and disputes in parallel
    final results = await Future.wait([
      _getDisputeMetrics(const NoParams()),
      _getDisputes(GetDisputesParams(
        bureau: state.selectedBureau,
        page: state.currentPage,
      )),
    ]);

    final metricsResult = results[0] as Either<Failure, DisputeMetricsEntity>;
    final disputesResult = results[1] as Either<Failure, List<DisputeEntity>>;

    // Handle results using fold
    metricsResult.fold(
      (failure) {
        emit(state.copyWith(
          status: DisputeOverviewStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (metrics) {
        disputesResult.fold(
          (failure) {
            emit(state.copyWith(
              status: DisputeOverviewStatus.failure,
              errorMessage: failure.message,
            ));
          },
          (disputes) {
            emit(state.copyWith(
              status: DisputeOverviewStatus.success,
              metrics: metrics,
              disputes: disputes,
            ));
          },
        );
      },
    );
  }

  Future<void> _onRefreshRequested(
    DisputeOverviewRefreshRequested event,
    Emitter<DisputeOverviewState> emit,
  ) async {
    // Load data without showing loading state (for pull-to-refresh)
    final results = await Future.wait([
      _getDisputeMetrics(const NoParams()),
      _getDisputes(GetDisputesParams(
        bureau: state.selectedBureau,
        page: state.currentPage,
      )),
    ]);

    final metricsResult = results[0] as Either<Failure, DisputeMetricsEntity>;
    final disputesResult = results[1] as Either<Failure, List<DisputeEntity>>;

    // Handle results using fold
    metricsResult.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
      },
      (metrics) {
        disputesResult.fold(
          (failure) {
            emit(state.copyWith(errorMessage: failure.message));
          },
          (disputes) {
            emit(state.copyWith(
              status: DisputeOverviewStatus.success,
              metrics: metrics,
              disputes: disputes,
            ));
          },
        );
      },
    );
  }

  Future<void> _onBureauFilterChanged(
    DisputeOverviewBureauFilterChanged event,
    Emitter<DisputeOverviewState> emit,
  ) async {
    emit(state.copyWith(
      selectedBureau: event.bureau,
      currentPage: 1, // Reset to first page
    ));
    add(const DisputeOverviewLoadRequested());
  }

  Future<void> _onPageChanged(
    DisputeOverviewPageChanged event,
    Emitter<DisputeOverviewState> emit,
  ) async {
    emit(state.copyWith(currentPage: event.page));
    add(const DisputeOverviewLoadRequested());
  }
}

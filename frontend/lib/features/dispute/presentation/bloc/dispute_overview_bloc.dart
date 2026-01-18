import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/error/failures.dart';
import 'package:ustaxx_csm/core/usecase/usecase.dart';
import 'package:ustaxx_csm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:ustaxx_csm/features/dispute/domain/usecases/get_dispute_metrics.dart';
import 'package:ustaxx_csm/features/dispute/domain/usecases/get_disputes.dart';
import 'package:ustaxx_csm/features/dispute/presentation/bloc/dispute_overview_event.dart';
import 'package:ustaxx_csm/features/dispute/presentation/bloc/dispute_overview_state.dart';
import 'package:ustaxx_csm/shared/domain/entities/dispute_metrics_entity.dart';

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
    on<DisputeOverviewLoadMore>(_onLoadMore);
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
        limit: 20,
      )),
    ]);

    final metricsResult = results[0] as Either<Failure, DisputeMetricsEntity>;
    final disputesResult = results[1] as Either<Failure, List<DisputeEntity>>;

    // Handle disputes result - this is required for the page to work
    disputesResult.fold(
      (failure) {
        emit(state.copyWith(
          status: DisputeOverviewStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (disputes) {
        // Disputes loaded successfully, now handle metrics
        // If metrics fail, use default values and show a warning
        metricsResult.fold(
          (failure) {
            // Use default metrics but still show the page
            emit(state.copyWith(
              status: DisputeOverviewStatus.success,
              metrics: const DisputeMetricsEntity(
                totalDisputes: 0,
                percentageChange: 0,
                pendingApproval: 0,
                inTransitViaLob: 0,
                slaBreaches: 0,
                slaBreachesToday: 0,
              ),
              disputes: disputes,
              hasMore: disputes.length >= 20,
              errorMessage: 'Analytics temporarily unavailable',
            ));
          },
          (metrics) {
            emit(state.copyWith(
              status: DisputeOverviewStatus.success,
              metrics: metrics,
              disputes: disputes,
              hasMore: disputes.length >= 20,
              errorMessage: null,
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
        limit: 20,
      )),
    ]);

    final metricsResult = results[0] as Either<Failure, DisputeMetricsEntity>;
    final disputesResult = results[1] as Either<Failure, List<DisputeEntity>>;

    // Handle disputes result - this is required for the page to work
    disputesResult.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
      },
      (disputes) {
        // Disputes loaded successfully, now handle metrics
        metricsResult.fold(
          (failure) {
            // Keep previous metrics if available, or use defaults
            emit(state.copyWith(
              status: DisputeOverviewStatus.success,
              disputes: disputes,
              hasMore: disputes.length >= 20,
              errorMessage: 'Analytics temporarily unavailable',
            ));
          },
          (metrics) {
            emit(state.copyWith(
              status: DisputeOverviewStatus.success,
              metrics: metrics,
              disputes: disputes,
              hasMore: disputes.length >= 20,
              errorMessage: null,
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
      cursor: null,
    ));
    add(const DisputeOverviewLoadRequested());
  }

  Future<void> _onLoadMore(
    DisputeOverviewLoadMore event,
    Emitter<DisputeOverviewState> emit,
  ) async {
    if (!state.hasMore || state.status == DisputeOverviewStatus.loading) {
      return;
    }

    final result = await _getDisputes(GetDisputesParams(
      bureau: state.selectedBureau,
      limit: 20,
      cursor: state.cursor,
    ));

    result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
      },
      (disputes) {
        emit(state.copyWith(
          disputes: [...state.disputes, ...disputes],
          hasMore: disputes.length >= 20,
        ));
      },
    );
  }
}

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/features/consumer/domain/usecases/get_consumer.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_detail_event.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_detail_state.dart';

@injectable
class ConsumerDetailBloc
    extends Bloc<ConsumerDetailEvent, ConsumerDetailState> {
  ConsumerDetailBloc(this._getConsumer) : super(const ConsumerDetailState()) {
    on<ConsumerDetailLoadRequested>(
      _onLoadRequested,
      transformer: droppable(),
    );
    on<ConsumerDetailRefreshRequested>(
      _onRefreshRequested,
      transformer: droppable(),
    );
    on<ConsumerDetailSmartCreditConnectRequested>(_onSmartCreditConnect);
    on<ConsumerDetailCreditReportRefreshRequested>(_onCreditReportRefresh);
  }

  final GetConsumer _getConsumer;
  String? _currentConsumerId;

  Future<void> _onLoadRequested(
    ConsumerDetailLoadRequested event,
    Emitter<ConsumerDetailState> emit,
  ) async {
    _currentConsumerId = event.consumerId;
    emit(state.copyWith(status: ConsumerDetailStatus.loading));

    final result = await _getConsumer(event.consumerId);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: ConsumerDetailStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (consumer) {
        emit(state.copyWith(
          status: ConsumerDetailStatus.success,
          consumer: consumer,
          // TODO: Load disputes and credit info from separate calls
        ));
      },
    );
  }

  Future<void> _onRefreshRequested(
    ConsumerDetailRefreshRequested event,
    Emitter<ConsumerDetailState> emit,
  ) async {
    if (_currentConsumerId == null) return;

    final result = await _getConsumer(_currentConsumerId!);

    result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
      },
      (consumer) {
        emit(state.copyWith(
          status: ConsumerDetailStatus.success,
          consumer: consumer,
        ));
      },
    );
  }

  Future<void> _onSmartCreditConnect(
    ConsumerDetailSmartCreditConnectRequested event,
    Emitter<ConsumerDetailState> emit,
  ) async {
    // TODO: Implement SmartCredit OAuth flow
    // This would open a browser or webview for OAuth
  }

  Future<void> _onCreditReportRefresh(
    ConsumerDetailCreditReportRefreshRequested event,
    Emitter<ConsumerDetailState> emit,
  ) async {
    // TODO: Implement credit report refresh
    // This would call the backend to refresh the credit report
  }
}

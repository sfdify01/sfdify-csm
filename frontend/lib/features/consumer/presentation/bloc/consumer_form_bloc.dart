import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/features/consumer/domain/repositories/consumer_repository.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_form_event.dart';
import 'package:sfdify_scm/features/consumer/presentation/bloc/consumer_form_state.dart';

@injectable
class ConsumerFormBloc extends Bloc<ConsumerFormEvent, ConsumerFormState> {
  ConsumerFormBloc(this._repository) : super(const ConsumerFormState()) {
    on<ConsumerFormLoadRequested>(
      _onLoadRequested,
      transformer: droppable(),
    );
    on<ConsumerFormSubmitted>(
      _onSubmitted,
      transformer: droppable(),
    );
  }

  final ConsumerRepository _repository;
  String? _editingConsumerId;

  Future<void> _onLoadRequested(
    ConsumerFormLoadRequested event,
    Emitter<ConsumerFormState> emit,
  ) async {
    _editingConsumerId = event.consumerId;

    if (event.consumerId == null) {
      // Create mode
      emit(state.copyWith(
        status: ConsumerFormStatus.ready,
        isEditMode: false,
      ));
      return;
    }

    // Edit mode - load existing consumer
    emit(state.copyWith(status: ConsumerFormStatus.loading));

    final result = await _repository.getConsumer(event.consumerId!);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: ConsumerFormStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (consumer) {
        emit(state.copyWith(
          status: ConsumerFormStatus.ready,
          isEditMode: true,
          consumer: consumer,
        ));
      },
    );
  }

  Future<void> _onSubmitted(
    ConsumerFormSubmitted event,
    Emitter<ConsumerFormState> emit,
  ) async {
    emit(state.copyWith(status: ConsumerFormStatus.submitting));

    final data = {
      'firstName': event.firstName,
      'lastName': event.lastName,
      'email': event.email,
      if (event.phone != null && event.phone!.isNotEmpty) 'phone': event.phone,
      if (event.street != null && event.street!.isNotEmpty)
        'address': {
          'street': event.street,
          'city': event.city,
          'state': event.state,
          'zipCode': event.zipCode,
        },
      'hasConsent': event.hasConsent,
    };

    final result = state.isEditMode && _editingConsumerId != null
        ? await _repository.updateConsumer(_editingConsumerId!, data)
        : await _repository.createConsumer(data);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: ConsumerFormStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (consumer) {
        emit(state.copyWith(
          status: ConsumerFormStatus.success,
          savedConsumer: consumer,
        ));
      },
    );
  }
}

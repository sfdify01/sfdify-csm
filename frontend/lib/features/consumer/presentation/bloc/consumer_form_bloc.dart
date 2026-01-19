import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/features/consumer/domain/repositories/consumer_repository.dart';
import 'package:ustaxx_csm/features/consumer/presentation/bloc/consumer_form_event.dart';
import 'package:ustaxx_csm/features/consumer/presentation/bloc/consumer_form_state.dart';

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

    // Format date as YYYY-MM-DD
    String? formattedDob;
    if (event.dateOfBirth != null) {
      final dob = event.dateOfBirth!;
      formattedDob = '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
    }

    // Format phone to E.164 format (strip formatting and add +1 for US numbers)
    String? formattedPhone;
    if (event.phone != null && event.phone!.isNotEmpty) {
      final digits = event.phone!.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 10) {
        formattedPhone = '+1$digits'; // US phone number
      } else if (digits.length == 11 && digits.startsWith('1')) {
        formattedPhone = '+$digits';
      }
    }

    final data = {
      'firstName': event.firstName,
      'lastName': event.lastName,
      if (formattedDob != null) 'dob': formattedDob,
      if (event.ssnLast4 != null && event.ssnLast4!.isNotEmpty) 'ssnLast4': event.ssnLast4,
      'addresses': [
        {
          'type': 'current',
          'street1': event.street,
          'city': event.city,
          'state': event.state,
          'zipCode': event.zipCode,
          'country': 'US',
          'isPrimary': true,
        }
      ],
      if (formattedPhone != null)
        'phones': [
          {
            'type': 'mobile',
            'number': formattedPhone,
            'isPrimary': true,
          }
        ],
      if (event.email.isNotEmpty)
        'emails': [
          {
            'address': event.email,
            'isPrimary': true,
          }
        ],
      if (event.smartCreditSource != null) 'smartCreditSource': event.smartCreditSource,
      if (event.smartCreditUsername != null && event.smartCreditUsername!.isNotEmpty)
        'smartCreditUsername': event.smartCreditUsername,
      'consent': {
        'termsAccepted': event.hasConsent,
        'privacyAccepted': event.hasConsent,
        'fcraDisclosureAccepted': event.hasConsent,
      },
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

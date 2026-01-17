import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/features/dispute/domain/repositories/dispute_repository.dart';
import 'package:sfdify_scm/features/letter/domain/entities/letter_template_entity.dart';
import 'package:sfdify_scm/features/letter/domain/repositories/letter_repository.dart';
import 'package:sfdify_scm/features/letter/presentation/bloc/letter_generate_event.dart';
import 'package:sfdify_scm/features/letter/presentation/bloc/letter_generate_state.dart';

@injectable
class LetterGenerateBloc
    extends Bloc<LetterGenerateEvent, LetterGenerateState> {
  LetterGenerateBloc(this._letterRepository, this._disputeRepository)
      : super(const LetterGenerateState()) {
    on<LetterGenerateLoadRequested>(_onLoadRequested, transformer: droppable());
    on<LetterGenerateTemplateChanged>(_onTemplateChanged);
    on<LetterGenerateMailTypeChanged>(_onMailTypeChanged);
    on<LetterGenerateSubmitted>(_onSubmitted, transformer: droppable());
  }

  final LetterRepository _letterRepository;
  final DisputeRepository _disputeRepository;
  String? _disputeId;

  // Mock templates - in production these would come from the backend
  static final List<LetterTemplateEntity> _mockTemplates = [
    LetterTemplateEntity(
      id: '609_request',
      name: 'FCRA Section 609 Request',
      description:
          'Request original documentation under FCRA Section 609. Use this to challenge items that cannot be verified with original documents.',
      type: '609_request',
      content: '',
      variables: const {},
      legalCitations: const ['15 U.S.C. § 1681g'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    LetterTemplateEntity(
      id: '611_dispute',
      name: 'FCRA Section 611 Dispute',
      description:
          'Formal dispute of inaccurate information under FCRA Section 611. The bureau must investigate within 30 days.',
      type: '611_dispute',
      content: '',
      variables: const {},
      legalCitations: const ['15 U.S.C. § 1681i'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    LetterTemplateEntity(
      id: 'mov_request',
      name: 'Method of Verification Request',
      description:
          'Request the method used to verify disputed information. Use after initial dispute if item was verified.',
      type: 'mov_request',
      content: '',
      variables: const {},
      legalCitations: const ['15 U.S.C. § 1681i(a)(6)'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    LetterTemplateEntity(
      id: 'deletion_request',
      name: 'Deletion Request',
      description:
          'Request removal of inaccurate or unverifiable information from your credit report.',
      type: 'deletion_request',
      content: '',
      variables: const {},
      legalCitations: const ['15 U.S.C. § 1681i'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    LetterTemplateEntity(
      id: 'goodwill_letter',
      name: 'Goodwill Letter',
      description:
          'Request removal of accurate negative information as an act of goodwill. Best for one-time late payments with otherwise good history.',
      type: 'goodwill_letter',
      content: '',
      variables: const {},
      legalCitations: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    LetterTemplateEntity(
      id: 'debt_validation',
      name: 'Debt Validation Letter',
      description:
          'Request validation of a debt from a collection agency under FDCPA. Must be sent within 30 days of first contact.',
      type: 'debt_validation',
      content: '',
      variables: const {},
      legalCitations: const ['15 U.S.C. § 1692g'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  Future<void> _onLoadRequested(
    LetterGenerateLoadRequested event,
    Emitter<LetterGenerateState> emit,
  ) async {
    _disputeId = event.disputeId;
    emit(state.copyWith(status: LetterGenerateStatus.loading));

    final result = await _disputeRepository.getDispute(event.disputeId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: LetterGenerateStatus.failure,
        errorMessage: failure.message,
      )),
      (dispute) => emit(state.copyWith(
        status: LetterGenerateStatus.ready,
        dispute: dispute,
        templates: _mockTemplates,
        selectedTemplateId: _getDefaultTemplateForDispute(dispute.type),
      )),
    );
  }

  void _onTemplateChanged(
    LetterGenerateTemplateChanged event,
    Emitter<LetterGenerateState> emit,
  ) {
    emit(state.copyWith(selectedTemplateId: event.templateId));
  }

  void _onMailTypeChanged(
    LetterGenerateMailTypeChanged event,
    Emitter<LetterGenerateState> emit,
  ) {
    emit(state.copyWith(selectedMailType: event.mailType));
  }

  Future<void> _onSubmitted(
    LetterGenerateSubmitted event,
    Emitter<LetterGenerateState> emit,
  ) async {
    if (!state.canSubmit || _disputeId == null) return;

    emit(state.copyWith(status: LetterGenerateStatus.submitting));

    final result = await _letterRepository.generateLetter(_disputeId!);

    result.fold(
      (failure) => emit(state.copyWith(
        status: LetterGenerateStatus.failure,
        errorMessage: failure.message,
      )),
      (letter) => emit(state.copyWith(
        status: LetterGenerateStatus.success,
        generatedLetter: letter,
      )),
    );
  }

  String? _getDefaultTemplateForDispute(String disputeType) {
    // Map dispute types to default templates
    return switch (disputeType) {
      '609_request' => '609_request',
      '611_dispute' => '611_dispute',
      'mov_request' => 'mov_request',
      'deletion_request' => 'deletion_request',
      'goodwill_letter' => 'goodwill_letter',
      'debt_validation' => 'debt_validation',
      _ => '611_dispute',
    };
  }
}

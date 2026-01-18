import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/tradeline_entity.dart';
import 'package:ustaxx_csm/features/consumer/domain/usecases/get_consumers.dart';
import 'package:ustaxx_csm/features/dispute/domain/repositories/dispute_repository.dart';
import 'package:ustaxx_csm/features/dispute/presentation/bloc/dispute_create_event.dart';
import 'package:ustaxx_csm/features/dispute/presentation/bloc/dispute_create_state.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/letter_template_entity.dart';

@injectable
class DisputeCreateBloc extends Bloc<DisputeCreateEvent, DisputeCreateState> {
  DisputeCreateBloc(this._getConsumers, this._repository)
      : super(const DisputeCreateState()) {
    on<DisputeCreateLoadRequested>(
      _onLoadRequested,
      transformer: droppable(),
    );
    on<DisputeCreateConsumerChanged>(_onConsumerChanged);
    on<DisputeCreateTradelineToggled>(_onTradelineToggled);
    on<DisputeCreateSelectAllTradelines>(_onSelectAllTradelines);
    on<DisputeCreateTemplateChanged>(_onTemplateChanged);
    on<DisputeCreateBureauToggled>(_onBureauToggled);
    on<DisputeCreateRecipientTypeChanged>(_onRecipientTypeChanged);
    on<DisputeCreateCreditorChanged>(_onCreditorChanged);
    on<DisputeCreateStepChanged>(_onStepChanged);
    on<DisputeCreateSubmitted>(
      _onSubmitted,
      transformer: droppable(),
    );
  }

  final GetConsumers _getConsumers;
  final DisputeRepository _repository;

  Future<void> _onLoadRequested(
    DisputeCreateLoadRequested event,
    Emitter<DisputeCreateState> emit,
  ) async {
    emit(state.copyWith(status: DisputeCreateStatus.loading));

    final result = await _getConsumers(limit: 100);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: DisputeCreateStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (consumers) {
        // Load mock templates for now
        final templates = _getMockTemplates();

        emit(state.copyWith(
          status: DisputeCreateStatus.ready,
          consumers: consumers,
          templates: templates,
          selectedConsumerId: event.preselectedConsumerId,
        ));

        // If consumer is preselected, load their tradelines
        if (event.preselectedConsumerId != null) {
          add(DisputeCreateConsumerChanged(event.preselectedConsumerId));
        }
      },
    );
  }

  Future<void> _onConsumerChanged(
    DisputeCreateConsumerChanged event,
    Emitter<DisputeCreateState> emit,
  ) async {
    if (event.consumerId == null) {
      emit(state.copyWith(
        clearSelectedConsumer: true,
        tradelines: [],
        selectedTradelineIds: [],
      ));
      return;
    }

    emit(state.copyWith(
      selectedConsumerId: event.consumerId,
      status: DisputeCreateStatus.loadingTradelines,
    ));

    // Load mock tradelines for the consumer
    // In a real app, this would fetch from the credit report
    await Future.delayed(const Duration(milliseconds: 500));
    final tradelines = _getMockTradelines(event.consumerId!);

    emit(state.copyWith(
      status: DisputeCreateStatus.ready,
      tradelines: tradelines,
      selectedTradelineIds: [],
    ));
  }

  void _onTradelineToggled(
    DisputeCreateTradelineToggled event,
    Emitter<DisputeCreateState> emit,
  ) {
    final currentIds = List<String>.from(state.selectedTradelineIds);
    if (currentIds.contains(event.tradelineId)) {
      currentIds.remove(event.tradelineId);
    } else {
      currentIds.add(event.tradelineId);
    }
    emit(state.copyWith(selectedTradelineIds: currentIds));
  }

  void _onSelectAllTradelines(
    DisputeCreateSelectAllTradelines event,
    Emitter<DisputeCreateState> emit,
  ) {
    if (event.selected) {
      final idsToSelect = event.bureau != null
          ? state.tradelines
              .where((t) => t.bureau == event.bureau)
              .map((t) => t.id)
              .toList()
          : state.tradelines.map((t) => t.id).toList();
      emit(state.copyWith(selectedTradelineIds: idsToSelect));
    } else {
      if (event.bureau != null) {
        final idsToRemove = state.tradelines
            .where((t) => t.bureau == event.bureau)
            .map((t) => t.id)
            .toSet();
        final remaining = state.selectedTradelineIds
            .where((id) => !idsToRemove.contains(id))
            .toList();
        emit(state.copyWith(selectedTradelineIds: remaining));
      } else {
        emit(state.copyWith(selectedTradelineIds: []));
      }
    }
  }

  void _onTemplateChanged(
    DisputeCreateTemplateChanged event,
    Emitter<DisputeCreateState> emit,
  ) {
    emit(state.copyWith(selectedTemplateId: event.templateId));
  }

  void _onBureauToggled(
    DisputeCreateBureauToggled event,
    Emitter<DisputeCreateState> emit,
  ) {
    final currentBureaus = List<String>.from(state.selectedBureaus);
    if (currentBureaus.contains(event.bureau)) {
      currentBureaus.remove(event.bureau);
    } else {
      currentBureaus.add(event.bureau);
    }
    emit(state.copyWith(selectedBureaus: currentBureaus));
  }

  void _onRecipientTypeChanged(
    DisputeCreateRecipientTypeChanged event,
    Emitter<DisputeCreateState> emit,
  ) {
    emit(state.copyWith(
      recipientType: event.recipientType,
      selectedBureaus: event.recipientType == RecipientType.bureau
          ? state.selectedBureaus
          : [],
      clearCreditor: event.recipientType == RecipientType.bureau,
    ));
  }

  void _onCreditorChanged(
    DisputeCreateCreditorChanged event,
    Emitter<DisputeCreateState> emit,
  ) {
    emit(state.copyWith(
      creditorName: event.name ?? state.creditorName,
      creditorAddress: event.address ?? state.creditorAddress,
    ));
  }

  void _onStepChanged(
    DisputeCreateStepChanged event,
    Emitter<DisputeCreateState> emit,
  ) {
    emit(state.copyWith(currentStep: event.step));
  }

  Future<void> _onSubmitted(
    DisputeCreateSubmitted event,
    Emitter<DisputeCreateState> emit,
  ) async {
    emit(state.copyWith(status: DisputeCreateStatus.submitting));

    final data = {
      'consumerId': event.consumerId,
      'bureau': event.bureau,
      'type': event.type,
      'reasonCodes': event.reasonCodes,
      if (event.narrative != null && event.narrative!.isNotEmpty)
        'narrative': event.narrative,
      'priority': event.priority,
      if (event.tradelineId != null) 'tradelineId': event.tradelineId,
      if (event.tradelineIds != null && event.tradelineIds!.isNotEmpty)
        'tradelineIds': event.tradelineIds,
      if (event.templateId != null) 'templateId': event.templateId,
      'recipientType': event.recipientType.name,
      if (event.creditorName != null) 'creditorName': event.creditorName,
      if (event.creditorAddress != null)
        'creditorAddress': event.creditorAddress,
    };

    final result = await _repository.createDispute(data);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: DisputeCreateStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (dispute) {
        emit(state.copyWith(
          status: DisputeCreateStatus.success,
          savedDispute: dispute,
        ));
      },
    );
  }

  /// Mock tradelines for demonstration
  List<TradelineEntity> _getMockTradelines(String consumerId) {
    final now = DateTime.now();
    return [
      TradelineEntity(
        id: 'tl_1',
        reportId: 'rpt_1',
        bureau: 'equifax',
        creditorName: 'Chase Bank',
        accountNumberMasked: '****4532',
        accountType: 'credit_card',
        openedDate: now.subtract(const Duration(days: 730)),
        balance: 2450.00,
        creditLimit: 5000.00,
        status: 'open',
        paymentStatus: 'current',
        createdAt: now,
      ),
      TradelineEntity(
        id: 'tl_2',
        reportId: 'rpt_1',
        bureau: 'equifax',
        creditorName: 'Capital One',
        accountNumberMasked: '****8821',
        accountType: 'credit_card',
        openedDate: now.subtract(const Duration(days: 1095)),
        balance: 850.00,
        creditLimit: 3000.00,
        status: 'open',
        paymentStatus: '30_days_late',
        createdAt: now,
      ),
      TradelineEntity(
        id: 'tl_3',
        reportId: 'rpt_1',
        bureau: 'experian',
        creditorName: 'ABC Collections',
        accountNumberMasked: '****1234',
        accountType: 'collection',
        balance: 1200.00,
        originalAmount: 1500.00,
        status: 'collection',
        createdAt: now,
      ),
      TradelineEntity(
        id: 'tl_4',
        reportId: 'rpt_1',
        bureau: 'experian',
        creditorName: 'Bank of America',
        accountNumberMasked: '****5678',
        accountType: 'auto_loan',
        openedDate: now.subtract(const Duration(days: 365)),
        balance: 15000.00,
        originalAmount: 25000.00,
        status: 'open',
        paymentStatus: 'current',
        createdAt: now,
      ),
      TradelineEntity(
        id: 'tl_5',
        reportId: 'rpt_1',
        bureau: 'transunion',
        creditorName: 'Discover',
        accountNumberMasked: '****9012',
        accountType: 'credit_card',
        openedDate: now.subtract(const Duration(days: 500)),
        balance: 1800.00,
        creditLimit: 4000.00,
        status: 'open',
        paymentStatus: '60_days_late',
        createdAt: now,
      ),
      TradelineEntity(
        id: 'tl_6',
        reportId: 'rpt_1',
        bureau: 'transunion',
        creditorName: 'Medical Collections Inc',
        accountNumberMasked: '****3456',
        accountType: 'collection',
        balance: 450.00,
        originalAmount: 450.00,
        status: 'collection',
        remarks: 'Medical debt',
        createdAt: now,
      ),
    ];
  }

  /// Mock templates for demonstration
  List<LetterTemplateEntity> _getMockTemplates() {
    final now = DateTime.now();
    return [
      LetterTemplateEntity(
        id: 'tmpl_609',
        name: 'FCRA 609 Information Request',
        type: '609_request',
        description: 'Request verification of account under Section 609 of FCRA',
        content: 'Template content...',
        variables: const {},
        legalCitations: const ['15 U.S.C. § 1681g', 'FCRA Section 609'],
        createdAt: now,
        updatedAt: now,
      ),
      LetterTemplateEntity(
        id: 'tmpl_611',
        name: 'FCRA 611 Dispute Letter',
        type: '611_dispute',
        description: 'Dispute inaccurate information under Section 611 of FCRA',
        content: 'Template content...',
        variables: const {},
        legalCitations: const ['15 U.S.C. § 1681i', 'FCRA Section 611'],
        createdAt: now,
        updatedAt: now,
      ),
      LetterTemplateEntity(
        id: 'tmpl_605b',
        name: 'Identity Theft - 605B Block',
        type: '605b_id_theft',
        description: 'Request blocking of fraudulent accounts under 605B',
        content: 'Template content...',
        variables: const {},
        legalCitations: const ['15 U.S.C. § 1681c-2', 'FCRA Section 605B'],
        createdAt: now,
        updatedAt: now,
      ),
      LetterTemplateEntity(
        id: 'tmpl_mov',
        name: 'Method of Verification Request',
        type: 'mov_request',
        description: 'Request details on how information was verified',
        content: 'Template content...',
        variables: const {},
        legalCitations: const ['15 U.S.C. § 1681i(a)(6)'],
        createdAt: now,
        updatedAt: now,
      ),
      LetterTemplateEntity(
        id: 'tmpl_goodwill',
        name: 'Goodwill Adjustment Request',
        type: 'goodwill',
        description: 'Request removal of late payment as a goodwill gesture',
        content: 'Template content...',
        variables: const {},
        legalCitations: const [],
        createdAt: now,
        updatedAt: now,
      ),
      LetterTemplateEntity(
        id: 'tmpl_pfd',
        name: 'Pay for Delete Request',
        type: 'pay_for_delete',
        description: 'Offer to pay collection in exchange for deletion',
        content: 'Template content...',
        variables: const {},
        legalCitations: const [],
        createdAt: now,
        updatedAt: now,
      ),
      LetterTemplateEntity(
        id: 'tmpl_dv',
        name: 'Debt Validation Letter',
        type: 'debt_validation',
        description: 'Request validation of debt under FDCPA',
        content: 'Template content...',
        variables: const {},
        legalCitations: const ['15 U.S.C. § 1692g', 'FDCPA Section 809'],
        createdAt: now,
        updatedAt: now,
      ),
      LetterTemplateEntity(
        id: 'tmpl_cd',
        name: 'Cease & Desist Letter',
        type: 'cease_desist',
        description: 'Demand collector cease all contact',
        content: 'Template content...',
        variables: const {},
        legalCitations: const ['15 U.S.C. § 1692c', 'FDCPA Section 805'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

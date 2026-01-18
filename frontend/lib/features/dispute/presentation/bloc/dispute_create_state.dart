import 'package:equatable/equatable.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/consumer_entity.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/tradeline_entity.dart';
import 'package:ustaxx_csm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/letter_template_entity.dart';

enum DisputeCreateStatus {
  initial,
  loading,
  loadingTradelines,
  ready,
  submitting,
  success,
  failure,
}

/// Recipient type for disputes
enum RecipientType {
  bureau,
  creditor,
  collector,
}

class DisputeCreateState extends Equatable {
  const DisputeCreateState({
    this.status = DisputeCreateStatus.initial,
    this.consumers = const [],
    this.selectedConsumerId,
    this.tradelines = const [],
    this.selectedTradelineIds = const [],
    this.templates = const [],
    this.selectedTemplateId,
    this.selectedBureaus = const [],
    this.recipientType = RecipientType.bureau,
    this.creditorName,
    this.creditorAddress,
    this.currentStep = 0,
    this.savedDispute,
    this.errorMessage,
  });

  final DisputeCreateStatus status;
  final List<ConsumerEntity> consumers;
  final String? selectedConsumerId;
  final List<TradelineEntity> tradelines;
  final List<String> selectedTradelineIds;
  final List<LetterTemplateEntity> templates;
  final String? selectedTemplateId;
  final List<String> selectedBureaus;
  final RecipientType recipientType;
  final String? creditorName;
  final String? creditorAddress;
  final int currentStep;
  final DisputeEntity? savedDispute;
  final String? errorMessage;

  /// Get selected consumer
  ConsumerEntity? get selectedConsumer {
    if (selectedConsumerId == null) return null;
    try {
      return consumers.firstWhere((c) => c.id == selectedConsumerId);
    } catch (_) {
      return null;
    }
  }

  /// Get selected tradelines
  List<TradelineEntity> get selectedTradelines {
    return tradelines
        .where((t) => selectedTradelineIds.contains(t.id))
        .toList();
  }

  /// Get selected template
  LetterTemplateEntity? get selectedTemplate {
    if (selectedTemplateId == null) return null;
    try {
      return templates.firstWhere((t) => t.id == selectedTemplateId);
    } catch (_) {
      return null;
    }
  }

  /// Check if step 1 (consumer/tradeline selection) is valid
  bool get isStep1Valid =>
      selectedConsumerId != null && selectedTradelineIds.isNotEmpty;

  /// Check if step 2 (letter type) is valid
  bool get isStep2Valid => selectedTemplateId != null;

  /// Check if step 3 (recipients) is valid
  bool get isStep3Valid {
    if (recipientType == RecipientType.bureau) {
      return selectedBureaus.isNotEmpty;
    }
    return creditorName != null && creditorName!.isNotEmpty;
  }

  /// Check if ready to submit
  bool get canSubmit => isStep1Valid && isStep2Valid && isStep3Valid;

  DisputeCreateState copyWith({
    DisputeCreateStatus? status,
    List<ConsumerEntity>? consumers,
    String? selectedConsumerId,
    List<TradelineEntity>? tradelines,
    List<String>? selectedTradelineIds,
    List<LetterTemplateEntity>? templates,
    String? selectedTemplateId,
    List<String>? selectedBureaus,
    RecipientType? recipientType,
    String? creditorName,
    String? creditorAddress,
    int? currentStep,
    DisputeEntity? savedDispute,
    String? errorMessage,
    bool clearSelectedConsumer = false,
    bool clearSelectedTemplate = false,
    bool clearCreditor = false,
  }) {
    return DisputeCreateState(
      status: status ?? this.status,
      consumers: consumers ?? this.consumers,
      selectedConsumerId:
          clearSelectedConsumer ? null : (selectedConsumerId ?? this.selectedConsumerId),
      tradelines: tradelines ?? this.tradelines,
      selectedTradelineIds: selectedTradelineIds ?? this.selectedTradelineIds,
      templates: templates ?? this.templates,
      selectedTemplateId:
          clearSelectedTemplate ? null : (selectedTemplateId ?? this.selectedTemplateId),
      selectedBureaus: selectedBureaus ?? this.selectedBureaus,
      recipientType: recipientType ?? this.recipientType,
      creditorName: clearCreditor ? null : (creditorName ?? this.creditorName),
      creditorAddress:
          clearCreditor ? null : (creditorAddress ?? this.creditorAddress),
      currentStep: currentStep ?? this.currentStep,
      savedDispute: savedDispute ?? this.savedDispute,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        consumers,
        selectedConsumerId,
        tradelines,
        selectedTradelineIds,
        templates,
        selectedTemplateId,
        selectedBureaus,
        recipientType,
        creditorName,
        creditorAddress,
        currentStep,
        savedDispute,
        errorMessage,
      ];
}

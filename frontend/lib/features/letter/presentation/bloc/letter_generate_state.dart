import 'package:equatable/equatable.dart';
import 'package:ustaxx_csm/features/dispute/domain/entities/dispute_entity.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/letter_entity.dart';
import 'package:ustaxx_csm/features/letter/domain/entities/letter_template_entity.dart';

enum LetterGenerateStatus { initial, loading, ready, submitting, success, failure }

class LetterGenerateState extends Equatable {
  const LetterGenerateState({
    this.status = LetterGenerateStatus.initial,
    this.dispute,
    this.templates = const [],
    this.selectedTemplateId,
    this.selectedMailType = 'usps_first_class',
    this.generatedLetter,
    this.errorMessage,
  });

  final LetterGenerateStatus status;
  final DisputeEntity? dispute;
  final List<LetterTemplateEntity> templates;
  final String? selectedTemplateId;
  final String selectedMailType;
  final LetterEntity? generatedLetter;
  final String? errorMessage;

  LetterGenerateState copyWith({
    LetterGenerateStatus? status,
    DisputeEntity? dispute,
    List<LetterTemplateEntity>? templates,
    String? selectedTemplateId,
    String? selectedMailType,
    LetterEntity? generatedLetter,
    String? errorMessage,
  }) {
    return LetterGenerateState(
      status: status ?? this.status,
      dispute: dispute ?? this.dispute,
      templates: templates ?? this.templates,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      selectedMailType: selectedMailType ?? this.selectedMailType,
      generatedLetter: generatedLetter ?? this.generatedLetter,
      errorMessage: errorMessage,
    );
  }

  /// Get the selected template
  LetterTemplateEntity? get selectedTemplate {
    if (selectedTemplateId == null || templates.isEmpty) return null;
    try {
      return templates.firstWhere((t) => t.id == selectedTemplateId);
    } catch (_) {
      return null;
    }
  }

  /// Check if form is valid for submission
  bool get canSubmit =>
      status == LetterGenerateStatus.ready &&
      selectedTemplateId != null &&
      dispute != null;

  /// Get estimated cost based on mail type
  double get estimatedCost {
    return switch (selectedMailType) {
      'usps_first_class' => 1.13,
      'usps_certified' => 4.65,
      'usps_certified_return_receipt' => 7.96,
      _ => 0.0,
    };
  }

  @override
  List<Object?> get props => [
        status,
        dispute,
        templates,
        selectedTemplateId,
        selectedMailType,
        generatedLetter,
        errorMessage,
      ];
}

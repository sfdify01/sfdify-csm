import 'package:equatable/equatable.dart';

/// Letter template entity for reusable dispute letter templates
class LetterTemplateEntity extends Equatable {
  final String id;
  final String? tenantId; // null for system templates
  final String name;
  final String type;
  final String? description;
  final String content; // Markdown with template variables
  final Map<String, dynamic> variables;
  final String? complianceNotes;
  final String? disclaimer;
  final List<String> legalCitations;
  final int version;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByUserId;

  const LetterTemplateEntity({
    required this.id,
    this.tenantId,
    required this.name,
    required this.type,
    this.description,
    required this.content,
    required this.variables,
    this.complianceNotes,
    this.disclaimer,
    required this.legalCitations,
    this.version = 1,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdByUserId,
  });

  /// Check if this is a system template
  bool get isSystemTemplate => tenantId == null;

  /// Check if this is a custom tenant template
  bool get isCustomTemplate => tenantId != null;

  /// Get template type display name
  String get typeDisplayName {
    switch (type) {
      case '609_request':
        return 'FCRA 609 Information Request';
      case '611_dispute':
        return 'FCRA 611 Dispute';
      case 'mov_request':
        return 'Method of Verification';
      case 'reinvestigation':
        return 'Reinvestigation Follow-up';
      case 'goodwill':
        return 'Goodwill Adjustment';
      case 'pay_for_delete':
        return 'Pay for Delete';
      case 'identity_theft_block':
        return 'Identity Theft Block';
      case 'cfpb_complaint':
        return 'CFPB Complaint';
      case 'custom':
        return 'Custom Template';
      default:
        return type;
    }
  }

  /// Get required variables from template
  List<String> get requiredVariables {
    final required = <String>[];
    variables.forEach((key, value) {
      if (value is Map && value['required'] == true) {
        required.add(key);
      }
    });
    return required;
  }

  /// Get optional variables from template
  List<String> get optionalVariables {
    final optional = <String>[];
    variables.forEach((key, value) {
      if (value is Map && value['required'] != true) {
        optional.add(key);
      }
    });
    return optional;
  }

  /// Check if template has specific variable
  bool hasVariable(String variableName) => variables.containsKey(variableName);

  /// Get variable description
  String? getVariableDescription(String variableName) {
    final variable = variables[variableName];
    if (variable is Map) {
      return variable['description']?.toString();
    }
    return null;
  }

  /// Get variable type
  String? getVariableType(String variableName) {
    final variable = variables[variableName];
    if (variable is Map) {
      return variable['type']?.toString();
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        name,
        type,
        description,
        content,
        variables,
        complianceNotes,
        disclaimer,
        legalCitations,
        version,
        active,
        createdAt,
        updatedAt,
        createdByUserId,
      ];

  LetterTemplateEntity copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? type,
    String? description,
    String? content,
    Map<String, dynamic>? variables,
    String? complianceNotes,
    String? disclaimer,
    List<String>? legalCitations,
    int? version,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByUserId,
  }) {
    return LetterTemplateEntity(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      content: content ?? this.content,
      variables: variables ?? this.variables,
      complianceNotes: complianceNotes ?? this.complianceNotes,
      disclaimer: disclaimer ?? this.disclaimer,
      legalCitations: legalCitations ?? this.legalCitations,
      version: version ?? this.version,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
    );
  }
}

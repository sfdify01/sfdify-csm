import 'package:equatable/equatable.dart';

/// Phone number value object
class PhoneEntity extends Equatable {
  final String type; // 'mobile', 'home', 'work'
  final String number; // E.164 format: +1-555-123-4567
  final bool isPrimary;
  final bool verified;

  const PhoneEntity({
    required this.type,
    required this.number,
    this.isPrimary = false,
    this.verified = false,
  });

  /// Format phone number for display (e.g., (555) 123-4567)
  String get formatted {
    final cleaned = number.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
      return '(${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    }
    return number;
  }

  /// Get clean phone number (digits only)
  String get digitsOnly => number.replaceAll(RegExp(r'[^\d]'), '');

  @override
  List<Object?> get props => [type, number, isPrimary, verified];

  PhoneEntity copyWith({
    String? type,
    String? number,
    bool? isPrimary,
    bool? verified,
  }) {
    return PhoneEntity(
      type: type ?? this.type,
      number: number ?? this.number,
      isPrimary: isPrimary ?? this.isPrimary,
      verified: verified ?? this.verified,
    );
  }
}

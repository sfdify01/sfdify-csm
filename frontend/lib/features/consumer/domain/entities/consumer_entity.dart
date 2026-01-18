import 'package:equatable/equatable.dart';

/// Consumer status enum representing the workflow stage
enum ConsumerStatus {
  unsent,
  awaitingResponse,
  inProgress,
  completed,
}

/// SmartCredit source provider enum
enum SmartCreditSource {
  smartCredit,
  identityIq,
  myScoreIq,
}

/// Document type enum for consumer verification documents
enum ConsumerDocumentType {
  idFront,
  idBack,
  addressVerification,
  ssnCard,
  idTheftAffidavit,
}

/// Consumer document entity for verification documents
class ConsumerDocument extends Equatable {
  const ConsumerDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedAt,
    this.mimeType,
    this.fileSize,
  });

  final String id;
  final ConsumerDocumentType type;
  final String fileName;
  final String fileUrl;
  final DateTime uploadedAt;
  final String? mimeType;
  final int? fileSize;

  @override
  List<Object?> get props => [id, type, fileName, fileUrl, uploadedAt, mimeType, fileSize];
}

/// Consumer address entity
class ConsumerAddress extends Equatable {
  const ConsumerAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.street2,
    this.type = 'current',
    this.isPrimary = true,
  });

  final String street;
  final String? street2;
  final String city;
  final String state;
  final String zipCode;
  final String type;
  final bool isPrimary;

  @override
  List<Object?> get props => [street, street2, city, state, zipCode, type, isPrimary];
}

/// Consumer domain entity representing a credit dispute consumer
///
/// Contains basic consumer information used across the application
class ConsumerEntity extends Equatable {
  const ConsumerEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.ssnLast4,
    this.status = ConsumerStatus.unsent,
    this.isActive = true,
    this.lastSentLetterAt,
    this.lastCreditReportAt,
    this.smartCreditSource,
    this.smartCreditUsername,
    this.smartCreditConnectionId,
    this.isSmartCreditConnected = false,
    this.addresses = const [],
    this.documents = const [],
    this.hasConsent = false,
    this.consentDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? ssnLast4;
  final ConsumerStatus status;
  final bool isActive;
  final DateTime? lastSentLetterAt;
  final DateTime? lastCreditReportAt;
  final SmartCreditSource? smartCreditSource;
  final String? smartCreditUsername;
  final String? smartCreditConnectionId;
  final bool isSmartCreditConnected;
  final List<ConsumerAddress> addresses;
  final List<ConsumerDocument> documents;
  final bool hasConsent;
  final DateTime? consentDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Returns the consumer's full name
  String get fullName => '$firstName $lastName';

  /// Returns the consumer's initials (first letter of first and last name)
  String get initials {
    if (firstName.isEmpty || lastName.isEmpty) return 'NA';
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  /// Returns the primary address if available
  ConsumerAddress? get primaryAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (addr) => addr.isPrimary,
      orElse: () => addresses.first,
    );
  }

  /// Returns formatted date of birth string
  String? get formattedDateOfBirth {
    if (dateOfBirth == null) return null;
    return '${dateOfBirth!.month.toString().padLeft(2, '0')}/${dateOfBirth!.day.toString().padLeft(2, '0')}/${dateOfBirth!.year}';
  }

  /// Creates a copy with modified fields
  ConsumerEntity copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? ssnLast4,
    ConsumerStatus? status,
    bool? isActive,
    DateTime? lastSentLetterAt,
    DateTime? lastCreditReportAt,
    SmartCreditSource? smartCreditSource,
    String? smartCreditUsername,
    String? smartCreditConnectionId,
    bool? isSmartCreditConnected,
    List<ConsumerAddress>? addresses,
    List<ConsumerDocument>? documents,
    bool? hasConsent,
    DateTime? consentDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsumerEntity(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      ssnLast4: ssnLast4 ?? this.ssnLast4,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      lastSentLetterAt: lastSentLetterAt ?? this.lastSentLetterAt,
      lastCreditReportAt: lastCreditReportAt ?? this.lastCreditReportAt,
      smartCreditSource: smartCreditSource ?? this.smartCreditSource,
      smartCreditUsername: smartCreditUsername ?? this.smartCreditUsername,
      smartCreditConnectionId: smartCreditConnectionId ?? this.smartCreditConnectionId,
      isSmartCreditConnected: isSmartCreditConnected ?? this.isSmartCreditConnected,
      addresses: addresses ?? this.addresses,
      documents: documents ?? this.documents,
      hasConsent: hasConsent ?? this.hasConsent,
      consentDate: consentDate ?? this.consentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phone,
        dateOfBirth,
        ssnLast4,
        status,
        isActive,
        lastSentLetterAt,
        lastCreditReportAt,
        smartCreditSource,
        smartCreditUsername,
        smartCreditConnectionId,
        isSmartCreditConnected,
        addresses,
        documents,
        hasConsent,
        consentDate,
        createdAt,
        updatedAt,
      ];
}

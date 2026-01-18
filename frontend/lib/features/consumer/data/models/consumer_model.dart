import 'package:ustaxx_csm/features/consumer/domain/entities/consumer_entity.dart';

/// JSON converter for ConsumerStatus enum
class ConsumerStatusConverter {
  const ConsumerStatusConverter();

  ConsumerStatus fromJson(String json) {
    switch (json) {
      case 'unsent':
        return ConsumerStatus.unsent;
      case 'awaiting_response':
        return ConsumerStatus.awaitingResponse;
      case 'in_progress':
        return ConsumerStatus.inProgress;
      case 'completed':
        return ConsumerStatus.completed;
      default:
        return ConsumerStatus.unsent;
    }
  }

  String toJson(ConsumerStatus object) {
    switch (object) {
      case ConsumerStatus.unsent:
        return 'unsent';
      case ConsumerStatus.awaitingResponse:
        return 'awaiting_response';
      case ConsumerStatus.inProgress:
        return 'in_progress';
      case ConsumerStatus.completed:
        return 'completed';
    }
  }
}

/// JSON converter for SmartCreditSource enum
class SmartCreditSourceConverter {
  const SmartCreditSourceConverter();

  SmartCreditSource? fromJson(String? json) {
    if (json == null) return null;
    switch (json) {
      case 'smart_credit':
        return SmartCreditSource.smartCredit;
      case 'identity_iq':
        return SmartCreditSource.identityIq;
      case 'my_score_iq':
        return SmartCreditSource.myScoreIq;
      default:
        return SmartCreditSource.smartCredit;
    }
  }

  String? toJson(SmartCreditSource? object) {
    if (object == null) return null;
    switch (object) {
      case SmartCreditSource.smartCredit:
        return 'smart_credit';
      case SmartCreditSource.identityIq:
        return 'identity_iq';
      case SmartCreditSource.myScoreIq:
        return 'my_score_iq';
    }
  }
}

/// JSON converter for ConsumerDocumentType enum
class ConsumerDocumentTypeConverter {
  const ConsumerDocumentTypeConverter();

  ConsumerDocumentType fromJson(String json) {
    switch (json) {
      case 'id_front':
        return ConsumerDocumentType.idFront;
      case 'id_back':
        return ConsumerDocumentType.idBack;
      case 'address_verification':
        return ConsumerDocumentType.addressVerification;
      case 'ssn_card':
        return ConsumerDocumentType.ssnCard;
      case 'id_theft_affidavit':
        return ConsumerDocumentType.idTheftAffidavit;
      default:
        return ConsumerDocumentType.idFront;
    }
  }

  String toJson(ConsumerDocumentType object) {
    switch (object) {
      case ConsumerDocumentType.idFront:
        return 'id_front';
      case ConsumerDocumentType.idBack:
        return 'id_back';
      case ConsumerDocumentType.addressVerification:
        return 'address_verification';
      case ConsumerDocumentType.ssnCard:
        return 'ssn_card';
      case ConsumerDocumentType.idTheftAffidavit:
        return 'id_theft_affidavit';
    }
  }
}

class ConsumerAddressModel extends ConsumerAddress {
  const ConsumerAddressModel({
    required super.street,
    required super.city,
    required super.state,
    required super.zipCode,
    super.street2,
    super.type = 'current',
    super.isPrimary = true,
  });

  factory ConsumerAddressModel.fromJson(Map<String, dynamic> json) {
    return ConsumerAddressModel(
      street: json['street1'] as String? ?? json['street'] as String? ?? '',
      street2: json['street2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zipCode: json['zipCode'] as String? ?? '',
      type: json['type'] as String? ?? 'current',
      isPrimary: json['isPrimary'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'street': street,
        if (street2 != null) 'street2': street2,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'type': type,
        'isPrimary': isPrimary,
      };

  factory ConsumerAddressModel.fromEntity(ConsumerAddress entity) =>
      ConsumerAddressModel(
        street: entity.street,
        street2: entity.street2,
        city: entity.city,
        state: entity.state,
        zipCode: entity.zipCode,
        type: entity.type,
        isPrimary: entity.isPrimary,
      );
}

class ConsumerDocumentModel extends ConsumerDocument {
  const ConsumerDocumentModel({
    required super.id,
    required super.type,
    required super.fileName,
    required super.fileUrl,
    required super.uploadedAt,
    super.mimeType,
    super.fileSize,
  });

  factory ConsumerDocumentModel.fromJson(Map<String, dynamic> json) {
    return ConsumerDocumentModel(
      id: json['id'] as String,
      type: const ConsumerDocumentTypeConverter().fromJson(json['type'] as String),
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      uploadedAt: json['uploadedAt'] is String
          ? DateTime.parse(json['uploadedAt'] as String)
          : (json['uploadedAt'] as Map<String, dynamic>)['_seconds'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  ((json['uploadedAt'] as Map<String, dynamic>)['_seconds'] as int) * 1000,
                )
              : DateTime.now(),
      mimeType: json['mimeType'] as String?,
      fileSize: json['fileSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': const ConsumerDocumentTypeConverter().toJson(type),
        'fileName': fileName,
        'fileUrl': fileUrl,
        'uploadedAt': uploadedAt.toIso8601String(),
        if (mimeType != null) 'mimeType': mimeType,
        if (fileSize != null) 'fileSize': fileSize,
      };

  factory ConsumerDocumentModel.fromEntity(ConsumerDocument entity) =>
      ConsumerDocumentModel(
        id: entity.id,
        type: entity.type,
        fileName: entity.fileName,
        fileUrl: entity.fileUrl,
        uploadedAt: entity.uploadedAt,
        mimeType: entity.mimeType,
        fileSize: entity.fileSize,
      );
}

class ConsumerModel extends ConsumerEntity {
  const ConsumerModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    super.phone,
    super.dateOfBirth,
    super.ssnLast4,
    super.status = ConsumerStatus.unsent,
    super.isActive = true,
    super.lastSentLetterAt,
    super.lastCreditReportAt,
    super.smartCreditSource,
    super.smartCreditUsername,
    super.smartCreditConnectionId,
    super.isSmartCreditConnected = false,
    super.addresses = const [],
    super.documents = const [],
    super.hasConsent = false,
    super.consentDate,
    super.createdAt,
    super.updatedAt,
  });

  factory ConsumerModel.fromJson(Map<String, dynamic> json) {
    // Parse addresses
    final addressesJson = json['addresses'] as List<dynamic>?;
    final addresses = addressesJson
            ?.map((addr) => ConsumerAddressModel.fromJson(addr as Map<String, dynamic>))
            .toList()
            .cast<ConsumerAddress>() ??
        [];

    // Parse documents
    final documentsJson = json['documents'] as List<dynamic>?;
    final documents = documentsJson
            ?.map((doc) => ConsumerDocumentModel.fromJson(doc as Map<String, dynamic>))
            .toList()
            .cast<ConsumerDocument>() ??
        [];

    return ConsumerModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: (json['emails'] as List<dynamic>?)?.isNotEmpty == true
          ? ((json['emails'] as List<dynamic>).first as Map<String, dynamic>)['address'] as String
          : json['email'] as String? ?? '',
      phone: (json['phones'] as List<dynamic>?)?.isNotEmpty == true
          ? ((json['phones'] as List<dynamic>).first as Map<String, dynamic>)['number'] as String?
          : json['phone'] as String?,
      dateOfBirth: _parseDateTime(json['dob'] ?? json['dateOfBirth']),
      ssnLast4: json['ssnLast4'] as String?,
      status: json['status'] != null
          ? const ConsumerStatusConverter().fromJson(json['status'] as String)
          : ConsumerStatus.unsent,
      isActive: json['isActive'] as bool? ?? true,
      lastSentLetterAt: _parseDateTime(json['lastSentLetterAt']),
      lastCreditReportAt: _parseDateTime(json['lastCreditReportAt']),
      smartCreditSource: const SmartCreditSourceConverter().fromJson(json['smartCreditSource'] as String?),
      smartCreditUsername: json['smartCreditUsername'] as String?,
      smartCreditConnectionId: json['smartCreditConnectionId'] as String?,
      isSmartCreditConnected: json['smartCreditConnectionId'] != null,
      addresses: addresses,
      documents: documents,
      hasConsent: json['consent'] != null || json['hasConsent'] == true,
      consentDate: json['consent'] != null ? _parseDateTime((json['consent'] as Map<String, dynamic>)['agreedAt']) : null,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is Map<String, dynamic>) {
      // Firestore Timestamp format
      final seconds = value['_seconds'] as int?;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null) 'phone': phone,
        if (dateOfBirth != null) 'dob': dateOfBirth!.toIso8601String(),
        if (ssnLast4 != null) 'ssnLast4': ssnLast4,
        'status': const ConsumerStatusConverter().toJson(status),
        'isActive': isActive,
        if (lastSentLetterAt != null) 'lastSentLetterAt': lastSentLetterAt!.toIso8601String(),
        if (lastCreditReportAt != null) 'lastCreditReportAt': lastCreditReportAt!.toIso8601String(),
        if (smartCreditSource != null)
          'smartCreditSource': const SmartCreditSourceConverter().toJson(smartCreditSource),
        if (smartCreditUsername != null) 'smartCreditUsername': smartCreditUsername,
        if (smartCreditConnectionId != null) 'smartCreditConnectionId': smartCreditConnectionId,
        'addresses': addresses.map((addr) => ConsumerAddressModel.fromEntity(addr).toJson()).toList(),
        'documents': documents.map((doc) => ConsumerDocumentModel.fromEntity(doc).toJson()).toList(),
        'hasConsent': hasConsent,
        if (consentDate != null) 'consentDate': consentDate!.toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  factory ConsumerModel.fromEntity(ConsumerEntity entity) => ConsumerModel(
        id: entity.id,
        firstName: entity.firstName,
        lastName: entity.lastName,
        email: entity.email,
        phone: entity.phone,
        dateOfBirth: entity.dateOfBirth,
        ssnLast4: entity.ssnLast4,
        status: entity.status,
        isActive: entity.isActive,
        lastSentLetterAt: entity.lastSentLetterAt,
        lastCreditReportAt: entity.lastCreditReportAt,
        smartCreditSource: entity.smartCreditSource,
        smartCreditUsername: entity.smartCreditUsername,
        smartCreditConnectionId: entity.smartCreditConnectionId,
        isSmartCreditConnected: entity.isSmartCreditConnected,
        addresses: entity.addresses,
        documents: entity.documents,
        hasConsent: entity.hasConsent,
        consentDate: entity.consentDate,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}

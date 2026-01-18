import 'package:equatable/equatable.dart';

sealed class ConsumerFormEvent extends Equatable {
  const ConsumerFormEvent();

  @override
  List<Object?> get props => [];
}

class ConsumerFormLoadRequested extends ConsumerFormEvent {
  final String? consumerId; // null for create mode

  const ConsumerFormLoadRequested({this.consumerId});

  @override
  List<Object?> get props => [consumerId];
}

class ConsumerFormSubmitted extends ConsumerFormEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? ssnLast4;
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? smartCreditSource;
  final String? smartCreditUsername;
  final bool hasConsent;

  const ConsumerFormSubmitted({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.ssnLast4,
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.smartCreditSource,
    this.smartCreditUsername,
    required this.hasConsent,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        email,
        phone,
        dateOfBirth,
        ssnLast4,
        street,
        city,
        state,
        zipCode,
        smartCreditSource,
        smartCreditUsername,
        hasConsent,
      ];
}

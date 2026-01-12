import 'package:equatable/equatable.dart';

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
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;

  /// Returns the consumer's full name
  String get fullName => '$firstName $lastName';

  /// Returns the consumer's initials (first letter of first and last name)
  String get initials {
    if (firstName.isEmpty || lastName.isEmpty) return 'NA';
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [id, firstName, lastName, email, phone];
}

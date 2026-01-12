import 'package:equatable/equatable.dart';

/// Address value object representing a physical address
class AddressEntity extends Equatable {
  final String type; // 'current', 'previous', 'mailing'
  final String street1;
  final String? street2;
  final String city;
  final String state;
  final String zip;
  final String country;
  final bool isCurrent;
  final DateTime? movedInDate;
  final DateTime? movedOutDate;

  const AddressEntity({
    required this.type,
    required this.street1,
    this.street2,
    required this.city,
    required this.state,
    required this.zip,
    this.country = 'US',
    this.isCurrent = false,
    this.movedInDate,
    this.movedOutDate,
  });

  /// Returns formatted single-line address
  String get formatted =>
      '$street1${street2 != null ? ', $street2' : ''}, $city, $state $zip';

  /// Returns multi-line formatted address
  String get multiLineFormatted {
    final buffer = StringBuffer();
    buffer.writeln(street1);
    if (street2 != null && street2!.isNotEmpty) {
      buffer.writeln(street2);
    }
    buffer.write('$city, $state $zip');
    return buffer.toString();
  }

  /// Check if address is valid (has all required fields)
  bool get isValid =>
      street1.isNotEmpty &&
      city.isNotEmpty &&
      state.isNotEmpty &&
      zip.isNotEmpty;

  @override
  List<Object?> get props => [
        type,
        street1,
        street2,
        city,
        state,
        zip,
        country,
        isCurrent,
        movedInDate,
        movedOutDate,
      ];

  AddressEntity copyWith({
    String? type,
    String? street1,
    String? street2,
    String? city,
    String? state,
    String? zip,
    String? country,
    bool? isCurrent,
    DateTime? movedInDate,
    DateTime? movedOutDate,
  }) {
    return AddressEntity(
      type: type ?? this.type,
      street1: street1 ?? this.street1,
      street2: street2 ?? this.street2,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      country: country ?? this.country,
      isCurrent: isCurrent ?? this.isCurrent,
      movedInDate: movedInDate ?? this.movedInDate,
      movedOutDate: movedOutDate ?? this.movedOutDate,
    );
  }
}

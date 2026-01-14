import 'package:equatable/equatable.dart';

class HomeEntity extends Equatable {
  const HomeEntity({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  List<Object?> get props => [title, description];
}

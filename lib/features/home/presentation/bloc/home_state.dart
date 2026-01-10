part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.data = const [],
    this.errorMessage,
  });

  final HomeStatus status;
  final List<HomeEntity> data;
  final String? errorMessage;

  HomeState copyWith({
    HomeStatus? status,
    List<HomeEntity>? data,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}

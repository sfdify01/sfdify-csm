import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/services/cloud_functions_service.dart';
import 'package:ustaxx_csm/features/users/data/models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<List<UserModel>> getUsers({int? limit, String? cursor});
  Future<UserModel> getUser(String userId);
  Future<UserModel> createUser(Map<String, dynamic> data);
  Future<UserModel> updateUser(String userId, Map<String, dynamic> updates);
}

@Injectable(as: UserRemoteDataSource)
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final CloudFunctionsService _functionsService;

  UserRemoteDataSourceImpl(this._functionsService);

  @override
  Future<List<UserModel>> getUsers({int? limit, String? cursor}) async {
    final response = await _functionsService.usersList(
      limit: limit,
      cursor: cursor,
      fromJson: (json) => UserModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch users');
    }

    return response.data!.items;
  }

  @override
  Future<UserModel> getUser(String userId) async {
    final response = await _functionsService.usersGet(
      userId,
      (json) => UserModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch user');
    }

    return response.data!;
  }

  @override
  Future<UserModel> createUser(Map<String, dynamic> data) async {
    final response = await _functionsService.usersCreate(
      data,
      (json) => UserModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to create user');
    }

    return response.data!;
  }

  @override
  Future<UserModel> updateUser(String userId, Map<String, dynamic> updates) async {
    // Note: usersUpdate is not in the cloud functions service yet
    // This would need to be added if user updates are required
    throw UnimplementedError('User update not yet implemented');
  }
}

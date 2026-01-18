import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/services/cloud_functions_service.dart';
import 'package:ustaxx_csm/features/tenant/data/models/tenant_model.dart';

abstract class TenantRemoteDataSource {
  /// Gets the current tenant (from auth token's tenantId)
  Future<TenantModel> getTenant();
  Future<TenantModel> updateTenant(Map<String, dynamic> updates);
}

@Injectable(as: TenantRemoteDataSource)
class TenantRemoteDataSourceImpl implements TenantRemoteDataSource {
  final CloudFunctionsService _functionsService;

  TenantRemoteDataSourceImpl(this._functionsService);

  @override
  Future<TenantModel> getTenant() async {
    final response = await _functionsService.tenantsGet(
      (json) => TenantModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch tenant');
    }

    return response.data!;
  }

  @override
  Future<TenantModel> updateTenant(Map<String, dynamic> updates) async {
    final response = await _functionsService.tenantsUpdate(
      updates,
      (json) => TenantModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to update tenant');
    }

    return response.data!;
  }
}

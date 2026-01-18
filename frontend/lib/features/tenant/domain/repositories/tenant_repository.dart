import 'package:fpdart/fpdart.dart';
import 'package:ustaxx_csm/core/error/failures.dart';
import 'package:ustaxx_csm/features/tenant/domain/entities/tenant_entity.dart';

abstract class TenantRepository {
  /// Gets the current tenant (from auth token's tenantId)
  Future<Either<Failure, TenantEntity>> getTenant();

  Future<Either<Failure, TenantEntity>> updateTenant(
    Map<String, dynamic> updates,
  );

  Future<Either<Failure, TenantEntity>> updateBranding({
    String? logoUrl,
    String? primaryColor,
    String? companyName,
    String? tagline,
  });
}

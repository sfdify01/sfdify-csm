import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/services/cloud_functions_service.dart';
import 'package:ustaxx_csm/features/consumer/data/models/consumer_model.dart';

abstract class ConsumerRemoteDataSource {
  Future<List<ConsumerModel>> getConsumers({
    int? limit,
    String? cursor,
    String? search,
  });
  Future<ConsumerModel> getConsumer(String consumerId);
  Future<ConsumerModel> createConsumer(Map<String, dynamic> data);
  Future<ConsumerModel> updateConsumer(String consumerId, Map<String, dynamic> updates);
}

@Injectable(as: ConsumerRemoteDataSource)
class ConsumerRemoteDataSourceImpl implements ConsumerRemoteDataSource {
  final CloudFunctionsService _functionsService;

  ConsumerRemoteDataSourceImpl(this._functionsService);

  @override
  Future<List<ConsumerModel>> getConsumers({
    int? limit,
    String? cursor,
    String? search,
  }) async {
    final response = await _functionsService.consumersList(
      limit: limit,
      cursor: cursor,
      search: search,
      fromJson: (json) => ConsumerModel.fromJson(_normalizeConsumerJson(json)),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch consumers');
    }

    return response.data!.items;
  }

  @override
  Future<ConsumerModel> getConsumer(String consumerId) async {
    final response = await _functionsService.consumersGet(
      consumerId,
      (json) => ConsumerModel.fromJson(_normalizeConsumerJson(json)),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch consumer');
    }

    return response.data!;
  }

  @override
  Future<ConsumerModel> createConsumer(Map<String, dynamic> data) async {
    final response = await _functionsService.consumersCreate(
      data,
      (json) => ConsumerModel.fromJson(_normalizeConsumerJson(json)),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to create consumer');
    }

    return response.data!;
  }

  @override
  Future<ConsumerModel> updateConsumer(
    String consumerId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _functionsService.consumersUpdate(
      consumerId,
      updates,
      (json) => ConsumerModel.fromJson(_normalizeConsumerJson(json)),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to update consumer');
    }

    return response.data!;
  }

  /// Normalize backend response JSON to match frontend model expectations
  Map<String, dynamic> _normalizeConsumerJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    // Extract primary email from emails array
    if (normalized['emails'] is List && (normalized['emails'] as List).isNotEmpty) {
      final emails = normalized['emails'] as List;
      final primaryEmail = emails.firstWhere(
        (e) => e is Map && e['isPrimary'] == true,
        orElse: () => emails.first,
      );
      if (primaryEmail is Map && primaryEmail['address'] != null) {
        normalized['email'] = primaryEmail['address'];
      }
    }

    // Extract primary phone from phones array
    if (normalized['phones'] is List && (normalized['phones'] as List).isNotEmpty) {
      final phones = normalized['phones'] as List;
      final primaryPhone = phones.firstWhere(
        (e) => e is Map && e['isPrimary'] == true,
        orElse: () => phones.first,
      );
      if (primaryPhone is Map && primaryPhone['number'] != null) {
        normalized['phone'] = primaryPhone['number'];
      }
    }

    // Convert timestamps
    for (final key in ['createdAt', 'updatedAt', 'kycVerifiedAt']) {
      if (normalized[key] != null) {
        normalized[key] = _convertTimestamp(normalized[key]);
      }
    }

    return normalized;
  }

  String? _convertTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
    }
    if (value is Map) {
      if (value.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          (value['_seconds'] as int) * 1000,
        ).toIso8601String();
      }
      if (value.containsKey('seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          (value['seconds'] as int) * 1000,
        ).toIso8601String();
      }
    }
    return null;
  }
}

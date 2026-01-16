import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/services/cloud_functions_service.dart';
import 'package:sfdify_scm/features/dispute/data/models/dispute_model.dart';
import 'package:sfdify_scm/shared/data/models/dispute_metrics_model.dart';

abstract class DisputeRemoteDataSource {
  Future<DisputeMetricsModel> getMetrics();
  Future<List<DisputeModel>> getDisputes({
    String? bureau,
    String? status,
    int? limit,
    String? cursor,
  });
  Future<DisputeModel> getDispute(String disputeId);
  Future<DisputeModel> createDispute(Map<String, dynamic> data);
  Future<DisputeModel> updateDispute(String disputeId, Map<String, dynamic> updates);
  Future<DisputeModel> submitDispute(String disputeId);
  Future<DisputeModel> approveDispute(String disputeId);
  Future<DisputeModel> closeDispute(String disputeId, String resolution);
}

@Injectable(as: DisputeRemoteDataSource)
class DisputeRemoteDataSourceImpl implements DisputeRemoteDataSource {
  final CloudFunctionsService _functionsService;

  DisputeRemoteDataSourceImpl(this._functionsService);

  @override
  Future<DisputeMetricsModel> getMetrics() async {
    final response = await _functionsService.adminAnalyticsDisputes(
      (json) => _transformAnalyticsToMetrics(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch dispute metrics');
    }

    return response.data!;
  }

  /// Transform backend analytics response to frontend metrics model
  DisputeMetricsModel _transformAnalyticsToMetrics(Map<String, dynamic> json) {
    final overview = json['overview'] as Map<String, dynamic>? ?? {};
    final byStatus = json['byStatus'] as Map<String, dynamic>? ?? {};
    final resolution = json['resolution'] as Map<String, dynamic>? ?? {};

    return DisputeMetricsModel(
      totalDisputes: (overview['total'] as num?)?.toInt() ?? 0,
      percentageChange: 0.0, // Not provided by backend, would need trend calculation
      pendingApproval: (byStatus['pending_approval'] as num?)?.toInt() ??
                       (byStatus['pendingApproval'] as num?)?.toInt() ?? 0,
      inTransitViaLob: (byStatus['in_transit'] as num?)?.toInt() ??
                       (byStatus['inTransit'] as num?)?.toInt() ?? 0,
      slaBreaches: (resolution['pendingOverSla'] as num?)?.toInt() ?? 0,
      slaBreachesToday: 0, // Not provided by backend
    );
  }

  @override
  Future<List<DisputeModel>> getDisputes({
    String? bureau,
    String? status,
    int? limit,
    String? cursor,
  }) async {
    final response = await _functionsService.disputesList(
      limit: limit,
      cursor: cursor,
      status: status,
      fromJson: (json) => DisputeModel.fromJson(_normalizeDisputeJson(json)),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch disputes');
    }

    var disputes = response.data!.items;

    // Filter by bureau client-side if provided (backend may not support this filter)
    if (bureau != null) {
      disputes = disputes.where((d) => d.bureau == bureau).toList();
    }

    return disputes;
  }

  @override
  Future<DisputeModel> getDispute(String disputeId) async {
    final response = await _functionsService.disputesGet(
      disputeId,
      (json) => DisputeModel.fromJson(_normalizeDisputeJson(json)),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch dispute');
    }

    return response.data!;
  }

  @override
  Future<DisputeModel> createDispute(Map<String, dynamic> data) async {
    final response = await _functionsService.disputesCreate(
      data,
      (json) => DisputeModel.fromJson(_normalizeDisputeJson(json)),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to create dispute');
    }

    return response.data!;
  }

  @override
  Future<DisputeModel> updateDispute(String disputeId, Map<String, dynamic> updates) async {
    final response = await _functionsService.disputesUpdate(
      disputeId,
      updates,
      (json) => DisputeModel.fromJson(_normalizeDisputeJson(json)),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to update dispute');
    }

    return response.data!;
  }

  @override
  Future<DisputeModel> submitDispute(String disputeId) async {
    final response = await _functionsService.disputesSubmit(
      disputeId,
      (json) => DisputeModel.fromJson(_normalizeDisputeJson(json)),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to submit dispute');
    }

    return response.data!;
  }

  @override
  Future<DisputeModel> approveDispute(String disputeId) async {
    final response = await _functionsService.disputesApprove(
      disputeId,
      (json) => DisputeModel.fromJson(_normalizeDisputeJson(json)),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to approve dispute');
    }

    return response.data!;
  }

  @override
  Future<DisputeModel> closeDispute(String disputeId, String resolution) async {
    final response = await _functionsService.disputesClose(
      disputeId,
      resolution,
      (json) => DisputeModel.fromJson(_normalizeDisputeJson(json)),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to close dispute');
    }

    return response.data!;
  }

  /// Normalize backend response JSON to match frontend model expectations
  Map<String, dynamic> _normalizeDisputeJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    // Backend stores timestamps in nested 'timestamps' object, flatten them
    if (normalized['timestamps'] is Map) {
      final timestamps = normalized['timestamps'] as Map<String, dynamic>;
      for (final key in timestamps.keys) {
        if (!normalized.containsKey(key)) {
          normalized[key] = timestamps[key];
        }
      }
      normalized.remove('timestamps');
    }

    // Backend stores 'updatedAt' at root level, keep it
    // Backend uses 'assignedTo', frontend uses 'assignedToUserId'
    if (normalized['assignedTo'] != null && !normalized.containsKey('assignedToUserId')) {
      normalized['assignedToUserId'] = normalized['assignedTo'];
    }

    // Backend uses 'internalNotes', frontend uses 'resolutionNotes'
    if (normalized['internalNotes'] != null && !normalized.containsKey('resolutionNotes')) {
      normalized['resolutionNotes'] = normalized['internalNotes'];
    }

    // Convert Firestore timestamps to ISO strings for JSON parsing
    final timestampKeys = [
      'createdAt', 'updatedAt', 'submittedAt', 'dueAt', 'closedAt',
      'followedUpAt', 'bureauResponseReceivedAt', 'approvedAt', 'rejectedAt',
      'mailedAt', 'deliveredAt', 'slaExtendedAt'
    ];

    for (final key in timestampKeys) {
      if (normalized[key] != null) {
        normalized[key] = _convertTimestamp(normalized[key]);
      }
    }

    return normalized;
  }

  /// Convert various timestamp formats to ISO string
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

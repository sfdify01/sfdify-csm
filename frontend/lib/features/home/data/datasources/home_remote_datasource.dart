import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/services/cloud_functions_service.dart';
import 'package:ustaxx_csm/features/home/data/models/home_model.dart';
import 'package:ustaxx_csm/shared/data/models/dispute_metrics_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<HomeModel>> getHomeData();
  Future<DashboardData> getDashboardData();
}

@Injectable(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final CloudFunctionsService _functionsService;

  HomeRemoteDataSourceImpl(this._functionsService);

  @override
  Future<List<HomeModel>> getHomeData() async {
    // Return dashboard cards based on real analytics
    final dashboard = await getDashboardData();

    return [
      HomeModel(
        title: 'Active Disputes',
        description: '${dashboard.disputeStats?.activeCount ?? 0} disputes in progress',
      ),
      HomeModel(
        title: 'Pending Letters',
        description: '${dashboard.letterStats?.pendingCount ?? 0} awaiting action',
      ),
      HomeModel(
        title: 'Success Rate',
        description: '${((dashboard.disputeStats?.successRate ?? 0) * 100).toStringAsFixed(0)}% resolved favorably',
      ),
    ];
  }

  @override
  Future<DashboardData> getDashboardData() async {
    // Fetch dispute analytics
    DisputeStatsModel? disputeStats;
    LetterStatsModel? letterStats;

    try {
      final disputeResponse = await _functionsService.adminAnalyticsDisputes(
        (json) => DisputeStatsModel.fromJson(json),
      );
      if (disputeResponse.success && disputeResponse.data != null) {
        disputeStats = disputeResponse.data;
      }
    } catch (_) {
      // Ignore analytics errors - dashboard should still work
    }

    try {
      final letterResponse = await _functionsService.adminAnalyticsLetters(
        (json) => LetterStatsModel.fromJson(json),
      );
      if (letterResponse.success && letterResponse.data != null) {
        letterStats = letterResponse.data;
      }
    } catch (_) {
      // Ignore analytics errors - dashboard should still work
    }

    return DashboardData(
      disputeStats: disputeStats,
      letterStats: letterStats,
    );
  }
}

/// Dashboard data container
class DashboardData {
  final DisputeStatsModel? disputeStats;
  final LetterStatsModel? letterStats;

  DashboardData({
    this.disputeStats,
    this.letterStats,
  });
}

/// Dispute statistics model
class DisputeStatsModel {
  final int totalCount;
  final int activeCount;
  final int resolvedCount;
  final double successRate;
  final Map<String, int> byStatus;
  final Map<String, int> byBureau;

  DisputeStatsModel({
    required this.totalCount,
    required this.activeCount,
    required this.resolvedCount,
    required this.successRate,
    required this.byStatus,
    required this.byBureau,
  });

  factory DisputeStatsModel.fromJson(Map<String, dynamic> json) {
    return DisputeStatsModel(
      totalCount: json['totalCount'] as int? ?? 0,
      activeCount: json['activeCount'] as int? ?? 0,
      resolvedCount: json['resolvedCount'] as int? ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
      byStatus: Map<String, int>.from(json['byStatus'] as Map? ?? {}),
      byBureau: Map<String, int>.from(json['byBureau'] as Map? ?? {}),
    );
  }
}

/// Letter statistics model
class LetterStatsModel {
  final int totalCount;
  final int pendingCount;
  final int sentCount;
  final int deliveredCount;
  final Map<String, int> byStatus;

  LetterStatsModel({
    required this.totalCount,
    required this.pendingCount,
    required this.sentCount,
    required this.deliveredCount,
    required this.byStatus,
  });

  factory LetterStatsModel.fromJson(Map<String, dynamic> json) {
    return LetterStatsModel(
      totalCount: json['totalCount'] as int? ?? 0,
      pendingCount: json['pendingCount'] as int? ?? 0,
      sentCount: json['sentCount'] as int? ?? 0,
      deliveredCount: json['deliveredCount'] as int? ?? 0,
      byStatus: Map<String, int>.from(json['byStatus'] as Map? ?? {}),
    );
  }
}

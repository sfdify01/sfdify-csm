import 'package:injectable/injectable.dart';
import 'package:sfdify_scm/core/network/dio_client.dart';
import 'package:sfdify_scm/features/consumer/data/models/consumer_model.dart';
import 'package:sfdify_scm/features/dispute/data/models/dispute_model.dart';
import 'package:sfdify_scm/shared/data/models/dispute_metrics_model.dart';

abstract class DisputeRemoteDataSource {
  Future<DisputeMetricsModel> getMetrics();
  Future<List<DisputeModel>> getDisputes({
    String? bureau,
    String? status,
    int page = 1,
    int perPage = 20,
  });
}

@Injectable(as: DisputeRemoteDataSource)
class DisputeRemoteDataSourceImpl implements DisputeRemoteDataSource {
  final DioClient _dioClient;

  DisputeRemoteDataSourceImpl(this._dioClient);

  @override
  Future<DisputeMetricsModel> getMetrics() async {
    // TODO: Replace with real API call when backend is ready
    // final response = await _dioClient.get(ApiConstants.disputeMetrics);
    // return DisputeMetricsModel.fromJson(response.data);

    // Mock data for development
    await Future.delayed(const Duration(milliseconds: 800));
    return const DisputeMetricsModel(
      totalDisputes: 1240,
      percentageChange: 5.0,
      pendingApproval: 45,
      inTransitViaLob: 120,
      slaBreaches: 3,
      slaBreachesToday: 1,
    );
  }

  @override
  Future<List<DisputeModel>> getDisputes({
    String? bureau,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    // TODO: Replace with real API call when backend is ready
    // final response = await _dioClient.get(
    //   ApiConstants.disputes,
    //   queryParameters: {
    //     if (bureau != null) 'bureau': bureau,
    //     if (status != null) 'status': status,
    //     'page': page,
    //     'per_page': perPage,
    //   },
    // );
    // return (response.data['data'] as List)
    //     .map((json) => DisputeModel.fromJson(json))
    //     .toList();

    // Mock data for development
    await Future.delayed(const Duration(milliseconds: 600));

    final mockDisputes = [
      DisputeModel(
        id: '1',
        consumerId: '849202',
        consumer: const ConsumerModel(
          id: '849202',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@example.com',
          phone: '(555) 123-4567',
        ),
        tradelineId: 'tl-1',
        bureau: 'experian',
        type: '611_dispute',
        reasonCodes: const ['inaccurate_balance', 'wrong_dates'],
        narrative: 'Inaccurate late payment',
        status: 'delivered',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        dueAt: DateTime.now().add(const Duration(days: 25)),
        priority: 'medium',
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DisputeModel(
        id: '2',
        consumerId: '849205',
        consumer: const ConsumerModel(
          id: '849205',
          firstName: 'Alice',
          lastName: 'Smith',
          email: 'alice.smith@example.com',
          phone: '(555) 234-5678',
        ),
        tradelineId: 'tl-2',
        bureau: 'equifax',
        type: '611_dispute',
        reasonCodes: const ['not_mine'],
        narrative: 'Unknown account',
        status: 'in_transit',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        dueAt: DateTime.now().add(const Duration(days: 27)),
        priority: 'high',
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      DisputeModel(
        id: '3',
        consumerId: '849211',
        consumer: const ConsumerModel(
          id: '849211',
          firstName: 'Michael',
          lastName: 'Jordan',
          email: 'michael.jordan@example.com',
          phone: '(555) 345-6789',
        ),
        tradelineId: 'tl-3',
        bureau: 'transunion',
        type: 'mov_request',
        reasonCodes: const ['invalid_verification'],
        narrative: 'Bankruptcy error',
        status: 'pending_review',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        priority: 'urgent',
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      DisputeModel(
        id: '4',
        consumerId: '849220',
        consumer: const ConsumerModel(
          id: '849220',
          firstName: 'Robert',
          lastName: 'Kiyosaki',
          email: 'robert.kiyosaki@example.com',
          phone: '(555) 456-7890',
        ),
        tradelineId: 'tl-4',
        bureau: 'equifax',
        type: '611_dispute',
        reasonCodes: const ['inaccurate_balance'],
        narrative: 'Collection update',
        status: 'mailed',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        dueAt: DateTime.now().add(const Duration(days: 23)),
        priority: 'medium',
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    // Filter by bureau if provided
    if (bureau != null) {
      return mockDisputes.where((d) => d.bureau == bureau).toList();
    }

    return mockDisputes;
  }
}

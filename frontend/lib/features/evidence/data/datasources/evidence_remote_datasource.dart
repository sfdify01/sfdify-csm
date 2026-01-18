import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/services/cloud_functions_service.dart';
import 'package:ustaxx_csm/features/evidence/data/models/evidence_model.dart';

abstract class EvidenceRemoteDataSource {
  Future<List<EvidenceModel>> getEvidenceList({
    int? limit,
    String? cursor,
    String? consumerId,
  });
  Future<EvidenceModel> getEvidence(String evidenceId);
  Future<EvidenceModel> uploadEvidence(Map<String, dynamic> data);
}

@Injectable(as: EvidenceRemoteDataSource)
class EvidenceRemoteDataSourceImpl implements EvidenceRemoteDataSource {
  final CloudFunctionsService _functionsService;

  EvidenceRemoteDataSourceImpl(this._functionsService);

  @override
  Future<List<EvidenceModel>> getEvidenceList({
    int? limit,
    String? cursor,
    String? consumerId,
  }) async {
    final response = await _functionsService.evidenceList(
      limit: limit,
      cursor: cursor,
      consumerId: consumerId,
      fromJson: (json) => EvidenceModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch evidence list');
    }

    return response.data!.items;
  }

  @override
  Future<EvidenceModel> getEvidence(String evidenceId) async {
    final response = await _functionsService.evidenceGet(
      evidenceId,
      (json) => EvidenceModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch evidence');
    }

    return response.data!;
  }

  @override
  Future<EvidenceModel> uploadEvidence(Map<String, dynamic> data) async {
    final response = await _functionsService.evidenceUpload(
      data,
      (json) => EvidenceModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to upload evidence');
    }

    return response.data!;
  }
}

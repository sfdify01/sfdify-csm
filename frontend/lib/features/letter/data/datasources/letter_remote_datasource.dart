import 'package:injectable/injectable.dart';
import 'package:ustaxx_csm/core/services/cloud_functions_service.dart';
import 'package:ustaxx_csm/features/letter/data/models/letter_model.dart';

abstract class LetterRemoteDataSource {
  Future<List<LetterModel>> getLetters({
    int? limit,
    String? cursor,
    String? disputeId,
    String? status,
  });
  Future<LetterModel> getLetter(String letterId);
  Future<LetterModel> generateLetter({
    required String disputeId,
    required String templateId,
    required String mailType,
    bool? includeEvidenceIndex,
    bool? attachEvidence,
    String? additionalText,
  });
  Future<LetterModel> approveLetter(String letterId);
  Future<LetterModel> sendLetter({
    required String letterId,
    required String idempotencyKey,
    String? mailType,
    String? scheduledSendDate,
  });
}

@Injectable(as: LetterRemoteDataSource)
class LetterRemoteDataSourceImpl implements LetterRemoteDataSource {
  final CloudFunctionsService _functionsService;

  LetterRemoteDataSourceImpl(this._functionsService);

  @override
  Future<List<LetterModel>> getLetters({
    int? limit,
    String? cursor,
    String? disputeId,
    String? status,
  }) async {
    final response = await _functionsService.lettersList(
      limit: limit,
      cursor: cursor,
      disputeId: disputeId,
      status: status,
      fromJson: (json) => LetterModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch letters');
    }

    return response.data!.items;
  }

  @override
  Future<LetterModel> getLetter(String letterId) async {
    final response = await _functionsService.lettersGet(
      letterId,
      (json) => LetterModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to fetch letter');
    }

    return response.data!;
  }

  @override
  Future<LetterModel> generateLetter({
    required String disputeId,
    required String templateId,
    required String mailType,
    bool? includeEvidenceIndex,
    bool? attachEvidence,
    String? additionalText,
  }) async {
    final response = await _functionsService.lettersGenerate(
      disputeId: disputeId,
      templateId: templateId,
      mailType: mailType,
      includeEvidenceIndex: includeEvidenceIndex,
      attachEvidence: attachEvidence,
      additionalText: additionalText,
      fromJson: (json) => LetterModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to generate letter');
    }

    return response.data!;
  }

  @override
  Future<LetterModel> approveLetter(String letterId) async {
    final response = await _functionsService.lettersApprove(
      letterId,
      (json) => LetterModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to approve letter');
    }

    return response.data!;
  }

  @override
  Future<LetterModel> sendLetter({
    required String letterId,
    required String idempotencyKey,
    String? mailType,
    String? scheduledSendDate,
  }) async {
    final response = await _functionsService.lettersSend(
      letterId: letterId,
      idempotencyKey: idempotencyKey,
      mailType: mailType,
      scheduledSendDate: scheduledSendDate,
      fromJson: (json) => LetterModel.fromJson(json),
    );

    if (!response.success || response.data == null) {
      throw Exception(response.error?.message ?? 'Failed to send letter');
    }

    return response.data!;
  }
}

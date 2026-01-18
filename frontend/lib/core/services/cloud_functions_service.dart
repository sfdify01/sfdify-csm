import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// API response wrapper matching backend response structure
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  final bool success;
  final T? data;
  final ApiError? error;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : json['data'] as T?,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// API error structure
class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final dynamic details;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'An error occurred',
      details: json['details'],
    );
  }
}

/// Paginated response structure
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  final List<T> items;
  final Pagination pagination;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final itemsList = (json['items'] as List<dynamic>?) ?? [];
    return PaginatedResponse(
      items: itemsList
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

/// Pagination metadata
class Pagination {
  const Pagination({
    required this.total,
    required this.limit,
    required this.hasMore,
    this.cursor,
  });

  final int total;
  final int limit;
  final bool hasMore;
  final String? cursor;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 20,
      hasMore: json['hasMore'] as bool? ?? false,
      cursor: json['cursor'] as String?,
    );
  }
}

/// Service for calling Firebase Cloud Functions.
///
/// Provides typed wrappers around callable functions with
/// error handling and response parsing.
@singleton
class CloudFunctionsService {
  CloudFunctionsService(this._functions);

  final FirebaseFunctions _functions;

  /// Call a Cloud Function and parse the response
  Future<ApiResponse<T>> call<T>({
    required String functionName,
    Map<String, dynamic>? data,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      debugPrint('[CloudFunctions] Calling $functionName with data: $data');
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call<Map<String, dynamic>>(data).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw FirebaseFunctionsException(
          code: 'deadline-exceeded',
          message: 'Request timed out after 30 seconds. Please try again.',
        ),
      );

      final responseData = result.data;
      debugPrint('[CloudFunctions] Response from $functionName: $responseData');
      return ApiResponse.fromJson(responseData, fromJson);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[CloudFunctions] FirebaseFunctionsException: ${e.code} - ${e.message} - ${e.details}');
      return ApiResponse(
        success: false,
        error: ApiError(
          code: e.code,
          message: e.message ?? 'An error occurred',
          details: e.details,
        ),
      );
    } catch (e) {
      debugPrint('[CloudFunctions] Unexpected error: $e');
      return ApiResponse(
        success: false,
        error: ApiError(
          code: 'UNKNOWN',
          message: e.toString(),
        ),
      );
    }
  }

  /// Call a Cloud Function that returns a paginated list
  Future<ApiResponse<PaginatedResponse<T>>> callPaginated<T>({
    required String functionName,
    Map<String, dynamic>? data,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call<Map<String, dynamic>>(data).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw FirebaseFunctionsException(
          code: 'deadline-exceeded',
          message: 'Request timed out after 30 seconds. Please try again.',
        ),
      );

      final responseData = result.data;
      final success = responseData['success'] as bool? ?? false;

      if (!success) {
        return ApiResponse(
          success: false,
          error: responseData['error'] != null
              ? ApiError.fromJson(
                  responseData['error'] as Map<String, dynamic>,
                )
              : null,
        );
      }

      final paginatedData = responseData['data'] as Map<String, dynamic>?;
      if (paginatedData == null) {
        return const ApiResponse(
          success: false,
          error: ApiError(code: 'INVALID_RESPONSE', message: 'No data'),
        );
      }

      return ApiResponse(
        success: true,
        data: PaginatedResponse.fromJson(paginatedData, fromJson),
      );
    } on FirebaseFunctionsException catch (e) {
      return ApiResponse(
        success: false,
        error: ApiError(
          code: e.code,
          message: e.message ?? 'An error occurred',
          details: e.details,
        ),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: ApiError(
          code: 'UNKNOWN',
          message: e.toString(),
        ),
      );
    }
  }

  // ============================================================================
  // Consumer Functions
  // ============================================================================

  Future<ApiResponse<T>> consumersCreate<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(functionName: 'consumersCreate', data: data, fromJson: fromJson);

  Future<ApiResponse<T>> consumersGet<T>(
    String consumerId,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'consumersGet',
        data: {'consumerId': consumerId},
        fromJson: fromJson,
      );

  Future<ApiResponse<T>> consumersUpdate<T>(
    String consumerId,
    Map<String, dynamic> updates,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'consumersUpdate',
        data: {'consumerId': consumerId, ...updates},
        fromJson: fromJson,
      );

  Future<ApiResponse<PaginatedResponse<T>>> consumersList<T>({
    int? limit,
    String? cursor,
    String? search,
    required T Function(Map<String, dynamic>) fromJson,
  }) =>
      callPaginated(
        functionName: 'consumersList',
        data: {
          if (limit != null) 'limit': limit,
          if (cursor != null) 'cursor': cursor,
          if (search != null) 'search': search,
        },
        fromJson: fromJson,
      );

  // ============================================================================
  // Dispute Functions
  // ============================================================================

  Future<ApiResponse<T>> disputesCreate<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(functionName: 'disputesCreate', data: data, fromJson: fromJson);

  Future<ApiResponse<T>> disputesGet<T>(
    String disputeId,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'disputesGet',
        data: {'disputeId': disputeId},
        fromJson: fromJson,
      );

  Future<ApiResponse<T>> disputesUpdate<T>(
    String disputeId,
    Map<String, dynamic> updates,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'disputesUpdate',
        data: {'disputeId': disputeId, ...updates},
        fromJson: fromJson,
      );

  Future<ApiResponse<PaginatedResponse<T>>> disputesList<T>({
    int? limit,
    String? cursor,
    String? consumerId,
    String? status,
    required T Function(Map<String, dynamic>) fromJson,
  }) =>
      callPaginated(
        functionName: 'disputesList',
        data: {
          if (limit != null) 'limit': limit,
          if (cursor != null) 'cursor': cursor,
          if (consumerId != null) 'consumerId': consumerId,
          if (status != null) 'status': status,
        },
        fromJson: fromJson,
      );

  Future<ApiResponse<T>> disputesSubmit<T>(
    String disputeId,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'disputesSubmit',
        data: {'disputeId': disputeId},
        fromJson: fromJson,
      );

  Future<ApiResponse<T>> disputesApprove<T>(
    String disputeId,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'disputesApprove',
        data: {'disputeId': disputeId},
        fromJson: fromJson,
      );

  Future<ApiResponse<T>> disputesClose<T>(
    String disputeId,
    String resolution,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'disputesClose',
        data: {'disputeId': disputeId, 'resolution': resolution},
        fromJson: fromJson,
      );

  // ============================================================================
  // Letter Functions
  // ============================================================================

  Future<ApiResponse<T>> lettersGenerate<T>(
    String disputeId,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'lettersGenerate',
        data: {'disputeId': disputeId},
        fromJson: fromJson,
      );

  Future<ApiResponse<T>> lettersGet<T>(
    String letterId,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'lettersGet',
        data: {'letterId': letterId},
        fromJson: fromJson,
      );

  Future<ApiResponse<T>> lettersApprove<T>(
    String letterId,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'lettersApprove',
        data: {'letterId': letterId},
        fromJson: fromJson,
      );

  Future<ApiResponse<T>> lettersSend<T>(
    String letterId,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'lettersSend',
        data: {'letterId': letterId},
        fromJson: fromJson,
      );

  Future<ApiResponse<PaginatedResponse<T>>> lettersList<T>({
    int? limit,
    String? cursor,
    String? disputeId,
    String? status,
    required T Function(Map<String, dynamic>) fromJson,
  }) =>
      callPaginated(
        functionName: 'lettersList',
        data: {
          if (limit != null) 'limit': limit,
          if (cursor != null) 'cursor': cursor,
          if (disputeId != null) 'disputeId': disputeId,
          if (status != null) 'status': status,
        },
        fromJson: fromJson,
      );

  // ============================================================================
  // Evidence Functions
  // ============================================================================

  Future<ApiResponse<T>> evidenceUpload<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(functionName: 'evidenceUpload', data: data, fromJson: fromJson);

  Future<ApiResponse<T>> evidenceGet<T>(
    String evidenceId,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'evidenceGet',
        data: {'evidenceId': evidenceId},
        fromJson: fromJson,
      );

  Future<ApiResponse<PaginatedResponse<T>>> evidenceList<T>({
    int? limit,
    String? cursor,
    String? consumerId,
    required T Function(Map<String, dynamic>) fromJson,
  }) =>
      callPaginated(
        functionName: 'evidenceList',
        data: {
          if (limit != null) 'limit': limit,
          if (cursor != null) 'cursor': cursor,
          if (consumerId != null) 'consumerId': consumerId,
        },
        fromJson: fromJson,
      );

  // ============================================================================
  // Admin/Analytics Functions
  // ============================================================================

  Future<ApiResponse<T>> adminAnalyticsDisputes<T>(
    T Function(Map<String, dynamic>) fromJson, {
    String? startDate,
    String? endDate,
  }) =>
      call(
        functionName: 'adminAnalyticsDisputes',
        data: {
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
        fromJson: fromJson,
      );

  Future<ApiResponse<T>> adminAnalyticsLetters<T>(
    T Function(Map<String, dynamic>) fromJson, {
    String? startDate,
    String? endDate,
  }) =>
      call(
        functionName: 'adminAnalyticsLetters',
        data: {
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
        fromJson: fromJson,
      );

  // ============================================================================
  // Tenant Functions
  // ============================================================================

  Future<ApiResponse<T>> tenantsGet<T>(
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(functionName: 'tenantsGet', fromJson: fromJson);

  Future<ApiResponse<T>> tenantsUpdate<T>(
    Map<String, dynamic> updates,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(functionName: 'tenantsUpdate', data: updates, fromJson: fromJson);

  // ============================================================================
  // Auth Functions (Public - No Authentication Required)
  // ============================================================================

  /// Sign up with email/password and create a new tenant
  Future<ApiResponse<T>> authSignUp<T>({
    required String email,
    required String password,
    required String displayName,
    required String companyName,
    String plan = 'starter',
    required T Function(Map<String, dynamic>) fromJson,
  }) =>
      call(
        functionName: 'authSignUp',
        data: {
          'email': email,
          'password': password,
          'displayName': displayName,
          'companyName': companyName,
          'plan': plan,
        },
        fromJson: fromJson,
      );

  /// Request a password reset email
  Future<ApiResponse<Map<String, dynamic>>> authRequestPasswordReset({
    required String email,
  }) =>
      call(
        functionName: 'authRequestPasswordReset',
        data: {'email': email},
        fromJson: (json) => json,
      );

  // ============================================================================
  // User Functions
  // ============================================================================

  Future<ApiResponse<T>> usersCreate<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(functionName: 'usersCreate', data: data, fromJson: fromJson);

  Future<ApiResponse<T>> usersGet<T>(
    String userId,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      call(
        functionName: 'usersGet',
        data: {'userId': userId},
        fromJson: fromJson,
      );

  Future<ApiResponse<PaginatedResponse<T>>> usersList<T>({
    int? limit,
    String? cursor,
    required T Function(Map<String, dynamic>) fromJson,
  }) =>
      callPaginated(
        functionName: 'usersList',
        data: {
          if (limit != null) 'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
        fromJson: fromJson,
      );
}

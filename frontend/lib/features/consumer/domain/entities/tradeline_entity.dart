import 'package:equatable/equatable.dart';

/// Tradeline entity representing an individual credit account
class TradelineEntity extends Equatable {
  final String id;
  final String reportId;
  final String bureau;
  final String creditorName;
  final String? accountNumberMasked;
  final String? accountType;
  final DateTime? openedDate;
  final DateTime? closedDate;
  final DateTime? lastPaymentDate;
  final DateTime? lastReportedDate;
  final double? balance;
  final double? originalAmount;
  final double? creditLimit;
  final double? highBalance;
  final double? monthlyPayment;
  final String? status;
  final String? paymentStatus;
  final String? disputeStatus;
  final String? remarks;
  final String? paymentHistory; // "000000111222" format
  final String? smartCreditTradelineId;
  final DateTime createdAt;

  const TradelineEntity({
    required this.id,
    required this.reportId,
    required this.bureau,
    required this.creditorName,
    this.accountNumberMasked,
    this.accountType,
    this.openedDate,
    this.closedDate,
    this.lastPaymentDate,
    this.lastReportedDate,
    this.balance,
    this.originalAmount,
    this.creditLimit,
    this.highBalance,
    this.monthlyPayment,
    this.status,
    this.paymentStatus,
    this.disputeStatus,
    this.remarks,
    this.paymentHistory,
    this.smartCreditTradelineId,
    required this.createdAt,
  });

  /// Check if account is open
  bool get isOpen => status?.toLowerCase() == 'open' && closedDate == null;

  /// Check if account is closed
  bool get isClosed => status?.toLowerCase() == 'closed' || closedDate != null;

  /// Check if account has late payments
  bool get hasLatePayments {
    return paymentStatus?.toLowerCase().contains('late') ?? false;
  }

  /// Check if account is in collection
  bool get isCollection =>
      status?.toLowerCase() == 'collection' ||
      accountType?.toLowerCase() == 'collection';

  /// Check if account is currently disputed
  bool get isDisputed => disputeStatus?.toLowerCase() == 'disputed';

  /// Get utilization percentage (for credit cards)
  double? get utilizationPercentage {
    if (creditLimit == null || creditLimit == 0 || balance == null) {
      return null;
    }
    return (balance! / creditLimit!) * 100;
  }

  /// Get account age in months
  int? get ageInMonths {
    if (openedDate == null) return null;
    return DateTime.now().difference(openedDate!).inDays ~/ 30;
  }

  /// Get display status color
  String get statusColor {
    if (isCollection) return 'red';
    if (hasLatePayments) return 'orange';
    if (isOpen && paymentStatus?.toLowerCase() == 'current') return 'green';
    return 'gray';
  }

  /// Get formatted balance
  String get formattedBalance {
    if (balance == null) return 'N/A';
    return '\$${balance!.toStringAsFixed(2)}';
  }

  /// Get formatted credit limit
  String get formattedCreditLimit {
    if (creditLimit == null) return 'N/A';
    return '\$${creditLimit!.toStringAsFixed(2)}';
  }

  /// Get account type display name
  String get accountTypeDisplayName {
    switch (accountType?.toLowerCase()) {
      case 'credit_card':
        return 'Credit Card';
      case 'mortgage':
        return 'Mortgage';
      case 'auto_loan':
        return 'Auto Loan';
      case 'student_loan':
        return 'Student Loan';
      case 'personal_loan':
        return 'Personal Loan';
      case 'collection':
        return 'Collection';
      default:
        return accountType ?? 'Unknown';
    }
  }

  @override
  List<Object?> get props => [
        id,
        reportId,
        bureau,
        creditorName,
        accountNumberMasked,
        accountType,
        openedDate,
        closedDate,
        lastPaymentDate,
        lastReportedDate,
        balance,
        originalAmount,
        creditLimit,
        highBalance,
        monthlyPayment,
        status,
        paymentStatus,
        disputeStatus,
        remarks,
        paymentHistory,
        smartCreditTradelineId,
        createdAt,
      ];

  TradelineEntity copyWith({
    String? id,
    String? reportId,
    String? bureau,
    String? creditorName,
    String? accountNumberMasked,
    String? accountType,
    DateTime? openedDate,
    DateTime? closedDate,
    DateTime? lastPaymentDate,
    DateTime? lastReportedDate,
    double? balance,
    double? originalAmount,
    double? creditLimit,
    double? highBalance,
    double? monthlyPayment,
    String? status,
    String? paymentStatus,
    String? disputeStatus,
    String? remarks,
    String? paymentHistory,
    String? smartCreditTradelineId,
    DateTime? createdAt,
  }) {
    return TradelineEntity(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      bureau: bureau ?? this.bureau,
      creditorName: creditorName ?? this.creditorName,
      accountNumberMasked: accountNumberMasked ?? this.accountNumberMasked,
      accountType: accountType ?? this.accountType,
      openedDate: openedDate ?? this.openedDate,
      closedDate: closedDate ?? this.closedDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      lastReportedDate: lastReportedDate ?? this.lastReportedDate,
      balance: balance ?? this.balance,
      originalAmount: originalAmount ?? this.originalAmount,
      creditLimit: creditLimit ?? this.creditLimit,
      highBalance: highBalance ?? this.highBalance,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      disputeStatus: disputeStatus ?? this.disputeStatus,
      remarks: remarks ?? this.remarks,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      smartCreditTradelineId:
          smartCreditTradelineId ?? this.smartCreditTradelineId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

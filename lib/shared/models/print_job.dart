/// Print job records (audit trail of every send attempt).
library;

enum PrintJobStatus { sent, failed }

extension PrintJobStatusX on PrintJobStatus {
  String get code => this == PrintJobStatus.sent ? 'sent' : 'failed';
}

class PrintJob {
  final int id;
  final int invoiceId;
  final int attemptedAt;
  final PrintJobStatus status;
  final String? connectionType;
  final String errorMessage;

  const PrintJob({
    required this.id,
    required this.invoiceId,
    required this.attemptedAt,
    required this.status,
    required this.connectionType,
    required this.errorMessage,
  });

  factory PrintJob.fromRow(Map<String, Object?> r) => PrintJob(
        id: r['id'] as int,
        invoiceId: r['invoice_id'] as int,
        attemptedAt: r['attempted_at'] as int,
        status: (r['status'] as String? ?? 'failed') == 'sent'
            ? PrintJobStatus.sent
            : PrintJobStatus.failed,
        connectionType: r['connection_type'] as String?,
        errorMessage: r['error_message'] as String? ?? '',
      );
}

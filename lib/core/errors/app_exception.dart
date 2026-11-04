/// Central error model. Services throw typed exceptions with stable codes;
/// the UI layer converts codes to localized strings.
library;

enum ErrorCode {
  dbFailure,
  invalidInput,
  notFound,
  invoiceConflict,
  printerNotSelected,
  printerConnectionFailed,
  printerNetworkTimeout,
  printerBusy,
  printerError,
  usbPermissionDenied,
  usbDeviceMissing,
  backupFailure,
  restoreFailure,
  exportFailure,
}

class AppException implements Exception {
  final ErrorCode code;
  final String debugDetail;

  AppException(this.code, [this.debugDetail = '']);

  @override
  String toString() => 'AppException($code): $debugDetail';
}

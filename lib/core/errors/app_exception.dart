class AppException implements Exception {
  const AppException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() {
    return 'AppException(code: $code, statusCode: $statusCode, message: $message)';
  }
}


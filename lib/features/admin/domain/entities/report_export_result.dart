class ReportExportResult {
  const ReportExportResult({
    required this.bytes,
    required this.contentType,
    this.fileName,
  });

  final List<int> bytes;
  final String contentType;
  final String? fileName;

  int get sizeInBytes => bytes.length;
}

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.data,
    this.rawData,
  });

  final int statusCode;
  final Map<String, dynamic> data;
  final dynamic rawData;
}

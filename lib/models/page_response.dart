class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  final int pageSize;

  PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNumber,
    required this.pageSize,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageResponse<T>(
      content: (json['content'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      pageNumber: json['pageable']?['pageNumber'] ?? 0,
      pageSize: json['pageable']?['pageSize'] ?? 0,
    );
  }
}

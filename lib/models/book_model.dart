class BookModel {
  final String id;
  final String title;
  final String author;
  final String description;
  final String content;
  final String? coverUrl;
  final String? pdfUrl;
  final String contentType; // 'text', 'pdf', or 'rich'
  final List<String> imageUrls;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.content,
    this.coverUrl,
    this.pdfUrl,
    this.contentType = 'text',
    this.imageUrls = const [],
    this.rating = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      coverUrl: json['cover_url'],
      pdfUrl: json['pdf_url'],
      contentType: json['content_type'] ?? 'text',
      imageUrls: json['image_urls'] != null 
          ? List<String>.from(json['image_urls']) 
          : [],
      rating: (json['rating'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'content': content,
      'cover_url': coverUrl,
      'pdf_url': pdfUrl,
      'content_type': contentType,
      'image_urls': imageUrls,
      'rating': rating,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
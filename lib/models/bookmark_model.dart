class BookmarkModel {
  final String id;
  final String userId;
  final String bookId;
  final DateTime createdAt;

  BookmarkModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
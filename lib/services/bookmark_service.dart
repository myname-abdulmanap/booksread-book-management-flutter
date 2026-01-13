import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_model.dart';
import '../config/supabase_config.dart';

class BookService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _bucketName = 'book-files';

  // ============ BOOK CRUD OPERATIONS ============

  /// Get all books
  Future<List<BookModel>> getAllBooks() async {
    try {
      final response = await _supabase
          .from('books')
          .select()
          .order('updated_at', ascending: false);
      return (response as List)
          .map((book) => BookModel.fromJson(book))
          .toList();
    } catch (e) {
      throw Exception('Failed to get books: ${e.toString()}');
    }
  }

  /// Get single book
  Future<BookModel?> getBook(String id) async {
    try {
      final response = await _supabase
          .from('books')
          .select()
          .eq('id', id)
          .single();
      return BookModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get book: ${e.toString()}');
    }
  }

  /// Add book (Admin only)
  Future<String> addBook(BookModel book) async {
    try {
      final response = await _supabase
          .from('books')
          .insert(book.toJson())
          .select()
          .single();
      return response['id'];
    } catch (e) {
      throw Exception('Failed to add book: ${e.toString()}');
    }
  }

  /// Update book (Admin only)
  Future<void> updateBook(String id, BookModel book) async {
    try {
      await _supabase
          .from('books')
          .update(book.toJson())
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to update book: ${e.toString()}');
    }
  }

  /// Delete book (Admin only)
  Future<void> deleteBook(String id) async {
    try {
      await _supabase.from('books').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete book: ${e.toString()}');
    }
  }

  /// Search books
  Future<List<BookModel>> searchBooks(String query) async {
    try {
      final response = await _supabase
          .from('books')
          .select()
          .or('title.ilike.%$query%,author.ilike.%$query%')
          .order('updated_at', ascending: false);
      return (response as List)
          .map((book) => BookModel.fromJson(book))
          .toList();
    } catch (e) {
      throw Exception('Failed to search books: ${e.toString()}');
    }
  }

  // ============ FILE UPLOAD METHODS ============

  /// Upload cover image
  Future<String?> uploadCoverImage(File imageFile, String bookId) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName =
          'cover_${bookId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'covers/$fileName';

      await _supabase.storage.from(_bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      final publicUrl =
          _supabase.storage.from(_bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload cover image: ${e.toString()}');
    }
  }

  /// Upload PDF file
  Future<String?> uploadPDF(File pdfFile, String bookId) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final fileName =
          'pdf_${bookId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = 'pdfs/$fileName';

      await _supabase.storage.from(_bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );

      final publicUrl =
          _supabase.storage.from(_bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload PDF: ${e.toString()}');
    }
  }

  /// Upload content image
  Future<String?> uploadContentImage(File imageFile, String bookId) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName =
          'content_${bookId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'content_images/$fileName';

      await _supabase.storage.from(_bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      final publicUrl =
          _supabase.storage.from(_bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload content image: ${e.toString()}');
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(String filePath) async {
    try {
      await _supabase.storage.from(_bucketName).remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  // ============ BOOKMARK OPERATIONS ============

  /// Check if book is bookmarked by current user
  Future<bool> isBookmarked(String bookId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('bookmarks')
          .select()
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Toggle bookmark (add/remove)
  Future<void> toggleBookmark(String bookId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if already bookmarked
      final existing = await _supabase
          .from('bookmarks')
          .select()
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .maybeSingle();

      if (existing != null) {
        // Remove bookmark
        await _supabase
            .from('bookmarks')
            .delete()
            .eq('user_id', userId)
            .eq('book_id', bookId);
      } else {
        // Add bookmark
        await _supabase.from('bookmarks').insert({
          'user_id': userId,
          'book_id': bookId,
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle bookmark: ${e.toString()}');
    }
  }

  /// Get user's bookmarked books
  Future<List<BookModel>> getBookmarkedBooks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get bookmarks with book details
      final response = await _supabase
          .from('bookmarks')
          .select('books(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => BookModel.fromJson(item['books']))
          .toList();
    } catch (e) {
      throw Exception('Failed to get bookmarked books: ${e.toString()}');
    }
  }

  // ============ STATISTICS (ADMIN) ============

  /// Get total books count
  Future<int> getTotalBooksCount() async {
    try {
      final response = await _supabase
          .from('books')
          .select('*')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      throw Exception('Failed to get books count: ${e.toString()}');
    }
  }

  /// Get total users count
  Future<int> getTotalUsersCount() async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      throw Exception('Failed to get users count: ${e.toString()}');
    }
  }

  /// Get total bookmarks count
  Future<int> getTotalBookmarksCount() async {
    try {
      final response = await _supabase
          .from('bookmarks')
          .select('*')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      throw Exception('Failed to get bookmarks count: ${e.toString()}');
    }
  }

  /// Get recent bookmark activities
  Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('bookmarks')
          .select('created_at, users(name, email), books(title)')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get recent activities: ${e.toString()}');
    }
  }

  /// Get most popular books (by bookmark count)
  Future<List<Map<String, dynamic>>> getMostPopularBooks({int limit = 5}) async {
    try {
      // Try using RPC function if available
      final response = await _supabase.rpc('get_popular_books', params: {
        'limit_count': limit,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback: Get all books and count manually
      try {
        final books = await getAllBooks();
        final bookPopularity = <String, int>{};

        // Count bookmarks for each book
        for (var book in books) {
          final count = await _getBookmarkCount(book.id);
          bookPopularity[book.id] = count;
        }

        // Sort by bookmark count
        final sortedBooks = books
          ..sort((a, b) =>
              (bookPopularity[b.id] ?? 0).compareTo(bookPopularity[a.id] ?? 0));

        return sortedBooks.take(limit).map((book) {
          return {
            'book_id': book.id,
            'title': book.title,
            'author': book.author,
            'cover_url': book.coverUrl,
            'bookmark_count': bookPopularity[book.id] ?? 0,
          };
        }).toList();
      } catch (e2) {
        return [];
      }
    }
  }

  /// Helper: Get bookmark count for a book
  Future<int> _getBookmarkCount(String bookId) async {
    try {
      final response = await _supabase
          .from('bookmarks')
          .select('*')
          .eq('book_id', bookId)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      return 0;
    }
  }
}
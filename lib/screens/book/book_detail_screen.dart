import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../constants/colors.dart';
import '../../services/book_service.dart';
import '../../widgets/custom_button.dart';
import 'book_read_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final BookService _bookService = BookService();
  bool _isBookmarked = false;
  bool _isLoadingBookmark = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      final isBookmarked = await _bookService.isBookmarked(widget.book.id);
      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
        });
      }
    } catch (e) {
      // Silently fail
      debugPrint('Error checking bookmark: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    setState(() => _isLoadingBookmark = true);
    try {
      await _bookService.toggleBookmark(widget.book.id);
      setState(() {
        _isBookmarked = !_isBookmarked;
        _isLoadingBookmark = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBookmarked
                  ? 'Added to bookmarks'
                  : 'Removed from bookmarks',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingBookmark = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Bookmark Button di AppBar
          IconButton(
            icon: _isLoadingBookmark
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
            onPressed: _isLoadingBookmark ? null : _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Center(
              child: Hero(
                tag: 'book_${widget.book.id}',
                child: Container(
                  height: 280,
                  width: 180,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: widget.book.coverUrl != null &&
                          widget.book.coverUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.book.coverUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildPlaceholder();
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholder();
                            },
                          ),
                        )
                      : _buildPlaceholder(),
                ),
              ),
            ),

            // Book Details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.book.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Author
                  Text(
                    'by ${widget.book.author}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rating
                  if (widget.book.rating > 0)
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < widget.book.rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${widget.book.rating.toStringAsFixed(1)})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                  // Content Type Badge
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getContentTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getContentTypeIcon(),
                          size: 16,
                          color: _getContentTypeColor(),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.book.contentType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getContentTypeColor(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Section
                  const Text(
                    'Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.book.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.justify,
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      // Read Button
                      Expanded(
                        flex: 3,
                        child: CustomButton(
                          text: 'BACA',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookReadScreen(book: widget.book),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Bookmark Button
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isBookmarked
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isLoadingBookmark
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: Icon(
                                  _isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: _isBookmarked
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                                onPressed: _toggleBookmark,
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.book,
          size: 60,
          color: AppColors.textGrey,
        ),
      ),
    );
  }

  Color _getContentTypeColor() {
    switch (widget.book.contentType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'rich':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  IconData _getContentTypeIcon() {
    switch (widget.book.contentType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'rich':
        return Icons.auto_awesome;
      default:
        return Icons.article;
    }
  }
}
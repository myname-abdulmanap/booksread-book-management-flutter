import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book_model.dart';
import '../constants/colors.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;

  const BookCard({
    Key? key,
    required this.book,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image dengan CachedNetworkImage
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.border,
              ),
              child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: book.coverUrl!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        // Optimasi memory - resize gambar
                        memCacheWidth: 280, // 140 * 2 (for high DPI)
                        memCacheHeight: 360, // 180 * 2 (for high DPI)
                        maxWidthDiskCache: 280,
                        maxHeightDiskCache: 360,
                        // Placeholder saat loading
                        placeholder: (context, url) => Container(
                          color: AppColors.border,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Error widget
                        errorWidget: (context, url, error) => _buildPlaceholder(),
                        // Smooth fade in
                        fadeInDuration: const Duration(milliseconds: 200),
                        fadeOutDuration: const Duration(milliseconds: 100),
                      ),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(height: 8),
            
            // Title
            Text(
              book.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Author
            Text(
              book.author,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Rating
            if (book.rating > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    book.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.border,
      ),
      child: Center(
        child: Icon(
          Icons.book,
          size: 40,
          color: AppColors.textGrey.withOpacity(0.5),
        ),
      ),
    );
  }
}
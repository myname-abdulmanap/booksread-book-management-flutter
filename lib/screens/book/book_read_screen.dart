import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/book_model.dart';
import '../../constants/colors.dart';

class BookReadScreen extends StatefulWidget {
  final BookModel book;

  const BookReadScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookReadScreen> createState() => _BookReadScreenState();
}

class _BookReadScreenState extends State<BookReadScreen> {
  double _fontSize = 16.0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.book.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (widget.book.contentType == 'text') ...[
            IconButton(
              icon: const Icon(Icons.text_decrease, color: AppColors.textPrimary),
              onPressed: () {
                setState(() {
                  if (_fontSize > 12) _fontSize--;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.text_increase, color: AppColors.textPrimary),
              onPressed: () {
                setState(() {
                  if (_fontSize < 24) _fontSize++;
                });
              },
            ),
          ],
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.book.contentType == 'pdf' && widget.book.pdfUrl != null) {
      return _buildPDFView();
    } else {
      return _buildTextContent();
    }
  }

  Widget _buildPDFView() {
    return SfPdfViewer.network(
      widget.book.pdfUrl!,
      enableDoubleTapZooming: true,
      enableTextSelection: true,
      scrollDirection: PdfScrollDirection.vertical,
      pageSpacing: 4,
    );
  }

  Widget _buildTextContent() {
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main text content
            SelectableText(
              widget.book.content,
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.8,
                color: AppColors.textPrimary,
              ),
            ),
            
            // Display images if any
            if (widget.book.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 32),
              ...widget.book.imageUrls.map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: AppColors.border,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: AppColors.border,
                      child: const Center(
                        child: Icon(Icons.error),
                      ),
                    ),
                    memCacheHeight: 600,
                    maxHeightDiskCache: 600,
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
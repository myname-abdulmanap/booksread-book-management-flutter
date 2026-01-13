import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/colors.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class BookFormScreen extends StatefulWidget {
  final BookModel? book;

  const BookFormScreen({Key? key, this.book}) : super(key: key);

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final BookService _bookService = BookService();
  
  bool _isLoading = false;
  File? _coverImage;
  File? _pdfFile;
  List<File> _contentImages = [];
  List<String> _imageUrls = [];
  String _contentType = 'text'; // 'text', 'pdf', 'rich'
  String? _existingCoverUrl;
  String? _existingPdfUrl;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.author;
      _descriptionController.text = widget.book!.description;
      _contentController.text = widget.book!.content;
      _existingCoverUrl = widget.book!.coverUrl;
      _existingPdfUrl = widget.book!.pdfUrl;
      _contentType = widget.book!.contentType;
      _imageUrls = List.from(widget.book!.imageUrls ?? []); // Fix null safety
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _coverImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
        _contentType = 'pdf';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF selected: ${result.files.single.name}')),
      );
    }
  }

  Future<void> _pickContentImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _contentImages.add(File(pickedFile.path));
      });
    }
  }

  void _addImageUrl() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Image URL'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'https://example.com/image.jpg',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _imageUrls.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String? coverUrl = _existingCoverUrl;
        String? pdfUrl = _existingPdfUrl;
        List<String> uploadedImageUrls = List.from(_imageUrls);

        // Create book first to get ID
        String bookId = widget.book?.id ?? '';
        
        if (widget.book == null) {
          final tempBook = BookModel(
            id: '',
            title: _titleController.text,
            author: _authorController.text,
            description: _descriptionController.text,
            content: _contentController.text,
            contentType: _contentType,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          bookId = await _bookService.addBook(tempBook);
        }

        // Upload cover if selected
        if (_coverImage != null) {
          coverUrl = await _bookService.uploadCoverImage(_coverImage!, bookId);
        }

        // Upload PDF if selected
        if (_pdfFile != null) {
          pdfUrl = await _bookService.uploadPDF(_pdfFile!, bookId);
        }

        // Upload content images - PERBAIKAN DI SINI
        for (var image in _contentImages) {
          final url = await _bookService.uploadContentImage(image, bookId);
          if (url != null) {  // Null check untuk menghindari error
            uploadedImageUrls.add(url);
          }
        }

        // Create final book object
        final book = BookModel(
          id: bookId,
          title: _titleController.text,
          author: _authorController.text,
          description: _descriptionController.text,
          content: _contentController.text,
          coverUrl: coverUrl,
          pdfUrl: pdfUrl,
          contentType: _contentType,
          imageUrls: uploadedImageUrls,
          createdAt: widget.book?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _bookService.updateBook(bookId, book);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.book == null
                    ? 'Book added successfully'
                    : 'Book updated successfully',
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
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
          widget.book == null ? 'Add Book' : 'Edit Book',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Cover Image
            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(12),
                  image: _coverImage != null
                      ? DecorationImage(
                          image: FileImage(_coverImage!),
                          fit: BoxFit.cover,
                        )
                      : _existingCoverUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_existingCoverUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: _coverImage == null && _existingCoverUrl == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 50, color: AppColors.textGrey),
                          const SizedBox(height: 8),
                          const Text('Add Cover Image'),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            CustomTextField(
              label: 'Title',
              controller: _titleController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Author',
              controller: _authorController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Author is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter book description',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content Type Selector
            const Text(
              'Content Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Text'),
                    value: 'text',
                    groupValue: _contentType,
                    onChanged: (value) {
                      setState(() {
                        _contentType = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('PDF'),
                    value: 'pdf',
                    groupValue: _contentType,
                    onChanged: (value) {
                      setState(() {
                        _contentType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // PDF Upload
            if (_contentType == 'pdf') ...[
              OutlinedButton.icon(
                onPressed: _pickPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_pdfFile != null
                    ? 'PDF Selected'
                    : _existingPdfUrl != null
                        ? 'Change PDF'
                        : 'Upload PDF'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Text Content
            if (_contentType == 'text') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Content',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _contentController,
                    maxLines: 10,
                    validator: (value) {
                      if (_contentType == 'text' &&
                          (value == null || value.isEmpty)) {
                        return 'Content is required';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter book content',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image Upload Options
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickContentImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Upload Image'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addImageUrl,
                      icon: const Icon(Icons.link),
                      label: const Text('Add URL'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preview uploaded images
              if (_contentImages.isNotEmpty || _imageUrls.isNotEmpty) ...[
                const Text(
                  'Content Images',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._contentImages.map((img) => Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(img),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _contentImages.remove(img);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                    ..._imageUrls.map((url) => Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imageUrls.remove(url);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ],

            const SizedBox(height: 32),
            CustomButton(
              text: widget.book == null ? 'Add Book' : 'Update Book',
              onPressed: _saveBook,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/book_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final BookService _bookService = BookService();
  bool _isLoading = true;
  int _totalBooks = 0;
  int _totalUsers = 0;
  int _pdfBooks = 0;
  int _textBooks = 0;
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final books = await _bookService.getTotalBooksCount();
      final users = await _bookService.getTotalUsersCount();
      final pdf = await _bookService.getPdfBooksCount();
      final text = await _bookService.getTextBooksCount();
      final activities = await _bookService.getRecentActivities(limit: 10);

      setState(() {
        _totalBooks = books;
        _totalUsers = users;
        _pdfBooks = pdf;
        _textBooks = text;
        _recentActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Statistics',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.book,
                          title: 'Total Books',
                          value: _totalBooks.toString(),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people,
                          title: 'Total Users',
                          value: _totalUsers.toString(),
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Additional Stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.picture_as_pdf,
                          title: 'PDF Books',
                          value: _pdfBooks.toString(),
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.text_fields,
                          title: 'Text Books',
                          value: _textBooks.toString(),
                          color: AppColors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Recent Activities
                  const Text(
                    'Recent Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_recentActivities.isEmpty)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 64,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No recent activities',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Activities will appear here once users start interacting with books',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textGrey.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._recentActivities.map((activity) {
                      final userName = activity['users']?['name'] ?? 'Unknown User';
                      final bookTitle = activity['books']?['title'] ?? 'Unknown Book';
                      final createdAt = DateTime.parse(activity['created_at']);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: const Icon(
                              Icons.bookmark,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('Bookmarked: $bookTitle'),
                          trailing: Text(
                            _formatDate(createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
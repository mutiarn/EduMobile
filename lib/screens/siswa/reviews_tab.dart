import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_edu/screens/siswa/providers/review_provider.dart';
import 'package:mobile_edu/screens/siswa/review_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewsTab extends ConsumerStatefulWidget {
  final String courseId;
  final bool isEnrolled;
  final void Function(List<Map<String, dynamic>>)? onReviewLoaded;

  const ReviewsTab({
    super.key,
    required this.courseId,
    required this.isEnrolled,
    this.onReviewLoaded,
  });

  @override
  ConsumerState<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends ConsumerState<ReviewsTab> {
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('review')
          .select('''
          id,
          user_id,
          rating,
          comment,
          created_at
        ''')
          .eq('course_id', widget.courseId)
          .order('created_at', ascending: false);

      final reviews = List<Map<String, dynamic>>.from(response);

      setState(() {
        ref.read(reviewListProvider.notifier).state = reviews;
        _reviews = reviews;
        _calculateRatingStats();
      });

      widget.onReviewLoaded?.call(reviews);
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateRatingStats() {
    if (_reviews.isEmpty) return;

    _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    int totalRating = 0;
    _totalReviews = _reviews.length;

    for (var review in _reviews) {
      int rating = review['rating'] ?? 0;
      totalRating += rating;

      if (rating >= 1 && rating <= 5) {
        _ratingDistribution[rating] = _ratingDistribution[rating]! + 1;
      }
    }

    _averageRating = totalRating / _totalReviews;
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getUserDisplayName(String? userId) {
    if (userId == null || userId.isEmpty) {
      return 'Anonymous User';
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null && currentUser.id == userId) {
      return 'You';
    }

    return 'User ${userId.substring(0, 8)}';
  }

  String _getUserInitial(String? userId) {
    if (userId == null || userId.isEmpty) {
      return 'A';
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null && currentUser.id == userId) {
      return 'Y';
    }

    return 'U';
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildRatingDistribution() {
    final theme = Theme.of(context);

    return Column(
      children: List.generate(5, (index) {
        int starCount = 5 - index;
        int reviewCount = _ratingDistribution[starCount] ?? 0;
        double percentage = _totalReviews > 0 ? reviewCount / _totalReviews : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$starCount',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$reviewCount',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReviewItem(dynamic review) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Text(
                  _getUserInitial(review['user_id']),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getUserDisplayName(review['user_id']),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        _buildRatingStars(review['rating'] ?? 0),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review['created_at'] ?? ''),
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['comment'] ?? '',
            style: TextStyle(
              height: 1.5,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colorScheme.primary.withOpacity(0.1),
                  colorScheme.secondary.withOpacity(0.1),
                ]
              : [
                  Colors.blue[50]!,
                  Colors.purple[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                _averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < _averageRating.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
              Text(
                '$_totalReviews reviews',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 30),
          Expanded(child: _buildRatingDistribution()),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchReviews,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewsHeader(),
                const SizedBox(height: 24),
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: colorScheme.primary),
                    ),
                  )
                else if (_reviews.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 64,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reviews for this course yet',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._reviews.map((review) => _buildReviewItem(review)),
              ],
            ),
          ),
        ),
        if (widget.isEnrolled)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to write a review.'),
                    ),
                  );
                  return;
                }

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ReviewForm(
                    courseId: widget.courseId,
                    userId: user.id,
                    onSubmitted: () async {
                      await _fetchReviews();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Review submitted successfully."),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                );
              },
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: const Icon(Icons.rate_review),
              label: const Text("Add Review"),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildReviewsTab();
  }
}

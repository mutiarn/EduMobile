import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewForm extends StatefulWidget {
  final String courseId;
  final String userId;
  final VoidCallback onSubmitted;

  const ReviewForm({
    super.key,
    required this.courseId,
    required this.userId,
    required this.onSubmitted,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Cukup';
      case 4:
        return 'Baik';
      case 5:
        return 'Sangat Baik';
      default:
        return 'Pilih Rating';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitReview() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tulis komentar Anda'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Supabase.instance.client.from('review').insert({
        'user_id': widget.userId,
        'course_id': widget.courseId,
        'rating': _rating,
        'comment': _commentController.text,
        'created_at': DateTime.now().toIso8601String(),
      });

      widget.onSubmitted();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tulis Review',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            'Rating',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Center(
            child: RatingBar.builder(
              initialRating: _rating.toDouble(),
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 40,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating.toInt();
                });
              },
              updateOnDrag: true,
              tapOnlyMode: false,
              ignoreGestures: false,
              glow: true,
              glowColor: Colors.amber.withOpacity(0.2),
              glowRadius: 2,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingText(_rating),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _getRatingColor(_rating),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          Text(
            'Komentar',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 4,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Tulis pengalaman Anda...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : Text(
                      'Kirim Review',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

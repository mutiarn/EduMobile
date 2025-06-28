import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_edu/screens/siswa/course_detail_page.dart';
import 'package:mobile_edu/screens/siswa/providers/review_provider.dart';
import 'package:mobile_edu/screens/siswa/providers/topic_provider.dart';

class CourseCard extends ConsumerWidget {
  final Map course;

  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final asyncAvg = ref.watch(averageRatingProvider(course['id']));
    final asyncTopicCount = ref.watch(topicCountProvider(course['id']));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CourseDetailPage(course: course)),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(right: 16.0, bottom: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surface,
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl:
                          course['thumbnail_url'] ??
                          'https://via.placeholder.com/200x120.png?text=Course',
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            height: 120,
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            height: 120,
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.broken_image,
                              color: colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.3), 
                            blurRadius: 4
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite_border, 
                        size: 18,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          asyncAvg.when(
                            data:
                                (avg) => Row(
                                  children: [
                                    ...List.generate(5, (index) {
                                      if (index < avg.floor()) {
                                        // Bintang penuh
                                        return const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        );
                                      } else if (index < avg &&
                                          avg - index >= 0.5) {
                                        // Bintang setengah
                                        return const Icon(
                                          Icons.star_half,
                                          color: Colors.amber,
                                          size: 16,
                                        );
                                      } else {
                                        return Icon(
                                          Icons.star_border,
                                          color: colorScheme.onSurface.withOpacity(0.4),
                                          size: 16,
                                        );
                                      }
                                    }),
                                    const SizedBox(width: 4),
                                    Text(
                                      avg.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                            loading:
                                () => Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (index) => Icon(
                                        Icons.star_border,
                                        color: colorScheme.onSurface.withOpacity(0.3),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                            error:
                                (e, _) => Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (index) => Icon(
                                        Icons.star_border,
                                        color: colorScheme.onSurface.withOpacity(0.4),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '0.0',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      asyncTopicCount.when(
                        data:
                            (topic) => Text(
                              '${topic.toInt()} lessons',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                        loading:
                            () => SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                        error: (_, __) => Text(
                          '0 lessons',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course['title'] ?? 'Tanpa Judul',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Rp ${_formatPrice(course['price'])}',
                              style: TextStyle(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatPrice(dynamic price) {
  if (price == null) return '0,00';

  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '', // Tidak pakai Rp di sini, bisa kamu tambahkan di UI kalau perlu
    decimalDigits: 2,
  );

  return formatter.format(price).trim();
}

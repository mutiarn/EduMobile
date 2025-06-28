import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_edu/providers/theme_provider.dart';
import 'package:mobile_edu/screens/siswa/course_card_widget.dart';
import 'package:mobile_edu/screens/siswa/home_siswa.dart';
import 'package:mobile_edu/screens/siswa/promo_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final SupabaseClient client = Supabase.instance.client;
  late Future<Map<String, List<dynamic>>> _randomCoursesFuture;
  String? _username;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _randomCoursesFuture = _fetchRandomCourses();
    _fetchUsername();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await client.from('category_course').select('id, name');
      _categories = res;

      setState(() {
        _categories = List<Map<String, dynamic>>.from(
          res.map((e) => e['name'] as String),
        );
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat kategori: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchUsername() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final res =
        await Supabase.instance.client
            .from('profiles')
            .select('username')
            .eq('id', user.id)
            .single();

    setState(() {
      _username = res['username'] ?? 'Siswa';
    });
  }

  Future<Map<String, List<dynamic>>> _fetchRandomCourses() async {
    final response = await client.from('course').select();

    if (response != null && response is List) {
      final List allCourses = List.from(response)..shuffle(Random());

      final popularCourses = allCourses.take(3).toList();
      final recommendedCourses = allCourses.skip(3).take(3).toList();

      return {'popular': popularCourses, 'recommended': recommendedCourses};
    } else {
      throw Exception('Failed to load courses.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7475d6), // Preserve this color
                    Color.fromARGB(255, 161, 161, 212),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(context, user),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(height: 178, child: PromoCarousel()),
              ],
            ),
            const SizedBox(height: 32),
            _buildCategoryTabs(),
            const SizedBox(height: 20),
            _buildPopularCoursesSection(),
            const SizedBox(height: 20),
            _buildRecommendedCoursesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final container = ProviderScope.containerOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${_username ?? '...'}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Find your lessons today!',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          Row(
          children: [
            // 🌙 Theme toggle (tanpa container)
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                container.read(themeModeProvider.notifier).state =
                    isDark ? ThemeMode.light : ThemeMode.dark;
              },
            ),
            const SizedBox(width: 8),
            // 🔔 Notifikasi
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HomeSiswa(initialIndex: 2)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 8),
                    Text(
                      'Search now...', 
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HomeSiswa(initialIndex: 2)),
              );
            },
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF4C5FD5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final colors = [
      colorScheme.primaryContainer.withOpacity(0.3),
      colorScheme.secondaryContainer.withOpacity(0.3),
      colorScheme.tertiaryContainer.withOpacity(0.3),
      colorScheme.errorContainer.withOpacity(0.3),
      colorScheme.surfaceContainerHighest.withOpacity(0.3),
    ];

    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_categories.length, (index) {
            final color = colors[index % colors.length];
            final category = _categories[index];

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeSiswa(initialIndex: 2),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    category['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRecommendedCoursesSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(right: 20, left: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended Courses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeSiswa(initialIndex: 2),
                    ),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCourseSection(_randomCoursesFuture, 'recommended'),
        ],
      ),
    );
  }

  Widget _buildPopularCoursesSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(right: 20, left: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Courses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeSiswa(initialIndex: 2),
                    ),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCourseSection(_randomCoursesFuture, 'popular'),
        ],
      ),
    );
  }

  Widget _buildCourseSection(
    Future<Map<String, List<dynamic>>> coursesFuture,
    String key,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return FutureBuilder<Map<String, List<dynamic>>>(
      future: coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                'Terjadi kesalahan: ${snapshot.error}',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          );
        }

        final courses = snapshot.data?[key];
        if (courses == null || courses.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                'Belum ada kursus tersedia.',
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
          );
        }

        return SizedBox(
          height: 305,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: CourseCard(course: course),
              );
            },
          ),
        );
      },
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_edu/screens/course_form_page.dart';
import 'package:mobile_edu/screens/topic_list_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_edu/components/theme_toggle_button.dart';

class ManageCourseTab extends StatefulWidget {
  const ManageCourseTab({super.key});

  @override
  State<ManageCourseTab> createState() => _ManageCourseTabState();
}

class _ManageCourseTabState extends State<ManageCourseTab>
    with SingleTickerProviderStateMixin {
  final SupabaseClient client = Supabase.instance.client;
  late Future<List<dynamic>> _coursesFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fetchCourses();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    final userId = client.auth.currentUser!.id;
    _coursesFuture = client.from('course').select().eq('teacher_id', userId);
    setState(() {});
    _animationController.forward();
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      await client.from('course').delete().eq('id', courseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Course deleted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _fetchCourses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete course: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  List<dynamic> _filterCourses(List<dynamic> courses) {
    if (_searchQuery.isEmpty) return courses;
    return courses.where((course) {
      return course['title'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();
  }

  Future<int> _getEnrollmentCount(Map<String, dynamic> course) async {
    final courseId = course['id'];

    final List data = await client
        .from('enrollment')
        .select('user_id')
        .eq('course_id', courseId);

    return data.length;
  }

  // Helper method to format price in Indonesian Rupiah with ,00
  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp 0,00';
    
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 2, // Ubah dari 0 menjadi 2 untuk menampilkan ,00
    );
    
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:[
                            const Color(0xFF7475d6),
                            const Color.fromARGB(255, 161, 161, 212),
                          ]
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 40,
                      right: 20,
                      child: ThemeToggleButton(),
                    ),
                    const Positioned(
                      bottom: 30,
                      left: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Courses',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Create and manage your courses',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Add Course Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CourseFormPage(),
                          ),
                        );
                        if (result == true) _fetchCourses();
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      label: const Text(
                        'Add New Course',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search your courses...',
                        hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with View Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Courses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isGridView = false;
                                });
                              },
                              icon: Icon(
                                Icons.view_list,
                                color: !_isGridView
                                    ? colorScheme.primary
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isGridView = true;
                                });
                              },
                              icon: Icon(
                                Icons.grid_view,
                                color: _isGridView
                                    ? colorScheme.primary
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<dynamic>>(
              future: _coursesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(color: colorScheme.primary),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Container(
                    height: 300,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.red.withOpacity(0.1) : Colors.red[50],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Terjadi kesalahan',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final filteredCourses = _filterCourses(snapshot.data!);

                if (filteredCourses.isEmpty) {
                  return Container(
                    height: 300,
                    margin: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 60,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No courses found',
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child:
                      _isGridView
                          ? _buildGridView(filteredCourses)
                          : _buildListView(filteredCourses),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2D3748), const Color(0xFF4A5568)]
                      : [const Color(0xFF1f2967), const Color(0xFF4a5394)],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Courses Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t created any courses yet.\nStart by creating your first course!',
              style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CourseFormPage()),
                );
                if (result == true) _fetchCourses();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Course'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<dynamic> courses) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];

        return FutureBuilder<int>(
          future: _getEnrollmentCount(course),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return const Text('Error loading enrollment count');
            }

            final enrollmentCount = snapshot.data ?? 0;

            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 100)),
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildCourseCard(course, enrollmentCount, false),
            );
          },
        );
      },
    );
  }

  Widget _buildGridView(List<dynamic> courses) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];

          return FutureBuilder<int>(
            future: _getEnrollmentCount(course),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('Error loading enrollment count'),
                  ),
                );
              }

              final enrollmentCount = snapshot.data ?? 0;

              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                child: _buildCourseCard(
                  course,
                  enrollmentCount,
                  true,
                ), // Pass true for isGrid
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(
    Map<String, dynamic> course,
    int enrollmentCount,
    bool isGrid,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child:
          isGrid
              ? _buildGridCard(course, enrollmentCount)
              : _buildListCard(course, enrollmentCount),
    );
  }

  Widget _buildListCard(Map<String, dynamic> course, int enrollmentCount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Course Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child:
                course['thumbnail_url'] != null
                    ? CachedNetworkImage(
                      imageUrl: course['thumbnail_url'],
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.broken_image,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                    )
                    : Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF2D3748), const Color(0xFF4A5568)]
                              : [const Color(0xFF1f2967), const Color(0xFF4a5394)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
          ),
          const SizedBox(width: 16),

          // Course Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['title'] ?? 'No Title',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  course['description'] ?? 'No description available.',
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatPrice(course['price']),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, size: 12, color: Colors.blue[700]),
                          const SizedBox(width: 2),
                          Text(
                            '$enrollmentCount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseFormPage(course: course),
                    ),
                  );
                  if (result == true) _fetchCourses();
                  break;
                case 'topics':
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TopicListPage(course: course),
                    ),
                  );
                  break;
                case 'delete':
                  _showDeleteBottomSheet(course);
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit, color: Colors.blue),
                      title: Text('Edit Course'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'topics',
                    child: ListTile(
                      leading: Icon(Icons.topic_outlined, color: Colors.purple),
                      title: Text('Manage Topics'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete Course'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.more_vert,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> course, int enrollmentCount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Thumbnail
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child:
                      course['thumbnail_url'] != null
                          ? CachedNetworkImage(
                            imageUrl: course['thumbnail_url'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder:
                                (context, url) => Container(
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                  child: Icon(
                                    Icons.broken_image,
                                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                                    size: 40,
                                  ),
                                ),
                          )
                          : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF2D3748), const Color(0xFF4A5568)]
                                    : [const Color(0xFF1f2967), const Color(0xFF4a5394)],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),

        // Course Info
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['title'] ?? 'No Title',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatPrice(course['price']),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.people, size: 12, color: Colors.blue[700]),
                    const SizedBox(width: 2),
                    Text(
                      '$enrollmentCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseFormPage(course: course),
                          ),
                        );
                        if (result == true) _fetchCourses();
                        break;
                      case 'topics':
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TopicListPage(course: course),
                          ),
                        );
                        break;
                      case 'delete':
                        _showDeleteBottomSheet(course);
                        break;
                    }
                  },
                  offset: const Offset(0, -120),
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit, color: Colors.blue),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'topics',
                          child: ListTile(
                            leading: Icon(
                              Icons.topic_outlined,
                              color: Colors.purple,
                            ),
                            title: Text('Topics'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Manage',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteBottomSheet(Map<String, dynamic> course) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textTheme.bodyMedium?.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Warning icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Delete Course?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                Text(
                  'Are you sure you want to delete "${course['title']}"?\n\nThis action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: theme.textTheme.bodyMedium?.color ?? Colors.grey),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteCourse(course['id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
    );
  }
}
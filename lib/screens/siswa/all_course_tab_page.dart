import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_edu/screens/siswa/course_detail_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AllCourseTab extends StatefulWidget {
  final String? initialCategoryId;
  const AllCourseTab({super.key, this.initialCategoryId});

  @override
  State<AllCourseTab> createState() => _AllCourseTabState();
}

class _AllCourseTabState extends State<AllCourseTab>
    with TickerProviderStateMixin {
  final SupabaseClient client = Supabase.instance.client;
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortBy = 'newest';
  bool _isGridView = false;
  late Future<List<dynamic>> _categoriesFuture;
  late Future<List<dynamic>> _coursesFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategoryId;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchCategories();
    _fetchCourses();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fetchCategories() {
    _categoriesFuture = client.from('category_course').select();
  }

  void _fetchCourses() {
    var query = client.from('course').select('*, category_course(name)');
    if (_searchQuery.isNotEmpty) {
      query = query.ilike('title', '%$_searchQuery%');
    }
    if (_selectedCategory != null) {
      query = query.eq('category_id', _selectedCategory!);
    }

    // Apply sorting
    switch (_sortBy) {
      case 'newest':
        _coursesFuture = query.order('created_at', ascending: false);
        break;
      case 'oldest':
        _coursesFuture = query.order('created_at', ascending: true);
        break;
      case 'price_low':
        _coursesFuture = query.order('price', ascending: true);
        break;
      case 'price_high':
        _coursesFuture = query.order('price', ascending: false);
        break;
      case 'popular':
        // Static implementation - you can add enrollment_count to backend later
        _coursesFuture = query.order('created_at', ascending: false);
        break;
    }

    setState(() {});
  }

  void _showFilterBottomSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String tempSortBy = _sortBy; // ← buffer state lokal

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter & Sort',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Urutkan berdasarkan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSortChip('Terbaru', 'newest', tempSortBy, (val) {
                        setModalState(() => tempSortBy = val);
                      }),
                      _buildSortChip('Terlama', 'oldest', tempSortBy, (val) {
                        setModalState(() => tempSortBy = val);
                      }),
                      _buildSortChip(
                        'Harga Terendah',
                        'price_low',
                        tempSortBy,
                        (val) {
                          setModalState(() => tempSortBy = val);
                        },
                      ),
                      _buildSortChip(
                        'Harga Tertinggi',
                        'price_high',
                        tempSortBy,
                        (val) {
                          setModalState(() => tempSortBy = val);
                        },
                      ),
                      _buildSortChip('Terpopuler', 'popular', tempSortBy, (
                        val,
                      ) {
                        setModalState(() => tempSortBy = val);
                      }),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(
                          () => _sortBy = tempSortBy,
                        ); // ← Simpan perubahan
                        Navigator.pop(context);
                        _fetchCourses();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(
    String text,
    String value,
    String selectedValue,
    Function(String) onSelected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedValue == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Text(text),
        selected: isSelected,
        showCheckmark: false, // Remove checkmark
        onSelected: (_) => onSelected(value),
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        checkmarkColor: colorScheme.onPrimary,
        labelStyle: TextStyle(
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.7),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: isSelected ? 2 : 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7475d6), // Preserve this color
                    Color.fromARGB(255, 161, 161, 212),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 85, left: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Courses',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find your best course to improve your magnificient skills',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Bar with enhanced design
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: colorScheme.surfaceContainerHighest,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          // Debounce search
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (_searchQuery == value) {
                              _fetchCourses();
                            }
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari kursus impian Anda...',
                          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _fetchCourses();
                                      });
                                    },
                                  )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter and View Toggle Row
                    Row(
                      children: [
                        Expanded(
                          child: FutureBuilder<List<dynamic>>(
                            future: _categoriesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return SizedBox(
                                  height: 40,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                );
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final categories = snapshot.data!;
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildCategoryChip('Semua', null),
                                    const SizedBox(width: 8),
                                    ...categories.map(
                                      (category) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: _buildCategoryChip(
                                          category['name'],
                                          category['id'],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            // Filter Button
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: _showFilterBottomSheet,
                                icon: Icon(
                                  Icons.tune,
                                  color: colorScheme.primary,
                                ),
                                tooltip: 'Filter',
                              ),
                            ),
                            const SizedBox(width: 8),
                            // View Toggle Button
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isGridView = !_isGridView;
                                  });
                                },
                                icon: Icon(
                                  _isGridView ? Icons.list : Icons.grid_view,
                                  color: colorScheme.primary,
                                ),
                                tooltip:
                                    _isGridView
                                        ? 'Tampilan List'
                                        : 'Tampilan Grid',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _coursesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Terjadi kesalahan',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada kursus ditemukan',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Coba ubah kata kunci pencarian atau filter',
                            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    );
                  }

                  final courses = snapshot.data!;
                  return _isGridView
                      ? _buildGridView(courses)
                      : _buildListView(courses);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String text, String? categoryId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedCategory == categoryId;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Text(text),
        selected: isSelected,
        showCheckmark: false, // Remove checkmark
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? categoryId : null;
            _fetchCourses();
          });
        },
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        checkmarkColor: colorScheme.onPrimary,
        labelStyle: TextStyle(
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.7),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: isSelected ? 2 : 0,
      ),
    );
  }

  Widget _buildListView(List<dynamic> courses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(course, index);
      },
    );
  }

  Widget _buildGridView(List<dynamic> courses) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildGridCourseCard(course, index);
      },
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CourseDetailPage(course: course)),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'course_${course['id']}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child:
                        course['thumbnail_url'] != null
                            ? CachedNetworkImage(
                              imageUrl: course['thumbnail_url'],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(
                                      Icons.broken_image,
                                      color: colorScheme.onSurface.withOpacity(0.4),
                                      size: 32,
                                    ),
                                  ),
                            )
                            : Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withOpacity(0.7),
                                    colorScheme.primary.withOpacity(0.5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.school,
                                color: colorScheme.onPrimary,
                                size: 32,
                              ),
                            ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course['description'] ?? 'Tidak ada deskripsi.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          height: 1.4,
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
                      const SizedBox(height: 8),
                      if (course['category_course'] != null &&
                          course['category_course']['name'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            course['category_course']['name'],
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }

  Widget _buildGridCourseCard(Map<String, dynamic> course, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CourseDetailPage(course: course)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Hero(
                  tag: 'course_grid_${course['id']}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child:
                        course['thumbnail_url'] != null
                            ? CachedNetworkImage(
                              imageUrl: course['thumbnail_url'],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
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
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: colorScheme.onSurface.withOpacity(0.4),
                                      size: 32,
                                    ),
                                  ),
                            )
                            : Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withOpacity(0.7),
                                    colorScheme.primary.withOpacity(0.5),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.school,
                                color: colorScheme.onPrimary,
                                size: 40,
                              ),
                            ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'],
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_formatPrice(course['price'])}',
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (course['category_course'] != null &&
                          course['category_course']['name'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            course['category_course']['name'],
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

  String _formatPrice(dynamic price) {
    if (price == null) return '0,00';

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol:
          '', // Tidak pakai Rp di sini, bisa kamu tambahkan di UI kalau perlu
      decimalDigits: 2,
    );

    return formatter.format(price).trim();
  }
}

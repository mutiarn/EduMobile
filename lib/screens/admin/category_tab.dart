import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage>
    with SingleTickerProviderStateMixin {
  final supa = Supabase.instance.client;
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  late Future<List<dynamic>> _categoriesFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  bool _isGridView = false;
  String? selectedCategoryId;
  bool _isFormVisible = false;

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
    _fetchCategories();
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  void _fetchCategories() {
    _categoriesFuture = supa
        .from('category_course')
        .select()
        .order('name', ascending: true);
    setState(() {});
    _animationController.forward();
  }

  Future<void> _saveCategory() async {
    try {
      final data = {
        'name': nameCtrl.text.trim(),
        'description': descCtrl.text.trim(),
      };

      if (selectedCategoryId == null) {
        await supa.from('category_course').insert(data);
      } else {
        await supa
            .from('category_course')
            .update(data)
            .eq('id', selectedCategoryId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedCategoryId == null
                  ? 'Category created successfully!'
                  : 'Category updated successfully!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _clearForm();
        _fetchCategories();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save category: $e'),
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

  void _clearForm() {
    setState(() {
      selectedCategoryId = null;
      nameCtrl.clear();
      descCtrl.clear();
      _isFormVisible = false;
    });
  }

  void _editCategory(Map<String, dynamic> category) {
    setState(() {
      selectedCategoryId = category['id'];
      nameCtrl.text = category['name'];
      descCtrl.text = category['description'] ?? '';
      _isFormVisible = true;
    });
  }

  Future<void> _deleteCategory(String categoryId) async {
    try {
      await supa.from('category_course').delete().eq('id', categoryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Category deleted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _fetchCategories();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete category: $e'),
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

  List<dynamic> _filterCategories(List<dynamic> categories) {
    if (_searchQuery.isEmpty) return categories;
    return categories.where((category) {
      return category['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (category['description']?.toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
    }).toList();
  }

  InputDecoration _inputDecoration(String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.primary),
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    );
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
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
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
                      bottom: 30,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Categories Management',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Manage course categories',
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
                  // Add Category Button
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
                      onPressed: () {
                        setState(() {
                          _isFormVisible = !_isFormVisible;
                          if (!_isFormVisible) {
                            _clearForm();
                          }
                        });
                      },
                      icon: Icon(
                        _isFormVisible ? Icons.close : Icons.add_circle_outline,
                        size: 24,
                      ),
                      label: Text(
                        _isFormVisible ? 'Cancel' : 'Add New Category',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormVisible
                            ? (isDark ? Colors.grey[700] : Colors.grey[600])
                            : colorScheme.primary,
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

                  // Category Form
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isFormVisible ? null : 0,
                    child: _isFormVisible
                        ? Container(
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
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                TextField(
                                  controller: nameCtrl,
                                  decoration: _inputDecoration('Category Name'),
                                  style: TextStyle(color: colorScheme.onSurface),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: descCtrl,
                                  decoration: _inputDecoration('Description'),
                                  maxLines: 3,
                                  style: TextStyle(color: colorScheme.onSurface),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _saveCategory,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 6,
                                    ),
                                    child: Text(
                                      selectedCategoryId == null
                                          ? 'Add Category'
                                          : 'Update Category',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (_isFormVisible) const SizedBox(height: 16),

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
                        hintText: 'Search categories...',
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
                        'Categories',
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
                                color: !_isGridView ? colorScheme.primary : theme.textTheme.bodyMedium?.color,
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
                                color: _isGridView ? colorScheme.primary : theme.textTheme.bodyMedium?.color,
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
              future: _categoriesFuture,
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
                            'Error occurred',
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

                final filteredCategories = _filterCategories(snapshot.data!);

                if (filteredCategories.isEmpty) {
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
                            'No categories found',
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
                  child: _isGridView
                      ? _buildGridView(filteredCategories)
                      : _buildListView(filteredCategories),
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
                Icons.category_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Categories Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No categories created yet.\nAdd the first one!',
              style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isFormVisible = true;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Category'),
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

  Widget _buildListView(List<dynamic> categories) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildCategoryCard(category, false),
        );
      },
    );
  }

  Widget _buildGridView(List<dynamic> categories) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            child: _buildCategoryCard(category, true),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, bool isGrid) {
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
      child: isGrid ? _buildGridCard(category) : _buildListCard(category),
    );
  }

  Widget _buildListCard(Map<String, dynamic> category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2D3748), const Color(0xFF4A5568)]
                    : [const Color(0xFF1f2967), const Color(0xFF4a5394)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.category, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),

          // Category Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category['name'] ?? 'No Name',
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
                  category['description'] ?? 'No description',
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Action Buttons
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  _editCategory(category);
                  break;
                case 'delete':
                  _showDeleteBottomSheet(category);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.blue),
                  title: Text('Edit Category'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Category'),
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

  Widget _buildGridCard(Map<String, dynamic> category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2D3748), const Color(0xFF4A5568)]
                      : [const Color(0xFF1f2967), const Color(0xFF4a5394)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.category, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 16),

          // Category Info
          Text(
            category['name'] ?? 'No Name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            category['description'] ?? 'No description',
            style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const Spacer(),

          // Action Button
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  _editCategory(category);
                  break;
                case 'delete':
                  _showDeleteBottomSheet(category);
                  break;
              }
            },
            offset: const Offset(0, -80),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.blue),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
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
              padding: const EdgeInsets.symmetric(vertical: 8),
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
    );
  }

  void _showDeleteBottomSheet(Map<String, dynamic> category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              'Delete Category?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Content
            Text(
              'Are you sure you want to delete "${category['name']}"?\n\nThis action cannot be undone.',
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
                      _deleteCategory(category['id']);
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

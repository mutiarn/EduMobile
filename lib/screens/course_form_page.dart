import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_edu/components/theme_toggle_button.dart';

class CourseFormPage extends StatefulWidget {
  final Map<String, dynamic>? course;
  const CourseFormPage({super.key, this.course});

  @override
  State<CourseFormPage> createState() => _CourseFormPageState();
}

class _CourseFormPageState extends State<CourseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _thumbController = TextEditingController();

  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  bool _loading = false;

  final supa = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.course != null) {
      _titleController.text = widget.course!['title'] ?? '';
      _descController.text = widget.course!['description'] ?? '';
      _priceController.text = widget.course!['price'].toString();
      _thumbController.text = widget.course!['thumbnail_url'] ?? '';
      _selectedCategory = widget.course!['category_id'];
    }
  }

  Future<void> _loadCategories() async {
    final result = await supa.from('category_course').select('id, name');
    setState(() {
      _categories = List<Map<String, dynamic>>.from(result);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final payload = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'thumbnail_url': _thumbController.text.trim(),
      'category_id': _selectedCategory,
      'teacher_id': supa.auth.currentUser!.id,
    };

    try {
      if (widget.course == null) {
        await supa.from('course').insert(payload);
      } else {
        await supa
            .from('course')
            .update(payload)
            .eq('id', widget.course!['id']);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          widget.course == null ? 'Create Course' : 'Edit Course',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ThemeToggleButton(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient
            Container(
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF7475d6),
                    Color.fromARGB(255, 161, 161, 212),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      widget.course == null
                          ? Icons.add_circle_outline
                          : Icons.edit_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.course == null
                        ? 'Create New Course'
                        : 'Edit Course Details',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Form Card
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      _buildSectionTitle('Course Title', Icons.book_outlined),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _titleController,
                        label: 'Enter course title',
                        icon: Icons.title,
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Title is required'
                                    : null,
                      ),

                      const SizedBox(height: 24),

                      // Description Field
                      _buildSectionTitle(
                        'Description',
                        Icons.description_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _descController,
                        label: 'Course description',
                        maxLines: 4,
                      ),

                      const SizedBox(height: 24),

                      // Category Field
                      _buildSectionTitle('Category', Icons.category_outlined),
                      const SizedBox(height: 12),
                      _buildDropdown(),

                      const SizedBox(height: 24),

                      // Price Field
                      _buildSectionTitle(
                        'Price',
                        Icons.monetization_on_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _priceController,
                        label: 'Price (IDR)',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 24),

                      // Thumbnail Section
                      _buildSectionTitle('Thumbnail', Icons.image_outlined),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _thumbController,
                        label: 'Thumbnail URL',
                        icon: Icons.link,
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 16),

                      // Thumbnail Preview
                      if (_thumbController.text.trim().isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: _thumbController.text.trim(),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 60,
                                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Failed to load image',
                                          style: TextStyle(
                                            color: theme.textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            shadowColor: colorScheme.primary.withOpacity(0.3),
                          ),
                          child:
                              _loading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        widget.course == null
                                            ? Icons.add
                                            : Icons.update,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.course == null
                                            ? 'Create Course'
                                            : 'Update Course',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.textTheme.bodyMedium?.color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
        prefixIcon:
            icon != null
                ? Icon(icon, color: theme.textTheme.bodyMedium?.color)
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: 'Select category',
        labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
        prefixIcon: Icon(Icons.category, color: theme.textTheme.bodyMedium?.color),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.all(16),
      ),
      dropdownColor: colorScheme.surface,
      items:
          _categories
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c['id'],
                  child: Text(
                    c['name'],
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
              )
              .toList(),
      onChanged: (v) => setState(() => _selectedCategory = v),
      validator: (v) => v == null ? 'Category is required' : null,
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: theme.textTheme.bodyMedium?.color,
      ),
    );
  }
}

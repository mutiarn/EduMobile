import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_edu/components/theme_toggle_button.dart';

class TopicFormPage extends StatefulWidget {
  final Map course;
  final Map? topic;
  const TopicFormPage({super.key, required this.course, this.topic});

  @override
  State<TopicFormPage> createState() => _TopicFormPageState();
}

class _TopicFormPageState extends State<TopicFormPage> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final videoUrlCtrl = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.topic != null) {
      titleCtrl.text = widget.topic!['title'] ?? '';
      descCtrl.text = widget.topic!['description'] ?? '';
      videoUrlCtrl.text = widget.topic!['video_url'] ?? '';
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    videoUrlCtrl.dispose();
    super.dispose();
  }

  String? _extractVideoId(String url) {
    if (url.isEmpty) return null;

    // Regex patterns for various YouTube URL formats
    final patterns = [
      RegExp(
        r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})',
      ),
      RegExp(r'youtube\.com\/v\/([a-zA-Z0-9_-]{11})'),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final supa = Supabase.instance.client;

    int orderNo = 1;
    if (widget.topic == null) {
      final maxRes =
          await supa
              .from('topic')
              .select('order_no')
              .eq('course_id', widget.course['id'])
              .order('order_no', ascending: false)
              .limit(1)
              .maybeSingle();

      orderNo = (maxRes?['order_no'] as int? ?? 0) + 1;
    } else {
      orderNo = widget.topic!['order_no'] ?? 1;
    }

    final data = {
      'course_id': widget.course['id'],
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      'video_url': videoUrlCtrl.text.trim(),
      'order_no': orderNo,
    };

    try {
      if (widget.topic == null) {
        await supa.from('topic').insert(data);
      } else {
        await supa.from('topic').update(data).eq('id', widget.topic!['id']);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
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
          widget.topic == null ? 'Add Topic' : 'Edit Topic',
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
                      widget.topic == null
                          ? Icons.playlist_add_outlined
                          : Icons.edit_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.topic == null
                        ? 'Add New Topic'
                        : 'Edit Topic Details',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Course Info Card
            Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.school_outlined,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Course',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.course['title'] ?? 'Unknown Course',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form Card
            Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                      _buildSectionTitle('Topic Title', Icons.title_outlined),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: titleCtrl,
                        label: 'Enter topic title',
                        icon: Icons.title,
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
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
                        controller: descCtrl,
                        label: 'Topic description (optional)',
                        maxLines: 4,
                      ),

                      const SizedBox(height: 24),

                      // Video URL Field
                      _buildSectionTitle(
                        'Video URL',
                        Icons.video_library_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: videoUrlCtrl,
                        label: 'YouTube video URL',
                        icon: Icons.link,
                        keyboardType: TextInputType.url,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Video URL is required';
                          }
                          if (_extractVideoId(v.trim()) == null) {
                            return 'Please enter a valid YouTube URL';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 16),

                      // Video Preview
                      if (videoUrlCtrl.text.trim().isNotEmpty &&
                          _extractVideoId(videoUrlCtrl.text.trim()) != null)
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
                            child: Column(
                              children: [
                                // Thumbnail preview
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        'https://img.youtube.com/vi/${_extractVideoId(videoUrlCtrl.text.trim())}/maxresdefault.jpg',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Valid YouTube video detected',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Invalid URL warning
                      if (videoUrlCtrl.text.trim().isNotEmpty &&
                          _extractVideoId(videoUrlCtrl.text.trim()) == null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.orange.withOpacity(0.1) : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.orange.withOpacity(0.3) : Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade600,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Invalid YouTube URL',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Supported formats:\n• youtu.be/VIDEO_ID\n• youtube.com/watch?v=VIDEO_ID',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : save,
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
                                        widget.topic == null
                                            ? Icons.add
                                            : Icons.update,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.topic == null
                                            ? 'Create Topic'
                                            : 'Update Topic',
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
            icon != null ? Icon(icon, color: theme.textTheme.bodyMedium?.color) : null,
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
}

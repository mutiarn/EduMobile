import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:mobile_edu/components/theme_toggle_button.dart';
import 'topic_form_page.dart';

class TopicListPage extends StatefulWidget {
  final Map course;
  const TopicListPage({super.key, required this.course});

  @override
  State<TopicListPage> createState() => _TopicListPageState();
}

class _TopicListPageState extends State<TopicListPage>
    with SingleTickerProviderStateMixin {
  final supa = Supabase.instance.client;
  late Future<List<dynamic>> _topicsFuture;
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
    _fetchTopics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fetchTopics() {
    _topicsFuture = supa
        .from('topic')
        .select()
        .eq('course_id', widget.course['id'])
        .order('order_no', ascending: true);
    setState(() {});
    _animationController.forward();
  }

  Future<void> _deleteTopic(String topicId) async {
    try {
      await supa.from('topic').delete().eq('id', topicId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Topic deleted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _fetchTopics();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete topic: $e'),
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

  String? _getYoutubeVideoId(String url) {
    if (url.contains('youtu.be/')) {
      return url.split('youtu.be/')[1].split('?')[0];
    } else if (url.contains('youtube.com/watch?v=')) {
      return url.split('v=')[1].split('&')[0];
    }
    return null;
  }

  List<dynamic> _filterTopics(List<dynamic> topics) {
    if (_searchQuery.isEmpty) return topics;
    return topics.where((topic) {
      return topic['title'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          topic['description'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: ThemeToggleButton(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7475d6),
                      Color.fromARGB(255, 161, 161, 212),
                    ],
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
                            'Course Topics',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.course['title'] ?? 'Course Title',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Add Topic Button
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
                            builder:
                                (_) => TopicFormPage(course: widget.course),
                          ),
                        );
                        if (result == true) {
                          _fetchTopics();
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      label: const Text(
                        'Add New Topic',
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
                        hintText: 'Search topics...',
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
                        'Topic List',
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
                                color:
                                    !_isGridView
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
                                color:
                                    _isGridView
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
              future: _topicsFuture,
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

                final filteredTopics = _filterTopics(snapshot.data!);

                if (filteredTopics.isEmpty) {
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
                            'No topics found',
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
                          ? _buildGridView(filteredTopics)
                          : _buildListView(filteredTopics),
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
                Icons.topic_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Topics Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No topics for this course yet.\nAdd the first one!',
              style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopicFormPage(course: widget.course),
                  ),
                );
                if (result == true) {
                  _fetchTopics();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Topic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
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

  Widget _buildListView(List<dynamic> topics) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildTopicCard(topic, false),
        );
      },
    );
  }

  Widget _buildGridView(List<dynamic> topics) {
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
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final topic = topics[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            child: _buildTopicCard(topic, true),
          );
        },
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic, bool isGrid) {
    final youtubeVideoId = _getYoutubeVideoId(topic['video_url'] ?? '');
    final thumbnailUrl =
        youtubeVideoId != null
            ? YoutubePlayer.getThumbnail(
              videoId: youtubeVideoId,
              quality: ThumbnailQuality.high,
            )
            : null;

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
              ? _buildGridCard(topic, thumbnailUrl)
              : _buildListCard(topic, thumbnailUrl),
    );
  }

  Widget _buildListCard(Map<String, dynamic> topic, String? thumbnailUrl) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child:
                thumbnailUrl != null
                    ? Image.network(
                      thumbnailUrl,
                      height: 80,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: 80,
                            width: 120,
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
                      width: 120,
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

          // Topic Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Topic ${topic['order_no']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  topic['title'] ?? 'No Title',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  topic['description'] ?? 'No description.',
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (thumbnailUrl != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_fill,
                          size: 12,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'YouTube Video',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
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
                      builder:
                          (_) => TopicFormPage(
                            course: widget.course,
                            topic: topic,
                          ),
                    ),
                  );
                  if (result == true) {
                    _fetchTopics();
                  }
                  break;
                case 'watch':
                  if (thumbnailUrl != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Preview only. Use player for full video.',
                        ),
                      ),
                    );
                  }
                  break;
                case 'delete':
                  _showDeleteBottomSheet(topic);
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit, color: Colors.blue),
                      title: Text('Edit Topic'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (thumbnailUrl != null)
                    const PopupMenuItem(
                      value: 'watch',
                      child: ListTile(
                        leading: Icon(
                          Icons.play_circle_fill,
                          color: Colors.red,
                        ),
                        title: Text('Watch Video'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete Topic'),
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

  Widget _buildGridCard(Map<String, dynamic> topic, String? thumbnailUrl) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic Thumbnail
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
                      thumbnailUrl != null
                          ? Image.network(
                            thumbnailUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
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
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Topic ${topic['order_no']}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Topic Info
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic['title'] ?? 'No Title',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  topic['description'] ?? 'No description.',
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => TopicFormPage(
                                  course: widget.course,
                                  topic: topic,
                                ),
                          ),
                        );
                        if (result == true) {
                          _fetchTopics();
                        }
                        break;
                      case 'watch':
                        if (thumbnailUrl != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Preview only. Use player for full video.',
                              ),
                            ),
                          );
                        }
                        break;
                      case 'delete':
                        _showDeleteBottomSheet(topic);
                        break;
                    }
                  },
                  offset: const Offset(0, -120),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit, color: Colors.blue),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (thumbnailUrl != null)
                          const PopupMenuItem(
                            value: 'watch',
                            child: ListTile(
                              leading: Icon(
                                Icons.play_circle_fill,
                                color: Colors.red,
                              ),
                              title: Text('Watch'),
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

  void _showDeleteBottomSheet(Map<String, dynamic> topic) {
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
                  'Delete Topic?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                Text(
                  'Are you sure you want to delete "${topic['title']}"?\n\nThis action cannot be undone.',
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
                          _deleteTopic(topic['id']);
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

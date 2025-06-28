import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_edu/components/theme_toggle_button.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab>
    with SingleTickerProviderStateMixin {
  final supa = Supabase.instance.client;
  late Future<List<dynamic>> _usersFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';
  bool _isGridView = false;
  String _selectedRole = 'All';

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
    _fetchUsers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fetchUsers() {
    _usersFuture = supa.from('public_users').select();
    setState(() {});
    _animationController.forward();
  }

  List<dynamic> _filterUsers(List<dynamic> users) {
    return users.where((user) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          user['email'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          user['id'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesRole =
          _selectedRole == 'All' || user['role'].toString() == _selectedRole;

      return matchesSearch && matchesRole;
    }).toList();
  }

  List<String> _getRoleOptions(List<dynamic> users) {
    final roles = users.map((user) => user['role'].toString()).toSet().toList();
    roles.sort();
    return ['All', ...roles];
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
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:  [
                            const Color(0xFF7475d6),
                            const Color.fromARGB(255, 161, 161, 212),
                          ]
                  ),
                ),
                child: Stack(
                  children: [
                    // Theme toggle button
                    Positioned(
                      top: 40,
                      right: 20,
                      child: ThemeToggleButton(),
                    ),
                    // Title and description
                    const Positioned(
                      bottom: 30,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Users Management',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Manage all registered users',
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
                        hintText: 'Search users by email or ID...',
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
                  // Filters and View Toggle Row
                  Row(
                    children: [
                      // Role Filter
                      Expanded(
                        child: FutureBuilder<List<dynamic>>(
                          future: _usersFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Container(
                                height: 50,
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
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            }

                            final roleOptions = _getRoleOptions(snapshot.data!);
                            return Container(
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
                              child: DropdownButtonFormField<String>(
                                value: _selectedRole,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                                style: TextStyle(color: colorScheme.onSurface),
                                dropdownColor: colorScheme.surface,
                                decoration: InputDecoration(
                                  labelText: 'Filter by Role',
                                  labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                                  prefixIcon: Icon(
                                    Icons.filter_list,
                                    color: colorScheme.primary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                ),
                                items: roleOptions.map((role) {
                                  return DropdownMenuItem<String>(
                                    value: role,
                                    child: Text(role, style: TextStyle(color: colorScheme.onSurface)),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // View Toggle
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
                  const SizedBox(height: 16),
                  // Header with Stats
                  FutureBuilder<List<dynamic>>(
                    future: _usersFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();

                      final filteredUsers = _filterUsers(snapshot.data!);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Users (${filteredUsers.length})',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onBackground,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Total: ${snapshot.data!.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<dynamic>>(
              future: _usersFuture,
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

                final filteredUsers = _filterUsers(snapshot.data!);

                if (filteredUsers.isEmpty) {
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
                            'No users found',
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filter',
                            style: TextStyle(
                              fontSize: 14,
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
                      ? _buildGridView(filteredUsers)
                      : _buildListView(filteredUsers),
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
                Icons.people_outline,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Users Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No registered users available\nat the moment.',
              style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<dynamic> users) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildUserCard(user, false),
        );
      },
    );
  }

  Widget _buildGridView(List<dynamic> users) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            child: _buildUserCard(user, true),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isGrid) {
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
      child: isGrid ? _buildGridCard(user) : _buildListCard(user),
    );
  }

  Widget _buildListCard(Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2D3748), const Color(0xFF4A5568)]
                    : [colorScheme.primary, const Color(0xFF4a5394)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['email'] ?? 'No Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${user['id']}',
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user['role']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user['role'] ?? 'No Role',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(user['role']),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Action Button
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'view':
                  _showUserDetails(user);
                  break;
                case 'edit':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit feature coming soon')),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: ListTile(
                  leading: Icon(Icons.visibility, color: Colors.blue),
                  title: Text('View Details'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.orange),
                  title: Text('Edit User'),
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
              child: Icon(Icons.more_vert, color: colorScheme.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // User Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2D3748), const Color(0xFF4A5568)]
                    : [colorScheme.primary, const Color(0xFF4a5394)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 12),
          // User Info
          Text(
            user['email'] ?? 'No Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${user['id']}',
            style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(user['role']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user['role'] ?? 'No Role',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getRoleColor(user['role']),
              ),
            ),
          ),
          const Spacer(),
          // Action Button
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'view':
                  _showUserDetails(user);
                  break;
                case 'edit':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit feature coming soon')),
                  );
                  break;
              }
            },
            offset: const Offset(0, -120),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: ListTile(
                  leading: Icon(Icons.visibility, color: Colors.blue),
                  title: Text('View'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.orange),
                  title: Text('Edit'),
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

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'teacher':
      case 'instructor':
        return Colors.green;
      case 'student':
        return Colors.blue;
      case 'user':
        return const Color(0xFF1f2967);
      default:
        return Colors.grey;
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
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
            // User Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1f2967), Color(0xFF4a5394)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            // User Details
            Text(
              'User Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Email', user['email'] ?? 'No Email'),
            _buildDetailRow('ID', user['id'] ?? 'No ID'),
            _buildDetailRow('Role', user['role'] ?? 'No Role'),
            const SizedBox(height: 24),
            // Close Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Close'),
            ),
            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

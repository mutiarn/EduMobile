import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_edu/screens/pengajar/dashboard.dart';
import 'package:mobile_edu/screens/pengajar/profile_tab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePengajar extends StatefulWidget {
  final int initialIndex;
  const HomePengajar({super.key, this.initialIndex = 0});

  @override
  State<HomePengajar> createState() => _HomePengajarState();
}

class _HomePengajarState extends State<HomePengajar>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<IconData> _iconList = const [
    LucideIcons.layoutDashboard,
    LucideIcons.user,
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _pageController.addListener(() {
      final newIndex = _pageController.page?.round();
      if (newIndex != null && newIndex != _currentIndex) {
        setState(() => _currentIndex = newIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [ManageCourseTab(), ProfileTab()],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_iconList.length, (i) {
            final isActive = _currentIndex == i;
            return GestureDetector(
              onTap: () => _onTabTapped(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconList[i],
                  size: 24,
                  color: isActive
                      ? colorScheme.primary
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_edu/providers/theme_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return IconButton(
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      color: Colors.white,
      onPressed: () {
        ref.read(themeModeProvider.notifier).toggle();
      },
    );
  }
}

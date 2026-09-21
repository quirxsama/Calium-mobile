import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/widgets/app_content_frame.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  DateTime? _lastBackPressTime;

  static const _items = [
    ('Ana Sayfa', Icons.home_outlined, Icons.home_rounded),
    ('Keşfet', Icons.explore_outlined, Icons.explore_rounded),
    ('Ara', Icons.search_rounded, Icons.search_rounded),
    ('Sosyal', Icons.people_outline_rounded, Icons.people_rounded),
    ('Kitaplık', Icons.video_library_outlined, Icons.video_library_rounded),
  ];

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;

      // If not on Home (tab 0), first back press returns to Home
      if (widget.selectedIndex != 0) {
        widget.onDestinationSelected(0);
        return;
      }

      // If already on Home (tab 0), double press to exit
      final now = DateTime.now();
      if (_lastBackPressTime == null ||
          now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
        _lastBackPressTime = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çıkmak için tekrar basın'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        SystemNavigator.pop();
      }
    },
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        final extended = constraints.maxWidth >= 1200;
        return Scaffold(
          body: Row(
            children: [
              if (wide) ...[
                SafeArea(
                  right: false,
                  child: NavigationRail(
                    selectedIndex: widget.selectedIndex,
                    onDestinationSelected: widget.onDestinationSelected,
                    extended: extended,
                    scrollable: true,
                    minExtendedWidth: 208,
                    labelType: extended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    backgroundColor: AppColors.surfaceDark,
                    indicatorColor: AppColors.primaryGlow,
                    groupAlignment: -0.7,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: extended
                          ? const Text(
                              'CALIUM',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            )
                          : const Icon(
                              Icons.play_circle_fill_rounded,
                              size: 32,
                              color: AppColors.primary,
                            ),
                    ),
                    destinations: [
                      for (final item in _items)
                        NavigationRailDestination(
                          icon: Icon(item.$2),
                          selectedIcon: Icon(item.$3, color: AppColors.primary),
                          label: Text(item.$1),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
              ],
              Expanded(
                child: AppContentFrame(
                  maxWidth: widget.selectedIndex == 3 ? 960 : 1400,
                  child: widget.child,
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: NavigationBar(
                    selectedIndex: widget.selectedIndex,
                    onDestinationSelected: widget.onDestinationSelected,
                    backgroundColor: AppColors.surfaceDark,
                    indicatorColor: AppColors.primaryGlow,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      for (final item in _items)
                        NavigationDestination(
                          icon: Icon(item.$2),
                          selectedIcon: Icon(item.$3, color: AppColors.primary),
                          label: item.$1,
                        ),
                    ],
                  ),
                ),
        );
      },
    ),
  );
}

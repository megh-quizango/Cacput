import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../home/home_dashboard_screen.dart';
import '../explore/explore_feed_screen.dart';
import '../ai_studio/ai_studio_hub_screen.dart';
import '../studio/my_studio_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/ad_tab_service.dart';
import '../../core/theme/responsive_orientation_manager.dart';
import '../../widgets/app_exit_dialog.dart';

class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeDashboardScreen(),
    ExploreFeedScreen(),
    AiStudioHubScreen(),
    MyStudioScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
    // Trigger Custom Chrome Tabs on navigation/click
    AdTabService.instance.onUserInteraction();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveOrientationHelper.enforce(context);
    return PopScope(
      key: const ValueKey('main_shell_pop_scope'),
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Custom chrome tab launching on back press/back gesture
        AdTabService.instance.onBackTriggered();

        if (_currentIndex != 0) {
          // If on another tab, navigate back to Home tab
          setState(() {
            _currentIndex = 0;
          });
        } else {
          // If already on Home screen, show exit confirmation dialog
          await AppExitDialog.show(context);
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111119),
          border: Border(
            top: BorderSide(color: Color(0xFF222230), width: 1),
          ),
        ),
        child: SafeArea(
          key: const ValueKey('bottom_nav_safe_area'),
          top: false,
          left: true,
          right: true,
          bottom: true,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  label: "Home",
                  activeIcon: Icons.home_filled,
                  inactiveIcon: Icons.home_outlined,
                ),
                _buildNavItem(
                  index: 1,
                  label: "Explore",
                  activeIcon: Icons.grid_view_rounded,
                  inactiveIcon: Icons.grid_view_outlined,
                ),
                _buildNavItem(
                  index: 2,
                  label: "AI",
                  activeIcon: Icons.bolt_rounded,
                  inactiveIcon: Icons.bolt_outlined,
                ),
                _buildNavItem(
                  index: 3,
                  label: "Studio",
                  activeIcon: Icons.folder_rounded,
                  inactiveIcon: Icons.folder_outlined,
                ),
                _buildNavItem(
                  index: 4,
                  label: "Me",
                  activeIcon: Icons.person_rounded,
                  inactiveIcon: Icons.person_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.brandPink : const Color(0xFF8A8F9E);

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

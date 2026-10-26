import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_wrapper_screen.dart';
import '../../screens/shell/main_shell_screen.dart';
import '../../screens/explore/template_detail_screen.dart';
import '../../screens/ai_studio/auto_caption_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../screens/editor/timeline_editor_screen.dart';
import '../../services/ad_tab_service.dart';
import '../theme/responsive_orientation_manager.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  observers: [
    AdTabNavigatorObserver(),
    OrientationLockRouteObserver(),
  ],
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.onboarding,
      builder: (context, state) => const OnboardingWrapperScreen(),
    ),
    GoRoute(
      path: RouteNames.quiz,
      redirect: (context, state) => RouteNames.home,
    ),
    GoRoute(
      path: RouteNames.home,
      builder: (context, state) => const MainShellScreen(initialIndex: 0),
    ),
    GoRoute(
      path: RouteNames.explore,
      builder: (context, state) => const MainShellScreen(initialIndex: 1),
    ),
    GoRoute(
      path: "${RouteNames.templateDetail}/:id",
      builder: (context, state) {
        final id = state.pathParameters["id"] ?? "temp_travel";
        return TemplateDetailScreen(templateId: id);
      },
    ),
    GoRoute(
      path: RouteNames.aiStudio,
      builder: (context, state) => const MainShellScreen(initialIndex: 2),
    ),
    GoRoute(
      path: RouteNames.autoCaption,
      builder: (context, state) => const AutoCaptionScreen(),
    ),
    GoRoute(
      path: RouteNames.myStudio,
      builder: (context, state) => const MainShellScreen(initialIndex: 3),
    ),
    GoRoute(
      path: RouteNames.profile,
      builder: (context, state) => const MainShellScreen(initialIndex: 4),
    ),
    GoRoute(
      path: RouteNames.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: RouteNames.editor,
      builder: (context, state) => const TimelineEditorScreen(),
    ),
  ],
);

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/responsive_orientation_manager.dart';
import 'core/routing/app_router.dart';
import 'services/connectivity_service.dart';
import 'services/ad_tab_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Core, Crashlytics, Remote Config, Analytics)
  await FirebaseService.instance.initialize();

  // Enforce initial responsive orientation lock (portrait for mobile, unlocked for tablets)
  ResponsiveOrientationHelper.enforceFromPlatformDispatcher();

  // Initialize network connectivity monitoring
  ConnectivityService.instance.initialize();

  // Initialize AdTabService and load persistent custom chrome tab and ad configuration
  await AdTabService.instance.initialize();

  // Dark navigation and status bar style matching Android specifications
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF111119),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(
    const ProviderScope(
      child: CapCutReplicaApp(),
    ),
  );
}

class CapCutReplicaApp extends StatelessWidget {
  const CapCutReplicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "PhotoVideoCourse",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        return ResponsiveOrientationManager(
          child: ConnectivityOverlayManager(
            child: child ?? const SizedBox(),
          ),
        );
      },
    );
  }
}

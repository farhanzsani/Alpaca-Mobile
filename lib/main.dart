/// Main entry point for the ALPACA application.
///
/// Initializes Firebase, sets up global error handling, and launches
/// the app with provider-based state management and GoRouter navigation.
library;

import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/app_providers.dart';
import 'viewmodels/auth_view_model.dart';

/// Application entry point.
///
/// Initializes Flutter bindings, Firebase services, and global error
/// handlers before launching the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handling for Flutter framework errors.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Set up global error handling for asynchronous errors.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('PlatformDispatcher error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  try {
    // Guard: hanya initialize jika belum ada Firebase app yang terdaftar.
    // Mencegah [core/duplicate-app] saat hot restart.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final prefs = await SharedPreferences.getInstance();

    runApp(AlpacaApp(prefs: prefs));
  } catch (error, stack) {
    debugPrint('Firebase initialization failed: $error');
    debugPrint('Stack trace: $stack');
    runApp(InitializationErrorApp(error: error));
  }
}

/// The root widget of the ALPACA application.
///
/// Wraps the app with [MultiProvider] for state management and uses
/// [MaterialApp.router] with GoRouter for declarative navigation.
class AlpacaApp extends StatelessWidget {
  /// Creates the ALPACA application widget.
  const AlpacaApp({required this.prefs, super.key});

  /// SharedPreferences instance for services that require it.
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: getAppProviders(prefs),
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'ALPACA',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            routerConfig: AppRouter.createRouter(
              context.read<AuthViewModel>(),
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// Fallback app displayed when Firebase initialization fails.
///
/// Shows a simple error screen with details about the initialization failure.
class InitializationErrorApp extends StatelessWidget {
  /// Creates an error app with the given [error].
  const InitializationErrorApp({
    required this.error,
    super.key,
  });

  /// The error that occurred during initialization.
  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALPACA - Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to initialize the application.\n'
                  'Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

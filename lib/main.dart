import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Filter out known Windows Flutter engine bug on Alt-Tab / focus change
  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionStr = details.exceptionAsString();
    if (exceptionStr.contains('keysPressed') ||
        exceptionStr.contains('_pressedKeys') ||
        exceptionStr.contains('physical key is already pressed') ||
        exceptionStr.contains('KeyDownEvent') ||
        exceptionStr.contains('RawKeyDownEvent') ||
        exceptionStr.contains('HardwareKeyboard')) {
      return;
    }
    FlutterError.presentError(details);
  };

  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    final errorStr = error.toString();
    if (errorStr.contains('keysPressed') ||
        errorStr.contains('_pressedKeys') ||
        errorStr.contains('physical key is already pressed') ||
        errorStr.contains('KeyDownEvent') ||
        errorStr.contains('RawKeyDownEvent') ||
        errorStr.contains('HardwareKeyboard')) {
      return true;
    }
    return false;
  };

  // Allow google_fonts to fetch fonts from network (required on desktop)
  GoogleFonts.config.allowRuntimeFetching = true;
  // Initialize locale data for Bahasa Indonesia date formatting
  await initializeDateFormatting('id', null);
  // Inisialisasi token tersimpan dari secure vault
  await ApiClient().init();
  runApp(const ProviderScope(child: SinarHarapanPmsApp()));
}

class SinarHarapanPmsApp extends ConsumerWidget {
  const SinarHarapanPmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Sinar Harapan Frontdesk & PMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

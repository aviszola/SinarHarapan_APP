import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/router.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Allow google_fonts to fetch fonts from network (required on desktop)
  GoogleFonts.config.allowRuntimeFetching = true;
  // Initialize locale data for Bahasa Indonesia date formatting
  await initializeDateFormatting('id', null);
  runApp(
    const ProviderScope(
      child: SinarHarapanPmsApp(),
    ),
  );
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

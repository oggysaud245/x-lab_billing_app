/// XLab Billing — app entry point. Bootstraps the database-backed app state
/// (language, theme, organization, receipt design) before the first frame,
/// wires the controllers, and shows a lightweight splash while loading.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/db/app_database.dart';
import 'core/theme/app_theme.dart';
import 'features/home_shell.dart';
import 'localization/app_localizations.dart';
import 'shared/controllers/app_state.dart';
import 'shared/controllers/billing_state.dart';
import 'shared/controllers/printer_state.dart';
import 'shared/repositories/invoice_repository.dart';
import 'shared/repositories/printer_repository.dart';
import 'shared/services/printer_discovery.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppRoot());
}

/// Loads [AppState] off the first frame, then mounts the real app.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  Future<List<ChangeNotifier>>? _bootstrap;

  @override
  void initState() {
    super.initState();
    _bootstrap = bootstrap();
  }

  /// Opens the app state first (fast pref-mirror decides the locale), then
  /// builds controllers. Printer configuration loads in the background so a
  /// photo of the splash is never blocked by hardware I/O.
  Future<List<ChangeNotifier>> bootstrap() async {
    await AppDatabase.open;
    final app = await AppState.create();
    final billing = BillingController(app: app)..syncFromSettings();
    final printer = PrinterController(
      printers: PrinterRepository(open: () => AppDatabase.open),
      invoiceRepo: InvoiceRepository(open: () => AppDatabase.open),
      discovery: PrinterDiscoveryService(),
    );
    unawaited(printer.load());
    return [app, billing, printer];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChangeNotifier>>(
      future: _bootstrap,
      builder: (context, snap) {
        final parts = snap.data;
        if (snap.connectionState != ConnectionState.done || parts == null) {
          return const SplashScreen();
        }
        final app = parts[0] as AppState;
        final billing = parts[1] as BillingController;
        final printer = parts[2] as PrinterController;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: app),
            ChangeNotifierProvider<BillingController>.value(value: billing),
            ChangeNotifierProvider<PrinterController>.value(value: printer),
          ],
          child: const XLabApp(),
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long, size: 56, color: AppTheme.seedBlue),
              const SizedBox(height: 16),
              const Text('XLab Billing',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('Loading… / लोड हुँदै…',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline)),
              const SizedBox(height: 24),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The localized, themed application shell. Listens to [AppState] so the
/// language switch re-roots the widget tree immediately.
class XLabApp extends StatelessWidget {
  static const supported = [
    Locale('en'),
    Locale('ne'),
  ];

  const XLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: state.locale,
      supportedLocales: supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.themeMode,
      home: const HomeShell(),
    );
  }
}

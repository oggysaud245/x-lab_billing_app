/// Five-tab home shell: Billing / Products / Invoices / Printer / Settings.
/// The top banners reflect printer status and first-run organization setup.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../shared/controllers/app_state.dart';
import '../shared/controllers/printer_state.dart';
import '../shared/models/printer.dart';
import '../shared/widgets/widgets_extra.dart';
import 'billing/billing_screen.dart';
import 'invoices/invoices_screen.dart';
import 'printer/printer_screen.dart';
import 'products/products_screen.dart';
import 'settings/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  int _seenBillingTabRequest = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    if (app.billingTabRequestVersion != _seenBillingTabRequest) {
      _seenBillingTabRequest = app.billingTabRequestVersion;
      _tab = 0;
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (!app.organization.isConfigured) _OrgBanner(onTap: _goSettingsOrg),
            _PrinterBanner(onTap: () => _jumpTo(3)),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  BillingPage(),
                  ProductsPage(),
                  InvoicesPage(),
                  PrinterPage(),
                  SettingsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l.navBilling,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: l.navProducts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_outlined),
            selectedIcon: const Icon(Icons.receipt),
            label: l.navInvoices,
          ),
          NavigationDestination(
            icon: const Icon(Icons.print_outlined),
            selectedIcon: const Icon(Icons.print),
            label: l.navPrinter,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.navSettings,
          ),
        ],
      ),
    );
  }

  void _jumpTo(int i) => setState(() => _tab = i);

  void _goSettingsOrg() {
    setState(() => _tab = 4);
  }
}

class _OrgBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _OrgBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.store_outlined, size: 18, color: cs.onPrimaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.orgSetupPrompt,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slim status banner above the tabs (different per PrinterStatus).
class _PrinterBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PrinterBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final printer = context.watch<PrinterController>();
    final s = printer.status;
    final name = printer.selected?.displayName ?? '';
    final subtitle = switch (s) {
      PrinterStatus.notSelected => l.printerNotSelectedMsg,
      PrinterStatus.disconnected => l.printerDisconnectedMsg,
      PrinterStatus.connected => l.printerConnectedTo(name),
      PrinterStatus.error => l.printerErrorMsg(printer.statusDetail ?? ''),
      PrinterStatus.usbPermissionRequired => l.printerUsbPermissionMsg,
      PrinterStatus.busy => l.printerBusyMsg,
      PrinterStatus.sending => l.printSendingMsg,
      _ => l.printerConnectionFailed,
    };
    // Only show the banner for statuses the biller needs to know about.
    if (!const {
      PrinterStatus.notSelected,
      PrinterStatus.usbPermissionRequired,
      PrinterStatus.error,
    }.contains(s)) {
      return const SizedBox();
    }
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(printerStatusIcon(s),
                  size: 18,
                  color: printerStatusColor(context, s)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${printerStatusLabel(l, s)} — $subtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

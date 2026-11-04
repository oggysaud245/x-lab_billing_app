/// Shared widgets and helpers used across feature screens: labeled inputs,
/// section cards, dialogs, snackbar, empty states and l10n mappers for the
/// enum-driven settings and printer status.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/formatting/money.dart';
import '../../localization/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/printer.dart';

// ---------------------------------------------------------------------------
// Locations of enum → localized label mappings
// ---------------------------------------------------------------------------

String printerStatusLabel(AppLocalizations l, PrinterStatus s) => switch (s) {
      PrinterStatus.connected => l.printerStatusConnected,
      PrinterStatus.disconnected => l.printerStatusDisconnected,
      PrinterStatus.searching => l.printerStatusSearching,
      PrinterStatus.connecting => l.printerStatusConnecting,
      PrinterStatus.busy => l.printerStatusBusy,
      PrinterStatus.error => l.printerStatusError,
      PrinterStatus.notSelected => l.printerStatusNotSelected,
      PrinterStatus.usbPermissionRequired => l.printerStatusUsbPermission,
      PrinterStatus.sending => l.printerStatusSending,
    };

IconData printerStatusIcon(PrinterStatus s) => switch (s) {
        PrinterStatus.connected => Icons.print,
        PrinterStatus.searching || PrinterStatus.connecting || PrinterStatus.sending =>
          Icons.sync,
        PrinterStatus.error => Icons.error_outline,
        PrinterStatus.usbPermissionRequired => Icons.usb,
        _ => Icons.print_disabled,
      };

Color printerStatusColor(BuildContext context, PrinterStatus s) {
  final cs = Theme.of(context).colorScheme;
  return switch (s) {
    PrinterStatus.connected => cs.primary,
    PrinterStatus.searching ||
    PrinterStatus.connecting ||
    PrinterStatus.busy ||
    PrinterStatus.sending =>
      cs.tertiary,
    PrinterStatus.error || PrinterStatus.usbPermissionRequired => cs.error,
    _ => cs.outline,
  };
}

// ---------------------------------------------------------------------------
// Text parsing helpers for money/qty/percent fields
// ---------------------------------------------------------------------------

/// User input → paisa. Empty input is null; invalid text is 0-tolerated by
/// the caller showing a validation message first.
int? paisaFromInput(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  return parseDecimalToScale(t, paisaPerNPR);
}

int? quantityMilliFromInput(String? raw, {int? precision}) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  final parsed = parseDecimalToScale(t, qtyScale);
  if (parsed == null) return null;
  return precision != null ? roundQuantityMilli(parsed, precision) : parsed;
}

int? percentFromInput(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  return parseDecimalToScale(t, percentScale);
}

// ---------------------------------------------------------------------------
// Display formatting (uses the session's settings for symbol/numerals/prec)
// ---------------------------------------------------------------------------

/// Money text honoring the settings' symbol + numeral choice.
String moneyText(
  AppSettings settings,
  int paisa, {
  bool withSymbol = true,
}) =>
    formatPaisa(
      paisa,
      symbol: settings.currency.label,
      devanagari: settings.numeralFormat.isDevanagari,
      withSymbol: withSymbol,
    );

/// Raw money text without any symbol (for small row/column layouts).
String moneyTextPlain(AppSettings settings, int paisa) =>
    formatPaisa(
      paisa,
      symbol: '',
      devanagari: settings.numeralFormat.isDevanagari,
      withSymbol: false,
    );

/// Quantity text honoring settings precision + numerals.
String qtyText(AppSettings settings, int quantityMilli) =>
    formatScaled(
      quantityMilli,
      scale: qtyScale,
      decimals: settings.quantityPrecision.clamp(0, 3),
      devanagari: settings.numeralFormat.isDevanagari,
    );

// ---------------------------------------------------------------------------
// Basic building blocks
// ---------------------------------------------------------------------------

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      dense: true,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Segmented control over enum values, localized by [labelOf].
class EnumSegment<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  const EnumSegment({
    super.key,
    required this.label,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        SegmentedButton<T>(
          segments: [
            for (final v in values)
              ButtonSegment(value: v, label: Text(labelOf(v), softWrap: false)),
          ],
          selected: {selected},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ],
    );
  }
}

class EnumDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final String Function(T) labelOf;
  final T value;
  final ValueChanged<T?> onChanged;

  const EnumDropdown({
    super.key,
    required this.label,
    required this.values,
    required this.labelOf,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        for (final v in values)
          DropdownMenuItem(value: v, child: Text(labelOf(v))),
      ],
      onChanged: onChanged,
    );
  }
}

class EmptyView extends StatelessWidget {
  final String text;
  final IconData icon;

  const EmptyView({super.key, required this.text, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog / snackbar / confirm
// ---------------------------------------------------------------------------

OverlayEntry? _activeNotificationEntry;
void Function()? _dismissActiveNotification;

/// Shows a notification message at the top of the screen across all routes,
/// bottom sheets and dialogs.
void showAppSnackBar(BuildContext context, String message) {
  _dismissActiveNotification?.call();
  _dismissActiveNotification = null;

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    return;
  }

  late final OverlayEntry entry;
  var removed = false;
  void removeEntry() {
    if (removed) return;
    removed = true;
    if (_activeNotificationEntry == entry) {
      _activeNotificationEntry = null;
      _dismissActiveNotification = null;
    }
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (ctx) => _TopNotificationBanner(
      message: message,
      onDismiss: removeEntry,
    ),
  );

  _activeNotificationEntry = entry;
  _dismissActiveNotification = removeEntry;
  overlay.insert(entry);
}

class _TopNotificationBanner extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _TopNotificationBanner({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<_TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    _timer = Timer(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _timer?.cancel();
    if (!mounted) {
      widget.onDismiss();
      return;
    }
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.inverseSurface;
    final fg = theme.colorScheme.onInverseSurface;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.up,
                onDismissed: (_) {
                  _timer?.cancel();
                  widget.onDismiss();
                },
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _dismiss,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: fg,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standardized confirmation dialog (Yes/No) using the app's own strings.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? positiveLabel,
}) async {
  final l = AppLocalizations.of(context);
  final res = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: message == null || message.isEmpty
          ? null
          : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(positiveLabel ?? l.yes),
        ),
      ],
    ),
  );
  return res ?? false;
}

/// Pads a sheet title row for the dialogs that edit sub-entities.
class SheetHeader extends StatelessWidget {
  final String title;

  const SheetHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

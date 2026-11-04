/// Printer tab: status/test, saved configurations, LAN discovery (raw TCP
/// probing of the local /24 on port 9100), USB device list with permission
/// flow, and the per-printer configuration editor sheet.
///
/// The XTKP607UL is an ESC/POS-class 58/80 mm thermal printer; LAN sockets
/// default to port 9100. Spec claims are intentionally conservative here:
/// see docs/printer_validation.md for the hardware validation procedure.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../localization/app_localizations.dart';
import '../../shared/controllers/app_state.dart';
import '../../shared/controllers/printer_state.dart';
import '../../shared/models/printer.dart';
import '../../shared/widgets/widgets_extra.dart';

class PrinterPage extends StatelessWidget {
  const PrinterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navPrinter),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        // Prebuild a screenful below the viewport: on font-scaled devices the
        // USB/section cards sit far below the first paint; without this range
        // their children never mount until well after scrolling starts.
        cacheExtent: 800,
        children: const [
          _StatusCard(),
          _SavedList(),
          _DiscoverySection(),
          _UsbSection(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status card
// ---------------------------------------------------------------------------

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ctrl = context.watch<PrinterController>();
    final sel = ctrl.selected;
    final s = ctrl.status;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(printerStatusIcon(s), color: printerStatusColor(context, s)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sel == null
                            ? l.printerNotSelectedMsg
                            : sel.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${printerStatusLabel(l, s)}'
                        '${sel == null ? '' : ' · ${_linkLabel(l, sel)}'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: sel == null
                        ? () => showAppSnackBar(context, l.selectPrinterFirst)
                        : () async {
                            final ok = await ctrl.testConnection(sel);
                            if (!context.mounted) return;
                            showAppSnackBar(
                                context, ok ? l.printerTestOk : l.connectionTestFailed);
                          },
                    icon: const Icon(Icons.wifi_tethering),
                    label: Text(l.testConnection),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: sel == null
                        ? () => showAppSnackBar(context, l.selectPrinterFirst)
                        : () async {
                            final bottomMargin = context
                                .read<AppState>()
                                .settings
                                .bottomMarginOnReceipt;
                            final ok = await ctrl.printTest(
                              sel,
                              bottomMargin: bottomMargin,
                            );
                            if (!context.mounted) return;
                            showAppSnackBar(
                                context,
                                ok
                                    ? l.printerTestOkLabel
                                    : l.connectionTestFailed);
                          },
                    icon: const Icon(Icons.print_outlined),
                    label: Text(l.testPrint),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _linkLabel(AppLocalizations l, PrinterConfig c) =>
      c.connectionType == ConnectionType.lan
          ? '${c.host.isEmpty ? '-' : '${c.host}:${c.port}'}'
          : c.usbDeviceName.isEmpty
              ? 'USB'
              : c.usbDeviceName;
}

// ---------------------------------------------------------------------------
// Saved configurations
// ---------------------------------------------------------------------------

class _SavedList extends StatelessWidget {
  const _SavedList();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final ctrl = context.watch<PrinterController>();
    return SectionCard(
      title: l.printerSettings,
      children: [
        if (ctrl.configs.isEmpty)
          Text(l.printerNotSelectedMsg,
              style: Theme.of(context).textTheme.bodySmall),
        for (final cfg in ctrl.configs)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: cfg.isSelected
                  ? cs.primaryContainer.withValues(alpha: 0.45)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (!cfg.isSelected) {
                    ctrl.select(cfg.id);
                  }
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        cfg.isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color:
                            cfg.isSelected ? cs.primary : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        cfg.connectionType == ConnectionType.lan
                            ? Icons.lan_outlined
                            : Icons.usb,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cfg.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: cfg.isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                            ),
                            Text(
                              cfg.connectionType == ConnectionType.lan
                                  ? '${cfg.host}:${cfg.port} · ${cfg.paperWidthMm}mm'
                                  : 'USB · ${cfg.paperWidthMm}mm',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l.printerSettings,
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => _editConfig(context, ctrl, cfg),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _addManual(context, ctrl),
              icon: const Icon(Icons.add),
              label: Text(l.manualPrinter),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _addManual(BuildContext context, PrinterController ctrl) =>
    _editConfig(context, ctrl, null);

Future<void> _editConfig(
  BuildContext context,
  PrinterController ctrl,
  PrinterConfig? existing,
) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ConfigSheet(existing: existing),
    );

// ---------------------------------------------------------------------------
// LAN discovery
// ---------------------------------------------------------------------------

/// Headline used in LAN-discovery result tiles, in priority order:
/// 1. a name the network resolved via the mDNS sweep (rare; bare port-9100
///    boards answer nothing);
/// 2. the matching saved configuration's user-chosen display name for the
///    same host+port — the scan frequently re-discovers the printer already
///    configured, and this is the name the user actually recognizes;
/// 3. the ip address (tiles then keep the plain ip + port look).
@visibleForTesting
String discoveryHeadline(DiscoveredPrinter d, List<PrinterConfig> configs) {
  final name = d.name.trim();
  if (name.isNotEmpty && name != d.host) return name;
  for (final c in configs) {
    final label = c.displayName.trim();
    if (c.connectionType == ConnectionType.lan &&
        c.host == d.host &&
        c.port == d.port &&
        label.isNotEmpty &&
        label != d.host) {
      return label;
    }
  }
  return d.host;
}

class _DiscoverySection extends StatelessWidget {
  const _DiscoverySection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ctrl = context.watch<PrinterController>();
    return SectionCard(
      title: l.connectionLan,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: ctrl.scanning
                    ? ctrl.cancelDiscover
                    : () => ctrl.discover(),
                icon: Icon(
                  ctrl.scanning ? Icons.stop : Icons.wifi_find_outlined,
                ),
                label: Text(ctrl.scanning ? l.stopSearch : l.discoverPrinters),
              ),
            ),
          ],
        ),
        if (ctrl.scanning) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ctrl.scanTotal <= 0
                ? null
                : ctrl.scanDone / ctrl.scanTotal,
          ),
          const SizedBox(height: 4),
          Text(
            '${l.discoveringNetwork} · ${ctrl.scanDone}/${ctrl.scanTotal}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(l.printerScanNote,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        for (final d in ctrl.discovered)
          Padding(
            key: ValueKey('lan-dev-${d.host}:${d.port}'),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: LayoutBuilder(builder: (context, constraints) {
              // Deterministic widths, same pattern as the USB rows: no
              // ListTile-with-trailing layout that can grow to the full tile
              // width on some Impeller/Vulkan devices (the trailing button
              // once laid out at exactly the tile width on real hardware,
              // failing ListTile's layout assert every frame and blanking
              // this whole card). The action column is capped at half the
              // row; the host text ellipsizes in the rest.
              final actionMax = constraints.maxWidth * 0.5;
              // Headline priority: mDNS name → saved config's name for the
              // same host+port → the ip itself (tiles keep ip + port then).
              final headline = discoveryHeadline(d, ctrl.configs);
              final labeled = headline != d.host;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.router_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          labeled ? '${d.host} · port ${d.port}' : 'port ${d.port}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: actionMax),
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        final cfg = PrinterConfig(
                          id: 0,
                          displayName: d.name.isEmpty ? d.host : d.name,
                          connectionType: ConnectionType.lan,
                          host: d.host,
                          port: d.port,
                          paperWidthMm: ctrl.selected?.paperWidthMm ?? 58,
                          renderingMode: RenderingMode.auto,
                          usbVendorId: null,
                          usbProductId: null,
                          usbDeviceName: '',
                          enableCut: true,
                          enableBeep: false,
                          enableDrawer: false,
                          isSelected: true,
                          updatedAt: DateTime.now().millisecondsSinceEpoch,
                        );
                        await ctrl.save(cfg);
                        if (!context.mounted) return;
                        showAppSnackBar(context, l.printerSavedMsg);
                      },
                      icon: const Icon(Icons.check),
                      label: Text(l.selectPrinter),
                    ),
                  ),
                ],
              );
            }),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// USB devices
// ---------------------------------------------------------------------------

class _UsbSection extends StatelessWidget {
  const _UsbSection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ctrl = context.watch<PrinterController>();
    return SectionCard(title: l.connectionUsb, children: [
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => ctrl.refreshUsbDevices(),
              icon: const Icon(Icons.usb),
              label: Text(l.usbDevices),
            ),
          ),
        ],
      ),
      if (ctrl.usbDevices.isEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(l.usbNoDevices,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            l.usbDeviceAttachHint,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
      ],
      for (final dev in ctrl.usbDevices)
        Padding(
          key: ValueKey('usb-dev-${dev.deviceName}-${dev.vendorId}:${dev.productId}'),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: LayoutBuilder(builder: (context, constraints) {
            // Deterministic widths: no child ever lays out unbounded, so no
            // renderer bug can paint content over the parent card. The name
            // column gets the space the action doesn't use.
            final actionMax = constraints.maxWidth * 0.5;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.usb_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dev.labelAutoName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '${dev.vendorId}:${dev.productId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: actionMax),
                  child: dev.hasPermission
                      ? FilledButton.tonalIcon(
                          onPressed: () async {
                            await ctrl.save(PrinterConfig(
                              id: 0,
                              displayName: dev.labelAutoName,
                              connectionType: ConnectionType.usb,
                              host: '',
                              port: 0,
                              usbVendorId: dev.vendorId,
                              usbProductId: dev.productId,
                              usbDeviceName: dev.deviceName,
                              paperWidthMm: ctrl.selected?.paperWidthMm ?? 58,
                              renderingMode: RenderingMode.auto,
                              enableCut: true,
                              enableBeep: false,
                              enableDrawer: false,
                              isSelected: true,
                              updatedAt:
                                  DateTime.now().millisecondsSinceEpoch,
                            ));
                            if (!context.mounted) return;
                            showAppSnackBar(context, l.printerSavedMsg);
                          },
                          icon: const Icon(Icons.check),
                          label: Text(l.selectPrinter),
                        )
                      : OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await ctrl.requestUsbPermission(dev);
                            if (!context.mounted) return;
                            showAppSnackBar(
                              context,
                              ok
                                  ? l.usbDeviceConnected
                                  : l.printerUsbPermissionMsg,
                            );
                          },
                          label: Text(l.requestPermission),
                        ),
                ),
              ],
            );
          }),
        ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Config editor sheet
// ---------------------------------------------------------------------------

class _ConfigSheet extends StatefulWidget {
  final PrinterConfig? existing;
  const _ConfigSheet({required this.existing});

  @override
  State<_ConfigSheet> createState() => _ConfigSheetState();
}

class _ConfigSheetState extends State<_ConfigSheet> {
  late final PrinterController _ctrl;
  late ConnectionType _type;
  late RenderingMode _mode;
  late bool _cut;
  late bool _beep;
  late bool _drawer;
  late int _width;

  late final TextEditingController _name;
  late final TextEditingController _ip;
  late final TextEditingController _port;
  late final TextEditingController _vid;
  late final TextEditingController _pid;
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ctrl = Provider.of<PrinterController>(context, listen: false);
    final c = widget.existing;
    _type = c?.connectionType ?? ConnectionType.lan;
    _mode = c?.renderingMode ?? RenderingMode.auto;
    _cut = c?.enableCut ?? true;
    _beep = c?.enableBeep ?? false;
    _drawer = c?.enableDrawer ?? false;
    _width = c?.paperWidthMm ?? 58;
    _name = TextEditingController(text: c?.displayName ?? '');
    _ip = TextEditingController(text: c?.host ?? '');
    _port = TextEditingController(
      text: c == null ? '9100' : (c.port <= 0 ? '9100' : '${c.port}'),
    );
    _vid = TextEditingController(
      text: c?.usbVendorId == null ? '' : '${c!.usbVendorId}',
    );
    _pid = TextEditingController(
      text: c?.usbProductId == null ? '' : '${c!.usbProductId}',
    );
    _name.addListener(_onFieldChanged);
    _ip.addListener(_onFieldChanged);
    _port.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSave {
    if (_name.text.trim().isEmpty) return false;
    if (_type == ConnectionType.lan) {
      if (_ip.text.trim().isEmpty) return false;
      final port = int.tryParse(_port.text.trim());
      if (port == null || port <= 0 || port > 65535) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _name.removeListener(_onFieldChanged);
    _ip.removeListener(_onFieldChanged);
    _port.removeListener(_onFieldChanged);
    _name.dispose();
    _ip.dispose();
    _port.dispose();
    _vid.dispose();
    _pid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final editing = widget.existing != null;
    return Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: Form(
        key: _form,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: SheetHeader(
                  title: editing ? l.edit : l.manualPrinter,
                ),
              ),
              const SizedBox(height: 10),
              EnumSegment<ConnectionType>(
                label: l.connectionType,
                values: const [ConnectionType.lan, ConnectionType.usb],
                labelOf: (t) => switch (t) {
                  ConnectionType.lan => l.connectionLan,
                  ConnectionType.usb => l.connectionUsb,
                },
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l.printerName,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (_type == ConnectionType.usb) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _vid,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l.usbVendorId,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _pid,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l.usbProductId,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_type == ConnectionType.lan)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _ip,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]')),
                        ],
                        decoration: InputDecoration(
                          labelText: l.printerIp,
                          hintText: '192.168.1.123',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          final parts = t.split('.');
                          if (t.isEmpty ||
                              parts.length != 4 ||
                              parts.any(
                                  (p) => int.tryParse(p) == null ||
                                      (int.parse(p) < 0 || int.parse(p) > 255))) {
                            return l.enteredIpError;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _port,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l.port,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n <= 0 || n > 65535) {
                            return l.portError;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              EnumSegment<String>(
                label: l.paperWidthLabel,
                values: const ['58', '80'],
                labelOf: (v) => v == '58' ? l.paperWidth58 : l.paperWidth80,
                selected: '$_width',
                onChanged: (v) => setState(() => _width = v == '80' ? 80 : 58),
              ),
              EnumSegment<RenderingMode>(
                label: l.renderingModeLabel,
                values: const [
                  RenderingMode.auto,
                  RenderingMode.text,
                  RenderingMode.image,
                ],
                labelOf: (m) => switch (m) {
                  RenderingMode.auto => l.renderingModeAuto,
                  RenderingMode.text => l.renderingModeText,
                  RenderingMode.image => l.renderingModeImage,
                },
                selected: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              Text(l.renderingModeNote,
                  style: Theme.of(context).textTheme.bodySmall),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(l.enableCutLabel),
                value: _cut,
                onChanged: (v) => setState(() => _cut = v),
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(l.enableBeepLabel),
                value: _beep,
                onChanged: (v) => setState(() => _beep = v),
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(l.enableDrawerLabel),
                value: _drawer,
                onChanged: (v) => setState(() => _drawer = v),
              ),
              FilledButton.icon(
                onPressed: _canSave ? _save : null,
                icon: const Icon(Icons.save),
                label: Text(l.save),
              ),
              if (editing)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () async {
                    final l2 = AppLocalizations.of(context);
                    final ok = await showConfirmDialog(
                      context,
                      title: l2.forgetPrinter,
                      positiveLabel: l2.forgetPrinter,
                    );
                    if (!ok || !context.mounted) return;
                    await _ctrl.forget(widget.existing!);
                    if (!context.mounted) return;
                    showAppSnackBar(context, l2.printerForgottenMsg);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.link_off),
                  label: Text(l.forgetPrinter),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      showAppSnackBar(context, l.nameRequired);
      return;
    }
    if (!_form.currentState!.validate()) return;
    final c = widget.existing;
    final manualVid = _type == ConnectionType.usb ? int.tryParse(_vid.text.trim()) : null;
    final manualPid = _type == ConnectionType.usb ? int.tryParse(_pid.text.trim()) : null;
    final savedUsbVendorId = (_type == ConnectionType.usb && manualVid != null)
        ? manualVid
        : c?.usbVendorId;
    final savedUsbProductId =
        (_type == ConnectionType.usb && manualPid != null) ? manualPid : c?.usbProductId;
    await _ctrl.save(
      PrinterConfig(
        id: c?.id ?? 0,
        displayName: _name.text.trim(),
        connectionType: _type,
        host: _type == ConnectionType.lan ? _ip.text.trim() : '',
        port: _type == ConnectionType.lan ? int.parse(_port.text.trim()) : 0,
        usbVendorId: savedUsbVendorId,
        usbProductId: savedUsbProductId,
        usbDeviceName: c?.usbDeviceName ?? '',
        paperWidthMm: _width,
        renderingMode: _mode,
        enableCut: _cut,
        enableBeep: _beep,
        enableDrawer: _drawer,
        isSelected: true,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      existingId: c?.id,
    );
    if (!mounted) return;
    showAppSnackBar(context, l.printerSavedMsg);
    Navigator.pop(context);
  }
}

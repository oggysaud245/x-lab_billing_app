# XTKP607UL Printer Validation Procedure

This document describes how to validate the XLab **XTKP607UL** thermal receipt
printer against this billing app's output, and which hardware-specific behaviors
are assumed versus verified.

## Assumed behavior (documented, not yet hardware-verified)

1. **Network printing**: raw TCP socket writes to port **9100** (printer default)
   are accepted by the printer and produce a print job. The app speaks ESC/POS.
2. **USB printing**: Android USB Host grants permission via the system dialog
   and the app writes via `UsbDeviceConnection.bulkTransfer`. Detection matches
   the vendor's own USB SDK demo (repo `Android SDK/USBDEMO`): the supported
   receipt boards identify by VID/PID (`0x0483:0x5740`, `0x1CBE:0x0003`,
   `0x1CB0:0x0003`, `0x0493:0x8760`, `0x0416:0x5011`, `0x0416:0xAABB`) and most
   do not advertise the printer device class, with the data bulk endpoint on a
   non-zero interface (CDC-style). Detection also lists class 7/8 devices and
   CDC-data/vendor-spec interfaces with a bulk OUT. The physical device's
   VID/PID is unverified.
3. **Cut / beep / drawer**: `GS V 0` (full cut), `ESC B` (beep), drawer control are
   supported per the printer's ESC/POS implementation. Note: earlier builds
   emitted a malformed `GS V 66 0` sequence (stray `0x42` parameter), which never
   cut; the canonical full cut is now emitted and print+cut over LAN was observed
   on real hardware (user-confirmed with a manually added LAN printer).
4. **Raster**: `GS v 0` with 1-bit images sized to the head's printable band —
   384 dots for 58 mm-class paper (≈48 mm printable) and 576 dots for 80 mm-class
   (≈72 mm); the band is fixed by the head, not by the roll width.
5. **Paper width**: ESC/POS status/transmit queries (`GS r`, `DLE EOT`) deliver
   paper *sensor* status only — they do not carry the paper width, and
   `GS W` (set printing area width) is a set-only command. There is therefore no
   device→host paper-width read-back in the standard ESC/POS profile this app
   speaks. The app applies the user-selected roll width (58 mm / 80 mm via the
   printer settings sheet) mapped to the head band (`dotsForWidthMm`: 384 dots
   for ≤62 mm-class, 576 dots for >62 mm-class). Saves made from the USB/LAN
   tile lists now inherit the currently selected printer's paper width instead
   of hardcoding 58 mm, so a selected 80 mm printer keeps its size.
6. **LAN discovery names**: raw port-9100 boards expose no identity in the
   standard ESC/POS profile, so friendly names come from one best-effort
   mDNS/DNS-SD sweep after the port scan (`_pdl-datastream`/`_ipp`/`_printer`
   service instances, plus a reverse-PTR hostname query per found host).
   Queries are RFC 6762 *QU* (unicast replies) so Android's Wi-Fi multicast
   filter cannot drop the answers without a multicast lock. Tiles then show a
   name ahead of the address in priority order
   (`discoveryHeadline` in `printer_screen.dart`): the network-resolved mDNS
   name → the saved configuration's user-chosen display name for the same
   host+port (the scan often re-discovers the printer the user already named)
   → the bare ip. Boards without Bonjour never answer the sweep — a documented
   finding, not a bug: a host-side probe (`/tmp/opencode/mdns_probe.dart`,
   passive listen + the same QU queries, from a PC on 192.168.1.0/24) measured
   **zero mDNS chatter and zero replies** from the validated XTKP607UL board
   at 192.168.1.100, so on this LAN tiles normally show the saved config's
   name or plain ip + port. Native `NsdManager` discovery is the candidate
   follow-up if target boards advertise services but respond differently to
   QU questions. **Vendor ships no discovery API at all** (read from the
   bundled SDK, 2013-era ZJ): `WIFIDEMO`/`NETDEMO` + `wfsdk.jar` expose only
   `WifiCommunication.initSocket(ip, port)` with manual IP entry; the USB
   side is a static VID/PID table (`UsbController.getDev`), not enumeration
   by broadcast. The only identification channel the board itself offers is
   **HTTP tcp/80** (open on the validated unit; tcp/515 and 8080 closed,
   UDP/161 SNMP silent): an "Ethernet WebSet System" page whose
   `GET http://<host>/printerConfig.js` returns
   `settingsCallback({ver, mac, ip, gw, sub})` — firmware version and MAC,
   no human name, and it speaks headerless HTTP/0.9-style responses. A tiny
   GET-only client on it could double as "this really is a printer" evidence
   (MAC/version) per discovered host; never POST its `config.cgi` — it
   writes network settings (ip/sub/gw).

These started as assumptions from the printer's public ESC/POS profile; the
next section records what has since been exercised on the physical device.

## Verified on device (Xiaomi Pad 6 "nabu", MIUI, Impeller/Vulkan — 2026-11)

- **LAN discovery → save flow works on real hardware.** Tap Find Printers on the
  192.168.1.0/24 wifi: raw TCP port-9100 probes found the printer at
  `192.168.1.100`, the result tile rendered with a Select action, and tapping it
  pushed "Printer saved." — deduped into the existing manually-added LAN config
  by host+port identity (`PrinterRepository.saveAndSelect`). The pad's own
  subnet is picked up from its wifi interface everywhere, without outbound
  internet (`localAddress` skips loopback; see `pickLanAddress`).
- **Discovery names: mechanism verified host-side, headline pending a device
  look.** The name shown on result tiles resolves as mDNS name → saved
  config's name → bare ip (`discoveryHeadline`, unit-tested). On the validated
  LAN the printer answers no mDNS at all (host-side probe from the PC on the
  same /24: zero chatter, zero replies), so tiles show the saved config's
  display name (e.g. the manually added "yggg" config) or plain ip + port.
  The rebuilt tile itself has not been eyeballed on the pad yet — the device
  was locked with a secure keyguard at build time.
- **Discovery card blanking (fixed, logged for regression context):** the first
  implementation used `ListTile` with a trailing `FilledButton.tonalIcon` in the
  discovery results; on the pad the button laid out at exactly the full tile
  width, firing ListTile's layout assert during `performLayout` on every frame —
  the whole LAN card painted blank with no error box (MIUI strips app logcat, so
  the exception was only visible from the `flutter run` console). The results
  rows now use the deterministic `LayoutBuilder` + `Row` pattern shared with the
  USB rows; `test/printer_discovery_render_test.dart` guards the row `ValueKey`s
  and card-geometry containment.
- **Print + cut over LAN**: user-confirmed on the physical printer with both
  text and `GS v 0` raster receipts (`xL/xH` in horizontal bytes, banded at 64
  rows, `feedLinesAtEnd = 5` to clear the ~15 mm printhead-to-cutter offset,
  and canonical `GS V 0` full cut). Hardware does not support `ESC K` / `ESC e`
  reverse paper feed (silently ignored by firmware), so the ~15 mm top margin
  after a cut is fixed by the physical distance between the printhead and the
  cutter blade.
- **USB test print: still unresolved.** Detection, product-name display, and the
  permission grant all behave; writes report success but nothing prints, and at
  one point the device appeared to disconnect during a test print. Next
  suspects: the bulk-write path in `MainActivity.kt` (interface / endpoint
  selection) or vendor firmware behavior. Reproduce with the `flutter run`
  console attached — MIUI suppresses the app's own logcat lines.

## Validation checklist

### 1. Network (LAN) test

1. Connect the printer to the same LAN as the device running the app.
2. Confirm printer IP (report → or print configuration page).
3. In the app: Printer tab → Find Printers → select the discovered printer →
   Test connection.
4. Print a **test receipt** (bilingual EN+NE, Devanagari → raster).
5. Verify on paper: bilingual text, Devanagari numerals correct, alignment,
   margins, cut behavior, no garbling.

### 2. USB test (Android)

1. Connect printer via USB host cable to the Android device.
2. In the app: Printer tab → USB section → refresh list → select device →
   request permission → open → test connection → print test receipt.
3. Note the VID:PID shown for the detected printer and report it back — it
   feeds the vendor-table check (`vendorPrinterIds` in `MainActivity.kt`);
   if the printer still does not appear, note whether any entry at all shows
   in the USB list (absent entry = detection problem; present entry = open or
   write problem).
3. Verify permission dialog appears, device is listed, write succeeds.
4. Manual add path (fallback if auto-detect misses the board): Add Printer
   Manually → connection type USB → enter the decimal Vendor ID / Product ID
   (hex pairs above are shown hex; type e.g. `1155` / `22336` for
   `0x0483:0x5740`) → save → test connection / print. The manual form now
   persists VID/PID, so a manual USB entry uses the real IDs instead of the
   null that previously forced `USB_PERMISSION_DENIED` for VID 0 / PID 0.

### 3. Nepali raster verification

- Receipt with Devanagari content must render via `GS v 0` bitmap, not text mode.
- Check: correct script, correct vowel signs (matras), correct digits, no tofu
  boxes, no clipped descenders/ascenders, correct right-to-left ordering.
- Check: western numerals option vs Devanagari numerals option both render.

### 4. Money & quantity formats

- NPR symbol choice: `NPR` (English) or `रु.` (Devanagari).
- Amounts in paisa; quantities in thousandths (x1000); percentages in hundredths
  (x100) end-to-end.

## Troubleshooting

- No discovery: ensure printer IP reachable, port 9100 open, same subnet.
- No printer name on LAN results: the printer (or router) answered no
  mDNS/DNS-SD queries (Bonjour print services / reverse PTR) for the host,
  so tiles keep ip + port; the name can also be set by editing the saved
  printer entry in Printer settings.
- USB permission: user must grant via system dialog; the app re-checks via
  `UsbManager.hasPermission` and treats that readback as authoritative — the
  reply's `EXTRA_PERMISSION_GRANTED` can be dropped (immutable reply
  PendingIntent on Android 12+, OEM quirks). `requestPermission` also resolves
  immediately when the grant already persisted and refreshes the device list on
  every return, so a granted tile flips to "Select" without a manual re-tap.
  Device validation should confirm: grant → tile switches without pressing
  "USB Devices" again; and that a second grant request for an already-granted
  device resolves instantly (no dialog) instead of hanging.
- Wrong paper size: the ESC/POS status channel does not transmit the paper width
  (sensor status only; `GS W` is set-only), so size must come from the app
  setting. Select 58 mm / 80 mm in the printer settings; USB/LAN tile saves
  inherit the selected printer's width. Validate on the physical device by
  printing a test receipt on each width and checking the printed band.
- Print failures: check `print_jobs` records and app logs; failed prints must not
  consume invoice numbers.

## Reporting issues

Record: printer firmware version, connection type, receipt content (EN/NE),
rendering mode used, error text from the app.

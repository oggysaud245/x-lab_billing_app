# AGENTS.md

Guidance for coding agents working in this repo (xlab_billing: Android-only Flutter app for billing + ESC/POS receipt printing, English/Nepali bilingual).

## Commands

- Requires Flutter/Dart SDK ^3.8. Setup: `flutter pub get`. `intl: any` in pubspec.yaml is pinned by the localization codegen on purpose — don't change it.
- After ARB edits, run `flutter gen-l10n` before `flutter analyze`/`flutter test` or the checked-in generated code is stale.
- Verification order: `flutter analyze` → `flutter test` (53 tests, ~10 s, no device or emulator needed). A cold analyzer run can transiently report duplicate issue counts (e.g. ~36); re-run before trusting a non-baseline count.
- Single file: `flutter test test/money_test.dart`. Single test: `flutter test --plain-name "<name>"`.
- `flutter run` / `flutter build apk` target Android. Release builds currently sign with the debug keystore (deliberate TODO in `android/app/build.gradle.kts`).
- `flutter analyze` is not clean today: 12 pre-existing info-level lints (mostly `use_build_context_synchronously` in screens). Treat that as the baseline — don't add new issues and don't hide them with `ignore_for_file`.

## Test prerequisites (non-obvious)

- Native sqflite doesn't run under `flutter test`. Every test file must do `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` in `setUpAll`, open `inMemoryDatabasePath`, and `await createSchema(db)` — which applies the exact production schema + seed data from `lib/core/db/app_database.dart` (see `test/database_test.dart` / `test/widget_test.dart`).
- Repositories and services take a `Future<Database> Function() open` callback, so tests inject a db instead of the lazy `AppDatabase.open` singleton. `AppDatabase.close()`/`openAt(path)` exist to reset it. Default wiring lives in `lib/shared/app_wiring.dart`.
- **Do not await sqflite-ffi repository/controller calls inside `testWidgets`** — the FakeAsync zone deadlocks the ffi transport (test silently hangs, no assertion fires). Put controller/data flows in plain `test()` (see the controller test in `test/printer_screen_test.dart`); `testWidgets` only drives UI with mocked channels.
- Widget-test finder traps (whole app lives in one `HomeShell` with `IndexedStack`): `find.byType`/`byIcon` are **exact-type** matchers, so `.icon` variants (`OutlinedButton.icon` → `_OutlinedButtonWithIcon`) are invisible to them — use `byWidgetPredicate((w) => w is OutlinedButton)` or `find.descendant(of: buttonPredicate, matching: label)`. Matchers also skip offstage subtrees: children under other `IndexedStack` tabs and behind-viewport `ListView` rows are mounted but unmatched unless `skipOffstage: false`. Every widget test avoids `pumpAndSettle` (frames never settle — use fixed pumps); the cause of the perpetual ticker is unknown but reproducible. Narrow-view tests must pass `skipOffstage: false` for list rows below the fold (`flutter test` treats them as offstage) and drag the list before tapping.
- `testWidgets` that pump the whole `HomeShell` can flake with "A Timer is still pending even after the widget tree was disposed": hidden `IndexedStack` tabs (e.g. Products) start background sqflite-ffi loads whose 10-second transaction watchdogs race the FakeAsync zone (the failure jumps between tests inside one file). When a test only exercises one page, pump that page directly (`home: const PrinterPage()` in `test/printer_discovery_render_test.dart`) instead of the shell.

## Generated localization code (import path trap)

- `pubspec.yaml` has `generate: true`, but `l10n.yaml` sets `synthetic-package: false`, so generated files are checked into `lib/localization/`. Import `package:xlab_billing/localization/app_localizations.dart` (or relative) — the synthetic `package:flutter_gen/...` import will NOT resolve.
- Add every new key to BOTH `lib/l10n/app_en.arb` and `app_ne.arb`, then run `flutter gen-l10n`. `test/l10n_test.dart` enforces EN/NE key parity, non-empty strings, and a required-key list.

## Architecture

- One Flutter package; the only native code is `android/app/src/main/kotlin/np/xlab/xlab_billing/MainActivity.kt`, which implements the single `usb_printer` MethodChannel (`listDevices`, `hasPermission`, `requestPermission`, `open`, `write`, `close`). USB is Android-only — unavailable on desktop where the channel would hit `notImplemented`.
- Entrypoint `lib/main.dart`: a splash blocks the first frame on `AppDatabase.open`, then AppState + BillingController + PrinterController are provided via MultiProvider; printer config loads async in the background — keep heavy I/O out of the bootstrap path.
- Layout: `lib/features/<screen>/` (UI), `lib/shared/{controllers,repositories,services,models}/` (state + data), `lib/core/{db,formatting,theme,errors}/` (pure helpers). Schema and future migrations live in `lib/core/db/app_database.dart` (`dbVersion` bumps need an `onUpgrade` step).

## Domain invariants (wrong changes fail silently in real-world use)

- Numbers are integer fixed-point end-to-end: paisa (x100) for amounts, milli-units (x1000) for quantities, hundredths (x100) for percent. Never `double`; use the round-half-up helpers in `lib/core/formatting/money.dart`, which also handle Devanagari digit normalization.
- Invoice numbers are sequential from `app_settings[invoice_next]`: failed prints must NOT consume or reuse a number, drafts don't consume them, and voided invoices keep their rows.
- Finalization snapshots organization/receipt/settings state into the invoice row at finalize time and never re-derives it (reprints use the stored snapshot).
- Devanagari receipt content must render as a raster bitmap (`GS v 0` with the Noto Sans Devanagari fonts from `assets/fonts/`); ASCII-only receipts use ESC/POS text mode. Shared logic in `lib/shared/services/receipt_layout.dart` + `receipt_bitmap.dart` (+ `escpos.dart` for text mode).
- Receipt content is deliberately fixed: no balance (due) row ever prints (Paid/Change still print when relevant), items render as a fixed-width Particulars | Qty | Rate | Amount table driven by `receiptTableFractions` in `escpos.dart` (shared by both engines), and right-aligned table cells must never wrap — the raster engine right-anchors them to the column edge so oversized values overflow the gap instead of breaking mid-number.
- `show_time_on_receipt` is read from the app-settings snapshot (string `'true'/'false'` via `PrintOrchestrator._boolFlag`, missing key = true) — the receipt-design snapshot has no such key, so reading it there silently enables the time forever.
- Printer hardware behavior (raw TCP 9100, USB detection via the vendor VID/PID table from `Android SDK/USBDEMO` + bulk-OUT interface heuristics, cut/beep/drawer/raster support for the XTKP607UL) is assumed, not hardware-verified. `docs/printer_validation.md` is the validation procedure and the list of live assumptions — keep claims consistent with it.
- **Adding a printer is identity-deduped in `PrinterRepository.saveAndSelect`**: a fresh insert reuses an existing configuration with the same connection identity (USB: vendor+product id and device path when both known; an empty path — manual add — matches any stored path of the same unit; LAN: host+port) instead of stacking duplicates. Identity reuse updates connection attributes but preserves a user-chosen display name; explicit edits (`existingId > 0`) overwrite all fields including the name. Covered by the controller test in `test/printer_screen_test.dart`.
- LAN-discovery result rows must stay on the deterministic `LayoutBuilder` + `Row` pattern in `_DiscoverySection` (ValueKey `lan-dev-<host>:<port>`, action capped at 50% width), never `ListTile` with a trailing button: on the Xiaomi Pad (Impeller/Vulkan) the trailing button once laid out at exactly the full tile width, firing ListTile's layout assert during `performLayout` every frame and painting the whole LAN card blank with no error box. `test/printer_discovery_render_test.dart` guards the row keys.

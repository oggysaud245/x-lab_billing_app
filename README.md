# xlab_billing

Flutter Android billing app for the **XLab XTKP607UL** thermal receipt printer,
bilingual in **English and Nepali**.

## Features

- **Billing**: product picker, cart with quantities in thousandths (x1000), unit
  pricing, line totals, discounts (percent/amount), tax (percent), other charges,
  grand total, cash/payment handling.
- **Invoices**: transactional sequential invoice numbers (`prefix/digits/FY`),
  drafts vs finalized vs voided lifecycle, void keeps records, never reuses
  numbers after failed prints, drafts do not consume numbers.
- **Receipts**: bilingual (EN/NE) text or raster (bitmap via `GS v 0`) rendering,
  Noto Sans + Noto Sans Devanagari fonts, 58/80 mm paper support, configurable
  header/footer messages and visible fields, alignment, text size.
- **Printing**: LAN raw TCP port 9100 (discovered via subnet scan) and USB host
  (Android `UsbManager` platform channel) with permission flow; ESC/POS encoding
  (`ESC @`, `ESC a`, `ESC !`, rules, two-part lines, `GS v 0`, `GS V 66 0`, `ESC B`).
- **i18n**: English + Nepali (Devanagari), persisted language, independent invoice
  language setting (follow app / always EN / always NE), Bikram Sambat vs Gregorian
  dates, western or Devanagari numerals, NPR or रु. currency symbol.
- **Data**: sqflite local database, full backup/restore, invoice CSV export.

## Tech stack

- Flutter (Dart), Provider, sqflite (sqlite3), flutter_localizations (en/ne),
  flutter_test + sqflite_common_ffi for tests.
- Android: Flutter embedding v2, `usb_printer` MethodChannel, USB Host API
  (UsbManager / UsbDeviceConnection / UsbEndpoint).

## Getting started

```bash
flutter pub get
flutter gen-l10n
flutter test
flutter analyze
flutter run
flutter build apk
```

## Testing

- Unit: money parsing/formatting/scaling, dates/Bikram Sambat, invoice numbering,
  BillTotals, receipt layout (text vs raster), ESC/POS bytes, database schema.
- Widget: home shell smoke test.

## Printer notes

- Raw TCP port 9100 default; subnet scan discovers the printer.
- Nepali (Devanagari) content is rendered as a raster bitmap (`GS v 0`) using
  Noto Sans Devanagari; ASCII-only receipts use ESC/POS text mode.
- USB printing uses the Android USB Host API (`usb_printer` channel) with runtime
  permission flow; no claim of untested hardware behavior — see
  [docs/printer_validation.md](docs/printer_validation.md).

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ARB files declare the same key set in EN and NE', () {
    final enPath = File('lib/l10n/app_en.arb');
    final nePath = File('lib/l10n/app_ne.arb');
    expect(enPath.existsSync(), isTrue, reason: 'app_en.arb must exist');
    expect(nePath.existsSync(), isTrue, reason: 'app_ne.arb must exist');
    final en = jsonDecode(enPath.readAsStringSync()) as Map<String, dynamic>;
    final ne = jsonDecode(nePath.readAsStringSync()) as Map<String, dynamic>;
    final enKeys = en.keys
        .where((k) => !k.startsWith('@') && k != 'en')
        .toSet();
    final neKeys = ne.keys
        .where((k) => !k.startsWith('@') && k != 'ne')
        .toSet();
    expect(neKeys, containsAll(enKeys));
    expect(enKeys, containsAll(neKeys));
  });

  test('ARB files carry required bilingual strings', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final enKeys = en.keys
        .where((k) => !k.startsWith('@') && k != 'en')
        .toSet();
    expect(enKeys, containsAll([
      'appTitle',
      'navBilling',
      'navProducts',
      'navInvoices',
      'navPrinter',
      'navSettings',
      'grandTotal',
      'invoiceNumber',
      'subtotal',
      'discount',
      'tax',
      'paidLabel',
      'dueLabel',
      'thankYou',
      'customerInformation',
      'paymentMethod',
      'amountPaid',
      'balanceDue',
      'notes',
      'previewInvoice',
      'printInvoice',
      'finalizeAndPrint',
      'finalizeAndSave',
      'invoiceSavedMsg',
      'printSendingMsg',
      'printSentMsg',
      'printAttemptFailed',
      'reprintInvoice',
      'voidInvoice',
      'statusFinalized',
      'statusVoided',
      'discoveringNetwork',
      'wifiRequiredHint',
      'printerStatusConnected',
      'printerStatusDisconnected',
      'printerStatusUsbPermission',
      'bikramSambatCalendar',
      'dateFormatLabel',
      'dateFormatStyleLabel',
      'dateStyleNumeric',
      'dateStyleLongMonth',
      'showTimeOnReceipt',
      'bottomMarginOnReceipt',
      'quantityPrecisionLabel',
      'selectedFormatHint',
      'taxPercentHint',
      'discountPercentHint',
      'discountAmountHint',
      'otherChargesHint',
      'otherChargesLabel',
      'enableTax',
      'enableOtherCharges',
      'defaultDiscountPercent',
      'invoicePrefixLabel',
      'invoiceNumberPreview',
      'startingNumberLabel',
      'numberOfDigitsLabel',
      'taxSettingsTitle',
      'templateLanguageTab',
      'headerMessages',
      'footerMessages',
      'visibleFields',
      'receiptDesign',
      'backupTitle',
      'createBackup',
      'restoreBackup',
      'exportInvoicesCsv',
      'appVersionLabel',
      'aboutAppText',
      'organizationSnapshotNote',
      'organizationSection',
      'receiptSection',
      'billingSection',
      'dataSection',
      'aboutSection',
      'paymentMethodQr',
      'paymentMethodBankTransfer',
      'paymentMethodOther',
      'receiptProfilesSection',
      'addReceiptProfile',
      'editReceiptProfile',
      'profileNameLabel',
      'defaultProfileName',
      'profileSavedMsg',
      'deleteProfileConfirm',
      'billingProfilesSection',
      'addBillingProfile',
      'editBillingProfile',
      'defaultBillingProfileName',
      'billingProfileSavedMsg',
      'deleteBillingProfileConfirm',
      'allProfilesFilter',
      'receiptProfileLabel',
      'profileNameExistsError',
      'profileNameRequiredError',
      'addCategory',
      'categoryName',
      'categorySavedMsg',
      'categoryExistsMsg',
      'enterCategoryName',
      'noCategory',
      'enterProductNameEn',
      'enterRate',
      'selectUnitRequired',
      'manageCategories',
      'editCategory',
      'deleteCategory',
      'categoryDeletedMsg',
      'deleteCategoryConfirm',
      'deleteCategoryConfirmProducts',
      'manageUnits',
      'editUnit',
      'deleteUnit',
      'unitDeletedMsg',
      'deleteUnitConfirm',
      'cannotDeleteUnitInUse',
      'standardUnit',
      'customUnitBadge',
      'productCountLabel',
      'snLabel',
    ]));
    for (final k in enKeys) {
      final v = en[k];
      expect(v, isA<String>(), reason: 'key $k must map to a string');
      expect((v as String).trim().isNotEmpty, isTrue, reason: 'key $k must be non-empty');
    }
  });
}

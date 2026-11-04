// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'XLab Billing';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get search => 'Search';

  @override
  String get confirm => 'Confirm';

  @override
  String get optional => 'Optional';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get savedSuccessfully => 'Saved successfully.';

  @override
  String get deleteSuccess => 'Deleted.';

  @override
  String get learnMoreHint => 'Hide keyboard to continue';

  @override
  String get splashTagline => 'Billing & Receipts';

  @override
  String get splashPreparing => 'Preparing app…';

  @override
  String get splashDatabase => 'Opening database…';

  @override
  String get splashSettings => 'Loading settings…';

  @override
  String get splashPrinter => 'Connecting printer…';

  @override
  String get splashProducts => 'Loading products…';

  @override
  String get splashOrgWarn =>
      'Organization details are not set yet. You can set them in Settings.';

  @override
  String get splashOfflinePrinter =>
      'Printer not connected. You can save bills now and print later.';

  @override
  String get navBilling => 'Billing';

  @override
  String get navProducts => 'Products';

  @override
  String get navInvoices => 'Invoices';

  @override
  String get navPrinter => 'Printer';

  @override
  String get navSettings => 'Settings';

  @override
  String get printerStatusConnected => 'Connected';

  @override
  String get printerStatusDisconnected => 'Disconnected';

  @override
  String get printerStatusSearching => 'Searching…';

  @override
  String get printerStatusConnecting => 'Connecting…';

  @override
  String get printerStatusBusy => 'Busy';

  @override
  String get printerStatusError => 'Error';

  @override
  String get printerStatusNotSelected => 'No printer selected';

  @override
  String get printerStatusUsbPermission => 'USB permission required';

  @override
  String get printerStatusSending => 'Sending…';

  @override
  String printerConnectedTo(String name) {
    return 'Printer connected: $name';
  }

  @override
  String get printerDisconnectedMsg => 'Printer disconnected.';

  @override
  String get printerNotSelectedMsg =>
      'Please select a printer in the Printer tab.';

  @override
  String get printerConnectionFailed => 'Printer connection failed.';

  @override
  String get printerNetworkTimeout =>
      'Could not reach the printer (connection timed out).';

  @override
  String get printerBusyMsg => 'Printer is busy. Please wait and try again.';

  @override
  String printerErrorMsg(String error) {
    return 'Printer error: $error';
  }

  @override
  String get printerUsbPermissionMsg =>
      'USB permission denied. Grant permission and try again.';

  @override
  String get searchProducts => 'Search Products';

  @override
  String get searchProductsHintNameSku =>
      'Search by English, Nepali names or SKU';

  @override
  String get allCategories => 'All';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get emptyProducts =>
      'No products yet. Add a product to start billing.';

  @override
  String get emptyProductsSearch => 'No products match your search.';

  @override
  String get currentBill => 'Current Bill';

  @override
  String get emptyCart => 'No items in the bill. Tap a product to add it.';

  @override
  String get clearBill => 'Clear Bill';

  @override
  String get clearBillConfirm => 'Clear all items of the current bill?';

  @override
  String get quantity => 'Quantity';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get itemAmount => 'Amount';

  @override
  String get removeItem => 'Remove item';

  @override
  String get deselect => 'Deselect';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Discount';

  @override
  String get tax => 'Tax';

  @override
  String get otherCharges => 'Other Charges';

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get addDiscount => 'Add Discount';

  @override
  String get editDiscount => 'Edit Discount';

  @override
  String get removeDiscount => 'Remove Discount';

  @override
  String get discountTypePercent => 'Percent (%)';

  @override
  String get discountTypeFixed => 'Fixed Amount';

  @override
  String get discountPercentHint => 'Discount % (e.g. 5 or 5.50)';

  @override
  String get discountAmountHint => 'Discount amount';

  @override
  String get taxPercentHint => 'Tax % (e.g. 13)';

  @override
  String get otherChargesHint => 'Other charges amount';

  @override
  String get noDiscount => 'No discount';

  @override
  String get itemAddedMsg => 'Added to bill';

  @override
  String get itemRemovedMsg => 'Item removed';

  @override
  String get billClearedMsg => 'Bill cleared';

  @override
  String get billEmptyError => 'Bill is empty. Add at least one item.';

  @override
  String get enterQuantity => 'Please enter a quantity.';

  @override
  String get enterValidQuantity => 'Invalid quantity.';

  @override
  String get enterValidRate => 'Please enter a valid rate.';

  @override
  String get discountExceedsSubtotal => 'Discount cannot exceed the subtotal.';

  @override
  String get paidExceedsTotal => 'Paid amount exceeds the grand total.';

  @override
  String get customerInformation => 'Customer (Optional)';

  @override
  String get customer => 'Customer';

  @override
  String get customerName => 'Customer Name';

  @override
  String get customerPhone => 'Phone Number';

  @override
  String get customerAddress => 'Address';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodQr => 'QR Payment';

  @override
  String get paymentMethodBankTransfer => 'Bank Transfer';

  @override
  String get paymentMethodOther => 'Other';

  @override
  String get amountPaid => 'Paid Amount';

  @override
  String get balanceDue => 'Balance Due';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'Internal or receipt notes';

  @override
  String get defaultCashPayment => 'Default payment method';

  @override
  String get previewInvoice => 'Preview Invoice';

  @override
  String get printInvoice => 'Print Invoice';

  @override
  String get finalizeAndSave => 'Save Invoice';

  @override
  String get finalizeAndPrint => 'Save & Print';

  @override
  String get invoiceSavedMsg => 'Invoice saved.';

  @override
  String get printUnavailableSavedMsg =>
      'Printer not connected. Invoice saved — reprint it later from Invoices.';

  @override
  String get printSendingMsg => 'Sending to printer…';

  @override
  String get printSentMsg => 'Sent to printer. Please check the paper.';

  @override
  String get printAlreadyFinalizedMsg => 'Invoice already finalized.';

  @override
  String get reprintInvoice => 'Reprint';

  @override
  String get startNewBill => 'Start New Bill';

  @override
  String get viewInvoice => 'View Invoice';

  @override
  String get invoiceLanguage => 'Invoice Language';

  @override
  String get invoiceLanguageFollowApp => 'Follow App Language';

  @override
  String get invoiceLanguageEnglish => 'English';

  @override
  String get invoiceLanguageNepali => 'नेपाली';

  @override
  String get previewUpdateHint => 'Preview updates when language changes.';

  @override
  String get previewLoadFailed => 'Could not render the receipt preview.';

  @override
  String previewLanguageDefault(String lang) {
    return '$lang (default)';
  }

  @override
  String get invoiceNumber => 'Invoice Number';

  @override
  String get date => 'Date';

  @override
  String get organization => 'Organization';

  @override
  String get products => 'Products';

  @override
  String get addProduct => 'Add Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String deleteProductConfirm(String name) {
    return 'Delete product \"$name\"? This cannot be undone.';
  }

  @override
  String get productNameEn => 'Product Name (English)';

  @override
  String get productNameNe => 'Product Name (नेपाली)';

  @override
  String get sku => 'SKU / Code';

  @override
  String get descriptionEn => 'Description (English)';

  @override
  String get descriptionNe => 'Description (नेपाली)';

  @override
  String get productRate => 'Selling Rate';

  @override
  String get unit => 'Unit';

  @override
  String get category => 'Category';

  @override
  String get categoryHint => 'e.g. Food, Drink, Goods';

  @override
  String get unitShortLabel => 'Unit';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get showInactiveProducts => 'Show inactive products';

  @override
  String get sortByName => 'Sort by Name';

  @override
  String get sortByRate => 'Sort by Rate';

  @override
  String get sortByNewest => 'Sort by Newest';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortByNameAsc => 'Name (A to Z)';

  @override
  String get sortByNameDesc => 'Name (Z to A)';

  @override
  String get sortByDateNewest => 'Date (Newest first)';

  @override
  String get sortByDateOldest => 'Date (Oldest first)';

  @override
  String get sortByRateAsc => 'Price (Low to High)';

  @override
  String get sortByRateDesc => 'Price (High to Low)';

  @override
  String get selectUnit => 'Select Unit';

  @override
  String get customUnit => 'Custom Unit';

  @override
  String get addCustomUnit => 'Add Custom Unit';

  @override
  String get customUnitHint =>
      'Examples: Bottle / बोतल, Bundle / बन्डल, Cup / कप, Trip / ट्रिप';

  @override
  String get unitNameEn => 'Unit Name (English)';

  @override
  String get unitNameNe => 'Unit Name (नेपाली)';

  @override
  String get unitAbbreviationEn => 'Abbreviation (English)';

  @override
  String get unitAbbreviationNe => 'Abbreviation (नेपाली)';

  @override
  String get enterProductNames => 'Enter the name in English or नेपाली.';

  @override
  String get enterUnitName => 'Enter the unit name in English or नेपाली.';

  @override
  String get productSavedMsg => 'Product saved.';

  @override
  String get productDeletedMsg => 'Product deleted.';

  @override
  String get unitExistsMsg => 'This unit already exists.';

  @override
  String get inactiveMark => 'Inactive';

  @override
  String get invoices => 'Invoices';

  @override
  String get searchInvoices => 'Search invoice number or customer';

  @override
  String get dateRange => 'Date Range';

  @override
  String get filterToday => 'Today';

  @override
  String get filterLast7Days => 'Last 7 days';

  @override
  String get filterThisMonth => 'This month';

  @override
  String get filter3Months => '3 months';

  @override
  String get filter6Months => '6 months';

  @override
  String get filterThisYear => 'This year';

  @override
  String get filterAllTime => 'All time';

  @override
  String get filterCustomRange => 'Custom (From – To)';

  @override
  String get fromDate => 'From Date';

  @override
  String get toDate => 'To Date';

  @override
  String get pickDateRangeCalendar => 'Calendar Range';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get emptyInvoices =>
      'No invoices yet. Create your first bill from Billing.';

  @override
  String get emptyInvoicesSearch => 'No invoices match the search or filters.';

  @override
  String get items => 'Items';

  @override
  String itemCount(String count) {
    return '$count items';
  }

  @override
  String get statusFinalized => 'Finalized';

  @override
  String get statusVoided => 'Voided';

  @override
  String get statusProcessing => 'Processing';

  @override
  String get statusSuccess => 'Paid / Success';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String get transactionConfirmation => 'Transaction Confirmation';

  @override
  String get transactionStatus => 'Transaction Status';

  @override
  String get waitingForPaymentMsg =>
      'Waiting for payment. Mark as Paid to save & print.';

  @override
  String get paymentConfirmedMsg => 'Payment received. Ready to save & print.';

  @override
  String get transactionCanceledMsg => 'Transaction canceled.';

  @override
  String get saveAsProcessing => 'Save as Processing';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String get invoiceProcessingMsg =>
      'Transaction is currently processing (waiting for payment).';

  @override
  String get voidInvoice => 'Void Invoice';

  @override
  String voidInvoiceConfirm(String number) {
    return 'Void invoice $number? Voided invoices are kept in history but cannot be reprinted.';
  }

  @override
  String get voidReasonLabel => 'Reason for voiding';

  @override
  String get voidReasonHint => 'e.g. Wrong entry';

  @override
  String get invoiceVoidedMsg => 'Invoice voided.';

  @override
  String get voidNotAllowedReprint => 'A voided invoice cannot be reprinted.';

  @override
  String get printAttempts => 'Print Attempts';

  @override
  String get printAttemptFailed => 'Failed';

  @override
  String get printAttemptSent => 'Sent';

  @override
  String get notPrintedYet => 'Not printed yet';

  @override
  String printedTimes(String count) {
    return 'Printed $count time(s)';
  }

  @override
  String get organizationSnapshotNote =>
      'This invoice keeps the organization, product and price information saved at billing time.';

  @override
  String get totalsSection => 'Totals';

  @override
  String get paymentSection => 'Payment';

  @override
  String get printer => 'Printer';

  @override
  String get printerSettings => 'Printer Settings';

  @override
  String get connectionType => 'Connection Type';

  @override
  String get connectionLan => 'LAN / Wi-Fi';

  @override
  String get connectionUsb => 'USB';

  @override
  String get discoverPrinters => 'Find Printers';

  @override
  String get stopSearch => 'Stop';

  @override
  String get discoveringNetwork => 'Scanning network for printers…';

  @override
  String get wifiRequiredHint =>
      'Connect the phone and the printer to the same Wi-Fi network, then search again.';

  @override
  String get manualPrinter => 'Add Printer Manually';

  @override
  String get printerName => 'Printer Name';

  @override
  String get printerIp => 'IP Address';

  @override
  String get port => 'Port';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get testPrint => 'Test Print';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get forgetPrinter => 'Forget Printer';

  @override
  String get selectPrinter => 'Select';

  @override
  String get selected => 'Selected';

  @override
  String get usbDevices => 'USB Devices';

  @override
  String get usbVendorId => 'Vendor ID';

  @override
  String get usbProductId => 'Product ID';

  @override
  String get usbNoDevices =>
      'No USB printers detected. Connect the printer with a USB cable.';

  @override
  String get usbPermission => 'Permission';

  @override
  String get requestPermission => 'Grant Permission';

  @override
  String get usbDeviceConnected => 'Connected';

  @override
  String get usbDeviceAttachHint =>
      'Plug the printer via USB and allow access when the phone asks.';

  @override
  String get paperWidthLabel => 'Paper Width';

  @override
  String get renderingModeLabel => 'Print Method';

  @override
  String get renderingModeAuto => 'Auto (Recommended)';

  @override
  String get renderingModeText => 'Text (fast, English only)';

  @override
  String get renderingModeImage => 'Image (for नेपाली)';

  @override
  String get renderingModeNote =>
      'नेपाली Unicode needs image printing unless the printer supports Devanagari fonts.';

  @override
  String get enableCutLabel => 'Cut paper after print';

  @override
  String get enableBeepLabel => 'Beep after print (experimental)';

  @override
  String get enableDrawerLabel => 'Open cash drawer (experimental)';

  @override
  String get printDensityLabel => 'Print Darkness';

  @override
  String get enteredIpError => 'Enter a valid IP address.';

  @override
  String get portError => 'Enter a valid port (1–65535).';

  @override
  String get nameRequired => 'Enter a name.';

  @override
  String get printerSavedMsg => 'Printer saved.';

  @override
  String get printerForgottenMsg => 'Printer removed.';

  @override
  String get printerTestOk => 'Connection successful.';

  @override
  String get printerTestOkLabel => 'Test receipt sent. Check the printer.';

  @override
  String get connectionTestFailed => 'Connection test failed.';

  @override
  String get selectPrinterFirst => 'Select or connect a printer first.';

  @override
  String get printerScanNote =>
      'Printers on port 9100 are found by scanning the local network.';

  @override
  String get deviceInfo => 'Device info';

  @override
  String get paperWidth58 => '58 mm';

  @override
  String get paperWidth80 => '80 mm';

  @override
  String get settings => 'Settings';

  @override
  String get generalSection => 'General';

  @override
  String get organizationSection => 'Organization';

  @override
  String get receiptSection => 'Receipt Design';

  @override
  String get billingSection => 'Billing';

  @override
  String get dataSection => 'Data';

  @override
  String get aboutSection => 'About';

  @override
  String get appLanguage => 'App Language';

  @override
  String get themeModeLabel => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get currencySymbolLabel => 'Currency Symbol';

  @override
  String get currencyNpr => 'NPR';

  @override
  String get currencyRu => 'रु.';

  @override
  String get invoiceLanguageSetting => 'Default Invoice Language';

  @override
  String get numeralFormatLabel => 'Number Style';

  @override
  String get westernNumerals => 'Latin digits (1,250.00)';

  @override
  String get devanagariNumerals => 'Devanagari digits (१,२५०.००)';

  @override
  String get dateFormatLabel => 'Calendar System';

  @override
  String get gregorianCalendar => 'Gregorian (AD)';

  @override
  String get bikramSambatCalendar => 'Bikram Sambat (BS)';

  @override
  String get dateFormatStyleLabel => 'Date Style';

  @override
  String get dateStyleNumeric => 'Numeric (2082-07-12)';

  @override
  String get dateStyleLongMonth => 'With month name (12 Kartik 2082)';

  @override
  String get showTimeOnReceipt => 'Show time on receipts';

  @override
  String get bottomMarginOnReceipt => 'Match top margin at bottom of receipt';

  @override
  String get quantityPrecisionLabel => 'Quantity Decimals';

  @override
  String get selectedFormatHint => 'Preview';

  @override
  String get orgInformation => 'Organization Information';

  @override
  String get orgNameEn => 'Organization Name (English)';

  @override
  String get orgNameNe => 'Organization Name (नेपाली)';

  @override
  String get orgAddressEn => 'Address (English)';

  @override
  String get orgAddressNe => 'Address (नेपाली)';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get altPhoneLabel => 'Alternative Phone (optional)';

  @override
  String get emailLabel => 'Email (optional)';

  @override
  String get panNumberLabel => 'PAN Number (optional)';

  @override
  String get vatNumberLabel => 'VAT Number (optional)';

  @override
  String get websiteLabel => 'Website (optional)';

  @override
  String get registrationNumberLabel => 'Registration Number (optional)';

  @override
  String get logoLabel => 'Organization Logo (optional)';

  @override
  String get pickLogo => 'Choose Logo';

  @override
  String get removeLogo => 'Remove Logo';

  @override
  String get orgCustomInfoEn => 'Extra Information (English)';

  @override
  String get orgCustomInfoNe => 'Extra Information (नेपाली)';

  @override
  String get orgCustomInfoHint => 'Shown on receipts if enabled';

  @override
  String get enterOrgName =>
      'Enter the organization name in English or नेपाली.';

  @override
  String get phoneOrContactRequired =>
      'Enter a valid phone number or leave it empty.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get orgSavedMsg => 'Organization information saved.';

  @override
  String get orgSetupPrompt =>
      'Set up your organization details so bills show the correct header.';

  @override
  String get setupOrganization => 'Set Organization';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get receiptDesign => 'Receipt Design';

  @override
  String get visibleFields => 'Show on Receipt';

  @override
  String get showLogo => 'Logo';

  @override
  String get showAddress => 'Address';

  @override
  String get showPhone => 'Phone Number';

  @override
  String get showEmail => 'Email';

  @override
  String get showWebsite => 'Website';

  @override
  String get showPanVat => 'PAN / VAT';

  @override
  String get showCustomer => 'Customer Details';

  @override
  String get showPayment => 'Payment Details';

  @override
  String get headerMessages => 'Header Messages';

  @override
  String get footerMessages => 'Footer Messages';

  @override
  String get welcomeMessage => 'Welcome Message';

  @override
  String get thankYouMessage => 'Thank-You Message';

  @override
  String get returnPolicy => 'Return / Exchange Policy';

  @override
  String get paymentTerms => 'Payment Terms';

  @override
  String get promoMessage => 'Promotional Message';

  @override
  String get additionalMessage => 'Additional Message';

  @override
  String get customMessageHint => 'Leave empty to use the default text';

  @override
  String get headerAlignmentLabel => 'Header Alignment';

  @override
  String get alignLeft => 'Left';

  @override
  String get alignCenter => 'Center';

  @override
  String get textSizeLabel => 'Receipt Text Size';

  @override
  String get textSizeSmall => 'Small';

  @override
  String get textSizeMedium => 'Medium';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get receiptSavedMsg => 'Receipt design saved.';

  @override
  String get receiptPreviewLabel => 'Live Preview';

  @override
  String get templateLanguageTab => 'Message Language';

  @override
  String get invoicePrefixLabel => 'Invoice Prefix';

  @override
  String get invoicePrefixHint => 'e.g. INV-';

  @override
  String get startingNumberLabel => 'Starting Number';

  @override
  String get numberOfDigitsLabel => 'Number of Digits';

  @override
  String get fiscalYearPrefix => 'Add fiscal year prefix (starts in Shrawan)';

  @override
  String invoiceNumberPreview(String number) {
    return 'Preview: $number';
  }

  @override
  String get defaultDiscountPercent => 'Default Discount (%)';

  @override
  String get taxSettingsTitle => 'Tax & Charges';

  @override
  String get enableTax => 'Enable Tax';

  @override
  String get taxPercentLabel => 'Tax Rate (%)';

  @override
  String get enableDiscount => 'Enable Discount';

  @override
  String get enableOtherCharges => 'Enable Other Charges';

  @override
  String get otherChargesLabel => 'Charge Name';

  @override
  String get backupTitle => 'Backup & Export';

  @override
  String get createBackup => 'Create Database Backup';

  @override
  String get restoreBackup => 'Restore Backup';

  @override
  String get osBackupsHint =>
      'Backups are saved in the app folder on your phone storage.';

  @override
  String get noBackupsAvailable => 'No backups available.';

  @override
  String backupCreatedMsg(String path) {
    return 'Backup created: $path';
  }

  @override
  String get restoreBackupConfirm =>
      'Restoring a backup replaces all current data. Continue?';

  @override
  String get restoredMsg => 'Backup restored. Please restart the app.';

  @override
  String get exportInvoicesCsv => 'Export Invoices CSV';

  @override
  String exportDoneMsg(String path) {
    return 'Export finished: $path';
  }

  @override
  String get restoreFailed => 'Restore failed. Please try again.';

  @override
  String get appVersionLabel => 'App Version';

  @override
  String get aboutAppText =>
      'XLab Billing — offline billing and receipt printing for XLab XTKP607UL thermal printers.';

  @override
  String get panCode => 'PAN:';

  @override
  String get vatCode => 'VAT:';

  @override
  String get phoneCode => 'Tel:';

  @override
  String get paidLabel => 'Paid';

  @override
  String get dueLabel => 'Balance';

  @override
  String get thankYou => 'Thank You';

  @override
  String get invoiceTitle => 'INVOICE';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get qtyLabel => 'Qty';

  @override
  String get unitLabel => 'Unit';

  @override
  String get rateLabel => 'Rate';

  @override
  String get amountLabel => 'Amount';

  @override
  String get snLabel => 'S.N.';

  @override
  String get particularsLabel => 'Particulars';

  @override
  String get changeLabel => 'Change';

  @override
  String get receiptProfilesSection => 'Receipt Profiles';

  @override
  String get addReceiptProfile => 'New Receipt Profile';

  @override
  String get editReceiptProfile => 'Edit Receipt Profile';

  @override
  String get profileNameLabel => 'Profile Name';

  @override
  String get defaultProfileName => 'Default Profile';

  @override
  String get profileSavedMsg => 'Receipt profile saved.';

  @override
  String get deleteProfileConfirm => 'Delete this receipt profile?';

  @override
  String get billingProfilesSection => 'Billing Profiles';

  @override
  String get addBillingProfile => 'New Billing Profile';

  @override
  String get editBillingProfile => 'Edit Billing Profile';

  @override
  String get defaultBillingProfileName => 'Default Billing';

  @override
  String get billingProfileSavedMsg => 'Billing profile saved.';

  @override
  String get deleteBillingProfileConfirm => 'Delete this billing profile?';

  @override
  String get allProfilesFilter => 'All Profiles';

  @override
  String get receiptProfileLabel => 'Receipt Profile';

  @override
  String get profileNameExistsError =>
      'A profile with this name already exists.';

  @override
  String get profileNameRequiredError => 'Please enter a profile name.';

  @override
  String get addCategory => 'Add Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryNameEn => 'Category Name (English)';

  @override
  String get categoryNameNe => 'Category Name (Nepali)';

  @override
  String get categorySavedMsg => 'Category saved.';

  @override
  String get categoryExistsMsg => 'This category already exists.';

  @override
  String get enterCategoryName => 'Please enter a category name.';

  @override
  String get noCategory => 'No Category';

  @override
  String get enterProductNameEn => 'Please enter the product name in English.';

  @override
  String get enterRate => 'Please enter a selling rate.';

  @override
  String get selectUnitRequired => 'Please select a unit.';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get categoryDeletedMsg => 'Category deleted.';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Delete category \"$name\"?';
  }

  @override
  String deleteCategoryConfirmProducts(String name, int count) {
    return 'Delete category \"$name\"? $count product(s) will be unassigned.';
  }

  @override
  String get manageUnits => 'Manage Units';

  @override
  String get editUnit => 'Edit Unit';

  @override
  String get deleteUnit => 'Delete Unit';

  @override
  String get unitDeletedMsg => 'Unit deleted.';

  @override
  String deleteUnitConfirm(String name) {
    return 'Delete unit \"$name\"?';
  }

  @override
  String cannotDeleteUnitInUse(String name, int count) {
    return 'Cannot delete unit \"$name\": used by $count product(s).';
  }

  @override
  String get standardUnit => 'Standard';

  @override
  String get customUnitBadge => 'Custom';

  @override
  String productCountLabel(int count) {
    return '$count product(s)';
  }
}

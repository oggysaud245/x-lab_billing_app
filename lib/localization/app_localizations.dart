import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'XLab Billing'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully.'**
  String get savedSuccessfully;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get deleteSuccess;

  /// No description provided for @learnMoreHint.
  ///
  /// In en, this message translates to:
  /// **'Hide keyboard to continue'**
  String get learnMoreHint;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Billing & Receipts'**
  String get splashTagline;

  /// No description provided for @splashPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing app…'**
  String get splashPreparing;

  /// No description provided for @splashDatabase.
  ///
  /// In en, this message translates to:
  /// **'Opening database…'**
  String get splashDatabase;

  /// No description provided for @splashSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading settings…'**
  String get splashSettings;

  /// No description provided for @splashPrinter.
  ///
  /// In en, this message translates to:
  /// **'Connecting printer…'**
  String get splashPrinter;

  /// No description provided for @splashProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products…'**
  String get splashProducts;

  /// No description provided for @splashOrgWarn.
  ///
  /// In en, this message translates to:
  /// **'Organization details are not set yet. You can set them in Settings.'**
  String get splashOrgWarn;

  /// No description provided for @splashOfflinePrinter.
  ///
  /// In en, this message translates to:
  /// **'Printer not connected. You can save bills now and print later.'**
  String get splashOfflinePrinter;

  /// No description provided for @navBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get navBilling;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get navInvoices;

  /// No description provided for @navPrinter.
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get navPrinter;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @printerStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get printerStatusConnected;

  /// No description provided for @printerStatusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get printerStatusDisconnected;

  /// No description provided for @printerStatusSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get printerStatusSearching;

  /// No description provided for @printerStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get printerStatusConnecting;

  /// No description provided for @printerStatusBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get printerStatusBusy;

  /// No description provided for @printerStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get printerStatusError;

  /// No description provided for @printerStatusNotSelected.
  ///
  /// In en, this message translates to:
  /// **'No printer selected'**
  String get printerStatusNotSelected;

  /// No description provided for @printerStatusUsbPermission.
  ///
  /// In en, this message translates to:
  /// **'USB permission required'**
  String get printerStatusUsbPermission;

  /// No description provided for @printerStatusSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get printerStatusSending;

  /// No description provided for @printerConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Printer connected: {name}'**
  String printerConnectedTo(String name);

  /// No description provided for @printerDisconnectedMsg.
  ///
  /// In en, this message translates to:
  /// **'Printer disconnected.'**
  String get printerDisconnectedMsg;

  /// No description provided for @printerNotSelectedMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a printer in the Printer tab.'**
  String get printerNotSelectedMsg;

  /// No description provided for @printerConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Printer connection failed.'**
  String get printerConnectionFailed;

  /// No description provided for @printerNetworkTimeout.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the printer (connection timed out).'**
  String get printerNetworkTimeout;

  /// No description provided for @printerBusyMsg.
  ///
  /// In en, this message translates to:
  /// **'Printer is busy. Please wait and try again.'**
  String get printerBusyMsg;

  /// No description provided for @printerErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Printer error: {error}'**
  String printerErrorMsg(String error);

  /// No description provided for @printerUsbPermissionMsg.
  ///
  /// In en, this message translates to:
  /// **'USB permission denied. Grant permission and try again.'**
  String get printerUsbPermissionMsg;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search Products'**
  String get searchProducts;

  /// No description provided for @searchProductsHintNameSku.
  ///
  /// In en, this message translates to:
  /// **'Search by English, Nepali names or SKU'**
  String get searchProductsHintNameSku;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @emptyProducts.
  ///
  /// In en, this message translates to:
  /// **'No products yet. Add a product to start billing.'**
  String get emptyProducts;

  /// No description provided for @emptyProductsSearch.
  ///
  /// In en, this message translates to:
  /// **'No products match your search.'**
  String get emptyProductsSearch;

  /// No description provided for @currentBill.
  ///
  /// In en, this message translates to:
  /// **'Current Bill'**
  String get currentBill;

  /// No description provided for @emptyCart.
  ///
  /// In en, this message translates to:
  /// **'No items in the bill. Tap a product to add it.'**
  String get emptyCart;

  /// No description provided for @clearBill.
  ///
  /// In en, this message translates to:
  /// **'Clear Bill'**
  String get clearBill;

  /// No description provided for @clearBillConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all items of the current bill?'**
  String get clearBillConfirm;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @itemAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get itemAmount;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get removeItem;

  /// No description provided for @deselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get deselect;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @otherCharges.
  ///
  /// In en, this message translates to:
  /// **'Other Charges'**
  String get otherCharges;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @addDiscount.
  ///
  /// In en, this message translates to:
  /// **'Add Discount'**
  String get addDiscount;

  /// No description provided for @editDiscount.
  ///
  /// In en, this message translates to:
  /// **'Edit Discount'**
  String get editDiscount;

  /// No description provided for @removeDiscount.
  ///
  /// In en, this message translates to:
  /// **'Remove Discount'**
  String get removeDiscount;

  /// No description provided for @discountTypePercent.
  ///
  /// In en, this message translates to:
  /// **'Percent (%)'**
  String get discountTypePercent;

  /// No description provided for @discountTypeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed Amount'**
  String get discountTypeFixed;

  /// No description provided for @discountPercentHint.
  ///
  /// In en, this message translates to:
  /// **'Discount % (e.g. 5 or 5.50)'**
  String get discountPercentHint;

  /// No description provided for @discountAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Discount amount'**
  String get discountAmountHint;

  /// No description provided for @taxPercentHint.
  ///
  /// In en, this message translates to:
  /// **'Tax % (e.g. 13)'**
  String get taxPercentHint;

  /// No description provided for @otherChargesHint.
  ///
  /// In en, this message translates to:
  /// **'Other charges amount'**
  String get otherChargesHint;

  /// No description provided for @noDiscount.
  ///
  /// In en, this message translates to:
  /// **'No discount'**
  String get noDiscount;

  /// No description provided for @itemAddedMsg.
  ///
  /// In en, this message translates to:
  /// **'Added to bill'**
  String get itemAddedMsg;

  /// No description provided for @itemRemovedMsg.
  ///
  /// In en, this message translates to:
  /// **'Item removed'**
  String get itemRemovedMsg;

  /// No description provided for @billClearedMsg.
  ///
  /// In en, this message translates to:
  /// **'Bill cleared'**
  String get billClearedMsg;

  /// No description provided for @billEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Bill is empty. Add at least one item.'**
  String get billEmptyError;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter a quantity.'**
  String get enterQuantity;

  /// No description provided for @enterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity.'**
  String get enterValidQuantity;

  /// No description provided for @enterValidRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid rate.'**
  String get enterValidRate;

  /// No description provided for @discountExceedsSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Discount cannot exceed the subtotal.'**
  String get discountExceedsSubtotal;

  /// No description provided for @paidExceedsTotal.
  ///
  /// In en, this message translates to:
  /// **'Paid amount exceeds the grand total.'**
  String get paidExceedsTotal;

  /// No description provided for @customerInformation.
  ///
  /// In en, this message translates to:
  /// **'Customer (Optional)'**
  String get customerInformation;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get customerPhone;

  /// No description provided for @customerAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get customerAddress;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodQr.
  ///
  /// In en, this message translates to:
  /// **'QR Payment'**
  String get paymentMethodQr;

  /// No description provided for @paymentMethodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get paymentMethodBankTransfer;

  /// No description provided for @paymentMethodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get paymentMethodOther;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get amountPaid;

  /// No description provided for @balanceDue.
  ///
  /// In en, this message translates to:
  /// **'Balance Due'**
  String get balanceDue;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Internal or receipt notes'**
  String get notesHint;

  /// No description provided for @defaultCashPayment.
  ///
  /// In en, this message translates to:
  /// **'Default payment method'**
  String get defaultCashPayment;

  /// No description provided for @previewInvoice.
  ///
  /// In en, this message translates to:
  /// **'Preview Invoice'**
  String get previewInvoice;

  /// No description provided for @printInvoice.
  ///
  /// In en, this message translates to:
  /// **'Print Invoice'**
  String get printInvoice;

  /// No description provided for @finalizeAndSave.
  ///
  /// In en, this message translates to:
  /// **'Save Invoice'**
  String get finalizeAndSave;

  /// No description provided for @finalizeAndPrint.
  ///
  /// In en, this message translates to:
  /// **'Save & Print'**
  String get finalizeAndPrint;

  /// No description provided for @invoiceSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Invoice saved.'**
  String get invoiceSavedMsg;

  /// No description provided for @printUnavailableSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Printer not connected. Invoice saved — reprint it later from Invoices.'**
  String get printUnavailableSavedMsg;

  /// No description provided for @printSendingMsg.
  ///
  /// In en, this message translates to:
  /// **'Sending to printer…'**
  String get printSendingMsg;

  /// No description provided for @printSentMsg.
  ///
  /// In en, this message translates to:
  /// **'Sent to printer. Please check the paper.'**
  String get printSentMsg;

  /// No description provided for @printAlreadyFinalizedMsg.
  ///
  /// In en, this message translates to:
  /// **'Invoice already finalized.'**
  String get printAlreadyFinalizedMsg;

  /// No description provided for @reprintInvoice.
  ///
  /// In en, this message translates to:
  /// **'Reprint'**
  String get reprintInvoice;

  /// No description provided for @startNewBill.
  ///
  /// In en, this message translates to:
  /// **'Start New Bill'**
  String get startNewBill;

  /// No description provided for @viewInvoice.
  ///
  /// In en, this message translates to:
  /// **'View Invoice'**
  String get viewInvoice;

  /// No description provided for @invoiceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Invoice Language'**
  String get invoiceLanguage;

  /// No description provided for @invoiceLanguageFollowApp.
  ///
  /// In en, this message translates to:
  /// **'Follow App Language'**
  String get invoiceLanguageFollowApp;

  /// No description provided for @invoiceLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get invoiceLanguageEnglish;

  /// No description provided for @invoiceLanguageNepali.
  ///
  /// In en, this message translates to:
  /// **'नेपाली'**
  String get invoiceLanguageNepali;

  /// No description provided for @previewUpdateHint.
  ///
  /// In en, this message translates to:
  /// **'Preview updates when language changes.'**
  String get previewUpdateHint;

  /// No description provided for @previewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not render the receipt preview.'**
  String get previewLoadFailed;

  /// No description provided for @previewLanguageDefault.
  ///
  /// In en, this message translates to:
  /// **'{lang} (default)'**
  String previewLanguageDefault(String lang);

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get invoiceNumber;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete product \"{name}\"? This cannot be undone.'**
  String deleteProductConfirm(String name);

  /// No description provided for @productNameEn.
  ///
  /// In en, this message translates to:
  /// **'Product Name (English)'**
  String get productNameEn;

  /// No description provided for @productNameNe.
  ///
  /// In en, this message translates to:
  /// **'Product Name (नेपाली)'**
  String get productNameNe;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU / Code'**
  String get sku;

  /// No description provided for @descriptionEn.
  ///
  /// In en, this message translates to:
  /// **'Description (English)'**
  String get descriptionEn;

  /// No description provided for @descriptionNe.
  ///
  /// In en, this message translates to:
  /// **'Description (नेपाली)'**
  String get descriptionNe;

  /// No description provided for @productRate.
  ///
  /// In en, this message translates to:
  /// **'Selling Rate'**
  String get productRate;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Food, Drink, Goods'**
  String get categoryHint;

  /// No description provided for @unitShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitShortLabel;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @showInactiveProducts.
  ///
  /// In en, this message translates to:
  /// **'Show inactive products'**
  String get showInactiveProducts;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by Name'**
  String get sortByName;

  /// No description provided for @sortByRate.
  ///
  /// In en, this message translates to:
  /// **'Sort by Rate'**
  String get sortByRate;

  /// No description provided for @sortByNewest.
  ///
  /// In en, this message translates to:
  /// **'Sort by Newest'**
  String get sortByNewest;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortByNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A to Z)'**
  String get sortByNameAsc;

  /// No description provided for @sortByNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name (Z to A)'**
  String get sortByNameDesc;

  /// No description provided for @sortByDateNewest.
  ///
  /// In en, this message translates to:
  /// **'Date (Newest first)'**
  String get sortByDateNewest;

  /// No description provided for @sortByDateOldest.
  ///
  /// In en, this message translates to:
  /// **'Date (Oldest first)'**
  String get sortByDateOldest;

  /// No description provided for @sortByRateAsc.
  ///
  /// In en, this message translates to:
  /// **'Price (Low to High)'**
  String get sortByRateAsc;

  /// No description provided for @sortByRateDesc.
  ///
  /// In en, this message translates to:
  /// **'Price (High to Low)'**
  String get sortByRateDesc;

  /// No description provided for @selectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select Unit'**
  String get selectUnit;

  /// No description provided for @customUnit.
  ///
  /// In en, this message translates to:
  /// **'Custom Unit'**
  String get customUnit;

  /// No description provided for @addCustomUnit.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Unit'**
  String get addCustomUnit;

  /// No description provided for @customUnitHint.
  ///
  /// In en, this message translates to:
  /// **'Examples: Bottle / बोतल, Bundle / बन्डल, Cup / कप, Trip / ट्रिप'**
  String get customUnitHint;

  /// No description provided for @unitNameEn.
  ///
  /// In en, this message translates to:
  /// **'Unit Name (English)'**
  String get unitNameEn;

  /// No description provided for @unitNameNe.
  ///
  /// In en, this message translates to:
  /// **'Unit Name (नेपाली)'**
  String get unitNameNe;

  /// No description provided for @unitAbbreviationEn.
  ///
  /// In en, this message translates to:
  /// **'Abbreviation (English)'**
  String get unitAbbreviationEn;

  /// No description provided for @unitAbbreviationNe.
  ///
  /// In en, this message translates to:
  /// **'Abbreviation (नेपाली)'**
  String get unitAbbreviationNe;

  /// No description provided for @enterProductNames.
  ///
  /// In en, this message translates to:
  /// **'Enter the name in English or नेपाली.'**
  String get enterProductNames;

  /// No description provided for @enterUnitName.
  ///
  /// In en, this message translates to:
  /// **'Enter the unit name in English or नेपाली.'**
  String get enterUnitName;

  /// No description provided for @productSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Product saved.'**
  String get productSavedMsg;

  /// No description provided for @productDeletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Product deleted.'**
  String get productDeletedMsg;

  /// No description provided for @unitExistsMsg.
  ///
  /// In en, this message translates to:
  /// **'This unit already exists.'**
  String get unitExistsMsg;

  /// No description provided for @inactiveMark.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveMark;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @searchInvoices.
  ///
  /// In en, this message translates to:
  /// **'Search invoice number or customer'**
  String get searchInvoices;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get filterLast7Days;

  /// No description provided for @filterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get filterThisMonth;

  /// No description provided for @filter3Months.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get filter3Months;

  /// No description provided for @filter6Months.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get filter6Months;

  /// No description provided for @filterThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get filterThisYear;

  /// No description provided for @filterAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get filterAllTime;

  /// No description provided for @filterCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom (From – To)'**
  String get filterCustomRange;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get toDate;

  /// No description provided for @pickDateRangeCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar Range'**
  String get pickDateRangeCalendar;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @emptyInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet. Create your first bill from Billing.'**
  String get emptyInvoices;

  /// No description provided for @emptyInvoicesSearch.
  ///
  /// In en, this message translates to:
  /// **'No invoices match the search or filters.'**
  String get emptyInvoicesSearch;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemCount(String count);

  /// No description provided for @statusFinalized.
  ///
  /// In en, this message translates to:
  /// **'Finalized'**
  String get statusFinalized;

  /// No description provided for @statusVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get statusVoided;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcessing;

  /// No description provided for @statusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Paid / Success'**
  String get statusSuccess;

  /// No description provided for @statusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get statusCanceled;

  /// No description provided for @transactionConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Transaction Confirmation'**
  String get transactionConfirmation;

  /// No description provided for @transactionStatus.
  ///
  /// In en, this message translates to:
  /// **'Transaction Status'**
  String get transactionStatus;

  /// No description provided for @waitingForPaymentMsg.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment. Mark as Paid to save & print.'**
  String get waitingForPaymentMsg;

  /// No description provided for @paymentConfirmedMsg.
  ///
  /// In en, this message translates to:
  /// **'Payment received. Ready to save & print.'**
  String get paymentConfirmedMsg;

  /// No description provided for @transactionCanceledMsg.
  ///
  /// In en, this message translates to:
  /// **'Transaction canceled.'**
  String get transactionCanceledMsg;

  /// No description provided for @saveAsProcessing.
  ///
  /// In en, this message translates to:
  /// **'Save as Processing'**
  String get saveAsProcessing;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @invoiceProcessingMsg.
  ///
  /// In en, this message translates to:
  /// **'Transaction is currently processing (waiting for payment).'**
  String get invoiceProcessingMsg;

  /// No description provided for @voidInvoice.
  ///
  /// In en, this message translates to:
  /// **'Void Invoice'**
  String get voidInvoice;

  /// No description provided for @voidInvoiceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Void invoice {number}? Voided invoices are kept in history but cannot be reprinted.'**
  String voidInvoiceConfirm(String number);

  /// No description provided for @voidReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for voiding'**
  String get voidReasonLabel;

  /// No description provided for @voidReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Wrong entry'**
  String get voidReasonHint;

  /// No description provided for @invoiceVoidedMsg.
  ///
  /// In en, this message translates to:
  /// **'Invoice voided.'**
  String get invoiceVoidedMsg;

  /// No description provided for @voidNotAllowedReprint.
  ///
  /// In en, this message translates to:
  /// **'A voided invoice cannot be reprinted.'**
  String get voidNotAllowedReprint;

  /// No description provided for @printAttempts.
  ///
  /// In en, this message translates to:
  /// **'Print Attempts'**
  String get printAttempts;

  /// No description provided for @printAttemptFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get printAttemptFailed;

  /// No description provided for @printAttemptSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get printAttemptSent;

  /// No description provided for @notPrintedYet.
  ///
  /// In en, this message translates to:
  /// **'Not printed yet'**
  String get notPrintedYet;

  /// No description provided for @printedTimes.
  ///
  /// In en, this message translates to:
  /// **'Printed {count} time(s)'**
  String printedTimes(String count);

  /// No description provided for @organizationSnapshotNote.
  ///
  /// In en, this message translates to:
  /// **'This invoice keeps the organization, product and price information saved at billing time.'**
  String get organizationSnapshotNote;

  /// No description provided for @totalsSection.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get totalsSection;

  /// No description provided for @paymentSection.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentSection;

  /// No description provided for @printer.
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get printer;

  /// No description provided for @printerSettings.
  ///
  /// In en, this message translates to:
  /// **'Printer Settings'**
  String get printerSettings;

  /// No description provided for @connectionType.
  ///
  /// In en, this message translates to:
  /// **'Connection Type'**
  String get connectionType;

  /// No description provided for @connectionLan.
  ///
  /// In en, this message translates to:
  /// **'LAN / Wi-Fi'**
  String get connectionLan;

  /// No description provided for @connectionUsb.
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get connectionUsb;

  /// No description provided for @discoverPrinters.
  ///
  /// In en, this message translates to:
  /// **'Find Printers'**
  String get discoverPrinters;

  /// No description provided for @stopSearch.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopSearch;

  /// No description provided for @discoveringNetwork.
  ///
  /// In en, this message translates to:
  /// **'Scanning network for printers…'**
  String get discoveringNetwork;

  /// No description provided for @wifiRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Connect the phone and the printer to the same Wi-Fi network, then search again.'**
  String get wifiRequiredHint;

  /// No description provided for @manualPrinter.
  ///
  /// In en, this message translates to:
  /// **'Add Printer Manually'**
  String get manualPrinter;

  /// No description provided for @printerName.
  ///
  /// In en, this message translates to:
  /// **'Printer Name'**
  String get printerName;

  /// No description provided for @printerIp.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get printerIp;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @testPrint.
  ///
  /// In en, this message translates to:
  /// **'Test Print'**
  String get testPrint;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @forgetPrinter.
  ///
  /// In en, this message translates to:
  /// **'Forget Printer'**
  String get forgetPrinter;

  /// No description provided for @selectPrinter.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectPrinter;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @usbDevices.
  ///
  /// In en, this message translates to:
  /// **'USB Devices'**
  String get usbDevices;

  /// No description provided for @usbVendorId.
  ///
  /// In en, this message translates to:
  /// **'Vendor ID'**
  String get usbVendorId;

  /// No description provided for @usbProductId.
  ///
  /// In en, this message translates to:
  /// **'Product ID'**
  String get usbProductId;

  /// No description provided for @usbNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No USB printers detected. Connect the printer with a USB cable.'**
  String get usbNoDevices;

  /// No description provided for @usbPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get usbPermission;

  /// No description provided for @requestPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get requestPermission;

  /// No description provided for @usbDeviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get usbDeviceConnected;

  /// No description provided for @usbDeviceAttachHint.
  ///
  /// In en, this message translates to:
  /// **'Plug the printer via USB and allow access when the phone asks.'**
  String get usbDeviceAttachHint;

  /// No description provided for @paperWidthLabel.
  ///
  /// In en, this message translates to:
  /// **'Paper Width'**
  String get paperWidthLabel;

  /// No description provided for @renderingModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Print Method'**
  String get renderingModeLabel;

  /// No description provided for @renderingModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto (Recommended)'**
  String get renderingModeAuto;

  /// No description provided for @renderingModeText.
  ///
  /// In en, this message translates to:
  /// **'Text (fast, English only)'**
  String get renderingModeText;

  /// No description provided for @renderingModeImage.
  ///
  /// In en, this message translates to:
  /// **'Image (for नेपाली)'**
  String get renderingModeImage;

  /// No description provided for @renderingModeNote.
  ///
  /// In en, this message translates to:
  /// **'नेपाली Unicode needs image printing unless the printer supports Devanagari fonts.'**
  String get renderingModeNote;

  /// No description provided for @enableCutLabel.
  ///
  /// In en, this message translates to:
  /// **'Cut paper after print'**
  String get enableCutLabel;

  /// No description provided for @enableBeepLabel.
  ///
  /// In en, this message translates to:
  /// **'Beep after print (experimental)'**
  String get enableBeepLabel;

  /// No description provided for @enableDrawerLabel.
  ///
  /// In en, this message translates to:
  /// **'Open cash drawer (experimental)'**
  String get enableDrawerLabel;

  /// No description provided for @printDensityLabel.
  ///
  /// In en, this message translates to:
  /// **'Print Darkness'**
  String get printDensityLabel;

  /// No description provided for @enteredIpError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IP address.'**
  String get enteredIpError;

  /// No description provided for @portError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid port (1–65535).'**
  String get portError;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get nameRequired;

  /// No description provided for @printerSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Printer saved.'**
  String get printerSavedMsg;

  /// No description provided for @printerForgottenMsg.
  ///
  /// In en, this message translates to:
  /// **'Printer removed.'**
  String get printerForgottenMsg;

  /// No description provided for @printerTestOk.
  ///
  /// In en, this message translates to:
  /// **'Connection successful.'**
  String get printerTestOk;

  /// No description provided for @printerTestOkLabel.
  ///
  /// In en, this message translates to:
  /// **'Test receipt sent. Check the printer.'**
  String get printerTestOkLabel;

  /// No description provided for @connectionTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection test failed.'**
  String get connectionTestFailed;

  /// No description provided for @selectPrinterFirst.
  ///
  /// In en, this message translates to:
  /// **'Select or connect a printer first.'**
  String get selectPrinterFirst;

  /// No description provided for @printerScanNote.
  ///
  /// In en, this message translates to:
  /// **'Printers on port 9100 are found by scanning the local network.'**
  String get printerScanNote;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device info'**
  String get deviceInfo;

  /// No description provided for @paperWidth58.
  ///
  /// In en, this message translates to:
  /// **'58 mm'**
  String get paperWidth58;

  /// No description provided for @paperWidth80.
  ///
  /// In en, this message translates to:
  /// **'80 mm'**
  String get paperWidth80;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @generalSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSection;

  /// No description provided for @organizationSection.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organizationSection;

  /// No description provided for @receiptSection.
  ///
  /// In en, this message translates to:
  /// **'Receipt Design'**
  String get receiptSection;

  /// No description provided for @billingSection.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billingSection;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @themeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeModeLabel;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @currencySymbolLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency Symbol'**
  String get currencySymbolLabel;

  /// No description provided for @currencyNpr.
  ///
  /// In en, this message translates to:
  /// **'NPR'**
  String get currencyNpr;

  /// No description provided for @currencyRu.
  ///
  /// In en, this message translates to:
  /// **'रु.'**
  String get currencyRu;

  /// No description provided for @invoiceLanguageSetting.
  ///
  /// In en, this message translates to:
  /// **'Default Invoice Language'**
  String get invoiceLanguageSetting;

  /// No description provided for @numeralFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Number Style'**
  String get numeralFormatLabel;

  /// No description provided for @westernNumerals.
  ///
  /// In en, this message translates to:
  /// **'Latin digits (1,250.00)'**
  String get westernNumerals;

  /// No description provided for @devanagariNumerals.
  ///
  /// In en, this message translates to:
  /// **'Devanagari digits (१,२५०.००)'**
  String get devanagariNumerals;

  /// No description provided for @dateFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Calendar System'**
  String get dateFormatLabel;

  /// No description provided for @gregorianCalendar.
  ///
  /// In en, this message translates to:
  /// **'Gregorian (AD)'**
  String get gregorianCalendar;

  /// No description provided for @bikramSambatCalendar.
  ///
  /// In en, this message translates to:
  /// **'Bikram Sambat (BS)'**
  String get bikramSambatCalendar;

  /// No description provided for @dateFormatStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Date Style'**
  String get dateFormatStyleLabel;

  /// No description provided for @dateStyleNumeric.
  ///
  /// In en, this message translates to:
  /// **'Numeric (2082-07-12)'**
  String get dateStyleNumeric;

  /// No description provided for @dateStyleLongMonth.
  ///
  /// In en, this message translates to:
  /// **'With month name (12 Kartik 2082)'**
  String get dateStyleLongMonth;

  /// No description provided for @showTimeOnReceipt.
  ///
  /// In en, this message translates to:
  /// **'Show time on receipts'**
  String get showTimeOnReceipt;

  /// No description provided for @bottomMarginOnReceipt.
  ///
  /// In en, this message translates to:
  /// **'Match top margin at bottom of receipt'**
  String get bottomMarginOnReceipt;

  /// No description provided for @quantityPrecisionLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity Decimals'**
  String get quantityPrecisionLabel;

  /// No description provided for @selectedFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get selectedFormatHint;

  /// No description provided for @orgInformation.
  ///
  /// In en, this message translates to:
  /// **'Organization Information'**
  String get orgInformation;

  /// No description provided for @orgNameEn.
  ///
  /// In en, this message translates to:
  /// **'Organization Name (English)'**
  String get orgNameEn;

  /// No description provided for @orgNameNe.
  ///
  /// In en, this message translates to:
  /// **'Organization Name (नेपाली)'**
  String get orgNameNe;

  /// No description provided for @orgAddressEn.
  ///
  /// In en, this message translates to:
  /// **'Address (English)'**
  String get orgAddressEn;

  /// No description provided for @orgAddressNe.
  ///
  /// In en, this message translates to:
  /// **'Address (नेपाली)'**
  String get orgAddressNe;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneLabel;

  /// No description provided for @altPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Alternative Phone (optional)'**
  String get altPhoneLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailLabel;

  /// No description provided for @panNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'PAN Number (optional)'**
  String get panNumberLabel;

  /// No description provided for @vatNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT Number (optional)'**
  String get vatNumberLabel;

  /// No description provided for @websiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website (optional)'**
  String get websiteLabel;

  /// No description provided for @registrationNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration Number (optional)'**
  String get registrationNumberLabel;

  /// No description provided for @logoLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization Logo (optional)'**
  String get logoLabel;

  /// No description provided for @pickLogo.
  ///
  /// In en, this message translates to:
  /// **'Choose Logo'**
  String get pickLogo;

  /// No description provided for @removeLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove Logo'**
  String get removeLogo;

  /// No description provided for @orgCustomInfoEn.
  ///
  /// In en, this message translates to:
  /// **'Extra Information (English)'**
  String get orgCustomInfoEn;

  /// No description provided for @orgCustomInfoNe.
  ///
  /// In en, this message translates to:
  /// **'Extra Information (नेपाली)'**
  String get orgCustomInfoNe;

  /// No description provided for @orgCustomInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Shown on receipts if enabled'**
  String get orgCustomInfoHint;

  /// No description provided for @enterOrgName.
  ///
  /// In en, this message translates to:
  /// **'Enter the organization name in English or नेपाली.'**
  String get enterOrgName;

  /// No description provided for @phoneOrContactRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number or leave it empty.'**
  String get phoneOrContactRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @orgSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Organization information saved.'**
  String get orgSavedMsg;

  /// No description provided for @orgSetupPrompt.
  ///
  /// In en, this message translates to:
  /// **'Set up your organization details so bills show the correct header.'**
  String get orgSetupPrompt;

  /// No description provided for @setupOrganization.
  ///
  /// In en, this message translates to:
  /// **'Set Organization'**
  String get setupOrganization;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionTitle;

  /// No description provided for @receiptDesign.
  ///
  /// In en, this message translates to:
  /// **'Receipt Design'**
  String get receiptDesign;

  /// No description provided for @visibleFields.
  ///
  /// In en, this message translates to:
  /// **'Show on Receipt'**
  String get visibleFields;

  /// No description provided for @showLogo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get showLogo;

  /// No description provided for @showAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get showAddress;

  /// No description provided for @showPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get showPhone;

  /// No description provided for @showEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get showEmail;

  /// No description provided for @showWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get showWebsite;

  /// No description provided for @showPanVat.
  ///
  /// In en, this message translates to:
  /// **'PAN / VAT'**
  String get showPanVat;

  /// No description provided for @showCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get showCustomer;

  /// No description provided for @showPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get showPayment;

  /// No description provided for @headerMessages.
  ///
  /// In en, this message translates to:
  /// **'Header Messages'**
  String get headerMessages;

  /// No description provided for @footerMessages.
  ///
  /// In en, this message translates to:
  /// **'Footer Messages'**
  String get footerMessages;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome Message'**
  String get welcomeMessage;

  /// No description provided for @thankYouMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank-You Message'**
  String get thankYouMessage;

  /// No description provided for @returnPolicy.
  ///
  /// In en, this message translates to:
  /// **'Return / Exchange Policy'**
  String get returnPolicy;

  /// No description provided for @paymentTerms.
  ///
  /// In en, this message translates to:
  /// **'Payment Terms'**
  String get paymentTerms;

  /// No description provided for @promoMessage.
  ///
  /// In en, this message translates to:
  /// **'Promotional Message'**
  String get promoMessage;

  /// No description provided for @additionalMessage.
  ///
  /// In en, this message translates to:
  /// **'Additional Message'**
  String get additionalMessage;

  /// No description provided for @customMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the default text'**
  String get customMessageHint;

  /// No description provided for @headerAlignmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Header Alignment'**
  String get headerAlignmentLabel;

  /// No description provided for @alignLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get alignLeft;

  /// No description provided for @alignCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get alignCenter;

  /// No description provided for @textSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt Text Size'**
  String get textSizeLabel;

  /// No description provided for @textSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get textSizeSmall;

  /// No description provided for @textSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get textSizeMedium;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @receiptSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Receipt design saved.'**
  String get receiptSavedMsg;

  /// No description provided for @receiptPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Live Preview'**
  String get receiptPreviewLabel;

  /// No description provided for @templateLanguageTab.
  ///
  /// In en, this message translates to:
  /// **'Message Language'**
  String get templateLanguageTab;

  /// No description provided for @invoicePrefixLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Prefix'**
  String get invoicePrefixLabel;

  /// No description provided for @invoicePrefixHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. INV-'**
  String get invoicePrefixHint;

  /// No description provided for @startingNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting Number'**
  String get startingNumberLabel;

  /// No description provided for @numberOfDigitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Digits'**
  String get numberOfDigitsLabel;

  /// No description provided for @fiscalYearPrefix.
  ///
  /// In en, this message translates to:
  /// **'Add fiscal year prefix (starts in Shrawan)'**
  String get fiscalYearPrefix;

  /// No description provided for @invoiceNumberPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview: {number}'**
  String invoiceNumberPreview(String number);

  /// No description provided for @defaultDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'Default Discount (%)'**
  String get defaultDiscountPercent;

  /// No description provided for @taxSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax & Charges'**
  String get taxSettingsTitle;

  /// No description provided for @enableTax.
  ///
  /// In en, this message translates to:
  /// **'Enable Tax'**
  String get enableTax;

  /// No description provided for @taxPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate (%)'**
  String get taxPercentLabel;

  /// No description provided for @enableDiscount.
  ///
  /// In en, this message translates to:
  /// **'Enable Discount'**
  String get enableDiscount;

  /// No description provided for @enableOtherCharges.
  ///
  /// In en, this message translates to:
  /// **'Enable Other Charges'**
  String get enableOtherCharges;

  /// No description provided for @otherChargesLabel.
  ///
  /// In en, this message translates to:
  /// **'Charge Name'**
  String get otherChargesLabel;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Export'**
  String get backupTitle;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Database Backup'**
  String get createBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @osBackupsHint.
  ///
  /// In en, this message translates to:
  /// **'Backups are saved in the app folder on your phone storage.'**
  String get osBackupsHint;

  /// No description provided for @noBackupsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No backups available.'**
  String get noBackupsAvailable;

  /// No description provided for @backupCreatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Backup created: {path}'**
  String backupCreatedMsg(String path);

  /// No description provided for @restoreBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restoring a backup replaces all current data. Continue?'**
  String get restoreBackupConfirm;

  /// No description provided for @restoredMsg.
  ///
  /// In en, this message translates to:
  /// **'Backup restored. Please restart the app.'**
  String get restoredMsg;

  /// No description provided for @exportInvoicesCsv.
  ///
  /// In en, this message translates to:
  /// **'Export Invoices CSV'**
  String get exportInvoicesCsv;

  /// No description provided for @exportDoneMsg.
  ///
  /// In en, this message translates to:
  /// **'Export finished: {path}'**
  String exportDoneMsg(String path);

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed. Please try again.'**
  String get restoreFailed;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionLabel;

  /// No description provided for @aboutAppText.
  ///
  /// In en, this message translates to:
  /// **'XLab Billing — offline billing and receipt printing for XLab XTKP607UL thermal printers.'**
  String get aboutAppText;

  /// No description provided for @panCode.
  ///
  /// In en, this message translates to:
  /// **'PAN:'**
  String get panCode;

  /// No description provided for @vatCode.
  ///
  /// In en, this message translates to:
  /// **'VAT:'**
  String get vatCode;

  /// No description provided for @phoneCode.
  ///
  /// In en, this message translates to:
  /// **'Tel:'**
  String get phoneCode;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// No description provided for @dueLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get dueLabel;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank You'**
  String get thankYou;

  /// No description provided for @invoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'INVOICE'**
  String get invoiceTitle;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @qtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qtyLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @rateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rateLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @snLabel.
  ///
  /// In en, this message translates to:
  /// **'S.N.'**
  String get snLabel;

  /// No description provided for @particularsLabel.
  ///
  /// In en, this message translates to:
  /// **'Particulars'**
  String get particularsLabel;

  /// No description provided for @changeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeLabel;

  /// No description provided for @receiptProfilesSection.
  ///
  /// In en, this message translates to:
  /// **'Receipt Profiles'**
  String get receiptProfilesSection;

  /// No description provided for @addReceiptProfile.
  ///
  /// In en, this message translates to:
  /// **'New Receipt Profile'**
  String get addReceiptProfile;

  /// No description provided for @editReceiptProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Receipt Profile'**
  String get editReceiptProfile;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Name'**
  String get profileNameLabel;

  /// No description provided for @defaultProfileName.
  ///
  /// In en, this message translates to:
  /// **'Default Profile'**
  String get defaultProfileName;

  /// No description provided for @profileSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Receipt profile saved.'**
  String get profileSavedMsg;

  /// No description provided for @deleteProfileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this receipt profile?'**
  String get deleteProfileConfirm;

  /// No description provided for @billingProfilesSection.
  ///
  /// In en, this message translates to:
  /// **'Billing Profiles'**
  String get billingProfilesSection;

  /// No description provided for @addBillingProfile.
  ///
  /// In en, this message translates to:
  /// **'New Billing Profile'**
  String get addBillingProfile;

  /// No description provided for @editBillingProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Billing Profile'**
  String get editBillingProfile;

  /// No description provided for @defaultBillingProfileName.
  ///
  /// In en, this message translates to:
  /// **'Default Billing'**
  String get defaultBillingProfileName;

  /// No description provided for @billingProfileSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Billing profile saved.'**
  String get billingProfileSavedMsg;

  /// No description provided for @deleteBillingProfileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this billing profile?'**
  String get deleteBillingProfileConfirm;

  /// No description provided for @allProfilesFilter.
  ///
  /// In en, this message translates to:
  /// **'All Profiles'**
  String get allProfilesFilter;

  /// No description provided for @receiptProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt Profile'**
  String get receiptProfileLabel;

  /// No description provided for @profileNameExistsError.
  ///
  /// In en, this message translates to:
  /// **'A profile with this name already exists.'**
  String get profileNameExistsError;

  /// No description provided for @profileNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a profile name.'**
  String get profileNameRequiredError;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryNameEn.
  ///
  /// In en, this message translates to:
  /// **'Category Name (English)'**
  String get categoryNameEn;

  /// No description provided for @categoryNameNe.
  ///
  /// In en, this message translates to:
  /// **'Category Name (Nepali)'**
  String get categoryNameNe;

  /// No description provided for @categorySavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Category saved.'**
  String get categorySavedMsg;

  /// No description provided for @categoryExistsMsg.
  ///
  /// In en, this message translates to:
  /// **'This category already exists.'**
  String get categoryExistsMsg;

  /// No description provided for @enterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category name.'**
  String get enterCategoryName;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No Category'**
  String get noCategory;

  /// No description provided for @enterProductNameEn.
  ///
  /// In en, this message translates to:
  /// **'Please enter the product name in English.'**
  String get enterProductNameEn;

  /// No description provided for @enterRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a selling rate.'**
  String get enterRate;

  /// No description provided for @selectUnitRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a unit.'**
  String get selectUnitRequired;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @categoryDeletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Category deleted.'**
  String get categoryDeletedMsg;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete category \"{name}\"?'**
  String deleteCategoryConfirm(String name);

  /// No description provided for @deleteCategoryConfirmProducts.
  ///
  /// In en, this message translates to:
  /// **'Delete category \"{name}\"? {count} product(s) will be unassigned.'**
  String deleteCategoryConfirmProducts(String name, int count);

  /// No description provided for @manageUnits.
  ///
  /// In en, this message translates to:
  /// **'Manage Units'**
  String get manageUnits;

  /// No description provided for @editUnit.
  ///
  /// In en, this message translates to:
  /// **'Edit Unit'**
  String get editUnit;

  /// No description provided for @deleteUnit.
  ///
  /// In en, this message translates to:
  /// **'Delete Unit'**
  String get deleteUnit;

  /// No description provided for @unitDeletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Unit deleted.'**
  String get unitDeletedMsg;

  /// No description provided for @deleteUnitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete unit \"{name}\"?'**
  String deleteUnitConfirm(String name);

  /// No description provided for @cannotDeleteUnitInUse.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete unit \"{name}\": used by {count} product(s).'**
  String cannotDeleteUnitInUse(String name, int count);

  /// No description provided for @standardUnit.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standardUnit;

  /// No description provided for @customUnitBadge.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customUnitBadge;

  /// No description provided for @productCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} product(s)'**
  String productCountLabel(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

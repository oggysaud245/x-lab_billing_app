// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'XLab बिलिङ';

  @override
  String get loading => 'लोड हुँदै…';

  @override
  String get retry => 'फेरि प्रयास';

  @override
  String get ok => 'ठीक छ';

  @override
  String get save => 'सुरक्षित गर्नुहोस्';

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get add => 'थप्नुहोस्';

  @override
  String get edit => 'सम्पादन';

  @override
  String get delete => 'मेट्नुहोस्';

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get yes => 'हो';

  @override
  String get no => 'होइन';

  @override
  String get search => 'खोज्नुहोस्';

  @override
  String get confirm => 'पक्का गर्नुहोस्';

  @override
  String get optional => '(वैकल्पिक)';

  @override
  String get errorGeneric => 'केही समस्या आयो। फेरि प्रयास गर्नुहोस्।';

  @override
  String get savedSuccessfully => 'सुरक्षित भयो।';

  @override
  String get deleteSuccess => 'मेटियो।';

  @override
  String get learnMoreHint => 'जारी राख्न किबोर्ड बन्द गर्नुहोस्';

  @override
  String get splashTagline => 'बिलिङ र रसिद';

  @override
  String get splashPreparing => 'एप तयार हुँदै…';

  @override
  String get splashDatabase => 'डेटाबेस खुल्दै…';

  @override
  String get splashSettings => 'सेटिङ लोड हुँदै…';

  @override
  String get splashPrinter => 'प्रिन्टर जडान हुँदै…';

  @override
  String get splashProducts => 'सामान लोड हुँदै…';

  @override
  String get splashOrgWarn =>
      'संस्थाको विवरण अझै भरिएको छैन। सेटिङबाट भर्न सकिन्छ।';

  @override
  String get splashOfflinePrinter =>
      'प्रिन्टर जडान भएको छैन। बिल अहिले सुरक्षित गरेर पछि प्रिन्ट गर्न सकिन्छ।';

  @override
  String get navBilling => 'बिलिङ';

  @override
  String get navProducts => 'सामानहरू';

  @override
  String get navInvoices => 'बिलहरू';

  @override
  String get navPrinter => 'प्रिन्टर';

  @override
  String get navSettings => 'सेटिङ';

  @override
  String get printerStatusConnected => 'जडान भयो';

  @override
  String get printerStatusDisconnected => 'जडान विच्छेद भयो';

  @override
  String get printerStatusSearching => 'खोज्दै';

  @override
  String get printerStatusConnecting => 'जडान हुँदै';

  @override
  String get printerStatusBusy => 'व्यस्त';

  @override
  String get printerStatusError => 'त्रुटि';

  @override
  String get printerStatusNotSelected => 'प्रिन्टर छानिएको छैन';

  @override
  String get printerStatusUsbPermission => 'USB अनुमति चाहिन्छ';

  @override
  String get printerStatusSending => 'पठाइँदै…';

  @override
  String printerConnectedTo(String name) {
    return 'प्रिन्टर जडान भयो: $name';
  }

  @override
  String get printerDisconnectedMsg => 'प्रिन्टरको जडान विच्छेद भयो।';

  @override
  String get printerNotSelectedMsg =>
      'कृपया प्रिन्टर ट्याबमा जाएर प्रिन्टर छान्नुहोस्।';

  @override
  String get printerConnectionFailed => 'प्रिन्टरसँग जडान असफल भयो।';

  @override
  String get printerNetworkTimeout => 'प्रिन्टरमा पुग्न सकिएन (समय सकियो)।';

  @override
  String get printerBusyMsg =>
      'प्रिन्टर व्यस्त छ। केही बेर पछि फेरि प्रयास गर्नुहोस्।';

  @override
  String printerErrorMsg(String error) {
    return 'प्रिन्टर त्रुटि: $error';
  }

  @override
  String get printerUsbPermissionMsg =>
      'USB अनुमति दिइएन। अनुमति दिएर फेरि प्रयास गर्नुहोस्।';

  @override
  String get searchProducts => 'सामान खोज्नुहोस्';

  @override
  String get searchProductsHintNameSku =>
      'अंग्रेजी वा नेपाली नाम वा SKU ले खोज्नुहोस्';

  @override
  String get allCategories => 'सबै';

  @override
  String get uncategorized => 'श्रेणीविहीन';

  @override
  String get emptyProducts =>
      'कुनै सामान छैन। बिलिङ सुरु गर्न सामान थप्नुहोस्।';

  @override
  String get emptyProductsSearch => 'खोजीसँग मिल्ने सामान भेटिएन।';

  @override
  String get currentBill => 'हालको बिल';

  @override
  String get emptyCart => 'बिलमा कुनै वस्तु छैन। थप्न सामानमा ट्याप गर्नुहोस्।';

  @override
  String get clearBill => 'बिल खाली गर्नुहोस्';

  @override
  String get clearBillConfirm => 'हालको बिलका सबै वस्तु खाली गर्ने?';

  @override
  String get quantity => 'परिमाण';

  @override
  String get unitPrice => 'प्रति एकाइ मूल्य';

  @override
  String get itemAmount => 'रकम';

  @override
  String get removeItem => 'वस्तु हटाउनुहोस्';

  @override
  String get deselect => 'छनौट हटाउनुहोस्';

  @override
  String get subtotal => 'जम्मा रकम';

  @override
  String get discount => 'छुट';

  @override
  String get tax => 'कर';

  @override
  String get otherCharges => 'अन्य शुल्क';

  @override
  String get grandTotal => 'कुल रकम';

  @override
  String get addDiscount => 'छुट थप्नुहोस्';

  @override
  String get editDiscount => 'छुट सम्पादन गर्नुहोस्';

  @override
  String get removeDiscount => 'छुट हटाउनुहोस्';

  @override
  String get discountTypePercent => 'प्रतिशत (%)';

  @override
  String get discountTypeFixed => 'निश्चित रकम';

  @override
  String get discountPercentHint => 'छुट % (जस्तै 5 वा 5.50)';

  @override
  String get discountAmountHint => 'छुट रकम';

  @override
  String get taxPercentHint => 'कर % (जस्तै 13)';

  @override
  String get otherChargesHint => 'अन्य शुल्क रकम';

  @override
  String get noDiscount => 'छुट छैन';

  @override
  String get itemAddedMsg => 'बिलमा थपियो';

  @override
  String get itemRemovedMsg => 'वस्तु हटाइयो';

  @override
  String get billClearedMsg => 'बिल खाली गरियो';

  @override
  String get billEmptyError => 'बिल खाली छ। कम्तीमा एक वस्तु थप्नुहोस्।';

  @override
  String get enterQuantity => 'कृपया परिमाण प्रविष्ट गर्नुहोस्।';

  @override
  String get enterValidQuantity => 'परिमाण सही छैन।';

  @override
  String get enterValidRate => 'कृपया सही दर प्रविष्ट गर्नुहोस्।';

  @override
  String get discountExceedsSubtotal => 'छुट जम्मा रकमभन्दा बढी हुन सक्दैन।';

  @override
  String get paidExceedsTotal =>
      'भुक्तानी गरिएको रकम कुल रकमभन्दा बढी हुन सक्दैन।';

  @override
  String get customerInformation => 'ग्राहक (वैकल्पिक)';

  @override
  String get customer => 'ग्राहक';

  @override
  String get customerName => 'ग्राहकको नाम';

  @override
  String get customerPhone => 'फोन नम्बर';

  @override
  String get customerAddress => 'ठेगाना';

  @override
  String get paymentMethod => 'भुक्तानी विधि';

  @override
  String get paymentMethodCash => 'नगद';

  @override
  String get paymentMethodQr => 'QR भुक्तानी';

  @override
  String get paymentMethodBankTransfer => 'बैंक स्थानान्तरण';

  @override
  String get paymentMethodOther => 'अन्य';

  @override
  String get amountPaid => 'भुक्तानी गरिएको रकम';

  @override
  String get balanceDue => 'बाँकी रकम';

  @override
  String get notes => 'कैफियत';

  @override
  String get notesHint => 'आन्तरिक वा रसिद कैफियत';

  @override
  String get defaultCashPayment => 'पूर्वनिर्धारित भुक्तानी विधि';

  @override
  String get previewInvoice => 'बिल पूर्वावलोकन';

  @override
  String get printInvoice => 'बिल प्रिन्ट गर्नुहोस्';

  @override
  String get finalizeAndSave => 'बिल सुरक्षित गर्नुहोस्';

  @override
  String get finalizeAndPrint => 'सुरक्षित गरेर प्रिन्ट';

  @override
  String get invoiceSavedMsg => 'बिल सुरक्षित भयो।';

  @override
  String get printUnavailableSavedMsg =>
      'प्रिन्टर जडान भएको छैन। बिल सुरक्षित भयो — पछि बिलहरूबाट फेरि प्रिन्ट गर्न सकिन्छ।';

  @override
  String get printSendingMsg => 'प्रिन्टरमा पठाइँदै…';

  @override
  String get printSentMsg => 'प्रिन्टरमा पठाइयो। कृपया कागज जाँच्नुहोस्।';

  @override
  String get printAlreadyFinalizedMsg => 'बिल पहिले नै सुरक्षित भैसकेको छ।';

  @override
  String get reprintInvoice => 'फेरि प्रिन्ट';

  @override
  String get startNewBill => 'नयाँ बिल सुरु';

  @override
  String get viewInvoice => 'बिल हेर्नुहोस्';

  @override
  String get invoiceLanguage => 'बिलको भाषा';

  @override
  String get invoiceLanguageFollowApp => 'एपको भाषा अनुसार';

  @override
  String get invoiceLanguageEnglish => 'अंग्रेजी';

  @override
  String get invoiceLanguageNepali => 'नेपाली';

  @override
  String get previewUpdateHint => 'भाषा परिवर्तनसँगै पूर्वावलोकन अपडेट हुन्छ।';

  @override
  String get previewLoadFailed => 'रसिदको पूर्वावलोकन बनाउन सकिएन।';

  @override
  String previewLanguageDefault(String lang) {
    return '$lang (पूर्वनिर्धारित)';
  }

  @override
  String get invoiceNumber => 'बिल नम्बर';

  @override
  String get date => 'मिति';

  @override
  String get organization => 'संस्था';

  @override
  String get products => 'सामानहरू';

  @override
  String get addProduct => 'सामान थप्नुहोस्';

  @override
  String get editProduct => 'सामान सम्पादन गर्नुहोस्';

  @override
  String get deleteProduct => 'सामान मेट्नुहोस्';

  @override
  String deleteProductConfirm(String name) {
    return '\"$name\" सामान मेट्ने? हुने गरेको चीज फिर्ता हुँदैन।';
  }

  @override
  String get productNameEn => 'सामानको नाम (अंग्रेजी)';

  @override
  String get productNameNe => 'सामानको नाम (नेपाली)';

  @override
  String get sku => 'SKU / कोड';

  @override
  String get descriptionEn => 'विवरण (अंग्रेजी)';

  @override
  String get descriptionNe => 'विवरण (नेपाली)';

  @override
  String get productRate => 'बिक्री दर';

  @override
  String get unit => 'एकाइ';

  @override
  String get category => 'श्रेणी';

  @override
  String get categoryHint => 'जस्तै: खाना, पेय, सामान';

  @override
  String get unitShortLabel => 'एकाइ';

  @override
  String get active => 'सक्रिय';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get showInactiveProducts => 'निष्क्रिय सामान पनि देखाउनुहोस्';

  @override
  String get sortByName => 'नाम अनुसार';

  @override
  String get sortByRate => 'दर अनुसार';

  @override
  String get sortByNewest => 'नयाँ अनुसार';

  @override
  String get sortBy => 'क्रमबद्ध गर्नुहोस्';

  @override
  String get sortByNameAsc => 'नाम (A देखि Z)';

  @override
  String get sortByNameDesc => 'नाम (Z देखि A)';

  @override
  String get sortByDateNewest => 'मिति (नयाँ पहिले)';

  @override
  String get sortByDateOldest => 'मिति (पुरानो पहिले)';

  @override
  String get sortByRateAsc => 'दर (कम देखि बढी)';

  @override
  String get sortByRateDesc => 'दर (बढी देखि कम)';

  @override
  String get selectUnit => 'एकाइ छान्नुहोस्';

  @override
  String get customUnit => 'अन्य एकाइ';

  @override
  String get addCustomUnit => 'नयाँ एकाइ थप्नुहोस्';

  @override
  String get customUnitHint => 'उदाहरण: बोतल, बन्डल, कप, ट्रिप';

  @override
  String get unitNameEn => 'एकाइको नाम (अंग्रेजी)';

  @override
  String get unitNameNe => 'एकाइको नाम (नेपाली)';

  @override
  String get unitAbbreviationEn => 'छोटो नाम (अंग्रेजी)';

  @override
  String get unitAbbreviationNe => 'छोटो नाम (नेपाली)';

  @override
  String get enterProductNames =>
      'सामानको नाम अंग्रेजी वा नेपालीमा प्रविष्ट गर्नुहोस्।';

  @override
  String get enterUnitName =>
      'एकाइको नाम अंग्रेजी वा नेपालीमा प्रविष्ट गर्नुहोस्।';

  @override
  String get productSavedMsg => 'सामान सुरक्षित भयो।';

  @override
  String get productDeletedMsg => 'सामान मेटियो।';

  @override
  String get unitExistsMsg => 'यो एकाइ पहिले नै छ।';

  @override
  String get inactiveMark => 'निष्क्रिय';

  @override
  String get invoices => 'बिलहरू';

  @override
  String get searchInvoices => 'बिल नम्बर वा ग्राहक खोज्नुहोस्';

  @override
  String get dateRange => 'मिति दायरा';

  @override
  String get filterToday => 'आज';

  @override
  String get filterLast7Days => 'पछिल्ला ७ दिन';

  @override
  String get filterThisMonth => 'यो महिना';

  @override
  String get filter3Months => '३ महिना';

  @override
  String get filter6Months => '६ महिना';

  @override
  String get filterThisYear => 'यो वर्ष';

  @override
  String get filterAllTime => 'सबै समय';

  @override
  String get filterCustomRange => 'मिति दायरा (देखि – सम्म)';

  @override
  String get fromDate => 'सुरु मिति';

  @override
  String get toDate => 'अन्तिम मिति';

  @override
  String get pickDateRangeCalendar => 'क्यालेन्डर दायरा';

  @override
  String get applyFilters => 'फिल्टर लागू गर्नुहोस्';

  @override
  String get clearFilters => 'फिल्टर हटाउनुहोस्';

  @override
  String get emptyInvoices => 'कुनै बिल छैन। बिलिङबाट पहिलो बिल बनाउनुहोस्।';

  @override
  String get emptyInvoicesSearch => 'खोजी वा फिल्टरसँग मिल्ने बिल भेटिएन।';

  @override
  String get items => 'वस्तुहरू';

  @override
  String itemCount(String count) {
    return '$count वटा वस्तु';
  }

  @override
  String get statusFinalized => 'पक्का गरिएको';

  @override
  String get statusVoided => 'रद्द गरिएको';

  @override
  String get statusProcessing => 'प्रक्रियामा';

  @override
  String get statusSuccess => 'सम्पन्न (भुक्तानी भयो)';

  @override
  String get statusCanceled => 'रद्द गरिएको';

  @override
  String get transactionConfirmation => 'कारोबार पुष्टि';

  @override
  String get transactionStatus => 'कारोबार स्थिति';

  @override
  String get waitingForPaymentMsg =>
      'भुक्तानीको पर्खाइमा। सुरक्षित र प्रिन्ट गर्न \'सम्पन्न\' चयन गर्नुहोस्।';

  @override
  String get paymentConfirmedMsg =>
      'भुक्तानी प्राप्त भयो। अब सुरक्षित र प्रिन्ट गर्न तयार छ।';

  @override
  String get transactionCanceledMsg => 'कारोबार रद्द गरिएको छ।';

  @override
  String get saveAsProcessing => 'प्रक्रियामा सुरक्षित गर्नुहोस्';

  @override
  String get markAsPaid => 'भुक्तानी भयो भनी चिन्ह लगाउनुहोस्';

  @override
  String get invoiceProcessingMsg =>
      'कारोबार अहिले प्रक्रियामा छ (भुक्तानीको पर्खाइमा)।';

  @override
  String get voidInvoice => 'बिल रद्द गर्नुहोस्';

  @override
  String voidInvoiceConfirm(String number) {
    return '$number बिल रद्द गर्ने? रद्द गरिएको बिल इतिहासमा रहन्छ तर फेरि प्रिन्ट हुँदैन।';
  }

  @override
  String get voidReasonLabel => 'रद्द गर्ने कारण';

  @override
  String get voidReasonHint => 'जस्तै: गलत प्रविष्टि';

  @override
  String get invoiceVoidedMsg => 'बिल रद्द भयो।';

  @override
  String get voidNotAllowedReprint =>
      'रद्द गरिएको बिल फेरि प्रिन्ट गर्न सकिँदैन।';

  @override
  String get printAttempts => 'प्रिन्ट प्रयासहरू';

  @override
  String get printAttemptFailed => 'असफल';

  @override
  String get printAttemptSent => 'पठाइयो';

  @override
  String get notPrintedYet => 'अझै प्रिन्ट भएको छैन';

  @override
  String printedTimes(String count) {
    return '$count पटक प्रिन्ट गरिएको';
  }

  @override
  String get organizationSnapshotNote =>
      'यस बिलमा बिलिङको समयमा सुरक्षित गरिएको संस्था, सामान र दरको जानकारी रहन्छ।';

  @override
  String get totalsSection => 'रकमहरू';

  @override
  String get paymentSection => 'भुक्तानी';

  @override
  String get printer => 'प्रिन्टर';

  @override
  String get printerSettings => 'प्रिन्टर सेटिङ';

  @override
  String get connectionType => 'जडानको प्रकार';

  @override
  String get connectionLan => 'LAN / Wi-Fi';

  @override
  String get connectionUsb => 'USB';

  @override
  String get discoverPrinters => 'प्रिन्टर खोज्नुहोस्';

  @override
  String get stopSearch => 'रोक्नुहोस्';

  @override
  String get discoveringNetwork => 'नेटवर्कमा प्रिन्टर खोज्दै…';

  @override
  String get wifiRequiredHint =>
      'फोन र प्रिन्टरलाई एउटै Wi-Fi नेटवर्कमा जोडेर फेरि खोज्नुहोस्। प्रिन्टरको IP ठेगाना थाहा भए तल म्यानुअल रूपमा थप्न पनि मिल्छ।';

  @override
  String get manualPrinter => 'म्यानुअल प्रिन्टर थप्नुहोस्';

  @override
  String get printerName => 'प्रिन्टरको नाम';

  @override
  String get printerIp => 'IP ठेगाना';

  @override
  String get port => 'पोर्ट';

  @override
  String get testConnection => 'जडान जाँच्नुहोस्';

  @override
  String get testPrint => 'टेस्ट प्रिन्ट';

  @override
  String get connect => 'जडान गर्नुहोस्';

  @override
  String get disconnect => 'जडान हटाउनुहोस्';

  @override
  String get forgetPrinter => 'प्रिन्टर बिर्सनुहोस्';

  @override
  String get selectPrinter => 'छान्नुहोस्';

  @override
  String get selected => 'छानिएको';

  @override
  String get usbDevices => 'USB उपकरणहरू';

  @override
  String get usbVendorId => 'भेण्डर ID';

  @override
  String get usbProductId => 'प्रोडक्ट ID';

  @override
  String get usbNoDevices =>
      'कुनै USB प्रिन्टर भेटिएन। प्रिन्टर USB केबलले जोड्नुहोस्।';

  @override
  String get usbPermission => 'अनुमति';

  @override
  String get requestPermission => 'अनुमति दिनुहोस्';

  @override
  String get usbDeviceConnected => 'जडित';

  @override
  String get usbDeviceAttachHint =>
      'प्रिन्टर USB बाट जोड्नुहोस् र फोनले सोध्दा उपकरण प्रयोगको अनुमति दिनुहोस्।';

  @override
  String get paperWidthLabel => 'कागजको चौडाइ';

  @override
  String get renderingModeLabel => 'प्रिन्ट विधि';

  @override
  String get renderingModeAuto => 'स्वतः (सिफारिस)';

  @override
  String get renderingModeText => 'पाठ (छिटो, अंग्रेजी मात्र)';

  @override
  String get renderingModeImage => 'तस्बिर (नेपालीका लागि)';

  @override
  String get renderingModeNote =>
      'नेपाली युनिकोड ठीकसँग प्रिन्ट गर्न तस्बिर विधि चाहिन्छ (प्रिन्टरमा देवनागरी फन्ट भए बाहेक)।';

  @override
  String get enableCutLabel => 'प्रिन्ट पछि कागज काट्ने';

  @override
  String get enableBeepLabel => 'प्रिन्ट पछि बीप (परीक्षण)';

  @override
  String get enableDrawerLabel => 'क्यास ड्रअर खोल्ने (परीक्षण)';

  @override
  String get printDensityLabel => 'प्रिन्ट गहिराइ';

  @override
  String get enteredIpError => 'सही IP ठेगाना प्रविष्ट गर्नुहोस्।';

  @override
  String get portError => 'सही पोर्ट प्रविष्ट गर्नुहोस् (1–65535)।';

  @override
  String get nameRequired => 'नाम प्रविष्ट गर्नुहोस्।';

  @override
  String get printerSavedMsg => 'प्रिन्टर सुरक्षित भयो।';

  @override
  String get printerForgottenMsg => 'प्रिन्टर हटाइयो।';

  @override
  String get printerTestOk => 'जडान सफल भयो।';

  @override
  String get printerTestOkLabel => 'टेस्ट रसिद पठाइयो। प्रिन्टर जाँच्नुहोस्।';

  @override
  String get connectionTestFailed => 'जडान परीक्षण असफल भयो।';

  @override
  String get selectPrinterFirst =>
      'पहिले प्रिन्टर छान्नुहोस् वा जडान गर्नुहोस्।';

  @override
  String get printerScanNote =>
      'स्थानीय नेटवर्क खोजेर पोर्ट 9100 मा भएका प्रिन्टरहरू फेला पारिन्छन्।';

  @override
  String get deviceInfo => 'उपकरण जानकारी';

  @override
  String get paperWidth58 => '58 mm';

  @override
  String get paperWidth80 => '80 mm';

  @override
  String get settings => 'सेटिङ';

  @override
  String get generalSection => 'साधारण';

  @override
  String get organizationSection => 'संस्था';

  @override
  String get receiptSection => 'रसिद डिजाइन';

  @override
  String get billingSection => 'बिलिङ';

  @override
  String get dataSection => 'डेटा';

  @override
  String get aboutSection => 'बारेमा';

  @override
  String get appLanguage => 'एपको भाषा';

  @override
  String get themeModeLabel => 'थिम';

  @override
  String get themeLight => 'उज्यालो';

  @override
  String get themeDark => 'अँध्यारो';

  @override
  String get themeSystem => 'फोन अनुसार';

  @override
  String get currencySymbolLabel => 'मुद्रा चिह्न';

  @override
  String get currencyNpr => 'NPR';

  @override
  String get currencyRu => 'रु.';

  @override
  String get invoiceLanguageSetting => 'बिलको भाषा (पूर्वनिर्धारित)';

  @override
  String get numeralFormatLabel => 'अंकको शैली';

  @override
  String get westernNumerals => 'अंग्रेजी अंक (1,250.00)';

  @override
  String get devanagariNumerals => 'देवनागरी अंक (१,२५०.००)';

  @override
  String get dateFormatLabel => 'पात्रो प्रणाली';

  @override
  String get gregorianCalendar => 'इस्वी सन् (AD)';

  @override
  String get bikramSambatCalendar => 'विक्रम सम्वत् (BS)';

  @override
  String get dateFormatStyleLabel => 'मितिको शैली';

  @override
  String get dateStyleNumeric => 'संख्यात्मक (2082-07-12)';

  @override
  String get dateStyleLongMonth => 'महिनासहित (12 कात्तिक 2082)';

  @override
  String get showTimeOnReceipt => 'रसिदमा समय पनि देखाउने';

  @override
  String get bottomMarginOnReceipt =>
      'रसिदको तल पनि माथिको जस्तै खाली ठाउँ राख्ने';

  @override
  String get quantityPrecisionLabel => 'परिमाणको दशमलव';

  @override
  String get selectedFormatHint => 'उदाहरण';

  @override
  String get orgInformation => 'संस्थाको विवरण';

  @override
  String get orgNameEn => 'संस्थाको नाम (अंग्रेजी)';

  @override
  String get orgNameNe => 'संस्थाको नाम (नेपाली)';

  @override
  String get orgAddressEn => 'ठेगाना (अंग्रेजी)';

  @override
  String get orgAddressNe => 'ठेगाना (नेपाली)';

  @override
  String get phoneLabel => 'फोन नम्बर';

  @override
  String get altPhoneLabel => 'वैकल्पिक फोन नम्बर (वैकल्पिक)';

  @override
  String get emailLabel => 'इमेल (वैकल्पिक)';

  @override
  String get panNumberLabel => 'PAN नम्बर (वैकल्पिक)';

  @override
  String get vatNumberLabel => 'VAT नम्बर (वैकल्पिक)';

  @override
  String get websiteLabel => 'वेबसाइट (वैकल्पिक)';

  @override
  String get registrationNumberLabel => 'दर्ता नम्बर (वैकल्पिक)';

  @override
  String get logoLabel => 'संस्थाको लोगो (वैकल्पिक)';

  @override
  String get pickLogo => 'लोगो छान्नुहोस्';

  @override
  String get removeLogo => 'लोगो हटाउनुहोस्';

  @override
  String get orgCustomInfoEn => 'अतिरिक्त जानकारी (अंग्रेजी)';

  @override
  String get orgCustomInfoNe => 'अतिरिक्त जानकारी (नेपाली)';

  @override
  String get orgCustomInfoHint => 'सेटिङले खुला गरे रसिदमा देखिन्छ';

  @override
  String get enterOrgName =>
      'संस्थाको नाम अंग्रेजी वा नेपालीमा प्रविष्ट गर्नुहोस्।';

  @override
  String get phoneOrContactRequired =>
      'सही फोन नम्बर प्रविष्ट गर्नुहोस् वा खाली छोड्नुहोस्।';

  @override
  String get emailInvalid => 'सही इमेल ठेगाना प्रविष्ट गर्नुहोस्।';

  @override
  String get orgSavedMsg => 'संस्थाको विवरण सुरक्षित भयो।';

  @override
  String get orgSetupPrompt =>
      'बिलहरूमा सही टाउको देखिन आफ्नो संस्थाको विवरण भर्नुहोस्।';

  @override
  String get setupOrganization => 'संस्थाको विवरण भर्नुहोस्';

  @override
  String get languageSectionTitle => 'भाषा';

  @override
  String get receiptDesign => 'रसिद डिजाइन';

  @override
  String get visibleFields => 'रसिदमा देखाउने जानकारी';

  @override
  String get showLogo => 'लोगो';

  @override
  String get showAddress => 'ठेगाना';

  @override
  String get showPhone => 'फोन नम्बर';

  @override
  String get showEmail => 'इमेल';

  @override
  String get showWebsite => 'वेबसाइट';

  @override
  String get showPanVat => 'PAN / VAT';

  @override
  String get showCustomer => 'ग्राहकको विवरण';

  @override
  String get showPayment => 'भुक्तानी विवरण';

  @override
  String get headerMessages => 'टाउकोका सन्देशहरू';

  @override
  String get footerMessages => 'फेदका सन्देशहरू';

  @override
  String get welcomeMessage => 'स्वागत सन्देश';

  @override
  String get thankYouMessage => 'धन्यवाद सन्देश';

  @override
  String get returnPolicy => 'फिर्ता / साटासाट नीति';

  @override
  String get paymentTerms => 'भुक्तानी शर्तहरू';

  @override
  String get promoMessage => 'प्रचार सन्देश';

  @override
  String get additionalMessage => 'अतिरिक्त सन्देश';

  @override
  String get customMessageHint => 'पूर्वनिर्धारित सन्देश चाहिए खाली छोड्नुहोस्';

  @override
  String get headerAlignmentLabel => 'टाउकोको पङ्क्ति';

  @override
  String get alignLeft => 'देब्रे';

  @override
  String get alignCenter => 'मध्यम';

  @override
  String get textSizeLabel => 'रसिद अक्षरको साइज';

  @override
  String get textSizeSmall => 'सानो';

  @override
  String get textSizeMedium => 'मध्यम';

  @override
  String get textSizeLarge => 'ठूलो';

  @override
  String get receiptSavedMsg => 'रसिद डिजाइन सुरक्षित भयो।';

  @override
  String get receiptPreviewLabel => 'प्रत्यक्ष पूर्वावलोकन';

  @override
  String get templateLanguageTab => 'सन्देशको भाषा';

  @override
  String get invoicePrefixLabel => 'बिल उपसर्ग (Prefix)';

  @override
  String get invoicePrefixHint => 'जस्तै INV-';

  @override
  String get startingNumberLabel => 'प्रारम्भिक नम्बर';

  @override
  String get numberOfDigitsLabel => 'अंकहरूको संख्या';

  @override
  String get fiscalYearPrefix => 'आ.व. (Shrawan–Shrawan) उपसर्ग थप्ने';

  @override
  String invoiceNumberPreview(String number) {
    return 'नमूना: $number';
  }

  @override
  String get defaultDiscountPercent => 'पूर्वनिर्धारित छुट (%)';

  @override
  String get taxSettingsTitle => 'कर र शुल्क';

  @override
  String get enableTax => 'कर सक्षम गर्नुहोस्';

  @override
  String get taxPercentLabel => 'कर दर (%)';

  @override
  String get enableDiscount => 'छुट सक्षम गर्नुहोस्';

  @override
  String get enableOtherCharges => 'अन्य शुल्क सक्षम गर्नुहोस्';

  @override
  String get otherChargesLabel => 'शुल्कको नाम';

  @override
  String get backupTitle => 'ब्याकअप र निर्यात';

  @override
  String get createBackup => 'डेटाबेस ब्याकअप लिनुहोस्';

  @override
  String get restoreBackup => 'ब्याकअप पुनर्स्थापना गर्नुहोस्';

  @override
  String get osBackupsHint => 'ब्याकअपहरू फोनको एप फोल्डरमा सुरक्षित हुन्छन्।';

  @override
  String get noBackupsAvailable => 'कुनै ब्याकअप छैन।';

  @override
  String backupCreatedMsg(String path) {
    return 'ब्याकअप बन्यो: $path';
  }

  @override
  String get restoreBackupConfirm =>
      'ब्याकअप पुनर्स्थापनाले हालको सबै डेटा बदलिनेछ। जारी राख्ने?';

  @override
  String get restoredMsg =>
      'ब्याकअप पुनर्स्थापित भयो। कृपया एप पुनः सुरु गर्नुहोस्।';

  @override
  String get exportInvoicesCsv => 'बिलहरू CSV मा निर्यात गर्नुहोस्';

  @override
  String exportDoneMsg(String path) {
    return 'निर्यात सम्पन्न: $path';
  }

  @override
  String get restoreFailed => 'पुनर्स्थापना असफल भयो। फेरि प्रयास गर्नुहोस्।';

  @override
  String get appVersionLabel => 'एपको भर्सन';

  @override
  String get aboutAppText =>
      'XLab बिलिङ — XLab XTKP607UL थर्मल प्रिन्टरका लागि अफलाइन बिलिङ र रसिद प्रिन्टिङ।';

  @override
  String get panCode => 'पा.नं:';

  @override
  String get vatCode => 'VAT:';

  @override
  String get phoneCode => 'फोन:';

  @override
  String get paidLabel => 'भुक्तानी भएको';

  @override
  String get dueLabel => 'बाँकी रकम';

  @override
  String get thankYou => 'धन्यवाद';

  @override
  String get invoiceTitle => 'नगद रसिद';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get qtyLabel => 'परि.';

  @override
  String get unitLabel => 'एकाइ';

  @override
  String get rateLabel => 'दर';

  @override
  String get amountLabel => 'रकम';

  @override
  String get snLabel => 'क्र.सं.';

  @override
  String get particularsLabel => 'विवरण';

  @override
  String get changeLabel => 'फिर्ता रकम';

  @override
  String get receiptProfilesSection => 'रसिद प्रोफाइलहरू';

  @override
  String get addReceiptProfile => 'नयाँ रसिद प्रोफाइल';

  @override
  String get editReceiptProfile => 'रसिद प्रोफाइल सम्पादन';

  @override
  String get profileNameLabel => 'प्रोफाइलको नाम';

  @override
  String get defaultProfileName => 'मुख्य प्रोफाइल';

  @override
  String get profileSavedMsg => 'रसिद प्रोफाइल सुरक्षित गरियो।';

  @override
  String get deleteProfileConfirm => 'यो रसिद प्रोफाइल हटाउने हो?';

  @override
  String get billingProfilesSection => 'बिलिङ प्रोफाइलहरू';

  @override
  String get addBillingProfile => 'नयाँ बिलिङ प्रोफाइल';

  @override
  String get editBillingProfile => 'बिलिङ प्रोफाइल सम्पादन';

  @override
  String get defaultBillingProfileName => 'मुख्य बिलिङ';

  @override
  String get billingProfileSavedMsg => 'बिलिङ प्रोफाइल सुरक्षित गरियो।';

  @override
  String get deleteBillingProfileConfirm => 'यो बिलिङ प्रोफाइल हटाउने हो?';

  @override
  String get allProfilesFilter => 'सबै प्रोफाइलहरू';

  @override
  String get receiptProfileLabel => 'रसिद प्रोफाइल';

  @override
  String get profileNameExistsError => 'यो नामको प्रोफाइल पहिले नै छ।';

  @override
  String get profileNameRequiredError =>
      'कृपया प्रोफाइलको नाम प्रविष्ट गर्नुहोस्।';

  @override
  String get addCategory => 'नयाँ श्रेणी थप्नुहोस्';

  @override
  String get categoryName => 'श्रेणीको नाम';

  @override
  String get categoryNameEn => 'श्रेणीको नाम (अंग्रेजी)';

  @override
  String get categoryNameNe => 'श्रेणीको नाम (नेपाली)';

  @override
  String get categorySavedMsg => 'श्रेणी सुरक्षित भयो।';

  @override
  String get categoryExistsMsg => 'यो श्रेणी पहिले नै छ।';

  @override
  String get enterCategoryName => 'कृपया श्रेणीको नाम प्रविष्ट गर्नुहोस्।';

  @override
  String get noCategory => 'कुनै श्रेणी छैन';

  @override
  String get enterProductNameEn =>
      'कृपया सामानको नाम अंग्रेजीमा प्रविष्ट गर्नुहोस्।';

  @override
  String get enterRate => 'कृपया बिक्री दर प्रविष्ट गर्नुहोस्।';

  @override
  String get selectUnitRequired => 'कृपया एकाइ छान्नुहोस्।';

  @override
  String get manageCategories => 'श्रेणीहरू व्यवस्थापन';

  @override
  String get editCategory => 'श्रेणी सम्पादन';

  @override
  String get deleteCategory => 'श्रेणी हटाउनुहोस्';

  @override
  String get categoryDeletedMsg => 'श्रेणी हटाइयो।';

  @override
  String deleteCategoryConfirm(String name) {
    return 'श्रेणी \"$name\" हटाउने हो?';
  }

  @override
  String deleteCategoryConfirmProducts(String name, int count) {
    return 'श्रेणी \"$name\" हटाउने हो? $count सामानको श्रेणी हट्नेछ।';
  }

  @override
  String get manageUnits => 'एकाइहरू व्यवस्थापन';

  @override
  String get editUnit => 'एकाइ सम्पादन';

  @override
  String get deleteUnit => 'एकाइ हटाउनुहोस्';

  @override
  String get unitDeletedMsg => 'एकाइ हटाइयो।';

  @override
  String deleteUnitConfirm(String name) {
    return 'एकाइ \"$name\" हटाउने हो?';
  }

  @override
  String cannotDeleteUnitInUse(String name, int count) {
    return 'एकाइ \"$name\" हटाउन सकिँदैन: $count सामानमा प्रयोग भइरहेको छ।';
  }

  @override
  String get standardUnit => 'मानक';

  @override
  String get customUnitBadge => 'कस्टम';

  @override
  String productCountLabel(int count) {
    return '$count सामान';
  }
}

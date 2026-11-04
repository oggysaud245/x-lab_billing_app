/// Session-wide app state: settings, organization, receipt design. Loads at
/// bootstrap; language and theme are mirrored into SharedPreferences so the
/// first frame after a cold start already has them.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/db/app_database.dart';
import '../models/app_settings.dart';
import '../models/billing_profile.dart';
import '../models/organization.dart';
import '../models/receipt_profile.dart';
import '../models/receipt_settings.dart';
import '../repositories/organization_repository.dart';
import '../repositories/receipt_settings_repository.dart';
import '../repositories/settings_repository.dart';

class AppState extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaults;
  Organization _org = Organization.empty;
  ReceiptSettings _receipt = ReceiptSettings.defaults;
  List<ReceiptProfile> _profiles = const [ReceiptProfile.emptyDefault];
  String _activeProfileId = ReceiptProfile.emptyDefault.id;
  List<BillingProfile> _billingProfiles = const [BillingProfile.emptyDefault];
  String _activeBillingProfileId = BillingProfile.emptyDefault.id;

  bool _initialized = false;
  bool _orgConfigured = false;
  int _dataVersion = 0;
  int _billingTabRequestVersion = 0;

  AppSettings get settings => _settings;
  Organization get organization => _org;
  ReceiptSettings get receipt => _receipt;
  List<ReceiptProfile> get profiles => List.unmodifiable(_profiles);
  String get activeProfileId => _activeProfileId;
  ReceiptProfile get activeProfile =>
      _profiles.where((p) => p.id == _activeProfileId).firstOrNull ??
      (_profiles.isNotEmpty ? _profiles.first : ReceiptProfile.emptyDefault);
  List<BillingProfile> get billingProfiles =>
      List.unmodifiable(_billingProfiles);
  String get activeBillingProfileId => _activeBillingProfileId;
  BillingProfile get activeBillingProfile =>
      _billingProfiles
          .where((p) => p.id == _activeBillingProfileId)
          .firstOrNull ??
      (_billingProfiles.isNotEmpty
          ? _billingProfiles.first
          : BillingProfile.emptyDefault);
  bool get initialized => _initialized;
  bool get orgConfigured => _orgConfigured && _org.isConfigured;

  /// Monotonically increasing counter bumped whenever products, units,
  /// invoices, or restored backups change so mounted IndexedStack tabs
  /// immediately refresh their lists without an app restart.
  int get dataVersion => _dataVersion;
  int get billingTabRequestVersion => _billingTabRequestVersion;

  void notifyDataChanged() {
    _dataVersion++;
    notifyListeners();
  }

  void requestBillingTab() {
    _billingTabRequestVersion++;
    _dataVersion++;
    notifyListeners();
  }

  /// Refreshes `invoiceNext` in [settings] and bumps [dataVersion]
  /// after an invoice is finalized so the Invoices and Settings tabs update
  /// immediately.
  Future<void> refreshAfterFinalize() async {
    _dataVersion++;
    if (_initialized) {
      try {
        final next = await _settingsRepo.peekInvoiceNumber();
        _settings = _settings.copyWith(invoiceNext: next);
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Reloads settings, organization, and receipt design from the database
  /// (e.g. after restoring a backup) and bumps [dataVersion].
  Future<void> reloadAll() async {
    _dataVersion++;
    if (_initialized) {
      try {
        _settings = await _settingsRepo.load();
        _org = await _orgRepo.loadActive();
        _receipt = await _receiptRepo.load();
        await _loadOrSeedProfiles();
        await _loadOrSeedBillingProfiles();
        _orgConfigured = _org.isConfigured;
      } catch (_) {}
    }
    notifyListeners();
  }

  late SettingsRepository _settingsRepo;
  late OrganizationRepository _orgRepo;
  late ReceiptSettingsRepository _receiptRepo;

  Locale get locale => Locale(_settings.appLanguage.code);

  ThemeMode get themeMode => switch (_settings.theme) {
        ThemeChoice.light => ThemeMode.light,
        ThemeChoice.dark => ThemeMode.dark,
        ThemeChoice.system => ThemeMode.system,
      };

  static Future<AppState> create() async {
    final s = AppState();
    await s.bootstrap();
    return s;
  }

  Future<void> bootstrap() async {
    _settingsRepo = SettingsRepository(open: () => AppDatabase.open);
    _orgRepo = OrganizationRepository(open: () => AppDatabase.open);
    _receiptRepo = ReceiptSettingsRepository(open: () => AppDatabase.open);

    try {
      // Fast mirror from prefs — determines first-frame locale.
      final prefs = await SharedPreferences.getInstance();
      final mirrorLang = prefs.getString('mirror_app_language');
      final mirrorTheme = prefs.getString('mirror_theme');
      if (mirrorLang != null || mirrorTheme != null) {
        final lang = mirrorLang == 'ne'
            ? AppLanguage.ne
            : (mirrorLang == 'en' ? AppLanguage.en : null);
        _settings = _settings.copyWith(
          appLanguage: lang,
          currency: lang == null
              ? null
              : (lang.isNepali ? CurrencySymbol.ru : CurrencySymbol.npr),
          numeralFormat: lang == null
              ? null
              : (lang.isNepali ? NumeralFormat.devanagari : NumeralFormat.western),
          theme: switch (mirrorTheme) {
            'light' => ThemeChoice.light,
            'dark' => ThemeChoice.dark,
            'system' => ThemeChoice.system,
            _ => null,
          },
        );
      }
    } catch (_) {
      // prefs unavailable — fall back to defaults
    }

    _settings = await _settingsRepo.load();
    // First launch: default to the device language, Nepali devices get Nepali.
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('first_run_done') ?? false;
      if (!seen) {
        final devIsNepali = WidgetsBinding
                .instance.platformDispatcher.locales
                .any((l) => l.languageCode.toLowerCase() == 'ne');
        if (_settings.appLanguage == AppSettings.defaults.appLanguage) {
          final lang = devIsNepali ? AppLanguage.ne : AppLanguage.en;
          _settings = _settings.copyWith(
            appLanguage: lang,
            currency: lang.isNepali ? CurrencySymbol.ru : CurrencySymbol.npr,
            numeralFormat:
                lang.isNepali ? NumeralFormat.devanagari : NumeralFormat.western,
          );
        }
        await prefs.setBool('first_run_done', true);
      }
    } catch (_) {}

    _org = await _orgRepo.loadActive();
    _receipt = await _receiptRepo.load();
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrated = prefs.getBool('pan_vat_default_migrated') ?? false;
      if (!migrated) {
        if (!_receipt.showPanVat) {
          _receipt = _receipt.copyWith(showPanVat: true);
          await _receiptRepo.save(_receipt);
        }
        await prefs.setBool('pan_vat_default_migrated', true);
      }
    } catch (_) {}
    await _loadOrSeedProfiles();
    await _loadOrSeedBillingProfiles();
    _orgConfigured = true;
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadOrSeedProfiles() async {
    final (loaded, activeId) = await _settingsRepo.loadProfiles();
    if (loaded.isEmpty) {
      final seeded = ReceiptProfile(
        id: 'profile_1',
        name: _org.displayName,
        organization: _org,
        invoiceLanguageMode: _settings.invoiceLanguageMode,
        useBikramSambat: _settings.useBikramSambat,
        longDateStyle: _settings.longDateStyle,
        showTimeOnReceipt: _settings.showTimeOnReceipt,
        bottomMarginOnReceipt: _settings.bottomMarginOnReceipt,
        receipt: _receipt,
      );
      _profiles = [seeded];
      _activeProfileId = seeded.id;
      await _settingsRepo.saveProfiles(_profiles, _activeProfileId);
    } else {
      _profiles = loaded;
      _activeProfileId =
          loaded.any((p) => p.id == activeId) ? activeId! : loaded.first.id;
      await _applyProfileToActiveState(activeProfile, persist: false);
    }
  }

  Future<void> _applyProfileToActiveState(
    ReceiptProfile p, {
    required bool persist,
  }) async {
    _org = p.organization;
    _receipt = p.receipt;
    _settings = _settings.copyWith(
      invoiceLanguageMode: p.invoiceLanguageMode,
      useBikramSambat: p.useBikramSambat,
      longDateStyle: p.longDateStyle,
      showTimeOnReceipt: p.showTimeOnReceipt,
      bottomMarginOnReceipt: p.bottomMarginOnReceipt,
    );
    _orgConfigured = _org.isConfigured;
    if (persist && _initialized) {
      _org = await _orgRepo.upsert(_org);
      await _receiptRepo.save(_receipt);
      await _settingsRepo.save({
        'invoice_language': p.invoiceLanguageMode.code,
        'use_bikram_sambat': p.useBikramSambat ? '1' : '0',
        'long_date_style': p.longDateStyle ? '1' : '0',
        'show_time_on_receipt': p.showTimeOnReceipt ? '1' : '0',
        'bottom_margin_on_receipt': p.bottomMarginOnReceipt ? '1' : '0',
      });
    }
  }

  Future<void> _syncActiveProfileFromCurrentState() async {
    final cur = activeProfile.copyWith(
      organization: _org,
      invoiceLanguageMode: _settings.invoiceLanguageMode,
      useBikramSambat: _settings.useBikramSambat,
      longDateStyle: _settings.longDateStyle,
      showTimeOnReceipt: _settings.showTimeOnReceipt,
      bottomMarginOnReceipt: _settings.bottomMarginOnReceipt,
      receipt: _receipt,
    );
    _profiles = [
      for (final p in _profiles) p.id == cur.id ? cur : p,
    ];
    final curBilling = activeBillingProfile.copyWith(
      taxEnabled: _settings.taxEnabled,
      taxPercent: _settings.taxPercent,
      defaultDiscountPercent: _settings.defaultDiscountPercent,
      otherChargesEnabled: _settings.otherChargesEnabled,
      otherChargesNote: _settings.otherChargesNote,
      defaultPaymentMethod: _settings.defaultPaymentMethod,
      invoicePrefix: _settings.invoicePrefix,
      invoiceDigits: _settings.invoiceDigits,
      fiscalYearPrefix: _settings.fiscalYearPrefix,
    );
    _billingProfiles = [
      for (final p in _billingProfiles) p.id == curBilling.id ? curBilling : p,
    ];
    if (_initialized) {
      await _settingsRepo.saveProfiles(_profiles, _activeProfileId);
      await _settingsRepo.saveBillingProfiles(
        _billingProfiles,
        _activeBillingProfileId,
      );
    }
  }

  Future<void> _loadOrSeedBillingProfiles() async {
    final (loaded, activeId) = await _settingsRepo.loadBillingProfiles();
    if (loaded.isEmpty) {
      final seeded = BillingProfile(
        id: 'billing_1',
        name: '',
        taxEnabled: _settings.taxEnabled,
        taxPercent: _settings.taxPercent,
        defaultDiscountPercent: _settings.defaultDiscountPercent,
        otherChargesEnabled: _settings.otherChargesEnabled,
        otherChargesNote: _settings.otherChargesNote,
        defaultPaymentMethod: _settings.defaultPaymentMethod,
        invoicePrefix: _settings.invoicePrefix,
        invoiceDigits: _settings.invoiceDigits,
        fiscalYearPrefix: _settings.fiscalYearPrefix,
      );
      _billingProfiles = [seeded];
      _activeBillingProfileId = seeded.id;
      await _settingsRepo.saveBillingProfiles(
        _billingProfiles,
        _activeBillingProfileId,
      );
    } else {
      _billingProfiles = loaded;
      _activeBillingProfileId =
          loaded.any((p) => p.id == activeId) ? activeId! : loaded.first.id;
      await _applyBillingProfileToActiveState(
        activeBillingProfile,
        persist: false,
      );
    }
  }

  Future<void> _applyBillingProfileToActiveState(
    BillingProfile p, {
    required bool persist,
  }) async {
    _settings = _settings.copyWith(
      taxEnabled: p.taxEnabled,
      taxPercent: p.taxPercent,
      defaultDiscountPercent: p.defaultDiscountPercent,
      otherChargesEnabled: p.otherChargesEnabled,
      otherChargesNote: p.otherChargesNote,
      defaultPaymentMethod: p.defaultPaymentMethod,
      invoicePrefix: p.invoicePrefix,
      invoiceDigits: p.invoiceDigits,
      fiscalYearPrefix: p.fiscalYearPrefix,
    );
    if (persist && _initialized) {
      await _settingsRepo.save({
        'tax_enabled': p.taxEnabled ? '1' : '0',
        'tax_percent': p.taxPercent.toString(),
        'default_discount_percent': p.defaultDiscountPercent.toString(),
        'other_charges_enabled': p.otherChargesEnabled ? '1' : '0',
        'other_charges_note': p.otherChargesNote,
        'default_payment_method': p.defaultPaymentMethod,
        'invoice_prefix': p.invoicePrefix,
        'invoice_digits': p.invoiceDigits.clamp(1, 12).toString(),
        'fiscal_year_prefix': p.fiscalYearPrefix ? '1' : '0',
      });
    }
  }

  Future<void> selectBillingProfile(String id) async {
    final match = _billingProfiles.where((p) => p.id == id).firstOrNull;
    if (match == null) return;
    _activeBillingProfileId = match.id;
    await _applyBillingProfileToActiveState(match, persist: true);
    if (_initialized) {
      await _settingsRepo.saveBillingProfiles(
        _billingProfiles,
        _activeBillingProfileId,
      );
    }
    notifyListeners();
  }

  Future<BillingProfile> saveBillingProfile(
    BillingProfile profile, {
    bool makeActive = true,
  }) async {
    final exists = _billingProfiles.any((p) => p.id == profile.id);
    if (exists) {
      _billingProfiles = [
        for (final p in _billingProfiles) p.id == profile.id ? profile : p,
      ];
    } else {
      _billingProfiles = [..._billingProfiles, profile];
    }
    if (makeActive || profile.id == _activeBillingProfileId) {
      _activeBillingProfileId = profile.id;
      await _applyBillingProfileToActiveState(profile, persist: true);
    }
    if (_initialized) {
      await _settingsRepo.saveBillingProfiles(
        _billingProfiles,
        _activeBillingProfileId,
      );
    }
    notifyListeners();
    return profile;
  }

  Future<void> deleteBillingProfile(String id) async {
    if (_billingProfiles.length <= 1) return;
    _billingProfiles = _billingProfiles.where((p) => p.id != id).toList();
    if (_activeBillingProfileId == id) {
      _activeBillingProfileId = _billingProfiles.first.id;
      await _applyBillingProfileToActiveState(
        activeBillingProfile,
        persist: true,
      );
    }
    if (_initialized) {
      await _settingsRepo.saveBillingProfiles(
        _billingProfiles,
        _activeBillingProfileId,
      );
    }
    notifyListeners();
  }

  Future<void> selectProfile(String id) async {
    final match = _profiles.where((p) => p.id == id).firstOrNull;
    if (match == null) return;
    _activeProfileId = match.id;
    await _applyProfileToActiveState(match, persist: true);
    if (_initialized) {
      await _settingsRepo.saveProfiles(_profiles, _activeProfileId);
    }
    notifyListeners();
  }

  Future<ReceiptProfile> saveProfile(
    ReceiptProfile profile, {
    bool makeActive = true,
  }) async {
    var updated = profile;
    if ((updated.organization.panNumber.trim().isNotEmpty ||
            updated.organization.vatNumber.trim().isNotEmpty) &&
        !_profiles.any((p) => p.id == updated.id)) {
      updated = updated.copyWith(
        receipt: updated.receipt.copyWith(showPanVat: true),
      );
    }
    final exists = _profiles.any((p) => p.id == updated.id);
    if (exists) {
      _profiles = [
        for (final p in _profiles) p.id == updated.id ? updated : p,
      ];
    } else {
      _profiles = [..._profiles, updated];
    }
    if (makeActive || updated.id == _activeProfileId) {
      _activeProfileId = updated.id;
      await _applyProfileToActiveState(updated, persist: true);
      updated = updated.copyWith(organization: _org);
      _profiles = [
        for (final p in _profiles) p.id == updated.id ? updated : p,
      ];
    }
    if (_initialized) {
      await _settingsRepo.saveProfiles(_profiles, _activeProfileId);
    }
    notifyListeners();
    return updated;
  }

  Future<void> deleteProfile(String id) async {
    if (_profiles.length <= 1) return;
    _profiles = _profiles.where((p) => p.id != id).toList();
    if (_activeProfileId == id) {
      _activeProfileId = _profiles.first.id;
      await _applyProfileToActiveState(activeProfile, persist: true);
    }
    if (_initialized) {
      await _settingsRepo.saveProfiles(_profiles, _activeProfileId);
    }
    notifyListeners();
  }

  bool hasReceiptProfileName(
    String name, {
    String? excludeId,
    required String defaultName,
  }) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return _profiles.any((p) =>
        p.id != excludeId &&
        p.displayTitle(defaultName).trim().toLowerCase() == needle);
  }

  bool hasBillingProfileName(
    String name, {
    String? excludeId,
    required String defaultName,
  }) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return _billingProfiles.any((p) =>
        p.id != excludeId &&
        p.displayTitle(defaultName).trim().toLowerCase() == needle);
  }

  Future<void> setAppLanguage(AppLanguage lang) async {
    final cur = lang.isNepali ? CurrencySymbol.ru : CurrencySymbol.npr;
    final numFmt =
        lang.isNepali ? NumeralFormat.devanagari : NumeralFormat.western;
    _settings = _settings.copyWith(
      appLanguage: lang,
      currency: cur,
      numeralFormat: numFmt,
    );
    notifyListeners();
    await _settingsRepo.save({
      'app_language': lang.code,
      'currency': cur.code,
      'numeral_format': numFmt.code,
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mirror_app_language', lang.code);
    } catch (_) {}
  }

  Future<void> _save(Map<String, String> kv) async {
    _settings = _settings.copyWithKv(kv);
    notifyListeners();
    await _settingsRepo.save(kv);
    await _syncActiveProfileFromCurrentState();
    if (kv.containsKey('app_language') || kv.containsKey('theme')) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final lang = kv['app_language'];
        final theme = kv['theme'];
        if (lang != null) await prefs.setString('mirror_app_language', lang);
        if (theme != null) await prefs.setString('mirror_theme', theme);
      } catch (_) {}
    }
  }

  Future<void> setTheme(ThemeChoice t) => _save({'theme': t.code});

  Future<void> setCurrency(CurrencySymbol c) => _save({'currency': c.code});

  Future<void> setInvoiceLanguageMode(InvoiceLanguageMode m) =>
      _save({'invoice_language': m.code});

  Future<void> setNumeralFormat(NumeralFormat n) => _save({'numeral_format': n.code});

  Future<void> setDateOptions({
    bool? useBikramSambat,
    bool? longDateStyle,
    bool? showTime,
  }) =>
      _save({
        if (useBikramSambat != null) 'use_bikram_sambat': useBikramSambat ? '1' : '0',
        if (longDateStyle != null) 'long_date_style': longDateStyle ? '1' : '0',
        if (showTime != null) 'show_time_on_receipt': showTime ? '1' : '0',
      });

  Future<void> setBottomMarginOnReceipt(bool v) =>
      _save({'bottom_margin_on_receipt': v ? '1' : '0'});

  Future<void> setQuantityPrecision(int p) =>
      _save({'quantity_precision': p.clamp(0, 3).toString()});

  Future<void> setNumbering({
    String? invoicePrefix,
    bool? fiscalYearPrefix,
    int? invoiceDigits,
    int? defaultDiscountPercent,
  }) =>
      _save({
        if (invoicePrefix != null) 'invoice_prefix': invoicePrefix,
        if (fiscalYearPrefix != null) 'fiscal_year_prefix': fiscalYearPrefix ? '1' : '0',
        if (invoiceDigits != null) 'invoice_digits': invoiceDigits.clamp(1, 12).toString(),
        if (defaultDiscountPercent != null)
          'default_discount_percent': defaultDiscountPercent.toString(),
      });

  Future<void> setBillingDefaults({
    bool? taxEnabled,
    int? taxPercent,
    bool? otherChargesEnabled,
    String? otherChargesNote,
    String? defaultPaymentMethod,
  }) =>
      _save({
        if (taxEnabled != null) 'tax_enabled': taxEnabled ? '1' : '0',
        if (taxPercent != null) 'tax_percent': taxPercent.toString(),
        if (otherChargesEnabled != null)
          'other_charges_enabled': otherChargesEnabled ? '1' : '0',
        if (otherChargesNote != null) 'other_charges_note': otherChargesNote,
        if (defaultPaymentMethod != null) 'default_payment_method': defaultPaymentMethod,
      });

  Future<void> saveOrganization(Organization org) async {
    _org = await _orgRepo.upsert(org);
    _orgConfigured = true;
    if ((_org.panNumber.trim().isNotEmpty || _org.vatNumber.trim().isNotEmpty) &&
        !_receipt.showPanVat) {
      _receipt = _receipt.copyWith(showPanVat: true);
      await _receiptRepo.save(_receipt);
    }
    await _syncActiveProfileFromCurrentState();
    notifyListeners();
  }

  Future<bool> reloadOrganization() async {
    _org = await _orgRepo.loadActive();
    _orgConfigured = _org.isConfigured;
    notifyListeners();
    return _org.isConfigured;
  }

  Future<void> saveReceipt(ReceiptSettings r) async {
    _receipt = r;
    await _receiptRepo.save(r);
    await _syncActiveProfileFromCurrentState();
    notifyListeners();
  }

  Future<void> reloadReceipt() async {
    _receipt = await _receiptRepo.load();
    notifyListeners();
  }
}

/// copyWith helper decoding a settings key/value change-set. Percent and
/// money-like fields arrive already scaled (hundredths), matching the model.
extension _AppSettingsPatch on AppSettings {
  AppSettings copyWithKv(Map<String, String> kv) {
    final base = this;
    String str(String key, String fallback) =>
        kv.containsKey(key) ? kv[key]! : fallback;

    int i(String key, int fallback) {
      final v = kv[key];
      return v == null ? fallback : int.tryParse(v) ?? fallback;
    }

    return base.copyWith(
      invoicePrefix: kv.containsKey('invoice_prefix')
          ? kv['invoice_prefix']
          : null,
      fiscalYearPrefix: kv['fiscal_year_prefix'] == '1'
          ? true
          : (kv['fiscal_year_prefix'] == '0' ? false : null),
      invoiceDigits: kv.containsKey('invoice_digits') ? i('invoice_digits', invoiceDigits) : null,
      useBikramSambat: kv['use_bikram_sambat'] == '1'
          ? true
          : (kv['use_bikram_sambat'] == '0' ? false : null),
      longDateStyle: kv['long_date_style'] == '1'
          ? true
          : (kv['long_date_style'] == '0' ? false : null),
      showTimeOnReceipt: kv['show_time_on_receipt'] == '1'
          ? true
          : (kv['show_time_on_receipt'] == '0' ? false : null),
      bottomMarginOnReceipt: kv['bottom_margin_on_receipt'] == '1'
          ? true
          : (kv['bottom_margin_on_receipt'] == '0' ? false : null),
      quantityPrecision: kv.containsKey('quantity_precision')
          ? i('quantity_precision', quantityPrecision)
          : null,
      currency: switch (kv['currency']) {
        'NPR' => CurrencySymbol.npr,
        'ru' => CurrencySymbol.ru,
        _ => null,
      },
      invoiceLanguageMode: switch (kv['invoice_language']) {
        'follow' => InvoiceLanguageMode.followApp,
        'en' => InvoiceLanguageMode.en,
        'ne' => InvoiceLanguageMode.ne,
        _ => null,
      },
      numeralFormat: switch (kv['numeral_format']) {
        'western' => NumeralFormat.western,
        'devanagari' => NumeralFormat.devanagari,
        _ => null,
      },
      defaultDiscountPercent:
          kv.containsKey('default_discount_percent') ? i('default_discount_percent', 0) : null,
      taxEnabled: kv['tax_enabled'] == '1'
          ? true
          : (kv['tax_enabled'] == '0' ? false : null),
      taxPercent: kv.containsKey('tax_percent') ? i('tax_percent', taxPercent) : null,
      otherChargesEnabled: kv['other_charges_enabled'] == '1'
          ? true
          : (kv['other_charges_enabled'] == '0' ? false : null),
      otherChargesNote:
          kv.containsKey('other_charges_note') ? str('other_charges_note', otherChargesNote) : null,
      defaultPaymentMethod:
          kv.containsKey('default_payment_method') ? str('default_payment_method', defaultPaymentMethod) : null,
      theme: switch (kv['theme']) {
        'system' => ThemeChoice.system,
        'light' => ThemeChoice.light,
        'dark' => ThemeChoice.dark,
        _ => null,
      },
    );
  }
}

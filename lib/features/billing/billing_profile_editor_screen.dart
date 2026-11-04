/// Unified billing profile editor: profile name, tax & discount defaults,
/// default payment method, other-charges note, and invoice numbering
/// (prefix, digits, fiscal-year prefix, and live preview).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting/money.dart' as money;
import '../../localization/app_localizations.dart';
import '../../shared/controllers/app_state.dart';
import '../../shared/models/app_settings.dart';
import '../../shared/models/billing_profile.dart';
import '../../shared/models/invoice.dart';
import '../../shared/services/invoice_service.dart';
import '../../shared/widgets/widgets_extra.dart';

class BillingProfileEditorScreen extends StatefulWidget {
  final BillingProfile profile;
  final bool isNew;

  const BillingProfileEditorScreen({
    super.key,
    required this.profile,
    this.isNew = false,
  });

  @override
  State<BillingProfileEditorScreen> createState() =>
      _BillingProfileEditorScreenState();
}

class _BillingProfileEditorScreenState
    extends State<BillingProfileEditorScreen> {
  final _profileName = TextEditingController();
  final _taxPercentCtrl = TextEditingController();
  final _discountPercentCtrl = TextEditingController();
  final _otherNoteCtrl = TextEditingController();
  final _prefixCtrl = TextEditingController();
  final _digitsCtrl = TextEditingController();
  String? _nameError;

  late bool _taxEnabled;
  late bool _discountEnabled;
  late bool _otherChargesEnabled;
  late PaymentMethod _paymentMethod;
  late bool _fiscalYearPrefix;

  static const _taxShortCodes = [1, 13, 20];
  static const _discountShortCodes = [5, 10, 15];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _profileName.text = p.name;
    _taxEnabled = p.taxEnabled;
    if (p.taxPercent > 0) {
      if (p.taxPercent % money.percentScale == 0) {
        _taxPercentCtrl.text = (p.taxPercent ~/ money.percentScale).toString();
      } else {
        _taxPercentCtrl.text = money.formatScaled(
          p.taxPercent,
          scale: money.percentScale,
        );
      }
    } else {
      _taxPercentCtrl.text = '';
    }
    final rawDisc = p.defaultDiscountPercent > 50
        ? (p.defaultDiscountPercent ~/ 100)
        : p.defaultDiscountPercent;
    _discountEnabled = rawDisc > 0;
    if (p.defaultDiscountPercent > 50 && p.defaultDiscountPercent % 100 != 0) {
      _discountPercentCtrl.text = money.formatScaled(
        p.defaultDiscountPercent,
        scale: money.percentScale,
      );
    } else if (rawDisc > 0) {
      _discountPercentCtrl.text = rawDisc.toString();
    } else {
      _discountPercentCtrl.text = '';
    }
    _otherChargesEnabled = p.otherChargesEnabled;
    _otherNoteCtrl.text = p.otherChargesNote;
    _paymentMethod = paymentMethodFromCode(p.defaultPaymentMethod);
    _prefixCtrl.text = p.invoicePrefix;
    _digitsCtrl.text = p.invoiceDigits.toString();
    _fiscalYearPrefix = p.fiscalYearPrefix;

    _prefixCtrl.addListener(_onNumberingFieldChanged);
    _digitsCtrl.addListener(_onNumberingFieldChanged);
    _profileName.addListener(_onProfileNameChanged);
    _taxPercentCtrl.addListener(_onTaxFieldChanged);
    _discountPercentCtrl.addListener(_onDiscountFieldChanged);
  }

  int? get _selectedTaxShortCode {
    if (!_taxEnabled) return null;
    final text = money.normalizeDigits(_taxPercentCtrl.text.trim());
    if (text.isEmpty) return null;
    final val = double.tryParse(text);
    if (val != null) {
      for (final code in _taxShortCodes) {
        if ((val - code).abs() < 0.001) return code;
      }
    }
    return null;
  }

  void _onTaxFieldChanged() {
    if (mounted) setState(() {});
  }

  void _onSelectTaxShortCode(int rate) {
    _taxPercentCtrl.text = rate.toString();
    _deferPersistIfExisting();
  }

  int? get _selectedDiscountShortCode {
    if (!_discountEnabled) return null;
    final text = money.normalizeDigits(_discountPercentCtrl.text.trim());
    if (text.isEmpty) return null;
    final val = double.tryParse(text);
    if (val != null) {
      for (final code in _discountShortCodes) {
        if ((val - code).abs() < 0.001) return code;
      }
    }
    return null;
  }

  void _onDiscountFieldChanged() {
    if (mounted) setState(() {});
  }

  void _onSelectDiscountShortCode(int rate) {
    _discountPercentCtrl.text = rate.toString();
    _deferPersistIfExisting();
  }

  void _deferPersistIfExisting() {
    if (widget.isNew) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _persistIfExisting();
    });
  }

  void _onNumberingFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSave => _profileName.text.trim().isNotEmpty;

  void _onProfileNameChanged() {
    if (mounted) {
      setState(() {
        if (_nameError != null) _nameError = null;
      });
    }
  }

  @override
  void dispose() {
    _profileName.removeListener(_onProfileNameChanged);
    _prefixCtrl.removeListener(_onNumberingFieldChanged);
    _digitsCtrl.removeListener(_onNumberingFieldChanged);
    _taxPercentCtrl.removeListener(_onTaxFieldChanged);
    _discountPercentCtrl.removeListener(_onDiscountFieldChanged);
    _profileName.dispose();
    _taxPercentCtrl.dispose();
    _discountPercentCtrl.dispose();
    _otherNoteCtrl.dispose();
    _prefixCtrl.dispose();
    _digitsCtrl.dispose();
    super.dispose();
  }

  BillingProfile _buildProfile() {
    final parsedTax = _taxEnabled
        ? (money.parseDecimalToScale(
                _taxPercentCtrl.text.trim(), money.percentScale) ??
            0)
        : 0;
    final parsedDigits =
        (int.tryParse(money.normalizeDigits(_digitsCtrl.text.trim())) ?? 6)
            .clamp(1, 12);
    final prefix = _prefixCtrl.text.trim().isEmpty
        ? 'INV-'
        : _prefixCtrl.text.trim();

    int parsedDiscount = 0;
    if (_discountEnabled) {
      final raw = _discountPercentCtrl.text.trim();
      if (raw.isNotEmpty) {
        final norm = money.normalizeDigits(raw);
        final asInt = int.tryParse(norm);
        if (asInt != null) {
          parsedDiscount = asInt.clamp(0, 100);
        } else {
          final scaled =
              money.parseDecimalToScale(norm, money.percentScale) ?? 0;
          parsedDiscount = scaled.clamp(0, 10000);
        }
      }
    }

    return widget.profile.copyWith(
      name: _profileName.text.trim(),
      taxEnabled: _taxEnabled,
      taxPercent: parsedTax < 0 ? 0 : parsedTax,
      defaultDiscountPercent: parsedDiscount,
      otherChargesEnabled: _otherChargesEnabled,
      otherChargesNote: _otherNoteCtrl.text.trim(),
      defaultPaymentMethod: _paymentMethod.code,
      invoicePrefix: prefix,
      invoiceDigits: parsedDigits,
      fiscalYearPrefix: _fiscalYearPrefix,
    );
  }

  void _persistIfExisting() {
    if (widget.isNew) return;
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    final built = _buildProfile();
    final candidateName = built.displayTitle(l.defaultBillingProfileName);
    if (app.hasBillingProfileName(
      candidateName,
      excludeId: widget.profile.id,
      defaultName: l.defaultBillingProfileName,
    )) {
      return;
    }
    app.saveBillingProfile(
      built,
      makeActive: app.activeBillingProfileId == widget.profile.id,
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    final built = _buildProfile();
    final candidateName = built.displayTitle(l.defaultBillingProfileName);

    if (candidateName.trim().isEmpty) {
      setState(() => _nameError = l.profileNameRequiredError);
      showAppSnackBar(context, l.profileNameRequiredError);
      return;
    }

    if (app.hasBillingProfileName(
      candidateName,
      excludeId: widget.profile.id,
      defaultName: l.defaultBillingProfileName,
    )) {
      setState(() => _nameError = l.profileNameExistsError);
      showAppSnackBar(context, l.profileNameExistsError);
      return;
    }

    setState(() => _nameError = null);
    await app.saveBillingProfile(built, makeActive: true);
    if (!mounted) return;
    showAppSnackBar(context, l.billingProfileSavedMsg);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final invoiceNext =
        context.select<AppState, int>((s) => s.settings.invoiceNext);
    final previewSettings = AppSettings.defaults.copyWith(
      invoicePrefix:
          _prefixCtrl.text.trim().isEmpty ? 'INV-' : _prefixCtrl.text.trim(),
      invoiceDigits:
          (int.tryParse(money.normalizeDigits(_digitsCtrl.text.trim())) ?? 6)
              .clamp(1, 12),
      fiscalYearPrefix: _fiscalYearPrefix,
    );
    final previewNumber = InvoiceService.numberFor(
      previewSettings,
      invoiceNext,
      DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? l.addBillingProfile : l.editBillingProfile),
        actions: [
          IconButton(
            tooltip: l.save,
            onPressed: _canSave ? _save : null,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          SectionCard(
            title: l.profileNameLabel,
            children: [
              _field(
                l.profileNameLabel,
                _profileName,
                errorText: _nameError,
              ),
            ],
          ),
          SectionCard(
            title: l.taxSettingsTitle,
            children: [
              SwitchTile(
                title: l.enableTax,
                value: _taxEnabled,
                onChanged: (v) {
                  setState(() {
                    _taxEnabled = v;
                    if (v && _taxPercentCtrl.text.trim().isEmpty) {
                      _taxPercentCtrl.text = '13';
                    }
                  });
                  _persistIfExisting();
                },
              ),
              if (_taxEnabled) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final rate in _taxShortCodes)
                      _ShortCodeChip(
                        label: '$rate%',
                        selected: _selectedTaxShortCode == rate,
                        onTap: () => _onSelectTaxShortCode(rate),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _field(
                  l.taxPercentLabel,
                  _taxPercentCtrl,
                  keyboard:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
              const SizedBox(height: 6),
              SwitchTile(
                title: l.enableDiscount,
                value: _discountEnabled,
                onChanged: (v) {
                  setState(() {
                    _discountEnabled = v;
                    if (v && _discountPercentCtrl.text.trim().isEmpty) {
                      _discountPercentCtrl.text = '5';
                    }
                  });
                  _persistIfExisting();
                },
              ),
              if (_discountEnabled) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final rate in _discountShortCodes)
                      _ShortCodeChip(
                        label: '$rate%',
                        selected: _selectedDiscountShortCode == rate,
                        onTap: () => _onSelectDiscountShortCode(rate),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _field(
                  l.defaultDiscountPercent,
                  _discountPercentCtrl,
                  keyboard:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l.paymentMethod,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              EnumSegment<PaymentMethod>(
                label: l.paymentMethod,
                values: PaymentMethod.values,
                labelOf: (m) => switch (m) {
                  PaymentMethod.cash => l.paymentMethodCash,
                  PaymentMethod.qr => l.paymentMethodQr,
                  PaymentMethod.bankTransfer => l.paymentMethodBankTransfer,
                  PaymentMethod.other => l.paymentMethodOther,
                },
                selected: _paymentMethod,
                onChanged: (m) {
                  setState(() => _paymentMethod = m);
                  _persistIfExisting();
                },
              ),
              const SizedBox(height: 8),
              SwitchTile(
                title: l.enableOtherCharges,
                value: _otherChargesEnabled,
                onChanged: (v) {
                  setState(() => _otherChargesEnabled = v);
                  _persistIfExisting();
                },
              ),
              if (_otherChargesEnabled) ...[
                const SizedBox(height: 6),
                _field(l.otherChargesLabel, _otherNoteCtrl),
              ],
            ],
          ),
          SectionCard(
            title: l.invoiceNumber,
            children: [
              _field(l.invoicePrefixLabel, _prefixCtrl),
              _field(
                l.numberOfDigitsLabel,
                _digitsCtrl,
                keyboard: TextInputType.number,
              ),
              SwitchTile(
                title: l.fiscalYearPrefix,
                value: _fiscalYearPrefix,
                onChanged: (v) {
                  setState(() => _fiscalYearPrefix = v);
                  _persistIfExisting();
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l.invoiceNumberPreview(previewNumber),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _canSave ? _save : null,
            icon: const Icon(Icons.save),
            label: Text(l.save),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _ShortCodeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ShortCodeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = selected
        ? (isDark
            ? cs.primary.withValues(alpha: 0.28)
            : cs.primaryContainer)
        : (isDark
            ? cs.surfaceContainerLow
            : cs.surfaceContainerLowest);

    final borderColor = selected
        ? cs.primary
        : cs.outlineVariant.withValues(alpha: 0.7);

    final textColor = selected
        ? (isDark ? cs.primary : cs.onPrimaryContainer)
        : cs.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: selected ? 1.6 : 1.0,
        ),
      ),
      child: SizedBox(
        width: 64,
        height: 38,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontFamilyFallback: const ['NotoSansDevanagari'],
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

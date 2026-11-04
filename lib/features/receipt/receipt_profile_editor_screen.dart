/// Unified receipt profile editor: profile name, organization details,
/// receipt language/date/margin options, field visibility, alignment/size,
/// and header/footer messages in a single screen.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../localization/app_localizations.dart';
import '../../shared/controllers/app_state.dart';
import '../../shared/models/app_settings.dart';
import '../../shared/models/organization.dart';
import '../../shared/models/receipt_profile.dart';
import '../../shared/models/receipt_settings.dart';
import '../../shared/widgets/widgets_extra.dart';

class ReceiptProfileEditorScreen extends StatefulWidget {
  final ReceiptProfile profile;
  final bool isNew;

  const ReceiptProfileEditorScreen({
    super.key,
    required this.profile,
    this.isNew = false,
  });

  @override
  State<ReceiptProfileEditorScreen> createState() =>
      _ReceiptProfileEditorScreenState();
}

class _ReceiptProfileEditorScreenState
    extends State<ReceiptProfileEditorScreen> {
  final _profileName = TextEditingController();
  String? _nameError;

  // Organization controllers
  final _nameEn = TextEditingController();
  final _nameNe = TextEditingController();
  final _addrEn = TextEditingController();
  final _addrNe = TextEditingController();
  final _phone = TextEditingController();
  final _altPhone = TextEditingController();
  final _email = TextEditingController();
  final _pan = TextEditingController();
  final _vat = TextEditingController();
  final _reg = TextEditingController();
  final _website = TextEditingController();
  final _customEn = TextEditingController();
  final _customNe = TextEditingController();
  final _logoPath = TextEditingController();

  // Receipt message controllers
  final _welcomeEn = TextEditingController();
  final _welcomeNe = TextEditingController();
  final _thankEn = TextEditingController();
  final _thankNe = TextEditingController();
  final _policyEn = TextEditingController();
  final _policyNe = TextEditingController();
  final _termsEn = TextEditingController();
  final _termsNe = TextEditingController();
  final _promoEn = TextEditingController();
  final _promoNe = TextEditingController();
  final _extraEn = TextEditingController();
  final _extraNe = TextEditingController();

  // Receipt language & format options
  late InvoiceLanguageMode _langMode;
  late bool _useBs;
  late bool _longDate;
  late bool _showTime;
  late bool _bottomMargin;

  // Receipt design toggles & options
  late bool _showLogo;
  late bool _showAddress;
  late bool _showPhone;
  late bool _showEmail;
  late bool _showWebsite;
  late bool _showPanVat;
  late bool _showCustomer;
  late bool _showPayment;
  late ReceiptHeaderAlign _align;
  late ReceiptTextSize _size;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    final org = p.organization;
    final r = p.receipt;

    _profileName.text = p.name;
    _profileName.addListener(_onProfileNameChanged);
    _nameEn.addListener(_onProfileNameChanged);
    _nameNe.addListener(_onProfileNameChanged);

    _nameEn.text = org.nameEn;
    _nameNe.text = org.nameNe;
    _addrEn.text = org.addressEn;
    _addrNe.text = org.addressNe;
    _phone.text = org.phone;
    _altPhone.text = org.alternativePhone;
    _email.text = org.email;
    _pan.text = org.panNumber;
    _vat.text = org.vatNumber;
    _reg.text = org.registrationNumber;
    _website.text = org.website;
    _customEn.text = org.customInfoEn;
    _customNe.text = org.customInfoNe;
    _logoPath.text = org.logoPath;

    _langMode = p.invoiceLanguageMode;
    _useBs = p.useBikramSambat;
    _longDate = p.longDateStyle;
    _showTime = p.showTimeOnReceipt;
    _bottomMargin = p.bottomMarginOnReceipt;

    _welcomeEn.text = r.welcomeEn;
    _welcomeNe.text = r.welcomeNe;
    _thankEn.text = r.thankEn;
    _thankNe.text = r.thankNe;
    _policyEn.text = r.policyEn;
    _policyNe.text = r.policyNe;
    _termsEn.text = r.termsEn;
    _termsNe.text = r.termsNe;
    _promoEn.text = r.promoEn;
    _promoNe.text = r.promoNe;
    _extraEn.text = r.extraEn;
    _extraNe.text = r.extraNe;

    _showLogo = r.showLogo;
    _showAddress = r.showAddress;
    _showPhone = r.showPhone;
    _showEmail = r.showEmail;
    _showWebsite = r.showWebsite;
    _showPanVat = r.showPanVat;
    _showCustomer = r.showCustomer;
    _showPayment = r.showPayment;
    _align = r.headerAlign;
    _size = r.textSize;
  }

  bool get _canSave {
    final rawName = _profileName.text.trim();
    final effective = rawName.isNotEmpty
        ? rawName
        : (_nameEn.text.trim().isNotEmpty ? _nameEn.text.trim() : _nameNe.text.trim());
    return effective.isNotEmpty;
  }

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
    _nameEn.removeListener(_onProfileNameChanged);
    _nameNe.removeListener(_onProfileNameChanged);
    _profileName.dispose();
    _nameEn.dispose();
    _nameNe.dispose();
    _addrEn.dispose();
    _addrNe.dispose();
    _phone.dispose();
    _altPhone.dispose();
    _email.dispose();
    _pan.dispose();
    _vat.dispose();
    _reg.dispose();
    _website.dispose();
    _customEn.dispose();
    _customNe.dispose();
    _logoPath.dispose();
    _welcomeEn.dispose();
    _welcomeNe.dispose();
    _thankEn.dispose();
    _thankNe.dispose();
    _policyEn.dispose();
    _policyNe.dispose();
    _termsEn.dispose();
    _termsNe.dispose();
    _promoEn.dispose();
    _promoNe.dispose();
    _extraEn.dispose();
    _extraNe.dispose();
    super.dispose();
  }

  ReceiptProfile _buildProfile() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final baseOrg = widget.profile.organization;
    final org = Organization(
      id: baseOrg.id,
      nameEn: _nameEn.text.trim(),
      nameNe: _nameNe.text.trim(),
      addressEn: _addrEn.text.trim(),
      addressNe: _addrNe.text.trim(),
      phone: _phone.text.trim(),
      alternativePhone: _altPhone.text.trim(),
      email: _email.text.trim(),
      panNumber: _pan.text.trim(),
      vatNumber: _vat.text.trim(),
      registrationNumber: _reg.text.trim(),
      website: _website.text.trim(),
      logoPath: _logoPath.text.trim(),
      customInfoEn: _customEn.text.trim(),
      customInfoNe: _customNe.text.trim(),
      createdAt: baseOrg.createdAt == 0 ? now : baseOrg.createdAt,
      updatedAt: now,
    );
    final receipt = widget.profile.receipt.copyWith(
      welcomeEn: _welcomeEn.text,
      welcomeNe: _welcomeNe.text,
      thankEn: _thankEn.text,
      thankNe: _thankNe.text,
      policyEn: _policyEn.text,
      policyNe: _policyNe.text,
      termsEn: _termsEn.text,
      termsNe: _termsNe.text,
      promoEn: _promoEn.text,
      promoNe: _promoNe.text,
      extraEn: _extraEn.text,
      extraNe: _extraNe.text,
      showLogo: _showLogo,
      showAddress: _showAddress,
      showPhone: _showPhone,
      showEmail: _showEmail,
      showWebsite: _showWebsite,
      showPanVat: _showPanVat,
      showCustomer: _showCustomer,
      showPayment: _showPayment,
      headerAlign: _align,
      textSize: _size,
    );
    final rawName = _profileName.text.trim();
    final effectiveName = rawName.isNotEmpty
        ? rawName
        : (org.nameEn.isNotEmpty ? org.nameEn : org.nameNe);
    return widget.profile.copyWith(
      name: effectiveName,
      organization: org,
      invoiceLanguageMode: _langMode,
      useBikramSambat: _useBs,
      longDateStyle: _longDate,
      showTimeOnReceipt: _showTime,
      bottomMarginOnReceipt: _bottomMargin,
      receipt: receipt,
    );
  }

  void _persistIfExisting() {
    if (widget.isNew) return;
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    final built = _buildProfile();
    final candidateName = built.displayTitle(l.defaultProfileName);
    if (app.hasReceiptProfileName(
      candidateName,
      excludeId: widget.profile.id,
      defaultName: l.defaultProfileName,
    )) {
      return;
    }
    app.saveProfile(
      built,
      makeActive: app.activeProfileId == widget.profile.id,
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    final nav = Navigator.of(context);
    final built = _buildProfile();
    final candidateName = built.displayTitle(l.defaultProfileName);

    if (candidateName.trim().isEmpty) {
      setState(() => _nameError = l.profileNameRequiredError);
      showAppSnackBar(context, l.profileNameRequiredError);
      return;
    }

    if (app.hasReceiptProfileName(
      candidateName,
      excludeId: widget.profile.id,
      defaultName: l.defaultProfileName,
    )) {
      setState(() => _nameError = l.profileNameExistsError);
      showAppSnackBar(context, l.profileNameExistsError);
      return;
    }

    setState(() => _nameError = null);
    await app.saveProfile(built, makeActive: true);
    if (!mounted) return;
    showAppSnackBar(context, l.profileSavedMsg);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? l.addReceiptProfile : l.editReceiptProfile),
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
            title: l.orgInformation,
            children: [
              _field(l.orgNameEn, _nameEn),
              _field(l.orgNameNe, _nameNe),
              _field(l.orgAddressEn, _addrEn),
              _field(l.orgAddressNe, _addrNe),
              _field(l.phoneLabel, _phone, keyboard: TextInputType.phone),
              _field(l.altPhoneLabel, _altPhone, keyboard: TextInputType.phone),
              _field(
                l.emailLabel,
                _email,
                keyboard: TextInputType.emailAddress,
              ),
              _field(l.panNumberLabel, _pan),
              _field(l.vatNumberLabel, _vat),
              _field(l.registrationNumberLabel, _reg),
              _field(l.websiteLabel, _website),
              _field(l.orgCustomInfoEn, _customEn),
              _field(l.orgCustomInfoNe, _customNe),
              _field(l.logoLabel, _logoPath),
            ],
          ),
          SectionCard(
            title: l.receiptSection,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  l.invoiceLanguageSetting,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              EnumSegment<InvoiceLanguageMode>(
                label: l.invoiceLanguageSetting,
                values: InvoiceLanguageMode.values,
                labelOf: (m) => switch (m) {
                  InvoiceLanguageMode.followApp => l.invoiceLanguageFollowApp,
                  InvoiceLanguageMode.en => l.invoiceLanguageEnglish,
                  InvoiceLanguageMode.ne => l.invoiceLanguageNepali,
                },
                selected: _langMode,
                onChanged: (m) {
                  setState(() => _langMode = m);
                  _persistIfExisting();
                },
              ),
              const SizedBox(height: 8),
              SwitchTile(
                title: l.bikramSambatCalendar,
                value: _useBs,
                onChanged: (v) {
                  setState(() => _useBs = v);
                  _persistIfExisting();
                },
              ),
              SwitchTile(
                title: l.dateStyleLongMonth,
                value: _longDate,
                onChanged: (v) {
                  setState(() => _longDate = v);
                  _persistIfExisting();
                },
              ),
              SwitchTile(
                title: l.showTimeOnReceipt,
                value: _showTime,
                onChanged: (v) {
                  setState(() => _showTime = v);
                  _persistIfExisting();
                },
              ),
              SwitchTile(
                title: l.bottomMarginOnReceipt,
                value: _bottomMargin,
                onChanged: (v) {
                  setState(() => _bottomMargin = v);
                  _persistIfExisting();
                },
              ),
            ],
          ),
          SectionCard(
            title: l.visibleFields,
            children: [
              SwitchTile(
                title: l.showPanVat,
                value: _showPanVat,
                onChanged: (v) {
                  setState(() => _showPanVat = v);
                  _persistIfExisting();
                },
              ),
              SwitchTile(
                title: l.showAddress,
                value: _showAddress,
                onChanged: (v) {
                  setState(() => _showAddress = v);
                  _persistIfExisting();
                },
              ),
              SwitchTile(
                title: l.showPhone,
                value: _showPhone,
                onChanged: (v) {
                  setState(() => _showPhone = v);
                  _persistIfExisting();
                },
              ),
              SwitchTile(
                title: l.showEmail,
                value: _showEmail,
                onChanged: (v) {
                  setState(() => _showEmail = v);
                  _persistIfExisting();
                },
              ),
              SwitchTile(
                title: l.showWebsite,
                value: _showWebsite,
                onChanged: (v) {
                  setState(() => _showWebsite = v);
                  _persistIfExisting();
                },
              ),
              SwitchTile(
                title: l.showCustomer,
                value: _showCustomer,
                onChanged: (v) {
                  setState(() => _showCustomer = v);
                  _persistIfExisting();
                },
              ),
              SwitchTile(
                title: l.showPayment,
                value: _showPayment,
                onChanged: (v) {
                  setState(() => _showPayment = v);
                  _persistIfExisting();
                },
              ),
              SwitchTile(
                title: l.showLogo,
                value: _showLogo,
                onChanged: (v) {
                  setState(() => _showLogo = v);
                  _persistIfExisting();
                },
              ),
            ],
          ),
          SectionCard(
            title: l.headerAlignmentLabel,
            children: [
              EnumSegment<ReceiptHeaderAlign>(
                label: l.headerAlignmentLabel,
                values: const [
                  ReceiptHeaderAlign.left,
                  ReceiptHeaderAlign.center,
                ],
                labelOf: (a) => switch (a) {
                  ReceiptHeaderAlign.left => l.alignLeft,
                  ReceiptHeaderAlign.center => l.alignCenter,
                },
                selected: _align,
                onChanged: (a) {
                  setState(() => _align = a);
                  _persistIfExisting();
                },
              ),
            ],
          ),
          SectionCard(
            title: l.textSizeLabel,
            children: [
              EnumSegment<ReceiptTextSize>(
                label: l.textSizeLabel,
                values: const [
                  ReceiptTextSize.small,
                  ReceiptTextSize.normal,
                  ReceiptTextSize.large,
                ],
                labelOf: (s) => switch (s) {
                  ReceiptTextSize.small => l.textSizeSmall,
                  ReceiptTextSize.normal => l.textSizeMedium,
                  ReceiptTextSize.large => l.textSizeLarge,
                },
                selected: _size,
                onChanged: (s) {
                  setState(() => _size = s);
                  _persistIfExisting();
                },
              ),
            ],
          ),
          SectionCard(
            title: l.headerMessages,
            children: [
              _msgRow(l.welcomeMessage, _welcomeEn, _welcomeNe),
              _msgRow(l.thankYouMessage, _thankEn, _thankNe),
              _msgRow(l.returnPolicy, _policyEn, _policyNe),
              _msgRow(l.paymentTerms, _termsEn, _termsNe),
              _msgRow(l.promoMessage, _promoEn, _promoNe),
              _msgRow(l.additionalMessage, _extraEn, _extraNe),
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

  Widget _msgRow(
    String title,
    TextEditingController en,
    TextEditingController ne,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: en,
          decoration: InputDecoration(
            labelText: '$title (EN)',
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ne,
          decoration: InputDecoration(
            labelText: '$title (नेपाली)',
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}


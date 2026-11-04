/// Organization editor: bilingual legal name / address plus contact,
/// tax, brand and custom fields; persisted as the single active org row and
/// snapshotted into every finalized invoice.
library;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/db/app_database.dart';
import '../../localization/app_localizations.dart';
import '../../shared/controllers/app_state.dart';
import '../../shared/models/organization.dart';
import '../../shared/repositories/organization_repository.dart';
import '../../shared/widgets/widgets_extra.dart';

class OrganizationEditorScreen extends StatefulWidget {
  const OrganizationEditorScreen({super.key});

  @override
  State<OrganizationEditorScreen> createState() =>
      _OrganizationEditorScreenState();
}

class _OrganizationEditorScreenState extends State<OrganizationEditorScreen> {
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

  @override
  void initState() {
    super.initState();
    final org = context.read<AppState>().organization;
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
    _nameEn.addListener(_onNameChanged);
    _nameNe.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSave =>
      _nameEn.text.trim().isNotEmpty || _nameNe.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameEn.removeListener(_onNameChanged);
    _nameNe.removeListener(_onNameChanged);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.orgInformation)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.orgInformation,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _field(l.orgNameEn, _nameEn, l.enterOrgName, required: true),
                  _field(l.orgNameNe, _nameNe, l.enterOrgName, required: true),
                  _field(l.orgAddressEn, _addrEn, l.optional, required: false),
                  _field(l.orgAddressNe, _addrNe, l.optional, required: false),
                  _field(l.phoneLabel, _phone, l.phoneOrContactRequired,
                      required: true, keyboard: TextInputType.phone),
                  _field(l.altPhoneLabel, _altPhone, l.optional, required: false),
                  _field(l.emailLabel, _email, l.emailInvalid,
                      required: false, keyboard: TextInputType.emailAddress),
                  _field(l.panNumberLabel, _pan, l.optional, required: false),
                  _field(l.vatNumberLabel, _vat, l.optional, required: false),
                  _field(l.registrationNumberLabel, _reg, l.optional, required: false),
                  _field(l.websiteLabel, _website, l.optional, required: false),
                  _field(l.orgCustomInfoEn, _customEn, l.optional, required: false),
                  _field(l.orgCustomInfoNe, _customNe, l.optional, required: false),
                  _field(l.logoLabel, _logoPath, l.pickLogo, required: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _canSave ? _save : null,
            icon: const Icon(Icons.save),
            label: Text(l.save),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String? error,
    {required bool required, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) {
                if ((v ?? '').trim().isEmpty) return label;
                return null;
              }
            : null,
      ),
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    final org = Organization(
      id: app.organization.id,
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
      createdAt: app.organization.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    if (org.isConfigured) {
      await app.saveOrganization(org);
      if (!context.mounted) return;
      showAppSnackBar(context, l.orgSavedMsg);
      Navigator.pop(context);
      return;
    }
    if (org.nameEn.trim().isEmpty && org.nameNe.trim().isEmpty) {
      if (!context.mounted) return;
      showAppSnackBar(context, l.enterOrgName);
      return;
    }
    final saved = await OrganizationRepository(
      open: () => AppDatabase.open,
    ).upsert(org);
    await app.saveOrganization(saved);
    if (!context.mounted) return;
    showAppSnackBar(context, l.orgSavedMsg);
    Navigator.pop(context);
  }
}

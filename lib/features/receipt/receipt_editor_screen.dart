/// Receipt template editor: header/footer messages, visibility toggles,
/// header alignment and text size. Persists through the shared AppState.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../localization/app_localizations.dart';
import '../../shared/controllers/app_state.dart';
import '../../shared/models/receipt_settings.dart';
import '../../shared/widgets/widgets_extra.dart';

class ReceiptEditorScreen extends StatefulWidget {
  const ReceiptEditorScreen({super.key});

  @override
  State<ReceiptEditorScreen> createState() => _ReceiptEditorScreenState();
}

class _ReceiptEditorScreenState extends State<ReceiptEditorScreen> {
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
  bool _showLogo = false;
  bool _showAddress = true;
  bool _showPhone = true;
  bool _showEmail = false;
  bool _showWebsite = false;
  bool _showPanVat = false;
  bool _showCustomer = true;
  bool _showPayment = true;
  ReceiptHeaderAlign _align = ReceiptHeaderAlign.center;
  ReceiptTextSize _size = ReceiptTextSize.normal;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final r = app.receipt;
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

  @override
  void dispose() {
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

  ReceiptSettings _buildCurrent(ReceiptSettings base) => base.copyWith(
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

  Future<void> _persistNow() async {
    final app = context.read<AppState>();
    await app.saveReceipt(_buildCurrent(app.receipt));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.read<AppState>();
    final r = app.receipt;
    return Scaffold(
      appBar: AppBar(title: Text(l.receiptDesign)),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
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
          SectionCard(
            title: l.visibleFields,
            children: [
              SwitchTile(
                title: l.showLogo,
                value: _showLogo,
                onChanged: (v) {
                  setState(() => _showLogo = v);
                  _persistNow();
                },
              ),
              SwitchTile(
                title: l.showAddress,
                value: _showAddress,
                onChanged: (v) {
                  setState(() => _showAddress = v);
                  _persistNow();
                },
              ),
              SwitchTile(
                title: l.showPhone,
                value: _showPhone,
                onChanged: (v) {
                  setState(() => _showPhone = v);
                  _persistNow();
                },
              ),
              SwitchTile(
                title: l.showEmail,
                value: _showEmail,
                onChanged: (v) {
                  setState(() => _showEmail = v);
                  _persistNow();
                },
              ),
              SwitchTile(
                title: l.showWebsite,
                value: _showWebsite,
                onChanged: (v) {
                  setState(() => _showWebsite = v);
                  _persistNow();
                },
              ),
              SwitchTile(
                title: l.showPanVat,
                value: _showPanVat,
                onChanged: (v) {
                  setState(() => _showPanVat = v);
                  _persistNow();
                },
              ),
              SwitchTile(
                title: l.showCustomer,
                value: _showCustomer,
                onChanged: (v) {
                  setState(() => _showCustomer = v);
                  _persistNow();
                },
              ),
              SwitchTile(
                title: l.showPayment,
                value: _showPayment,
                onChanged: (v) {
                  setState(() => _showPayment = v);
                  _persistNow();
                },
              ),
            ],
          ),
          SectionCard(
            title: l.headerAlignmentLabel,
            children: [
              EnumSegment<ReceiptHeaderAlign>(
                label: l.headerAlignmentLabel,
                values: const [ReceiptHeaderAlign.left, ReceiptHeaderAlign.center],
                labelOf: (a) => switch (a) {
                  ReceiptHeaderAlign.left => l.alignLeft,
                  ReceiptHeaderAlign.center => l.alignCenter,
                },
                selected: _align,
                onChanged: (a) {
                  setState(() => _align = a);
                  _persistNow();
                },
              ),
            ],
          ),
          SectionCard(
            title: l.textSizeLabel,
            children: [
              EnumSegment<ReceiptTextSize>(
                label: l.textSizeLabel,
                values: const [ReceiptTextSize.small, ReceiptTextSize.normal, ReceiptTextSize.large],
                labelOf: (s) => switch (s) {
                  ReceiptTextSize.small => l.textSizeSmall,
                  ReceiptTextSize.normal => l.textSizeMedium,
                  ReceiptTextSize.large => l.textSizeLarge,
                },
                selected: _size,
                onChanged: (s) {
                  setState(() => _size = s);
                  _persistNow();
                },
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: () async {
              final next = _buildCurrent(r);
              await context.read<AppState>().saveReceipt(next);
              if (mounted) {
                showAppSnackBar(context, l.receiptSavedMsg);
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.save),
            label: Text(l.save),
          ),
        ],
      ),
    );
  }

  Widget _msgRow(String title, TextEditingController en, TextEditingController ne) {
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
            labelText: title,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ne,
          decoration: InputDecoration(
            labelText: title,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

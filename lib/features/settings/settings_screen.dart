/// Settings tab: general, receipt profiles, billing profiles, data and about
/// sections. Persists through the shared AppState; receipt profile editor and
/// billing profile editor open as pushed routes.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting/money.dart' as money;
import '../../localization/app_localizations.dart';
import '../../shared/app_wiring.dart';
import '../../shared/controllers/app_state.dart';
import '../../shared/models/app_settings.dart';
import '../../shared/models/billing_profile.dart';
import '../../shared/models/organization.dart';
import '../../shared/models/receipt_profile.dart';
import '../../shared/models/receipt_settings.dart';
import '../../shared/repositories/invoice_repository.dart';
import '../../shared/services/backup_service.dart';
import '../../shared/services/invoice_service.dart';
import '../../shared/widgets/widgets_extra.dart';
import '../billing/billing_profile_editor_screen.dart';
import '../receipt/receipt_profile_editor_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final settings = app.settings;

    return Scaffold(
      appBar: AppBar(title: Text(l.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          SectionCard(
            title: l.generalSection,
            children: [
              _EnumSection<AppLanguage>(
                title: l.languageSectionTitle,
                values: AppLanguage.values,
                labelOf: (a) => switch (a) {
                  AppLanguage.en => l.invoiceLanguageEnglish,
                  AppLanguage.ne => l.invoiceLanguageNepali,
                },
                value: settings.appLanguage,
                onChanged: app.setAppLanguage,
              ),
              _EnumSection<ThemeChoice>(
                title: l.themeModeLabel,
                values: ThemeChoice.values,
                labelOf: (t) => switch (t) {
                  ThemeChoice.light => l.themeLight,
                  ThemeChoice.dark => l.themeDark,
                  ThemeChoice.system => l.themeSystem,
                },
                value: settings.theme,
                onChanged: (t) => app.setTheme(t),
              ),
              _EnumSection<int>(
                title: l.quantityPrecisionLabel,
                values: const [0, 1, 2, 3],
                labelOf: (n) => n.toString(),
                value: settings.quantityPrecision,
                onChanged: (n) => app.setQuantityPrecision(n),
              ),
            ],
          ),
          SectionCard(
            title: l.receiptProfilesSection,
            children: [
              for (final p in app.profiles)
                _ProfileRow(
                  profile: p,
                  isActive: p.id == app.activeProfileId,
                  canDelete: app.profiles.length > 1,
                  onSelect: () => app.selectProfile(p.id),
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReceiptProfileEditorScreen(
                        profile: p,
                        isNew: false,
                      ),
                    ),
                  ),
                  onDelete: () => app.deleteProfile(p.id),
                ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  final fresh = ReceiptProfile(
                    id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
                    name: '',
                    organization: Organization.empty,
                    invoiceLanguageMode: settings.invoiceLanguageMode,
                    useBikramSambat: settings.useBikramSambat,
                    longDateStyle: settings.longDateStyle,
                    showTimeOnReceipt: settings.showTimeOnReceipt,
                    bottomMarginOnReceipt: settings.bottomMarginOnReceipt,
                    receipt: ReceiptSettings.defaults,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReceiptProfileEditorScreen(
                        profile: fresh,
                        isNew: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: Text(l.addReceiptProfile),
              ),
            ],
          ),
          SectionCard(
            title: l.billingProfilesSection,
            children: [
              for (final bp in app.billingProfiles)
                _BillingProfileRow(
                  profile: bp,
                  settings: settings,
                  isActive: bp.id == app.activeBillingProfileId,
                  canDelete: app.billingProfiles.length > 1,
                  onSelect: () => app.selectBillingProfile(bp.id),
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BillingProfileEditorScreen(
                        profile: bp,
                        isNew: false,
                      ),
                    ),
                  ),
                  onDelete: () => app.deleteBillingProfile(bp.id),
                ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  final fresh = BillingProfile(
                    id: 'billing_${DateTime.now().millisecondsSinceEpoch}',
                    name: '',
                    taxEnabled: settings.taxEnabled,
                    taxPercent: settings.taxPercent,
                    defaultDiscountPercent: settings.defaultDiscountPercent,
                    otherChargesEnabled: settings.otherChargesEnabled,
                    otherChargesNote: settings.otherChargesNote,
                    defaultPaymentMethod: settings.defaultPaymentMethod,
                    invoicePrefix: settings.invoicePrefix,
                    invoiceDigits: settings.invoiceDigits,
                    fiscalYearPrefix: settings.fiscalYearPrefix,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BillingProfileEditorScreen(
                        profile: fresh,
                        isNew: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: Text(l.addBillingProfile),
              ),
            ],
          ),
          SectionCard(
            title: l.dataSection,
            children: [
              FilledButton.tonalIcon(
                onPressed: () async {
                  final service = const BackupService();
                  final file = await service.createBackup();
                  if (!context.mounted) return;
                  showAppSnackBar(context, '${l.backupCreatedMsg} ${file.path}');
                },
                icon: const Icon(Icons.save_alt),
                label: Text(l.createBackup),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final files = await const BackupService().listBackups();
                  if (files.isEmpty) {
                    if (context.mounted) {
                      showAppSnackBar(context, l.noBackupsAvailable);
                    }
                    return;
                  }
                  final file = files.firstWhere((f) => f.existsSync());
                  final ok = await showConfirmDialog(
                    context,
                    title: l.restoreBackup,
                    message: l.restoreBackupConfirm,
                    positiveLabel: l.restoreBackup,
                  );
                  if (ok && context.mounted) {
                    await const BackupService().restoreBackup(file.path);
                    await app.reloadAll();
                    if (context.mounted) {
                      showAppSnackBar(context, l.restoredMsg);
                    }
                  }
                },
                icon: const Icon(Icons.restore),
                label: Text(l.restoreBackup),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final invoices =
                      await AppWiring.invoices.list(const InvoiceFilter());
                  final f =
                      await const BackupService().exportInvoicesCsv(invoices);
                  if (context.mounted) {
                    showAppSnackBar(context, '${l.exportDoneMsg} ${f.path}');
                  }
                },
                icon: const Icon(Icons.download),
                label: Text(l.exportInvoicesCsv),
              ),
            ],
          ),
          SectionCard(
            title: l.aboutSection,
            children: [
              Text(l.aboutAppText),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final ReceiptProfile profile;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProfileRow({
    required this.profile,
    required this.isActive,
    required this.canDelete,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final title = profile.displayTitle(l.defaultProfileName);
    final orgName = profile.organization.nameEn.trim().isNotEmpty
        ? profile.organization.nameEn.trim()
        : profile.organization.nameNe.trim();
    final langLabel = switch (profile.invoiceLanguageMode) {
      InvoiceLanguageMode.followApp => l.invoiceLanguageFollowApp,
      InvoiceLanguageMode.en => l.invoiceLanguageEnglish,
      InvoiceLanguageMode.ne => l.invoiceLanguageNepali,
    };
    final subtitleParts = <String>[
      if (orgName.isNotEmpty && orgName != title) orgName,
      langLabel,
      if (profile.organization.panNumber.trim().isNotEmpty)
        'PAN: ${profile.organization.panNumber.trim()}',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isActive
            ? cs.primaryContainer.withValues(alpha: 0.45)
            : cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isActive
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w600,
                            ),
                      ),
                      if (subtitleParts.isNotEmpty)
                        Text(
                          subtitleParts.join(' • '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l.edit,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                if (canDelete)
                  IconButton(
                    tooltip: l.delete,
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BillingProfileRow extends StatelessWidget {
  final BillingProfile profile;
  final AppSettings settings;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BillingProfileRow({
    required this.profile,
    required this.settings,
    required this.isActive,
    required this.canDelete,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final title = profile.displayTitle(l.defaultBillingProfileName);
    final previewSettings = settings.copyWith(
      invoicePrefix: profile.invoicePrefix,
      invoiceDigits: profile.invoiceDigits,
      fiscalYearPrefix: profile.fiscalYearPrefix,
    );
    final numberSample = InvoiceService.numberFor(
      previewSettings,
      settings.invoiceNext,
      DateTime.now(),
    );
    final taxSummary = profile.taxEnabled && profile.taxPercent > 0
        ? '${l.tax}: ${money.formatScaled(profile.taxPercent, scale: money.percentScale)}%'
        : null;
    final discVal = profile.defaultDiscountPercent > 50
        ? (profile.defaultDiscountPercent ~/ 100)
        : profile.defaultDiscountPercent;
    final discSummary = discVal > 0 ? '${l.discount}: $discVal%' : null;
    final subtitleParts = <String>[
      numberSample,
      if (taxSummary != null) taxSummary,
      if (discSummary != null) discSummary,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isActive
            ? cs.primaryContainer.withValues(alpha: 0.45)
            : cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isActive
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w600,
                            ),
                      ),
                      if (subtitleParts.isNotEmpty)
                        Text(
                          subtitleParts.join(' • '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l.edit,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                if (canDelete)
                  IconButton(
                    tooltip: l.delete,
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnumSection<T> extends StatelessWidget {
  final String title;
  final List<T> values;
  final String Function(T) labelOf;
  final T value;
  final ValueChanged<T> onChanged;

  const _EnumSection({
    super.key,
    required this.title,
    required this.values,
    required this.labelOf,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        EnumSegment<T>(
          label: title,
          values: values,
          labelOf: labelOf,
          selected: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

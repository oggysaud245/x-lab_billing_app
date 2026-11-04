/// Invoice history: search, period filters, voided visibility, list of
/// finalized bills with print attempt counts.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting/dates.dart' as d;
import '../../localization/app_localizations.dart';
import '../../shared/app_wiring.dart';
import '../../shared/controllers/app_state.dart';
import '../../shared/models/app_settings.dart';
import '../../shared/models/invoice.dart';
import '../../shared/repositories/invoice_repository.dart';
import '../../shared/widgets/widgets_extra.dart';
import 'invoice_detail_screen.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

enum _Period {
  all,
  today,
  last7Days,
  month,
  threeMonths,
  sixMonths,
  year,
  custom,
}

class _InvoicesPageState extends State<InvoicesPage> {
  String _search = '';
  _Period _period = _Period.all;
  DateTime? _customFrom;
  DateTime? _customTo;
  bool _includeVoided = true;
  String? _selectedProfileId;

  List<Invoice>? _items;
  int _lastDataVersion = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = Provider.of<AppState>(context).dataVersion;
    if (_lastDataVersion != v) {
      _lastDataVersion = v;
      _reload();
    }
  }

  (int, int) _range() {
    final now = DateTime.now();
    switch (_period) {
      case _Period.all:
        return (0, 0);
      case _Period.today:
        return d.todayRange(now);
      case _Period.last7Days:
        return d.lastNDaysRange(now, 7);
      case _Period.month:
        return d.thisMonthRange(now);
      case _Period.threeMonths:
        return d.lastMonthsRange(now, 3);
      case _Period.sixMonths:
        return d.lastMonthsRange(now, 6);
      case _Period.year:
        return d.thisYearRange(now);
      case _Period.custom:
        if (_customFrom == null || _customTo == null) return (0, 0);
        final start = DateTime(
          _customFrom!.year,
          _customFrom!.month,
          _customFrom!.day,
        );
        final end = DateTime(
          _customTo!.year,
          _customTo!.month,
          _customTo!.day,
          23,
          59,
          59,
          999,
        );
        return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
    }
  }

  Future<void> _reload() async {
    final (from, to) = _range();
    final items = await AppWiring.invoices.list(InvoiceFilter(
      search: _search,
      fromMillis: from,
      toMillis: to,
      includeVoided: _includeVoided,
    ));
    if (!mounted) return;
    setState(() => _items = items);
  }

  String _formatDateShort(DateTime dt, AppSettings settings) {
    return d.formatReceiptDate(
      dt,
      system: settings.useBikramSambat ? d.DateSystem.bs : d.DateSystem.ad,
      style: d.DateStyle.numeric,
      nepaliNames: settings.appLanguage.isNepali,
      devanagariNumerals: settings.appLanguage.isNepali ||
          settings.numeralFormat.isDevanagari,
    );
  }

  String _formatDateDisplay(DateTime dt, AppSettings settings) {
    final primary = d.formatReceiptDate(
      dt,
      system: settings.useBikramSambat ? d.DateSystem.bs : d.DateSystem.ad,
      style: d.DateStyle.numeric,
      nepaliNames: settings.appLanguage.isNepali,
      devanagariNumerals: settings.appLanguage.isNepali ||
          settings.numeralFormat.isDevanagari,
    );
    final secondary = d.formatReceiptDate(
      dt,
      system: settings.useBikramSambat ? d.DateSystem.ad : d.DateSystem.bs,
      style: d.DateStyle.numeric,
      nepaliNames: settings.appLanguage.isNepali,
      devanagariNumerals: settings.appLanguage.isNepali ||
          settings.numeralFormat.isDevanagari,
    );
    return '$primary  ($secondary)';
  }

  String _dateFilterLabel(AppLocalizations l, AppSettings settings) {
    switch (_period) {
      case _Period.all:
        return l.filterAllTime;
      case _Period.today:
        return l.filterToday;
      case _Period.last7Days:
        return l.filterLast7Days;
      case _Period.month:
        return l.filterThisMonth;
      case _Period.threeMonths:
        return l.filter3Months;
      case _Period.sixMonths:
        return l.filter6Months;
      case _Period.year:
        return l.filterThisYear;
      case _Period.custom:
        if (_customFrom != null && _customTo != null) {
          final fromStr = _formatDateShort(_customFrom!, settings);
          final toStr = _formatDateShort(_customTo!, settings);
          return '$fromStr – $toStr';
        }
        return l.filterCustomRange;
    }
  }

  Future<void> _openCustomDateRangeDialog(
    BuildContext context,
    AppLocalizations l,
    AppSettings settings,
  ) async {
    DateTime from =
        _customFrom ?? DateTime.now().subtract(const Duration(days: 7));
    DateTime to = _customTo ?? DateTime.now();

    final result = await showDialog<_DateRangeResult>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final fromDisplay = _formatDateDisplay(from, settings);
            final toDisplay = _formatDateDisplay(to, settings);

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.date_range_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.filterCustomRange)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DatePickTile(
                      label: l.fromDate,
                      display: fromDisplay,
                      icon: Icons.calendar_today_outlined,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: from,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          helpText: l.fromDate,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            from = picked;
                            if (from.isAfter(to)) {
                              to = from;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _DatePickTile(
                      label: l.toDate,
                      display: toDisplay,
                      icon: Icons.event_outlined,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: to,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          helpText: l.toDate,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            to = picked;
                            if (to.isBefore(from)) {
                              from = to;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: ctx,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          initialDateRange: DateTimeRange(start: from, end: to),
                          helpText: l.dateRange,
                        );
                        if (range != null) {
                          setDialogState(() {
                            from = range.start;
                            to = range.end;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: Text(l.pickDateRangeCalendar),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          label: Text(l.filterToday),
                          onPressed: () {
                            setDialogState(() {
                              final now = DateTime.now();
                              from = DateTime(now.year, now.month, now.day);
                              to = from;
                            });
                          },
                        ),
                        ActionChip(
                          label: Text(l.filterLast7Days),
                          onPressed: () {
                            setDialogState(() {
                              final now = DateTime.now();
                              to = DateTime(now.year, now.month, now.day);
                              from = to.subtract(const Duration(days: 6));
                            });
                          },
                        ),
                        ActionChip(
                          label: Text(l.filterThisMonth),
                          onPressed: () {
                            setDialogState(() {
                              final now = DateTime.now();
                              from = DateTime(now.year, now.month, 1);
                              to = DateTime(now.year, now.month + 1, 0);
                            });
                          },
                        ),
                        ActionChip(
                          label: Text(l.filter3Months),
                          onPressed: () {
                            setDialogState(() {
                              final now = DateTime.now();
                              to = DateTime(now.year, now.month, now.day);
                              from = d.subtractMonths(to, 3);
                            });
                          },
                        ),
                        ActionChip(
                          label: Text(l.filter6Months),
                          onPressed: () {
                            setDialogState(() {
                              final now = DateTime.now();
                              to = DateTime(now.year, now.month, now.day);
                              from = d.subtractMonths(to, 6);
                            });
                          },
                        ),
                        ActionChip(
                          label: Text(l.filterThisYear),
                          onPressed: () {
                            setDialogState(() {
                              final now = DateTime.now();
                              from = DateTime(now.year, 1, 1);
                              to = DateTime(now.year, 12, 31);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                if (_period != _Period.all)
                  TextButton(
                    onPressed: () =>
                        Navigator.of(ctx).pop(_DateRangeResult.clear()),
                    child: Text(l.clearFilters),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(l.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(
                    _DateRangeResult.apply(from, to),
                  ),
                  child: Text(l.applyFilters),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    if (result.isClear) {
      setState(() {
        _period = _Period.all;
        _customFrom = null;
        _customTo = null;
      });
      _reload();
    } else if (result.from != null && result.to != null) {
      setState(() {
        _period = _Period.custom;
        _customFrom = result.from;
        _customTo = result.to;
      });
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = context.watch<AppState>();
    final items = _items;
    final filteredItems = items == null
        ? null
        : (_selectedProfileId == null
            ? items
            : items.where((inv) {
                final p = app.profiles
                    .where((prof) => prof.id == _selectedProfileId)
                    .firstOrNull;
                if (p == null) return true;
                return inv.matchesReceiptProfile(p, app.profiles);
              }).toList());

    return Scaffold(
      appBar: AppBar(title: Text(l.navInvoices)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.searchInvoices,
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (v) {
                      _search = v.trim();
                      _reload();
                    },
                    onSubmitted: (v) {
                      _search = v.trim();
                      _reload();
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: l.dateRange,
                  icon: Icon(
                    Icons.filter_list,
                    color: _period != _Period.all
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onSelected: (v) {
                    if (v == 'custom') {
                      _openCustomDateRangeDialog(context, l, app.settings);
                      return;
                    }
                    setState(() {
                      _period = switch (v) {
                        'today' => _Period.today,
                        'last7Days' => _Period.last7Days,
                        'month' => _Period.month,
                        'threeMonths' => _Period.threeMonths,
                        'sixMonths' => _Period.sixMonths,
                        'year' => _Period.year,
                        _ => _Period.all,
                      };
                      if (_period != _Period.custom) {
                        _customFrom = null;
                        _customTo = null;
                      }
                    });
                    _reload();
                  },
                  itemBuilder: (c) => [
                    for (final p in const [
                      ('all', _Period.all),
                      ('today', _Period.today),
                      ('last7Days', _Period.last7Days),
                      ('month', _Period.month),
                      ('threeMonths', _Period.threeMonths),
                      ('sixMonths', _Period.sixMonths),
                      ('year', _Period.year),
                      ('custom', _Period.custom),
                    ])
                      PopupMenuItem(
                        value: p.$1,
                        child: Row(
                          children: [
                            if (_period == p.$2)
                              const Icon(Icons.check, size: 18)
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 6),
                            Text(switch (p.$2) {
                              _Period.all => l.filterAllTime,
                              _Period.today => l.filterToday,
                              _Period.last7Days => l.filterLast7Days,
                              _Period.month => l.filterThisMonth,
                              _Period.threeMonths => l.filter3Months,
                              _Period.sixMonths => l.filter6Months,
                              _Period.year => l.filterThisYear,
                              _Period.custom => l.filterCustomRange,
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Row(
              children: [
                if (_period == _Period.all)
                  ActionChip(
                    avatar: const Icon(Icons.date_range_outlined, size: 16),
                    label: Text(l.dateRange),
                    onPressed: () =>
                        _openCustomDateRangeDialog(context, l, app.settings),
                  )
                else
                  InputChip(
                    selected: true,
                    showCheckmark: false,
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_dateFilterLabel(l, app.settings)),
                    onPressed: () =>
                        _openCustomDateRangeDialog(context, l, app.settings),
                    onDeleted: () {
                      setState(() {
                        _period = _Period.all;
                        _customFrom = null;
                        _customTo = null;
                      });
                      _reload();
                    },
                    deleteButtonTooltipMessage: l.clearFilters,
                  ),
                Container(
                  height: 24,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                ChoiceChip(
                  label: Text(l.allProfilesFilter),
                  selected: _selectedProfileId == null,
                  onSelected: (_) {
                    setState(() => _selectedProfileId = null);
                  },
                ),
                for (final p in app.profiles) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(p.displayTitle(l.defaultProfileName)),
                    selected: _selectedProfileId == p.id,
                    onSelected: (selected) {
                      setState(() {
                        _selectedProfileId = selected ? p.id : null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(l.statusVoided),
            value: _includeVoided,
            onChanged: (v) {
              setState(() => _includeVoided = v);
              _reload();
            },
          ),
          Expanded(
            child: filteredItems == null
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                    ? EmptyView(
                        text: _search.isEmpty &&
                                _selectedProfileId == null &&
                                _period == _Period.all
                            ? l.emptyInvoices
                            : l.emptyInvoicesSearch,
                        icon: Icons.receipt_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, i) {
                          final inv = filteredItems[i];
                          final voided = inv.status == InvoiceStatus.canceled;
                          final processing =
                              inv.status == InvoiceStatus.processing;
                          final profileTitle = inv.profileDisplayTitle(
                            app.profiles,
                            l.defaultProfileName,
                          );
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              voided
                                  ? Icons.cancel_outlined
                                  : (processing
                                      ? Icons.pending_actions_outlined
                                      : Icons.receipt),
                              color: voided
                                  ? Theme.of(context).colorScheme.error
                                  : (processing
                                      ? Colors.amber.shade800
                                      : null),
                            ),
                            title: Text(
                              inv.invoiceNumber,
                              style: TextStyle(
                                decoration: voided
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.formatReceiptDateMillis(
                                    inv.createdAt,
                                    system: inv.dateSystem == 'bs'
                                        ? d.DateSystem.bs
                                        : d.DateSystem.ad,
                                    style: inv.dateStyle == 'long'
                                        ? d.DateStyle.longMonth
                                        : d.DateStyle.numeric,
                                    withTime: true,
                                    nepaliNames:
                                        app.settings.appLanguage.isNepali,
                                    devanagariNumerals:
                                        app.settings.appLanguage.isNepali,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer
                                            .withValues(alpha: 0.7),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        profileTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(moneyText(
                                    app.settings, inv.totals.grandTotal)),
                                Text(
                                  switch (inv.status) {
                                    InvoiceStatus.processing =>
                                      l.statusProcessing,
                                    InvoiceStatus.success => l.statusSuccess,
                                    InvoiceStatus.canceled => l.statusCanceled,
                                  },
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: voided
                                            ? Theme.of(context).colorScheme.error
                                            : (processing
                                                ? Colors.amber.shade800
                                                : Colors.green.shade700),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.of(context).push(
                                InvoiceDetailScreen.route(inv),
                              );
                              _reload();
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _DatePickTile extends StatelessWidget {
  final String label;
  final String display;
  final IconData icon;
  final VoidCallback onTap;

  const _DatePickTile({
    required this.label,
    required this.display,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    display,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _DateRangeResult {
  final bool isClear;
  final DateTime? from;
  final DateTime? to;

  _DateRangeResult.clear()
      : isClear = true,
        from = null,
        to = null;

  _DateRangeResult.apply(DateTime f, DateTime t)
      : isClear = false,
        from = f,
        to = t;
}

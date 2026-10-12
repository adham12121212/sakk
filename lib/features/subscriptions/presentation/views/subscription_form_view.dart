import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/segmented_toggle.dart';
import '../../../scan/presentation/widgets/capsule_field.dart';
import '../../../scan/presentation/widgets/datex.dart';
import '../../../scan/presentation/widgets/field_label.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/catalog_service.dart';
import '../../domain/entities/subscription_category.dart';
import '../../domain/entities/user_subscription.dart';
import '../../domain/renewal_schedule.dart';
import '../cubit/subscription_form_cubit.dart';
import '../util/subscription_category_ui.dart';
import '../widgets/subscription_category_selector.dart';
import '../widgets/subscription_logo.dart';

/// What the form opens with: a catalog service (and maybe a plan), an
/// existing subscription to edit, or nothing for a custom one.
class SubscriptionFormArgs {
  const SubscriptionFormArgs.custom()
    : existing = null,
      service = null,
      plan = null;

  const SubscriptionFormArgs.fromCatalog(CatalogService this.service, this.plan)
    : existing = null;

  const SubscriptionFormArgs.edit(UserSubscription this.existing)
    : service = null,
      plan = null;

  final UserSubscription? existing;
  final CatalogService? service;

  /// Null for "Other plan": the user types the price.
  final CatalogPlan? plan;
}

/// Add flow, step 2 (confirm), and the edit screen. Pops with `true` once
/// the subscription is saved or deleted.
class SubscriptionFormView extends StatefulWidget {
  const SubscriptionFormView({super.key, required this.args});

  final SubscriptionFormArgs args;

  @override
  State<SubscriptionFormView> createState() => _SubscriptionFormViewState();
}

class _SubscriptionFormViewState extends State<SubscriptionFormView> {
  final _formKey = GlobalKey<FormState>();

  UserSubscription? get _existing => widget.args.existing;
  CatalogService? get _service => widget.args.service;
  CatalogPlan? get _plan => widget.args.plan;

  /// Catalog subscriptions show the service instead of a name field.
  bool get _fromCatalog =>
      _service != null || (_existing != null && !_existing!.isCustom);

  late final _nameController = TextEditingController(
    text: _existing?.customName ?? '',
  );
  late final _planController = TextEditingController(
    text: _existing?.planName ?? _plan?.name ?? '',
  );
  late final _priceController = TextEditingController(text: _initialPrice());
  late final _paymentController = TextEditingController(
    text: _existing?.paymentMethod ?? '',
  );
  late final _notesController = TextEditingController(
    text: _existing?.notes ?? '',
  );

  late SubscriptionCategory _category =
      _existing?.category ??
      _service?.category ??
      SubscriptionCategory.other;
  late String _currency =
      _existing?.currency ?? _plan?.currency ?? 'EGP';
  late BillingCycle _cycle =
      _existing?.billingCycle ??
      _plan?.billingCycle ??
      BillingCycle.monthly;
  late DateTime _renewalDate =
      _existing?.nextRenewalDate ?? _defaultRenewal(_cycle);

  /// Until the user picks a date, a new subscription's date follows the cycle.
  bool _dateTouched = false;

  static const _currencies = ['EGP', 'USD', 'EUR'];

  String _initialPrice() {
    final price = _existing?.price ?? _plan?.price;
    if (price == null) return '';
    return price == price.truncateToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
  }

  DateTime _defaultRenewal(BillingCycle cycle) =>
      addMonthsClamped(DateTime.now(), cycle.months);

  @override
  void dispose() {
    _nameController.dispose();
    _planController.dispose();
    _priceController.dispose();
    _paymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Accepts Arabic-Indic digits and the Arabic decimal separator.
  static double? _parsePrice(String raw) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final normalized = raw.trim().split('').map((c) {
      final i = arabic.indexOf(c);
      if (i >= 0) return '$i';
      return c == '٫' || c == ',' ? '.' : c;
    }).join();
    return double.tryParse(normalized);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final earliest = DateTime(today.year - 1, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _renewalDate,
      firstDate: _renewalDate.isBefore(earliest) ? _renewalDate : earliest,
      lastDate: DateTime(today.year + 5, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _renewalDate = picked;
        _dateTouched = true;
      });
    }
  }

  void _setCycle(BillingCycle cycle) {
    setState(() {
      _cycle = cycle;
      if (_existing == null && !_dateTouched) {
        _renewalDate = _defaultRenewal(cycle);
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SubscriptionFormCubit>().save(
      id: _existing?.id,
      catalogId: _existing?.catalogId ?? _service?.id,
      customName: _fromCatalog ? null : _nameController.text.trim(),
      planName: _emptyToNull(_planController.text),
      category: _category,
      price: _parsePrice(_priceController.text)!,
      currency: _currency,
      billingCycle: _cycle,
      nextRenewalDate: _renewalDate,
      paymentMethod: _emptyToNull(_paymentController.text),
      notes: _emptyToNull(_notesController.text),
    );
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final existing = _existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteSubscriptionQuestion),
        content: Text(l10n.deleteSubscriptionBody(existing.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<SubscriptionFormCubit>().delete(existing.id);
  }

  void _onStateChange(BuildContext context, SubscriptionFormState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state) {
      case SubscriptionFormSaved():
        AppSnackBar.success(context, l10n.subscriptionSaved);
        Navigator.of(context).pop(true);
      case SubscriptionFormDeleted():
        AppSnackBar.success(context, l10n.subscriptionDeleted);
        Navigator.of(context).pop(true);
      case SubscriptionFormFailure(:final message):
        AppSnackBar.error(context, userFacingError(l10n, message));
      case SubscriptionFormIdle() || SubscriptionFormBusy():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<SubscriptionFormCubit, SubscriptionFormState>(
      listener: _onStateChange,
      builder: (context, state) {
        final isBusy = state is SubscriptionFormBusy;
        final currencies = {..._currencies, _currency};

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _existing == null ? l10n.addSubscription : l10n.editSubscription,
            ),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            actions: [
              if (_existing != null)
                IconButton(
                  tooltip: l10n.delete,
                  icon: Icon(AppIcons.delete, color: AppColors.error),
                  onPressed: isBusy ? null : _confirmDelete,
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_fromCatalog) ...[
                      _ServiceHeader(
                        name: _service?.name ?? _existing!.name,
                        logoUrl: _service?.logoUrl ?? _existing?.logoUrl,
                        domain: _service?.domain ?? _existing?.domain,
                        category: SubscriptionCategoryUi.label(
                          context,
                          _category,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      FieldLabel(l10n.subscriptionName),
                      CapsuleField(
                        semanticLabel: l10n.subscriptionName,
                        controller: _nameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.subscriptionNameRequired
                            : null,
                      ),
                      const SizedBox(height: 20),
                      FieldLabel(l10n.category),
                      SubscriptionCategorySelector(
                        selected: _category,
                        onChanged: (c) => setState(() => _category = c),
                      ),
                      const SizedBox(height: 20),
                    ],

                    FieldLabel(l10n.planNameOptional),
                    CapsuleField(
                      semanticLabel: l10n.planNameOptional,
                      controller: _planController,
                    ),
                    const SizedBox(height: 20),

                    FieldLabel(l10n.price),
                    CapsuleField(
                      semanticLabel: l10n.price,
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.priceRequired;
                        }
                        final price = _parsePrice(v);
                        return price == null || price < 0
                            ? l10n.invalidNumber
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    FieldLabel(l10n.currency),
                    SegmentedToggle<String>(
                      options: {
                        for (final c in currencies)
                          c: c == 'EGP' ? l10n.currencyEgp : c,
                      },
                      selected: _currency,
                      onChanged: (c) => setState(() => _currency = c),
                    ),
                    const SizedBox(height: 20),

                    FieldLabel(l10n.billingCycle),
                    SegmentedToggle<BillingCycle>(
                      options: {
                        BillingCycle.monthly: l10n.billingMonthly,
                        BillingCycle.yearly: l10n.billingYearly,
                      },
                      selected: _cycle,
                      onChanged: _setCycle,
                    ),
                    const SizedBox(height: 20),

                    FieldLabel(l10n.nextRenewal),
                    Semantics(
                      button: true,
                      label: l10n.nextRenewal,
                      child: InkWell(
                        onTap: isBusy ? null : _pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: CapsuleShell(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _renewalDate.toIsoDate(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(AppIcons.calendar, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    FieldLabel(l10n.paymentMethodOptional),
                    CapsuleField(
                      semanticLabel: l10n.paymentMethodOptional,
                      controller: _paymentController,
                    ),
                    const SizedBox(height: 20),

                    FieldLabel(l10n.notesOptional),
                    CapsuleField(
                      semanticLabel: l10n.notesOptional,
                      controller: _notesController,
                      maxLines: 3,
                      minLines: 3,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: isBusy ? null : _save,
                        child: isBusy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _existing == null
                                    ? l10n.addSubscription
                                    : l10n.saveChanges,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ServiceHeader extends StatelessWidget {
  const _ServiceHeader({
    required this.name,
    this.logoUrl,
    this.domain,
    required this.category,
  });

  final String name;
  final String? logoUrl;
  final String? domain;
  final String category;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SubscriptionLogo(
            name: name,
            logoUrl: logoUrl,
            domain: domain,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: textTheme.titleMedium),
                Text(
                  category,
                  style: textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

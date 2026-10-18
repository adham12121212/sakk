import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/route/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/catalog_service.dart';
import '../cubit/catalog_cubit.dart';
import '../cubit/catalog_state.dart';
import '../cubit/smart_add_cubit.dart';
import '../widgets/smart_add_sheets.dart';
import '../util/subscription_category_ui.dart';
import '../util/subscription_format.dart';
import '../widgets/subscription_logo.dart';
import 'subscription_form_view.dart';

/// Add flow, step 1: search the catalog and pick a service (then a plan), or
/// choose to enter a custom subscription.
class CatalogPickerView extends StatefulWidget {
  const CatalogPickerView({super.key});

  @override
  State<CatalogPickerView> createState() => _CatalogPickerViewState();
}

class _CatalogPickerViewState extends State<CatalogPickerView> {
  final _searchController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<CatalogCubit>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Opens the form; once it saves, this picker closes too, back to the list.
  Future<void> _openForm(SubscriptionFormArgs args) async {
    final saved = await context.push<bool>(
      AppRoutes.subscriptionForm,
      extra: args,
    );
    if (saved == true && mounted) context.pop();
  }

  Future<void> _pickService(CatalogService service) async {
    final choice = await showModalBottomSheet<_PlanChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PlanSheet(service: service),
    );
    if (choice == null || !mounted) return;
    await _openForm(SubscriptionFormArgs.fromCatalog(service, choice.plan));
  }

  /// Smart add: pick a source, read it with the AI, then open the form
  /// (handled by the listener in [build]).
  Future<void> _smartAdd() async {
    final source = await showSmartAddSourceSheet(context);
    if (source == null || !mounted) return;

    String? imagePath;
    String? text;
    if (source == SmartAddSource.text) {
      text = await showPasteMessageSheet(context);
      if (text == null) return;
    } else {
      // Same size limits as receipt scanning: sharp text, small upload.
      final picked = await _picker.pickImage(
        source: source == SmartAddSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (picked == null) return;
      imagePath = picked.path;
    }
    if (!mounted) return;
    await context.read<SmartAddCubit>().read(
      imagePath: imagePath,
      text: text,
      catalog: context.read<CatalogCubit>().state.services,
    );
  }

  Future<void> _onSmartAddState(
    BuildContext context,
    SmartAddState state,
  ) async {
    switch (state) {
      case SmartAddReady(:final args):
        context.read<SmartAddCubit>().acknowledge();
        await _openForm(args);
      case SmartAddFailure(:final message):
        context.read<SmartAddCubit>().acknowledge();
        AppSnackBar.error(
          context,
          userFacingError(AppLocalizations.of(context)!, message),
        );
      case SmartAddIdle() || SmartAddReading():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<SmartAddCubit, SmartAddState>(
      listener: _onSmartAddState,
      builder: (context, smartAdd) => Stack(
        children: [
          _scaffold(context, l10n),
          if (smartAdd is SmartAddReading) const SmartAddReadingOverlay(),
        ],
      ),
    );
  }

  Widget _scaffold(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addSubscription),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) => TextField(
                  controller: _searchController,
                  onChanged: context.read<CatalogCubit>().search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchServicesHint,
                    prefixIcon: const Icon(AppIcons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).deleteButtonTooltip,
                            icon: const Icon(AppIcons.close, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              context.read<CatalogCubit>().search('');
                            },
                          ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<CatalogCubit, CatalogState>(
                builder: (context, state) => _list(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, CatalogState state) {
    final l10n = AppLocalizations.of(context)!;
    final isInitialLoading = state.isLoading && state.services.isEmpty;

    final actions = Column(
      children: [
        _ActionTile(
          icon: AppIcons.scan,
          title: l10n.smartAdd,
          subtitle: l10n.smartAddHint,
          onTap: _smartAdd,
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: AppIcons.edit,
          title: l10n.customSubscription,
          subtitle: l10n.customSubscriptionHint,
          onTap: () => _openForm(const SubscriptionFormArgs.custom()),
        ),
      ],
    );

    if (state.error != null && state.services.isEmpty && !isInitialLoading) {
      // The custom option still works without the catalog... once online.
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          actions,
          AppErrorView(
            message: state.error,
            onRetry: context.read<CatalogCubit>().load,
          ),
        ],
      );
    }

    final services = isInitialLoading
        ? List.generate(
            6,
            (i) => CatalogService(id: '$i', name: 'Service name'),
          )
        : state.filtered;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        actions,
        const SizedBox(height: 16),
        if (services.isEmpty)
          AppEmptyView(icon: AppIcons.searchEmpty, title: l10n.noServicesFound)
        else
          Skeletonizer(
            enabled: isInitialLoading,
            child: Column(
              children: [
                for (final service in services) ...[
                  _ServiceTile(
                    service: service,
                    onTap: isInitialLoading
                        ? null
                        : () => _pickService(service),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
      ],
    );
  }
}


/// Tinted icon, title, hint and a chevron: the picker's top actions.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(
            AppIcons.chevronForward,
            size: 20,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, this.onTap});

  final CatalogService service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final cheapest = service.plans.isEmpty
        ? null
        : service.plans.reduce(
            (a, b) =>
                a.price / a.billingCycle.months <=
                    b.price / b.billingCycle.months
                ? a
                : b,
          );
    final category = SubscriptionCategoryUi.label(context, service.category);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SubscriptionLogo(
            name: service.name,
            logoUrl: service.logoUrl,
            domain: service.domain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
                Text(
                  cheapest == null
                      ? category
                      : '$category · ${l10n.fromPrice(formatPricePerCycle(context, cheapest.price, cheapest.currency, cheapest.billingCycle))}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(
            AppIcons.chevronForward,
            size: 20,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

/// What the plan sheet returns: a plan, or null [plan] for "Other plan".
class _PlanChoice {
  const _PlanChoice(this.plan);
  final CatalogPlan? plan;
}

class _PlanSheet extends StatelessWidget {
  const _PlanSheet({required this.service});

  final CatalogService service;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            Row(
              children: [
                SubscriptionLogo(
                  name: service.name,
                  logoUrl: service.logoUrl,
                  domain: service.domain,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name, style: textTheme.titleMedium),
                      Text(l10n.choosePlan, style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final plan in service.plans)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(plan.name),
                trailing: Text(
                  formatPricePerCycle(
                    context,
                    plan.price,
                    plan.currency,
                    plan.billingCycle,
                  ),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(_PlanChoice(plan)),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.otherPlan),
              subtitle: Text(l10n.otherPlanHint),
              trailing: const Icon(AppIcons.edit, size: 20),
              onTap: () => Navigator.of(context).pop(const _PlanChoice(null)),
            ),
          ],
        ),
      ),
    );
  }
}

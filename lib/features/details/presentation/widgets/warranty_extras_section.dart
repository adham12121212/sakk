import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/domain/entities/warranty_claim.dart';
import '../cubit/details_cubit.dart';
import '../../../../core/theme/app_icons.dart';

/// Extra warranties and warranty claims, shown under the Details tab.
class WarrantyExtrasSection extends StatelessWidget {
  const WarrantyExtrasSection({super.key, required this.product, this.canEdit = true});

  final ProductEntity product;

  /// False on a household member's product: view only.
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final busy = context.watch<DetailsCubit>().state is DetailsActionInProgress;
    final dateFormat = DateFormat.yMMMd(_dateLocale(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _SectionHeader(
          title: l10n.extraWarranties,
          actionLabel: l10n.addWarranty,
          onAction: busy || !canEdit ? null : () => _showAddWarrantySheet(context, product),
          showAction: canEdit,
        ),
        const SizedBox(height: 8),
        if (product.extraWarranties.isEmpty)
          _EmptyHint(l10n.extraWarrantiesHint)
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final w in product.extraWarranties)
                  ListTile(
                    leading: Icon(AppIcons.warranty, color: colorScheme.primary),
                    title: Text(w.provider),
                    subtitle: Text(
                      '${dateFormat.format(w.startDate)} – ${dateFormat.format(w.endDate)}',
                    ),
                    trailing: !canEdit ? null : IconButton(
                      tooltip: l10n.delete,
                      icon: const Icon(AppIcons.delete),
                      onPressed: busy
                          ? null
                          : () => context.read<DetailsCubit>().deleteExtraWarranty(product.id, w.id),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: l10n.warrantyClaims,
          actionLabel: l10n.startClaim,
          onAction: busy || !canEdit ? null : () => _showStartClaimSheet(context, product),
          showAction: canEdit,
        ),
        const SizedBox(height: 8),
        if (product.claims.isEmpty)
          _EmptyHint(l10n.warrantyClaimsHint)
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final c in product.claims)
                  ListTile(
                    onTap: busy || !canEdit ? null : () => _showClaimStatusSheet(context, c),
                    title: Text(c.issue, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(dateFormat.format(c.createdAt), style: textTheme.bodySmall),
                    trailing: _ClaimStatusChip(c.status),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Arabic gets Arabic-Indic digits, like DetailsTab.
String _dateLocale(BuildContext context) {
  final appLocale = Localizations.localeOf(context);
  return appLocale.languageCode == 'ar' ? 'ar_EG' : appLocale.toLanguageTag();
}

String claimStatusLabel(AppLocalizations l10n, ClaimStatus status) => switch (status) {
      ClaimStatus.submitted => l10n.claimSubmitted,
      ClaimStatus.inRepair => l10n.claimInRepair,
      ClaimStatus.resolved => l10n.claimResolved,
      ClaimStatus.rejected => l10n.claimRejected,
    };

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.showAction = true,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        if (showAction)
          TextButton.icon(
          onPressed: onAction,
          icon: const Icon(AppIcons.add, size: 18),
          label: Text(actionLabel),
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _ClaimStatusChip extends StatelessWidget {
  const _ClaimStatusChip(this.status);

  final ClaimStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      ClaimStatus.submitted || ClaimStatus.inRepair => (colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
      ClaimStatus.resolved => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      ClaimStatus.rejected => (colorScheme.errorContainer, colorScheme.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(
        claimStatusLabel(AppLocalizations.of(context)!, status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

Future<void> _showAddWarrantySheet(BuildContext context, ProductEntity product) {
  final cubit = context.read<DetailsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(value: cubit, child: _AddWarrantySheet(product: product)),
  );
}

class _AddWarrantySheet extends StatefulWidget {
  const _AddWarrantySheet({required this.product});

  final ProductEntity product;

  @override
  State<_AddWarrantySheet> createState() => _AddWarrantySheetState();
}

class _AddWarrantySheetState extends State<_AddWarrantySheet> {
  final _formKey = GlobalKey<FormState>();
  final _providerController = TextEditingController();
  final _monthsController = TextEditingController();

  // Extended warranties usually start when the manufacturer's one ends.
  late DateTime _startDate = widget.product.manufacturerWarrantyEndDate;
  bool _saving = false;

  @override
  void dispose() {
    _providerController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: widget.product.purchaseDate,
      lastDate: DateTime(DateTime.now().year + 20),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await context.read<DetailsCubit>().addExtraWarranty(
          productId: widget.product.id,
          provider: _providerController.text.trim(),
          startDate: _startDate,
          months: int.parse(_monthsController.text.trim()),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SheetBody(
      title: l10n.addWarranty,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _providerController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.warrantyProvider, hintText: l10n.warrantyProviderHint),
              validator: (v) => v == null || v.trim().isEmpty ? l10n.warrantyProviderRequired : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickStartDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(labelText: l10n.warrantyStartDate),
                child: Text(DateFormat.yMMMd(_dateLocale(context)).format(_startDate)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _monthsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.warrantyMonths),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                return n == null || n < 1 || n > 240 ? l10n.invalidWarrantyMonths : null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const _ButtonSpinner() : Text(l10n.saveChanges),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showStartClaimSheet(BuildContext context, ProductEntity product) {
  final cubit = context.read<DetailsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(value: cubit, child: _StartClaimSheet(product: product)),
  );
}

class _StartClaimSheet extends StatefulWidget {
  const _StartClaimSheet({required this.product});

  final ProductEntity product;

  @override
  State<_StartClaimSheet> createState() => _StartClaimSheetState();
}

class _StartClaimSheetState extends State<_StartClaimSheet> {
  final _formKey = GlobalKey<FormState>();
  final _issueController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  /// Ready-to-send message for the store or maker, in the app's language.
  String _claimMessage(AppLocalizations l10n, String issue) {
    final p = widget.product;
    final dateFormat = DateFormat.yMMMd(_dateLocale(context));
    final name = p.brand == null ? p.name : '${p.name} (${p.brand})';
    final buffer = StringBuffer()
      ..writeln(l10n.claimMessageIntro(
        name,
        dateFormat.format(p.purchaseDate),
        dateFormat.format(p.warrantyEndDate),
      ));
    if (p.store != null) buffer.writeln(l10n.shareStore(p.store!));
    if (p.serialNumber != null) buffer.writeln('${l10n.serialNumber}: ${p.serialNumber}');
    if (p.invoiceNumber != null) buffer.writeln('${l10n.invoiceNumber}: ${p.invoiceNumber}');
    buffer.writeln(l10n.claimMessageIssue(issue));
    final invoice = p.receiptUrl ?? p.imageUrl;
    if (invoice != null) buffer.writeln(l10n.shareInvoiceUrl(invoice).trim());
    return buffer.toString().trim();
  }

  Future<void> _sendAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final issue = _issueController.text.trim();
    setState(() => _saving = true);

    // Save first, so the claim is recorded even if the user cancels sharing.
    final ok = await context.read<DetailsCubit>().startClaim(productId: widget.product.id, issue: issue);
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      return;
    }
    final message = _claimMessage(l10n, issue);
    Navigator.of(context).pop();
    try {
      await SharePlus.instance.share(ShareParams(text: message, subject: l10n.claimSubject(widget.product.name)));
    } catch (_) {
      // Sharing is optional; the claim is already saved.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SheetBody(
      title: l10n.startClaim,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.startClaimExplanation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _issueController,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              decoration: InputDecoration(labelText: l10n.claimIssue, hintText: l10n.claimIssueHint),
              validator: (v) => v == null || v.trim().isEmpty ? l10n.claimIssueRequired : null,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _sendAndSave,
              icon: _saving ? const _ButtonSpinner() : const Icon(AppIcons.send),
              label: Text(l10n.saveAndSendClaim),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showClaimStatusSheet(BuildContext context, WarrantyClaim claim) {
  final cubit = context.read<DetailsCubit>();
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _SheetBody(
      title: l10n.claimStatus,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(claim.issue, style: Theme.of(sheetContext).textTheme.bodyMedium),
          const SizedBox(height: 8),
          RadioGroup<ClaimStatus>(
            groupValue: claim.status,
            onChanged: (status) {
              Navigator.of(sheetContext).pop();
              if (status != null && status != claim.status) cubit.updateClaimStatus(claim.id, status);
            },
            child: Column(
              children: [
                for (final status in ClaimStatus.values)
                  RadioListTile<ClaimStatus>(
                    value: status,
                    title: Text(claimStatusLabel(l10n, status)),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              cubit.deleteClaim(claim.id);
            },
            icon: const Icon(AppIcons.delete),
            label: Text(l10n.deleteClaim),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(sheetContext).colorScheme.error,
              minimumSize: const Size(0, 48),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Title plus content, padded above the keyboard.
class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
    );
  }
}

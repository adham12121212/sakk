import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/service/pdf_invoice_reader.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/util/date_math.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/usecase/get_user_usecase.dart';
import '../../../auth/presentation/widgets/segmented_toggle.dart';
import '../../../products/data/product_data_source/product_data_source.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../scan/presentation/widgets/capsule_field.dart';
import '../../../scan/presentation/widgets/confidence_banner.dart';
import '../../../scan/presentation/widgets/field_label.dart';
import '../../domain/entities/installment_plan.dart';
import '../../domain/entities/installment_plan_draft.dart';
import '../../domain/entities/installment_terms.dart';
import '../../domain/entities/scanned_installment.dart';
import '../../domain/installment_schedule.dart';
import '../../../subscriptions/presentation/widgets/smart_add_sheets.dart';
import '../cubit/installment_form_cubit.dart';
import '../cubit/installment_smart_add_cubit.dart';
import '../util/installment_format.dart';
import '../widgets/product_picker_sheet.dart';
import '../widgets/schedule_preview.dart';
import '../../../pro/domain/pro_limit.dart';
import '../../../pro/presentation/pro_actions.dart';

/// What the form opens with: nothing, a product to link (from product
/// details), or a plan to edit.
class InstallmentFormArgs {
  const InstallmentFormArgs.add({this.product}) : existing = null;

  const InstallmentFormArgs.edit(InstallmentPlan this.existing)
    : product = null;

  final InstallmentPlan? existing;
  final ProductEntity? product;
}

/// Add and edit screen. Shows the schedule it will save as the user types.
/// Pops with `true` once the plan is saved.
class InstallmentFormView extends StatefulWidget {
  const InstallmentFormView({super.key, required this.args, this.products});

  final InstallmentFormArgs args;

  /// The products a plan can be linked to; the user's own by default (not a
  /// household member's).
  final List<ProductEntity>? products;

  @override
  State<InstallmentFormView> createState() => _InstallmentFormViewState();
}

class _InstallmentFormViewState extends State<InstallmentFormView> {
  final _formKey = GlobalKey<FormState>();

  InstallmentPlan? get _existing => widget.args.existing;
  InstallmentTerms? get _existingTerms => _existing?.terms;

  /// Common providers in Egypt; Bank and Store are added in the user's language.
  static const _providers = [
    'Valu',
    'Contact',
    'Sympl',
    'Souhoola',
    'aman',
    'forsa',
  ];
  static const _counts = [3, 6, 12, 18, 24, 36];
  static const _currencies = ['EGP', 'USD', 'EUR'];

  late final List<ProductEntity> _myProducts =
      widget.products ??
      () {
        final me = getIt<GetUserUseCase>()()?.id;
        return getIt<ProductsCubit>().state.products
            .where((p) => p.isOwnedBy(me))
            .toList();
      }();

  late ProductEntity? _product =
      widget.args.product ??
      (_existing?.productId == null
          ? null
          : _myProducts.where((p) => p.id == _existing!.productId).firstOrNull);

  /// Linking a product (rather than typing a title).
  late bool _linkProduct = _product != null || _existing?.productId != null;

  late final _titleController = TextEditingController(
    text: _existing?.productId == null ? _existing?.title ?? '' : '',
  );
  late final _providerController = TextEditingController(
    text: _existing?.provider ?? '',
  );
  late final _totalController = TextEditingController(
    text: _amountText(_existingTerms?.totalPrice ?? widget.args.product?.price),
  );
  late final _downController = TextEditingController(
    text: _amountText(_existingTerms?.downPayment, zeroIsEmpty: true),
  );
  late final _feesController = TextEditingController(
    text: _amountText(_existingTerms?.interestOrFees, zeroIsEmpty: true),
  );
  late final _countController = TextEditingController(
    text: _existingTerms == null ? '' : '${_existingTerms!.installmentsCount}',
  );
  late final _amountController = TextEditingController(
    text: _amountText(_existingTerms?.installmentAmount),
  );
  late final _notesController = TextEditingController(
    text: _existing?.notes ?? '',
  );

  late String _currency =
      _existing?.currency ?? widget.args.product?.currency ?? 'EGP';
  late DateTime _startDate =
      _existingTerms?.startDate ?? _defaultStart(widget.args.product);
  late int _dueDay = _existingTerms?.dueDayOfMonth ?? _startDate.day;

  /// Until the user changes them, the amount follows the split, the due day
  /// follows the start date, and the start date follows the product.
  late bool _amountTouched =
      _existingTerms != null &&
      suggestedInstallmentAmount(_existingTerms!) !=
          _existingTerms!.installmentAmount;
  late bool _dueDayTouched =
      _existingTerms != null &&
      _existingTerms!.dueDayOfMonth != _existingTerms!.startDate.day;
  late bool _startTouched = _existingTerms != null;

  /// A month after the purchase for a product, otherwise a month from today.
  static DateTime _defaultStart(ProductEntity? product) =>
      addMonthsClamped(dateOnly(product?.purchaseDate ?? DateTime.now()), 1);

  static String _amountText(double? value, {bool zeroIsEmpty = false}) {
    if (value == null || (zeroIsEmpty && value == 0)) return '';
    return value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    for (final c in [
      _totalController,
      _downController,
      _feesController,
      _countController,
    ]) {
      c.addListener(_onTermsTyped);
    }
    _amountController.addListener(_onAmountTyped);
  }

  @override
  void dispose() {
    for (final c in [
      _titleController,
      _providerController,
      _totalController,
      _downController,
      _feesController,
      _countController,
      _amountController,
      _notesController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The amount last filled in from the even split.
  late String? _autoAmountText = _amountTouched ? null : _amountController.text;

  /// Typing an amount of their own takes it over from the split. (The
  /// listener also fires on cursor moves, hence comparing the text.)
  void _onAmountTyped() {
    final custom = _amountController.text != _autoAmountText;
    if (custom != _amountTouched) setState(() => _amountTouched = custom);
  }

  double? _number(TextEditingController c) => parseLocalizedNumber(c.text);
  double _optional(TextEditingController c) =>
      c.text.trim().isEmpty ? 0 : (_number(c) ?? 0);
  int? get _count {
    final n = _number(_countController);
    return n == null || n != n.truncateToDouble() ? null : n.toInt();
  }

  double? get _financed {
    final total = _number(_totalController);
    if (total == null) return null;
    return total - _optional(_downController) + _optional(_feesController);
  }

  /// Keeps the amount on the even split until the user types their own.
  void _onTermsTyped() {
    if (!_amountTouched) {
      final financed = _financed;
      final count = _count;
      final suggested = financed == null || count == null
          ? null
          : suggestedAmountFor(financed, count);
      final text = _amountText(suggested);
      _autoAmountText = text;
      if (_amountController.text != text) _amountController.text = text;
    }
    setState(() {});
  }

  /// The terms as typed, or null while something needed is missing.
  InstallmentTerms? get _terms {
    final total = _number(_totalController);
    final count = _count;
    final amount = _number(_amountController);
    if (total == null ||
        count == null ||
        amount == null ||
        count < 1 ||
        count > 360 ||
        amount <= 0) {
      return null;
    }
    final fees = _optional(_feesController);
    return InstallmentTerms(
      totalPrice: total,
      downPayment: _optional(_downController),
      interestOrFees: fees > 0 ? fees : null,
      installmentAmount: amount,
      installmentsCount: count,
      startDate: _startDate,
      dueDayOfMonth: _dueDay,
    );
  }

  /// What the save will leave the plan with: paid installments kept (when
  /// editing) and the unpaid ones from the terms.
  List<PreviewRow> _previewRows(InstallmentTerms? terms) {
    if (terms == null) return const [];
    final existing = _existing;
    if (existing == null) {
      return [
        for (final p in buildSchedule(terms))
          PreviewRow(dueDate: p.dueDate, amount: p.amount),
      ];
    }
    if (terms.installmentsCount < minimumInstallmentsCount(existing)) {
      return const [];
    }
    return [
      for (final p in existing.payments.where((p) => p.isPaid))
        PreviewRow(dueDate: p.dueDate, amount: p.amount, isPaid: true),
      for (final p in unpaidScheduleForEdit(existing, terms))
        PreviewRow(dueDate: p.dueDate, amount: p.amount),
    ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<void> _pickProduct() async {
    final picked = await ProductPickerSheet.show(context, _myProducts);
    if (picked == null || !mounted) return;
    setState(() {
      _product = picked;
      if (_totalController.text.trim().isEmpty && picked.price != null) {
        _totalController.text = _amountText(picked.price);
        _currency = picked.currency;
      }
      if (!_startTouched) {
        _startDate = _defaultStart(picked);
        if (!_dueDayTouched) _dueDay = _startDate.day;
      }
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 10, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      _startTouched = true;
      if (!_dueDayTouched) _dueDay = picked.day;
    });
  }

  final _imagePicker = ImagePicker();

  /// What smart add read, shown as a banner until the user saves.
  ScannedInstallment? _scan;

  /// Smart add: pick a source, read it with the AI, then fill the form
  /// (handled by the listener in [build]). The user still reviews and saves.
  Future<void> _smartAdd() async {
    // Reading it with the AI is a scan.
    if (!ProActions.ensureCanUse(context, QuotaType.scan)) return;
    final smartAdd = context.read<InstallmentSmartAddCubit>();
    final source = await showSmartAddSourceSheet(context, allowPdf: true);
    if (source == null || !mounted) return;

    String? imagePath;
    String? pdfText;
    String? text;
    switch (source) {
      case SmartAddSource.text:
        text = await showPasteMessageSheet(context);
        if (text == null) return;
      case SmartAddSource.pdf:
        final List<PlatformFile> files;
        try {
          files = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
        } catch (_) {
          return; // picker unavailable or cancelled by the system
        }
        if (files.isEmpty) return;
        try {
          // Its first page goes to the AI with the PDF's own text.
          final contract = await PdfInvoiceReader().read(
            await files.first.xFile.readAsBytes(),
          );
          imagePath = contract.imagePath;
          pdfText = contract.text;
        } on PdfInvoiceException {
          smartAdd.fail(ProductDataSourceImpl.pdfUnreadable);
          return;
        }
      case SmartAddSource.camera || SmartAddSource.gallery:
        // Same size limits as receipt scanning: sharp text, small upload.
        final picked = await _imagePicker.pickImage(
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
    await smartAdd.read(imagePath: imagePath, pdfText: pdfText, text: text);
  }

  void _onSmartAddState(BuildContext context, InstallmentSmartAddState state) {
    switch (state) {
      case InstallmentSmartAddReady(:final scan):
        context.read<InstallmentSmartAddCubit>().acknowledge();
        _applyScan(scan);
      case InstallmentSmartAddFailure(:final message):
        context.read<InstallmentSmartAddCubit>().acknowledge();
        AppSnackBar.error(
          context,
          userFacingError(AppLocalizations.of(context)!, message),
        );
      case InstallmentSmartAddIdle() || InstallmentSmartAddReading():
        break;
    }
  }

  /// Fills the form with what was read. Fields it didn't find keep what the
  /// user already typed; a product they already picked stays linked.
  void _applyScan(ScannedInstallment scan) {
    setState(() {
      _scan = scan;
      if (scan.title != null && _product == null) {
        _linkProduct = false;
        _titleController.text = scan.title!;
      }
      if (scan.provider != null) _providerController.text = scan.provider!;
      if (scan.currency != null) _currency = scan.currency!;
      // An amount that was read is the user's own, not the even split.
      if (scan.installmentAmount != null) _amountTouched = true;
      if (scan.totalPrice != null) {
        _totalController.text = _amountText(scan.totalPrice);
      }
      if (scan.downPayment != null) {
        _downController.text = _amountText(scan.downPayment);
      }
      if (scan.interestOrFees != null) {
        _feesController.text = _amountText(scan.interestOrFees);
      }
      if (scan.installmentsCount != null) {
        _countController.text = '${scan.installmentsCount}';
      }
      if (scan.installmentAmount != null) {
        _amountController.text = _amountText(scan.installmentAmount);
        // Back on the split if it matches it anyway.
        _onAmountTyped();
      }
      if (scan.firstDueDate != null) {
        _startDate = dateOnly(scan.firstDueDate!);
        _startTouched = true;
      }
      if (scan.dueDayOfMonth != null) {
        _dueDay = scan.dueDayOfMonth!;
        _dueDayTouched = true;
      } else if (scan.firstDueDate != null && !_dueDayTouched) {
        _dueDay = _startDate.day;
      }
    });
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final terms = _terms;
    if (terms == null) return;
    if (_linkProduct && _product == null && _existing?.productId == null) {
      AppSnackBar.error(context, l10n.chooseProductRequired);
      return;
    }
    final productId = _linkProduct
        ? (_product?.id ?? _existing?.productId)
        : null;
    final title = _linkProduct
        ? (_product?.name ?? _existing!.name)
        : _titleController.text.trim();
    context.read<InstallmentFormCubit>().save(
      InstallmentPlanDraft(
        productId: productId,
        title: title,
        provider: _emptyToNull(_providerController.text),
        currency: _currency,
        terms: terms,
        notes: _emptyToNull(_notesController.text),
        isCancelled: _existing?.isCancelled ?? false,
      ),
      current: _existing,
    );
  }

  void _onStateChange(BuildContext context, InstallmentFormState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state) {
      case InstallmentFormSaved():
        AppSnackBar.success(context, l10n.installmentSaved);
        Navigator.of(context).pop(true);
      case InstallmentFormFailure(:final message):
        AppSnackBar.error(context, userFacingError(l10n, message));
      case InstallmentFormIdle() ||
          InstallmentFormBusy() ||
          InstallmentFormDeleted():
        break;
    }
  }

  // ---- Validators ----

  String? _requiredAmount(
    String? v,
    AppLocalizations l10n, {
    bool positive = false,
  }) {
    if (v == null || v.trim().isEmpty) return l10n.priceRequired;
    final n = parseLocalizedNumber(v);
    if (n == null || n < 0 || (positive && n == 0)) return l10n.invalidNumber;
    return null;
  }

  String? _optionalAmount(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return null;
    final n = parseLocalizedNumber(v);
    return n == null || n < 0 ? l10n.invalidNumber : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final existing = _existing;
    final paidCount = existing?.paidCount ?? 0;
    final terms = _terms;

    return BlocListener<InstallmentSmartAddCubit, InstallmentSmartAddState>(
      listener: _onSmartAddState,
      child: BlocConsumer<InstallmentFormCubit, InstallmentFormState>(
        listener: _onStateChange,
        builder: (context, state) {
          final isBusy = state is InstallmentFormBusy;
          final currencies = {..._currencies, _currency};

          final reading =
              context.watch<InstallmentSmartAddCubit>().state
                  is InstallmentSmartAddReading;

          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: Text(
                    existing == null
                        ? l10n.addInstallment
                        : l10n.editInstallment,
                  ),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: false,
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (existing == null) ...[
                            _SmartAddCard(
                              onTap: isBusy || reading ? null : _smartAdd,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_scan != null) ...[
                            ConfidenceBanner(confidence: _scan!.confidence),
                            const SizedBox(height: 8),
                            _InfoNote(l10n.smartAddInstallmentReview),
                            const SizedBox(height: 16),
                          ],
                          if (paidCount > 0) ...[
                            _InfoNote(
                              l10n.editPaidInstallmentsNote(
                                paidCount,
                                formatCount(context, paidCount),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          FieldLabel(l10n.installmentFor),
                          SegmentedToggle<bool>(
                            options: {
                              true: l10n.installmentForProduct,
                              false: l10n.installmentForOther,
                            },
                            selected: _linkProduct,
                            onChanged: (v) => setState(() => _linkProduct = v),
                          ),
                          const SizedBox(height: 12),
                          if (_linkProduct)
                            Semantics(
                              button: true,
                              label: l10n.chooseProduct,
                              child: InkWell(
                                onTap: isBusy ? null : _pickProduct,
                                borderRadius: BorderRadius.circular(16),
                                child: CapsuleShell(
                                  child: Row(
                                    children: [
                                      Icon(
                                        AppIcons.productPlaceholder,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _product?.name ??
                                              (existing?.productId != null
                                                  ? existing!.name
                                                  : l10n.chooseProduct),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        AppIcons.chevronForward,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            CapsuleField(
                              semanticLabel: l10n.installmentTitle,
                              controller: _titleController,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? l10n.installmentTitleRequired
                                  : null,
                            ),
                          const SizedBox(height: 20),

                          FieldLabel(l10n.installmentProviderOptional),
                          CapsuleField(
                            semanticLabel: l10n.installmentProviderOptional,
                            controller: _providerController,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final p in [
                                ..._providers,
                                l10n.providerBank,
                                l10n.providerStore,
                              ])
                                ChoiceChip(
                                  label: Text(p),
                                  selected:
                                      _providerController.text.trim() == p,
                                  onSelected: (_) => setState(
                                    () => _providerController.text = p,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          FieldLabel(l10n.totalPrice),
                          CapsuleField(
                            semanticLabel: l10n.totalPrice,
                            controller: _totalController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) =>
                                _requiredAmount(v, l10n, positive: true),
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

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FieldLabel(l10n.downPaymentOptional),
                                    CapsuleField(
                                      semanticLabel: l10n.downPaymentOptional,
                                      controller: _downController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (v) {
                                        final error = _optionalAmount(v, l10n);
                                        if (error != null) return error;
                                        final total = _number(_totalController);
                                        if (total != null &&
                                            _optional(_downController) >
                                                total) {
                                          return l10n.downPaymentTooHigh;
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FieldLabel(l10n.interestOrFeesOptional),
                                    CapsuleField(
                                      semanticLabel:
                                          l10n.interestOrFeesOptional,
                                      controller: _feesController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (v) =>
                                          _optionalAmount(v, l10n),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          FieldLabel(l10n.installmentsCountLabel),
                          CapsuleField(
                            semanticLabel: l10n.installmentsCountLabel,
                            controller: _countController,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final count = v == null
                                  ? null
                                  : parseLocalizedNumber(v);
                              if (count == null ||
                                  count != count.truncateToDouble() ||
                                  count < 1 ||
                                  count > 360) {
                                return l10n.installmentsCountInvalid;
                              }
                              if (existing != null &&
                                  count < minimumInstallmentsCount(existing)) {
                                return l10n.installmentsCountBelowPaid(
                                  paidCount,
                                  formatCount(context, paidCount),
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final n in _counts)
                                ChoiceChip(
                                  label: Text(
                                    l10n.monthsCount(
                                      n,
                                      formatCount(context, n),
                                    ),
                                  ),
                                  selected: _count == n,
                                  onSelected: (_) =>
                                      _countController.text = '$n',
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          FieldLabel(l10n.installmentAmountPerMonth),
                          CapsuleField(
                            semanticLabel: l10n.installmentAmountPerMonth,
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              final error = _requiredAmount(
                                v,
                                l10n,
                                positive: true,
                              );
                              if (error != null) return error;
                              final financed = _financed;
                              return financed != null && financed <= 0
                                  ? l10n.nothingLeftToFinance
                                  : null;
                            },
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 4,
                              top: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _amountTouched
                                        ? l10n.installmentAmountCustom
                                        : l10n.installmentAmountAuto,
                                    style: textTheme.bodySmall,
                                  ),
                                ),
                                if (_amountTouched)
                                  TextButton(
                                    onPressed: () {
                                      _amountTouched = false;
                                      _onTermsTyped();
                                    },
                                    child: Text(l10n.useEvenSplit),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FieldLabel(l10n.firstInstallmentDate),
                                    Semantics(
                                      button: true,
                                      label: l10n.firstInstallmentDate,
                                      child: InkWell(
                                        onTap: isBusy ? null : _pickStartDate,
                                        borderRadius: BorderRadius.circular(16),
                                        child: CapsuleShell(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  formatInstallmentDate(
                                                    context,
                                                    _startDate,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const Icon(
                                                AppIcons.calendar,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FieldLabel(l10n.dueDayOfMonth),
                                    CapsuleShell(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: _dueDay,
                                          isExpanded: true,
                                          isDense: true,
                                          menuMaxHeight: 320,
                                          items: [
                                            for (var d = 1; d <= 31; d++)
                                              DropdownMenuItem(
                                                value: d,
                                                child: Text(
                                                  formatCount(context, d),
                                                ),
                                              ),
                                          ],
                                          onChanged: isBusy
                                              ? null
                                              : (d) => setState(() {
                                                  _dueDay = d!;
                                                  _dueDayTouched = true;
                                                }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_dueDay > 28)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 4,
                                top: 6,
                              ),
                              child: Text(
                                l10n.dueDayShortMonthsHint,
                                style: textTheme.bodySmall,
                              ),
                            ),
                          const SizedBox(height: 20),

                          FieldLabel(l10n.notesOptional),
                          CapsuleField(
                            semanticLabel: l10n.notesOptional,
                            controller: _notesController,
                            maxLines: 3,
                            minLines: 3,
                          ),
                          const SizedBox(height: 24),

                          SchedulePreview(
                            rows: _previewRows(terms),
                            currency: _currency,
                            downPayment: terms?.downPayment ?? 0,
                          ),
                          const SizedBox(height: 24),

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
                                      existing == null
                                          ? l10n.addInstallment
                                          : l10n.saveChanges,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (reading) const SmartAddReadingOverlay(),
            ],
          );
        },
      ),
    );
  }
}

/// "Fill from a contract or screenshot": opens smart add.
class _SmartAddCard extends StatelessWidget {
  const _SmartAddCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(AppIcons.ai, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.smartAdd, style: textTheme.titleSmall),
                    Text(
                      l10n.smartAddInstallmentHint,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                AppIcons.chevronForward,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.info, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

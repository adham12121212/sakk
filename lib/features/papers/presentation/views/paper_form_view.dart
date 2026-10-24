import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../scan/presentation/widgets/capsule_field.dart';
import '../../../scan/presentation/widgets/field_label.dart';
import '../../domain/entities/paper.dart';
import '../cubit/paper_form_cubit.dart';
import '../util/paper_format.dart';
import '../util/paper_ui.dart';
import '../widgets/paper_photo_slot.dart';

/// Adds a paper, or edits [existing]. Pops with `true` once the paper is
/// saved or deleted.
class PaperFormView extends StatefulWidget {
  const PaperFormView({super.key, this.existing});

  final Paper? existing;

  @override
  State<PaperFormView> createState() => _PaperFormViewState();
}

class _PaperFormViewState extends State<PaperFormView> {
  final _formKey = GlobalKey<FormState>();

  Paper? get _existing => widget.existing;

  late PaperKind _kind = _existing?.kind ?? PaperKind.nationalId;
  late final _nameController = TextEditingController(
    text: _existing?.title ?? '',
  );
  late final _numberController = TextEditingController(
    text: _existing?.number ?? '',
  );
  late final _notesController = TextEditingController(
    text: _existing?.notes ?? '',
  );
  late DateTime? _expiry = _existing?.expiryDate;
  late bool _noExpiry = _existing != null && _existing!.expiryDate == null;

  late PaperPhoto _front = _savedPhoto(
    _existing?.frontPath,
    _existing?.frontUrl,
  );
  late PaperPhoto _back = _savedPhoto(_existing?.backPath, _existing?.backUrl);

  static PaperPhoto _savedPhoto(String? path, String? url) =>
      path == null ? const PaperPhoto.none() : PaperPhoto.saved(url);

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final initial = _expiry ?? DateTime(today.year + 1, today.month, today.day);
    final earliest = DateTime(today.year - 10);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial.isBefore(earliest) ? initial : earliest,
      lastDate: DateTime(today.year + 30, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _expiry = picked;
        _noExpiry = false;
      });
    }
  }

  /// The saved path to keep for a photo slot: the previous one while the
  /// saved photo is still showing, none once it was replaced or removed.
  String? _keptPath(PaperPhoto photo, String? previousPath) =>
      photo.isSaved ? previousPath : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<PaperFormCubit>().save(
      PaperDraft(
        previous: _existing,
        kind: _kind,
        title: _emptyToNull(_nameController.text),
        number: _emptyToNull(_numberController.text),
        expiryDate: _noExpiry ? null : _expiry,
        frontPath: _keptPath(_front, _existing?.frontPath),
        backPath: _keptPath(_back, _existing?.backPath),
        newFrontImage: _front.localPath,
        newBackImage: _back.localPath,
        notes: _emptyToNull(_notesController.text),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final existing = _existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deletePaperQuestion),
        content: Text(l10n.deletePaperBody(PaperUi.name(l10n, existing))),
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
    context.read<PaperFormCubit>().delete(existing);
  }

  void _onStateChange(BuildContext context, PaperFormState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state) {
      case PaperFormSaved():
        AppSnackBar.success(context, l10n.paperSaved);
        Navigator.of(context).pop(true);
      case PaperFormDeleted():
        AppSnackBar.success(context, l10n.paperDeleted);
        Navigator.of(context).pop(true);
      case PaperFormFailure(:final message):
        AppSnackBar.error(context, userFacingError(l10n, message));
      case PaperFormIdle() || PaperFormBusy():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<PaperFormCubit, PaperFormState>(
      listener: _onStateChange,
      builder: (context, state) {
        final isBusy = state is PaperFormBusy;
        final nameRequired = _kind == PaperKind.other;

        return Scaffold(
          appBar: AppBar(
            title: Text(_existing == null ? l10n.addPaper : l10n.editPaper),
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
                    FieldLabel(l10n.paperType),
                    _KindSelector(
                      selected: _kind,
                      onChanged: (kind) => setState(() => _kind = kind),
                    ),
                    const SizedBox(height: 20),

                    FieldLabel(
                      nameRequired ? l10n.paperName : l10n.paperNameOptional,
                    ),
                    CapsuleField(
                      semanticLabel: nameRequired
                          ? l10n.paperName
                          : l10n.paperNameOptional,
                      controller: _nameController,
                      validator: (v) =>
                          nameRequired && (v == null || v.trim().isEmpty)
                          ? l10n.paperNameRequired
                          : null,
                    ),
                    const SizedBox(height: 20),

                    FieldLabel(l10n.paperNumberOptional),
                    CapsuleField(
                      semanticLabel: l10n.paperNumberOptional,
                      controller: _numberController,
                    ),
                    const SizedBox(height: 20),

                    FieldLabel(l10n.paperExpiryDate),
                    if (!_noExpiry)
                      Semantics(
                        button: true,
                        label: l10n.paperExpiryDate,
                        child: InkWell(
                          onTap: isBusy ? null : _pickDate,
                          borderRadius: BorderRadius.circular(16),
                          child: CapsuleShell(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _expiry == null
                                        ? l10n.paperPickDate
                                        : formatPaperDate(context, _expiry!),
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
                    CheckboxListTile(
                      value: _noExpiry,
                      title: Text(l10n.paperNoExpiry),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: isBusy
                          ? null
                          : (on) => setState(() => _noExpiry = on ?? false),
                    ),
                    const SizedBox(height: 12),

                    FieldLabel(l10n.paperPhotos),
                    Row(
                      children: [
                        Expanded(
                          child: PaperPhotoSlot(
                            label: l10n.paperFront,
                            photo: _front,
                            enabled: !isBusy,
                            onChanged: (p) => setState(() => _front = p),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PaperPhotoSlot(
                            label: l10n.paperBack,
                            photo: _back,
                            enabled: !isBusy,
                            onChanged: (p) => setState(() => _back = p),
                          ),
                        ),
                      ],
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
                        onPressed: isBusy || (!_noExpiry && _expiry == null)
                            ? null
                            : _save,
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
                                    ? l10n.addPaper
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

/// The kinds of paper as chips that wrap, styled like the category chips.
class _KindSelector extends StatelessWidget {
  const _KindSelector({required this.selected, required this.onChanged});

  final PaperKind selected;
  final ValueChanged<PaperKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final kind in PaperKind.values)
          _KindChip(
            label: PaperUi.kindName(l10n, kind),
            icon: PaperUi.icon(kind),
            color: PaperUi.color(kind),
            selected: kind == selected,
            onTap: () => onChanged(kind),
          ),
      ],
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.sp, color: selected ? Colors.white : color),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

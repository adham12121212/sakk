import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sakk/core/route/app_router.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/error/network_info.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/service/share_intake.dart';
import '../../../products/data/product_data_source/product_data_source.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pro/domain/pro_limit.dart';
import '../../../pro/presentation/pro_actions.dart';
import '../../../pro/presentation/widgets/quota_hint.dart';
import '../cubit/scan_cubit.dart';
import '../widgets/scan_source_button.dart';
import 'reviewproduct_view.dart';
import 'scan_processing_view.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/constant/app_colors.dart';

class ScanView extends StatefulWidget {
  const ScanView({super.key, this.shared});

  /// A receipt shared to Sakk from another app: scanned as soon as the
  /// screen opens, as if it had been picked here.
  final SharedReceipt? shared;

  @override
  State<ScanView> createState() => ScanViewState();
}

class ScanViewState extends State<ScanView> {
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final shared = widget.shared;
    if (shared != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scanShared(shared));
    }
  }

  /// If it can't be scanned (limit, offline, unreadable file) the user stays
  /// here with the usual message and can pick another way.
  Future<void> _scanShared(SharedReceipt shared) async {
    if (!await _canScan()) return;
    if (!shared.isPdf) {
      _openProcessing(ScanCubit()..processReceipt(shared.path));
      return;
    }
    final Uint8List bytes;
    try {
      bytes = await File(shared.path).readAsBytes();
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          userFacingError(
            AppLocalizations.of(context)!,
            ProductDataSourceImpl.pdfUnreadable,
          ),
        );
      }
      return;
    }
    if (mounted) _openProcessing(ScanCubit()..processPdf(bytes));
  }

  void _openProcessing(ScanCubit cubit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const ScanProcessingView()),
      ),
    );
  }

  /// Before an AI scan: room for one more product, a scan left today and
  /// a connection (otherwise the paywall, or an offline message instead of
  /// a failed upload). The server checks the limits again.
  Future<bool> _canScan() async {
    if (!ProActions.ensureCanAdd(context, LimitedItem.products)) return false;
    if (!ProActions.ensureCanUse(context, QuotaType.scan)) return false;
    if (getIt.isRegistered<NetworkInfo>() &&
        !await getIt<NetworkInfo>().isConnected) {
      if (mounted) {
        AppSnackBar.error(
          context,
          AppLocalizations.of(context)!.scanNeedsInternet,
        );
      }
      return false;
    }
    return mounted;
  }

  Future<void> pickAndScan(ImageSource source) async {
    if (!await _canScan()) return;
    // ~2000px keeps receipt text sharp while cutting a 4-8 MB camera photo
    // to a few hundred KB: faster uploads and scans on mobile data.
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (picked == null || !mounted) return;

    _openProcessing(ScanCubit()..processReceipt(picked.path));
  }

  /// PDF invoices, e.g. the ones online stores email.
  Future<void> pickPdf() async {
    if (!await _canScan()) return;
    final List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } catch (_) {
      return; // picker unavailable or cancelled by the system
    }
    if (files.isEmpty || !mounted) return;
    final bytes = await files.first.xFile.readAsBytes();
    if (!mounted) return;

    _openProcessing(ScanCubit()..processPdf(bytes));
  }

  /// For products without a receipt (lost, or bought online): straight to
  /// the review form with empty fields.
  void enterManually() {
    if (!ProActions.ensureCanAdd(context, LimitedItem.products)) return;
    final cubit = ScanCubit()..startManualEntry();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const ReviewProductView()),
      ),
    );
  }

  // Scan is reached via `context.push(AppRoutes.scan)` from whichever
  // bottom-nav tab is currently active (Home, Products, Analytics, or
  // AI) — hardcoding `go(home)` here used to drop the user back on Home
  // even if they'd scanned from a different tab. Popping back onto the
  // real stack when possible, and only falling back to Home if Scan was
  // somehow reached with nothing to pop to (e.g. a deep link).
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanReceiptTitle),
        leading: IconButton(
          onPressed: () => _goBack(context),
          tooltip: l10n.back,
          icon: const Icon(AppIcons.back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.brandGradientColors,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x404A5CFA),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    AppIcons.scan,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.scanYourWarrantyReceipt,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.scanInstructions,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                const QuotaHint(type: QuotaType.scan),
                const SizedBox(height: 16),
                ScanSourceButton.filled(
                  icon: AppIcons.camera,
                  label: l10n.takePhoto,
                  onPressed: () => pickAndScan(ImageSource.camera),
                ),
                const SizedBox(height: 12),
                ScanSourceButton.outlined(
                  icon: AppIcons.gallery,
                  label: l10n.chooseFromGallery,
                  onPressed: () => pickAndScan(ImageSource.gallery),
                ),
                const SizedBox(height: 12),
                ScanSourceButton.outlined(
                  icon: AppIcons.pdf,
                  label: l10n.uploadPdfInvoice,
                  onPressed: pickPdf,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: enterManually,
                  icon: const Icon(AppIcons.edit),
                  label: Text(l10n.enterDetailsManually),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

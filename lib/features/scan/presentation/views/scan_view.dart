import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sakk/core/route/app_router.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/service/notification_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/scan_cubit.dart';
import '../widgets/sacn_source_button.dart';
import 'scan_processing_view.dart';

class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => ScanViewState();
}

class ScanViewState extends State<ScanView> {
  final picker = ImagePicker();

  Future<void> pickAndScan(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    final cubit = ScanCubit()..processReceipt(picked.path);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const ScanProcessingView(),
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanReceiptTitle,
          style: TextStyle(
              color: Theme.of(context).colorScheme.surface
          ),),
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => _goBack(context),
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.08),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.scanYourWarrantyReceipt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.scanInstructions,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 32),
                ScanSourceButton.filled(
                  icon: Icons.camera_alt_outlined,
                  label: l10n.takePhoto,
                  onPressed: () => pickAndScan(ImageSource.camera),
                ),
                const SizedBox(height: 12),
                ScanSourceButton.outlined(
                  icon: Icons.photo_library_outlined,
                  label: l10n.chooseFromGallery,
                  onPressed: () => pickAndScan(ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

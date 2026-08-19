import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/service/notification_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: const Color(0xFFF8F9FB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
                const Text(
                  'Scan your warranty receipt',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We'll pull out the product, price, and warranty info automatically.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                ScanSourceButton.filled(
                  icon: Icons.camera_alt_outlined,
                  label: 'Take Photo',
                  onPressed: () => pickAndScan(ImageSource.camera),
                ),
                const SizedBox(height: 12),
                ScanSourceButton.outlined(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from Gallery',
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
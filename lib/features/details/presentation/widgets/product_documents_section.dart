import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/service/pdf_invoice_reader.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/enties/product_document.dart';
import '../../../products/domain/enties/product_entity.dart';
import '../cubit/details_cubit.dart';

String documentKindLabel(AppLocalizations l10n, DocumentKind kind) => switch (kind) {
      DocumentKind.receipt => l10n.documentReceipt,
      DocumentKind.warrantyCard => l10n.documentWarrantyCard,
      DocumentKind.productPhoto => l10n.documentProductPhoto,
      DocumentKind.manual => l10n.documentManual,
      DocumentKind.other => l10n.documentOther,
    };

/// Extra files kept with a product (warranty card, photo, manual...), shown
/// as thumbnails. Only the product's owner can add or delete them.
class ProductDocumentsSection extends StatelessWidget {
  const ProductDocumentsSection({super.key, required this.product, required this.canEdit});

  final ProductEntity product;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final busy = context.watch<DetailsCubit>().state is DetailsActionInProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Text(l10n.documents, style: textTheme.titleMedium)),
            if (canEdit)
              TextButton.icon(
                onPressed: busy ? null : () => _showAddDocumentSheet(context, product),
                icon: const Icon(AppIcons.add, size: 18),
                label: Text(l10n.addDocument),
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (product.documents.isEmpty)
          Text(
            canEdit ? l10n.documentsHint : l10n.noDocuments,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          )
        else
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: product.documents.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final document = product.documents[i];
                return Semantics(
                  button: true,
                  label: documentKindLabel(l10n, document.kind),
                  child: InkWell(
                    onTap: () => _openDocument(context, document, product: product, canEdit: canEdit && !busy),
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 96,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              document.url,
                              width: 96,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 96,
                                height: 100,
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(AppIcons.brokenImage, color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            documentKindLabel(l10n, document.kind),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

Future<void> _openDocument(
  BuildContext context,
  ProductDocument document, {
  required ProductEntity product,
  required bool canEdit,
}) {
  final cubit = context.read<DetailsCubit>();
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(child: Image.network(document.url, fit: BoxFit.contain)),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.back,
                  icon: const Icon(AppIcons.close, color: Colors.white),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                Expanded(
                  child: Text(
                    documentKindLabel(l10n, document.kind),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: l10n.share,
                  icon: const Icon(AppIcons.share, color: Colors.white),
                  onPressed: () => _shareDocument(dialogContext, document, product),
                ),
                if (canEdit)
                  IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(AppIcons.delete, color: Colors.white),
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await cubit.deleteDocument(document);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Downloads the document and opens the share sheet with it (e.g. to send a
/// warranty card on Messenger), captioned with its kind and the product.
Future<void> _shareDocument(BuildContext context, ProductDocument document, ProductEntity product) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final response = await http.get(Uri.parse(document.url)).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    final isPng = document.path.toLowerCase().endsWith('.png');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sakk_document_${DateTime.now().millisecondsSinceEpoch}.${isPng ? 'png' : 'jpg'}');
    await file.writeAsBytes(response.bodyBytes);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: isPng ? 'image/png' : 'image/jpeg')],
      text: '${documentKindLabel(l10n, document.kind)}: ${product.name}',
      subject: product.name,
    ));
  } catch (_) {
    if (context.mounted) AppSnackBar.error(context, l10n.couldNotShare);
  }
}

Future<void> _showAddDocumentSheet(BuildContext context, ProductEntity product) {
  final cubit = context.read<DetailsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(value: cubit, child: _AddDocumentSheet(product: product)),
  );
}

class _AddDocumentSheet extends StatefulWidget {
  const _AddDocumentSheet({required this.product});

  final ProductEntity product;

  @override
  State<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<_AddDocumentSheet> {
  DocumentKind _kind = DocumentKind.warrantyCard;
  bool _working = false;

  Future<void> _add(Future<String?> Function() pickFile) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _working = true);
    String? path;
    try {
      path = await pickFile();
    } on PdfInvoiceException {
      if (mounted) AppSnackBar.error(context, l10n.pdfUnreadable);
    } catch (_) {
      // Picker cancelled or unavailable.
    }
    if (!mounted) return;
    if (path == null) {
      setState(() => _working = false);
      return;
    }
    final ok = await context.read<DetailsCubit>().addDocument(
          productId: widget.product.id,
          kind: _kind,
          filePath: path,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _working = false);
    }
  }

  Future<String?> _photo(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 2000, maxHeight: 2000);
    return picked?.path;
  }

  /// A PDF is kept as an image of its first page, like PDF invoices.
  Future<String?> _pdf() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (files.isEmpty) return null;
    final invoice = await PdfInvoiceReader().read(await files.first.xFile.readAsBytes());
    return invoice.imagePath;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.addDocument, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in DocumentKind.values)
                  ChoiceChip(
                    label: Text(documentKindLabel(l10n, kind)),
                    selected: _kind == kind,
                    onSelected: _working ? null : (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_working)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
            else ...[
              FilledButton.icon(
                onPressed: () => _add(() => _photo(ImageSource.camera)),
                icon: const Icon(AppIcons.camera),
                label: Text(l10n.takePhoto),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _add(() => _photo(ImageSource.gallery)),
                icon: const Icon(AppIcons.gallery),
                label: Text(l10n.chooseFromGallery),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _add(_pdf),
                icon: const Icon(AppIcons.pdf),
                label: Text(l10n.choosePdf),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

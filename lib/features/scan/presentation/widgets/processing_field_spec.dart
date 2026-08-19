import '../../../products/domain/enties/scanned_receipt.dart';
import 'datex.dart';

/// Describes a single field row shown on the scan-processing screen: how to
/// read its display value from the scanned data, and how wide its loading
/// skeleton should be while the value isn't available yet.
class ProcessingFieldSpec {
  const ProcessingFieldSpec({
    required this.label,
    required this.valueOf,
    required this.skeletonWidth,
  });

  final String label;
  final String? Function(ScannedReceiptData data) valueOf;
  final double skeletonWidth;
}

/// The ordered set of fields revealed while a receipt is being processed.
final List<ProcessingFieldSpec> scanProcessingFields = [
  ProcessingFieldSpec(
    label: 'Product Name',
    valueOf: (d) => d.productName,
    skeletonWidth: 150,
  ),
  ProcessingFieldSpec(
    label: 'Brand',
    valueOf: (d) => d.brand,
    skeletonWidth: 90,
  ),
  ProcessingFieldSpec(
    label: 'Price',
    valueOf: (d) =>
    d.price == null ? null : 'SAR ${d.price!.toStringAsFixed(0)}',
    skeletonWidth: 110,
  ),
  ProcessingFieldSpec(
    label: 'Purchase Date',
    valueOf: (d) => d.purchaseDate?.toShortLabel(),
    skeletonWidth: 130,
  ),
  ProcessingFieldSpec(
    label: 'Warranty Duration',
    valueOf: (d) =>
    d.warrantyMonths == null ? null : 'Months ${d.warrantyMonths}',
    skeletonWidth: 100,
  ),
  ProcessingFieldSpec(
    label: 'Store',
    valueOf: (d) => d.store,
    skeletonWidth: 120,
  ),
];
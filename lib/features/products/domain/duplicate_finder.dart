import 'entities/product_entity.dart';

/// Why a new product looks like one the user already saved.
enum DuplicateReason { sameInvoiceNumber, sameSerialNumber, sameNameAndDate }

class DuplicateMatch {
  const DuplicateMatch(this.product, this.reason);

  final ProductEntity product;
  final DuplicateReason reason;
}

/// Looks for an existing product that is probably the same purchase, so the
/// user can be warned before saving the same receipt twice.
///
/// Strongest evidence first: the same invoice number, then the same serial
/// number, then the same product name bought on the same day (and, when both
/// have one, at the same price). Returns null when nothing matches.
DuplicateMatch? findDuplicate(
  List<ProductEntity> existing, {
  required String name,
  required DateTime purchaseDate,
  double? price,
  String? serialNumber,
  String? invoiceNumber,
}) {
  final invoice = _normalizeCode(invoiceNumber);
  if (invoice != null) {
    for (final p in existing) {
      if (_normalizeCode(p.invoiceNumber) == invoice) {
        return DuplicateMatch(p, DuplicateReason.sameInvoiceNumber);
      }
    }
  }

  final serial = _normalizeCode(serialNumber);
  if (serial != null) {
    for (final p in existing) {
      if (_normalizeCode(p.serialNumber) == serial) {
        return DuplicateMatch(p, DuplicateReason.sameSerialNumber);
      }
    }
  }

  final normalizedName = _normalizeName(name);
  for (final p in existing) {
    final sameDay =
        p.purchaseDate.year == purchaseDate.year &&
        p.purchaseDate.month == purchaseDate.month &&
        p.purchaseDate.day == purchaseDate.day;
    final priceDiffers =
        price != null && p.price != null && (price - p.price!).abs() >= 0.01;
    if (sameDay && !priceDiffers && _normalizeName(p.name) == normalizedName) {
      return DuplicateMatch(p, DuplicateReason.sameNameAndDate);
    }
  }
  return null;
}

/// "INV-2026 / 0731", "inv2026/0731" and Arabic-Indic digits typed by hand
/// (٠٧٣١) are the same number.
String? _normalizeCode(String? code) {
  if (code == null) return null;
  final normalized = code
      .replaceAllMapped(
        RegExp('[٠-٩]'),
        (m) => '${m[0]!.codeUnitAt(0) - 0x0660}',
      )
      .toUpperCase()
      .replaceAll(RegExp(r'[\s\-_/.#]'), '');
  return normalized.isEmpty ? null : normalized;
}

String _normalizeName(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

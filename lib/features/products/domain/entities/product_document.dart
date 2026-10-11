import 'package:equatable/equatable.dart';

/// Kinds of files kept with a product, next to its receipt. Names match the
/// `kind` values the database accepts (snake_case there).
enum DocumentKind { receipt, warrantyCard, productPhoto, manual, other }

extension DocumentKindX on DocumentKind {
  String get dbValue => switch (this) {
        DocumentKind.warrantyCard => 'warranty_card',
        DocumentKind.productPhoto => 'product_photo',
        _ => name,
      };

  static DocumentKind fromDb(String? value) =>
      DocumentKind.values.firstWhere((k) => k.dbValue == value, orElse: () => DocumentKind.other);
}

/// A photo (or rendered PDF page) attached to a product.
class ProductDocument extends Equatable {
  const ProductDocument({
    required this.id,
    required this.kind,
    required this.url,
    required this.path,
    required this.createdAt,
  });

  final String id;
  final DocumentKind kind;

  /// Signed URL to show the file.
  final String url;

  /// Storage path, used to delete the file with the document.
  final String path;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, kind, url, path, createdAt];
}

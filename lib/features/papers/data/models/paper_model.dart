import '../../domain/entities/paper.dart';

class PaperModel extends Paper {
  const PaperModel({
    required super.id,
    required super.kind,
    super.title,
    super.number,
    super.expiryDate,
    super.frontPath,
    super.backPath,
    super.frontUrl,
    super.backUrl,
    super.notes,
    super.createdAt,
  });

  /// [json] is a papers row, plus `front_url` and `back_url` when its photos
  /// have been signed.
  factory PaperModel.fromJson(Map<String, dynamic> json) {
    return PaperModel(
      id: json['id'] as String,
      kind: PaperKindX.fromDbName(json['kind'] as String?),
      title: json['title'] as String?,
      number: json['number'] as String?,
      expiryDate: DateTime.tryParse(json['expiry_date'] as String? ?? ''),
      frontPath: json['front_path'] as String?,
      backPath: json['back_path'] as String?,
      frontUrl: json['front_url'] as String?,
      backUrl: json['back_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  /// Insert and update body. user_id is left to the database (defaults to
  /// auth.uid(), and RLS rejects any other value).
  static Map<String, dynamic> writeJson({
    required PaperKind kind,
    String? title,
    String? number,
    DateTime? expiryDate,
    String? frontPath,
    String? backPath,
    String? notes,
  }) {
    return {
      'kind': kind.dbName,
      'title': title,
      'number': number,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'front_path': frontPath,
      'back_path': backPath,
      'notes': notes,
    };
  }
}

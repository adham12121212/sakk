import 'package:equatable/equatable.dart';

/// What kind of paper it is; picks its icon, its default name and what the
/// form asks for.
enum PaperKind {
  nationalId,
  passport,
  drivingLicence,
  carLicence,
  carInsurance,
  healthInsurance,
  rentalContract,
  other,
}

extension PaperKindX on PaperKind {
  /// The database value (`national_id`...).
  String get dbName => switch (this) {
    PaperKind.nationalId => 'national_id',
    PaperKind.passport => 'passport',
    PaperKind.drivingLicence => 'driving_licence',
    PaperKind.carLicence => 'car_licence',
    PaperKind.carInsurance => 'car_insurance',
    PaperKind.healthInsurance => 'health_insurance',
    PaperKind.rentalContract => 'rental_contract',
    PaperKind.other => 'other',
  };

  static PaperKind fromDbName(String? name) => PaperKind.values.firstWhere(
    (k) => k.dbName == name,
    orElse: () => PaperKind.other,
  );
}

/// How close a paper is to running out.
enum PaperStatus {
  /// No expiry date.
  noExpiry,
  valid,

  /// Within [Paper.soonDays] of its expiry date.
  expiringSoon,
  expired,
}

/// One of the user's official papers: an ID, a passport, a licence, an
/// insurance card... with photos of each side and when it expires.
class Paper extends Equatable {
  const Paper({
    required this.id,
    required this.kind,
    this.title,
    this.number,
    this.expiryDate,
    this.frontPath,
    this.backPath,
    this.frontUrl,
    this.backUrl,
    this.notes,
    this.createdAt,
  });

  final String id;
  final PaperKind kind;

  /// Whose it is or what it is; always set for [PaperKind.other].
  final String? title;
  final String? number;

  /// Date only; null for a paper that doesn't expire.
  final DateTime? expiryDate;

  /// Storage paths of the photos (papers bucket).
  final String? frontPath;
  final String? backPath;

  /// Short-lived links to the photos, signed when the list loads.
  final String? frontUrl;
  final String? backUrl;

  final String? notes;
  final DateTime? createdAt;

  /// Papers expiring this soon are flagged.
  static const soonDays = 30;

  /// Days from [today] until the expiry date: 0 on the day itself,
  /// negative once it has passed, null without one.
  int? daysLeft(DateTime today) {
    final expiry = expiryDate;
    if (expiry == null) return null;
    final from = DateTime.utc(today.year, today.month, today.day);
    final to = DateTime.utc(expiry.year, expiry.month, expiry.day);
    return to.difference(from).inDays;
  }

  PaperStatus status(DateTime today) {
    final days = daysLeft(today);
    if (days == null) return PaperStatus.noExpiry;
    if (days < 0) return PaperStatus.expired;
    if (days <= soonDays) return PaperStatus.expiringSoon;
    return PaperStatus.valid;
  }

  Paper copyWith({String? frontUrl, String? backUrl}) => Paper(
    id: id,
    kind: kind,
    title: title,
    number: number,
    expiryDate: expiryDate,
    frontPath: frontPath,
    backPath: backPath,
    frontUrl: frontUrl ?? this.frontUrl,
    backUrl: backUrl ?? this.backUrl,
    notes: notes,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    kind,
    title,
    number,
    expiryDate,
    frontPath,
    backPath,
    frontUrl,
    backUrl,
    notes,
    createdAt,
  ];
}

/// What the form saves: a new paper, or new values for [previous]. Each
/// photo is kept ([frontPath] is the previous path), replaced (a new local
/// file in [newFrontImage]) or removed (both null).
class PaperDraft extends Equatable {
  const PaperDraft({
    this.previous,
    required this.kind,
    this.title,
    this.number,
    this.expiryDate,
    this.frontPath,
    this.backPath,
    this.newFrontImage,
    this.newBackImage,
    this.notes,
  });

  /// The paper being edited; null for a new one.
  final Paper? previous;
  final PaperKind kind;
  final String? title;
  final String? number;
  final DateTime? expiryDate;
  final String? frontPath;
  final String? backPath;

  /// Local files picked in the form, uploaded when it's saved.
  final String? newFrontImage;
  final String? newBackImage;
  final String? notes;

  @override
  List<Object?> get props => [
    previous,
    kind,
    title,
    number,
    expiryDate,
    frontPath,
    backPath,
    newFrontImage,
    newBackImage,
    notes,
  ];
}

/// Soonest expiry first (expired ones on top), then papers without an
/// expiry date in the order of [PaperKind].
List<Paper> sortedByExpiry(Iterable<Paper> papers) {
  return [...papers]..sort((a, b) {
    final ea = a.expiryDate;
    final eb = b.expiryDate;
    if (ea != null && eb != null) return ea.compareTo(eb);
    if (ea != null) return -1;
    if (eb != null) return 1;
    return a.kind.index.compareTo(b.kind.index);
  });
}

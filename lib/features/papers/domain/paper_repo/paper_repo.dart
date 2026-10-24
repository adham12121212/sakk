import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/paper.dart';

abstract class PaperRepo {
  /// The signed-in user's papers, soonest expiry first.
  Future<Either<Failure, List<Paper>>> getPapers();

  /// Adds a paper, or updates [PaperDraft.previous]: uploads the photos
  /// picked in the form and deletes the ones they replace.
  Future<Either<Failure, Paper>> savePaper(PaperDraft draft);

  /// Deletes the paper and its photos.
  Future<Either<Failure, void>> deletePaper(Paper paper);
}

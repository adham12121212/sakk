import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/paper.dart';
import '../paper_repo/paper_repo.dart';

abstract class SavePaperUseCase {
  Future<Either<Failure, Paper>> call(PaperDraft draft);
}

class SavePaperUseCaseImpl implements SavePaperUseCase {
  final PaperRepo _repository;
  SavePaperUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, Paper>> call(PaperDraft draft) =>
      _repository.savePaper(draft);
}

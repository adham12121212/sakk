import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/paper.dart';
import '../paper_repo/paper_repo.dart';

abstract class DeletePaperUseCase {
  Future<Either<Failure, void>> call(Paper paper);
}

class DeletePaperUseCaseImpl implements DeletePaperUseCase {
  final PaperRepo _repository;
  DeletePaperUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, void>> call(Paper paper) =>
      _repository.deletePaper(paper);
}

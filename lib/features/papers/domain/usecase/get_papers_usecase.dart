import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/paper.dart';
import '../paper_repo/paper_repo.dart';

abstract class GetPapersUseCase {
  Future<Either<Failure, List<Paper>>> call();
}

class GetPapersUseCaseImpl implements GetPapersUseCase {
  final PaperRepo _repository;
  GetPapersUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, List<Paper>>> call() => _repository.getPapers();
}

import 'package:dartz/dartz.dart';

import '../../../../core/data/online_repo.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/network_info.dart';
import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/paper.dart';
import '../../domain/paper_repo/paper_repo.dart';
import '../models/paper_model.dart';
import '../paper_data_source/paper_data_source.dart';

/// Online only: papers aren't kept on the device, since they hold ID and
/// passport numbers and their photos need a connection anyway.
class PaperRepoImpl with OnlineRepo implements PaperRepo {
  PaperRepoImpl(this._dataSource, this._networkInfo, this._logger);

  final PaperDataSource _dataSource;
  final NetworkInfo _networkInfo;
  final AppLogger _logger;

  @override
  NetworkInfo get networkInfo => _networkInfo;
  @override
  AppLogger get logger => _logger;

  @override
  Future<Either<Failure, List<Paper>>> getPapers() async {
    final result = await online('getPapers', _dataSource.getPapers);
    return result.map((papers) => sortedByExpiry(papers));
  }

  @override
  Future<Either<Failure, Paper>> savePaper(PaperDraft draft) {
    return online('savePaper', () async {
      final uploaded = <String>[];
      try {
        final frontPath = draft.newFrontImage == null
            ? draft.frontPath
            : await _upload(draft.newFrontImage!, uploaded);
        final backPath = draft.newBackImage == null
            ? draft.backPath
            : await _upload(draft.newBackImage!, uploaded);
        final json = PaperModel.writeJson(
          kind: draft.kind,
          title: draft.title,
          number: draft.number,
          expiryDate: draft.expiryDate,
          frontPath: frontPath,
          backPath: backPath,
          notes: draft.notes,
        );
        final previous = draft.previous;
        final saved = previous == null
            ? await _dataSource.addPaper(json)
            : await _dataSource.updatePaper(previous.id, json);
        // Photos the edit replaced or removed.
        await _dataSource.deletePhotos([
          for (final path in [previous?.frontPath, previous?.backPath])
            if (path != null && path != frontPath && path != backPath) path,
        ]);
        return saved;
      } catch (_) {
        // Nothing points to the new photos if the paper wasn't saved.
        await _dataSource.deletePhotos(uploaded);
        rethrow;
      }
    });
  }

  Future<String> _upload(String imagePath, List<String> uploaded) async {
    final path = await _dataSource.uploadPhoto(imagePath);
    uploaded.add(path);
    return path;
  }

  @override
  Future<Either<Failure, void>> deletePaper(Paper paper) {
    return online('deletePaper', () => _dataSource.deletePaper(paper));
  }
}

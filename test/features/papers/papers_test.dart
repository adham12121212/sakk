import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/exceptions.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/error/network_info.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/features/papers/data/models/paper_model.dart';
import 'package:sakk/features/papers/data/paper_data_source/paper_data_source.dart';
import 'package:sakk/features/papers/data/paper_repo_impl/paper_repo_impl.dart';
import 'package:sakk/features/papers/domain/entities/paper.dart';
import 'package:sakk/features/papers/domain/usecase/delete_paper_usecase.dart';
import 'package:sakk/features/papers/domain/usecase/get_papers_usecase.dart';
import 'package:sakk/features/papers/domain/usecase/save_paper_usecase.dart';
import 'package:sakk/features/papers/presentation/cubit/paper_form_cubit.dart';
import 'package:sakk/features/papers/presentation/cubit/papers_cubit.dart';
import 'package:sakk/features/papers/presentation/cubit/papers_state.dart';
import 'package:sakk/features/pro/domain/entities/pro_status.dart';
import 'package:sakk/features/pro/domain/pro_limit.dart';

final today = DateTime(2026, 10, 24);

Paper paper(String id, {DateTime? expiry, PaperKind kind = PaperKind.other}) =>
    Paper(id: id, kind: kind, title: id, expiryDate: expiry);

class _Network implements NetworkInfo {
  bool connected = true;
  @override
  Future<bool> get isConnected async => connected;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class _NoLog implements AppLogger {
  @override
  dynamic noSuchMethod(Invocation i) {}
}

/// Remembers uploads, deletes and what was written.
class _Remote implements PaperDataSource {
  final uploads = <String>[];
  final deleted = <String>[];
  Map<String, dynamic>? written;
  String? updatedId;
  bool failWrite = false;
  List<PaperModel> rows = [];

  @override
  Future<List<PaperModel>> getPapers() async => rows;

  PaperModel _saved(String id, Map<String, dynamic> json) =>
      PaperModel.fromJson({'id': id, ...json});

  @override
  Future<PaperModel> addPaper(Map<String, dynamic> insertJson) async {
    if (failWrite) throw ServerException(ProLimit.code('papers'));
    written = insertJson;
    return _saved('new', insertJson);
  }

  @override
  Future<PaperModel> updatePaper(
    String id,
    Map<String, dynamic> updateJson,
  ) async {
    if (failWrite) throw ServerException('boom');
    written = updateJson;
    updatedId = id;
    return _saved(id, updateJson);
  }

  @override
  Future<void> deletePaper(Paper paper) async {
    deleted.addAll([?paper.frontPath, ?paper.backPath]);
  }

  @override
  Future<String> uploadPhoto(String imagePath) async {
    final path = 'u/${uploads.length}.jpg';
    uploads.add(imagePath);
    return path;
  }

  @override
  Future<void> deletePhotos(List<String> paths) async => deleted.addAll(paths);
}

void main() {
  group('Paper', () {
    test('days left and status by calendar day', () {
      expect(paper('a').status(today), PaperStatus.noExpiry);
      expect(paper('a').daysLeft(today), isNull);
      expect(
        paper('a', expiry: DateTime(2026, 10, 23)).status(today),
        PaperStatus.expired,
      );
      final onTheDay = paper('a', expiry: today);
      expect(onTheDay.daysLeft(today), 0);
      expect(onTheDay.status(today), PaperStatus.expiringSoon);
      expect(
        paper('a', expiry: DateTime(2026, 11, 23)).status(today),
        PaperStatus.expiringSoon,
      );
      expect(
        paper('a', expiry: DateTime(2026, 11, 24)).status(today),
        PaperStatus.valid,
      );
    });

    test('sorted: soonest expiry first, no expiry last in kind order', () {
      final sorted = sortedByExpiry([
        paper('rent', kind: PaperKind.rentalContract),
        paper('later', expiry: DateTime(2028)),
        paper('id', kind: PaperKind.nationalId),
        paper('expired', expiry: DateTime(2025)),
      ]);
      expect(sorted.map((p) => p.id), ['expired', 'later', 'id', 'rent']);
    });

    test('model round trip with database names and signed links', () {
      final json = PaperModel.writeJson(
        kind: PaperKind.drivingLicence,
        number: '123',
        expiryDate: DateTime(2027, 3, 9),
        frontPath: 'u/f.jpg',
      );
      expect(json['kind'], 'driving_licence');
      expect(json['expiry_date'], '2027-03-09');
      final model = PaperModel.fromJson({
        'id': 'p',
        ...json,
        'front_url': 'https://signed',
      });
      expect(model.kind, PaperKind.drivingLicence);
      expect(model.expiryDate, DateTime(2027, 3, 9));
      expect(model.frontUrl, 'https://signed');
      expect(PaperKindX.fromDbName('something new'), PaperKind.other);
    });
  });

  group('PaperRepoImpl.savePaper', () {
    late _Remote remote;
    late _Network network;
    late PaperRepoImpl repo;

    setUp(() {
      remote = _Remote();
      network = _Network();
      repo = PaperRepoImpl(remote, network, _NoLog());
    });

    test('uploads the new photos and saves their paths', () async {
      final result = await repo.savePaper(
        const PaperDraft(
          kind: PaperKind.passport,
          newFrontImage: '/tmp/front.jpg',
          newBackImage: '/tmp/back.jpg',
        ),
      );
      expect(result.isRight(), isTrue);
      expect(remote.uploads, ['/tmp/front.jpg', '/tmp/back.jpg']);
      expect(remote.written?['front_path'], 'u/0.jpg');
      expect(remote.written?['back_path'], 'u/1.jpg');
      expect(remote.deleted, isEmpty);
    });

    test(
      'an edit deletes the photos it replaced or removed, keeps the rest',
      () async {
        const previous = Paper(
          id: 'p',
          kind: PaperKind.nationalId,
          frontPath: 'u/old-front.jpg',
          backPath: 'u/old-back.jpg',
        );
        await repo.savePaper(
          const PaperDraft(
            previous: previous,
            kind: PaperKind.nationalId,
            newFrontImage: '/tmp/new.jpg',
          ),
        );
        expect(remote.updatedId, 'p');
        expect(remote.written?['front_path'], 'u/0.jpg');
        expect(remote.written?['back_path'], isNull);
        expect(remote.deleted, ['u/old-front.jpg', 'u/old-back.jpg']);

        remote.deleted.clear();
        await repo.savePaper(
          const PaperDraft(
            previous: previous,
            kind: PaperKind.nationalId,
            frontPath: 'u/old-front.jpg',
            backPath: 'u/old-back.jpg',
            number: '2990',
          ),
        );
        expect(remote.deleted, isEmpty);
      },
    );

    test('a refused save deletes the photos it uploaded', () async {
      remote.failWrite = true;
      final result = await repo.savePaper(
        const PaperDraft(kind: PaperKind.other, newFrontImage: '/tmp/f.jpg'),
      );
      expect(
        result.fold((f) => f.message, (_) => null),
        ProLimit.code('papers'),
      );
      expect(remote.deleted, ['u/0.jpg']);
    });

    test('offline: nothing is uploaded', () async {
      network.connected = false;
      final result = await repo.savePaper(
        const PaperDraft(kind: PaperKind.other, newFrontImage: '/tmp/f.jpg'),
      );
      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
      expect(remote.uploads, isEmpty);
    });

    test('the list comes back soonest expiry first', () async {
      remote.rows = [
        PaperModel(id: 'b', kind: PaperKind.other, expiryDate: DateTime(2030)),
        PaperModel(id: 'a', kind: PaperKind.other, expiryDate: DateTime(2027)),
      ];
      final result = await repo.getPapers();
      expect(result.getOrElse(() => []).map((p) => p.id), ['a', 'b']);
    });
  });

  group('cubits', () {
    test('the list state finds the next expiry and what needs renewing', () {
      final state = PapersState(
        papers: sortedByExpiry([
          paper('none'),
          paper('expired', expiry: DateTime(2026, 9, 1)),
          paper('soon', expiry: DateTime(2026, 11, 10)),
          paper('later', expiry: DateTime(2028)),
        ]),
      );
      expect(state.nextExpiry(today)?.id, 'soon');
      expect(state.needsAttention(today), 2);

      final allExpired = PapersState(
        papers: [paper('old', expiry: DateTime(2025))],
      );
      expect(allExpired.nextExpiry(today)?.id, 'old');
    });

    test(
      'saving puts the paper in the shared list; deleting removes it',
      () async {
        final papers = PapersCubit(_Get([paper('a', expiry: DateTime(2030))]));
        await papers.refresh();
        final form = PaperFormCubit(_Save(), _Delete(), papers);

        await form.save(const PaperDraft(kind: PaperKind.other, title: 'x'));
        expect(form.state, isA<PaperFormSaved>());
        expect(papers.state.papers.map((p) => p.id), ['a', 'saved']);

        await form.delete(papers.state.papers.first);
        expect(form.state, isA<PaperFormDeleted>());
        expect(papers.state.papers.map((p) => p.id), ['saved']);
      },
    );

    test('a failed load keeps the error for the screen', () async {
      final papers = PapersCubit(_Get(null));
      await papers.refresh();
      expect(papers.state.error, 'boom');
      expect(papers.state.hasLoadedOnce, isFalse);
    });
  });

  test('the plan status reads the papers limit', () {
    final status = ProStatus.fromJson({
      'pro': false,
      'items': {
        'papers': {'count': 3, 'limit': 3},
      },
    });
    expect(status.item(LimitedItem.papers).isFull, isTrue);
    expect(ProLimit.reasonFor('papers'), PaywallReason.papersLimit);
    expect(
      ProLimit.reasonForItem(LimitedItem.papers),
      PaywallReason.papersLimit,
    );
  });
}

class _Get implements GetPapersUseCase {
  _Get(this.papers);
  final List<Paper>? papers;
  @override
  Future<Either<Failure, List<Paper>>> call() async =>
      papers == null ? const Left(ServerFailure('boom')) : Right(papers!);
}

class _Save implements SavePaperUseCase {
  @override
  Future<Either<Failure, Paper>> call(PaperDraft draft) async =>
      Right(Paper(id: 'saved', kind: draft.kind, title: draft.title));
}

class _Delete implements DeletePaperUseCase {
  @override
  Future<Either<Failure, void>> call(Paper paper) async => const Right(null);
}

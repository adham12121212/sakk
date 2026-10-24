import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/paper.dart';
import '../../../pro/domain/pro_limit.dart';
import '../models/paper_model.dart';

abstract class PaperDataSource {
  /// The signed-in user's papers, with their photos signed.
  Future<List<PaperModel>> getPapers();

  Future<PaperModel> addPaper(Map<String, dynamic> insertJson);

  Future<PaperModel> updatePaper(String id, Map<String, dynamic> updateJson);

  /// Deletes the paper, then its photos.
  Future<void> deletePaper(Paper paper);

  /// Uploads a photo to the user's folder and returns its storage path.
  Future<String> uploadPhoto(String imagePath);

  /// Best effort: a leftover photo is only visible to its owner.
  Future<void> deletePhotos(List<String> paths);
}

class PaperDataSourceImpl implements PaperDataSource {
  PaperDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const _table = 'papers';
  static const _bucket = 'papers';

  /// Links to ID and passport photos stay short-lived: the list signs them
  /// again each time it loads.
  static const _photoUrlExpiry = Duration(hours: 1);

  static final _random = Random.secure();

  @override
  Future<List<PaperModel>> getPapers() async {
    try {
      final rows = await _client
          .from(_table)
          .select()
          .order('expiry_date', nullsFirst: false)
          .order('created_at');
      final signed = await _withSignedUrls(
        (rows as List).cast<Map<String, dynamic>>(),
      );
      return signed.map(PaperModel.fromJson).toList();
    } catch (e) {
      throw ServerException('Failed to load papers: $e');
    }
  }

  @override
  Future<PaperModel> addPaper(Map<String, dynamic> insertJson) async {
    try {
      final row = await _client
          .from(_table)
          .insert(insertJson)
          .select()
          .single();
      ProLimit.notifyUsageChanged();
      return PaperModel.fromJson((await _withSignedUrls([row])).single);
    } catch (e) {
      throw ProLimit.exceptionFor(e, 'Failed to save paper: $e');
    }
  }

  @override
  Future<PaperModel> updatePaper(
    String id,
    Map<String, dynamic> updateJson,
  ) async {
    try {
      final row = await _client
          .from(_table)
          .update(updateJson)
          .eq('id', id)
          .select()
          .single();
      return PaperModel.fromJson((await _withSignedUrls([row])).single);
    } catch (e) {
      throw ServerException('Failed to update paper: $e');
    }
  }

  @override
  Future<void> deletePaper(Paper paper) async {
    try {
      await _client.from(_table).delete().eq('id', paper.id);
      ProLimit.notifyUsageChanged();
    } catch (e) {
      throw ServerException('Failed to delete paper: $e');
    }
    // After the row is gone, so a failed delete never leaves a paper
    // without its photos.
    await deletePhotos([?paper.frontPath, ?paper.backPath]);
  }

  @override
  Future<String> uploadPhoto(String imagePath) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw ServerException('You must be signed in to add a paper');
    }
    final extension = imagePath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    // Random, so a photo's path can't be guessed and says nothing about
    // the paper.
    final name = [
      for (var i = 0; i < 16; i++)
        _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    final path = '$userId/$name.$extension';
    try {
      await _client.storage.from(_bucket).upload(path, File(imagePath));
      return path;
    } catch (e) {
      throw ServerException('Failed to upload the photo: $e');
    }
  }

  @override
  Future<void> deletePhotos(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(_bucket).remove(paths);
    } catch (_) {}
  }

  /// Adds `front_url` and `back_url` to each row. If signing fails the
  /// papers still load, without their photos.
  Future<List<Map<String, dynamic>>> _withSignedUrls(
    List<Map<String, dynamic>> rows,
  ) async {
    final paths = {
      for (final row in rows) ...[
        ?row['front_path'] as String?,
        ?row['back_path'] as String?,
      ],
    };
    if (paths.isEmpty) return rows;

    final Map<String, String> urls;
    try {
      final results = await _client.storage
          .from(_bucket)
          .createSignedUrlsResult(paths.toList(), _photoUrlExpiry.inSeconds);
      urls = {
        for (final r in results)
          if (r is SignedUrlSuccess) r.path: r.signedUrl,
      };
    } catch (_) {
      return rows;
    }
    return [
      for (final row in rows)
        {
          ...row,
          'front_url': urls[row['front_path']],
          'back_url': urls[row['back_path']],
        },
    ];
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/exceptions.dart';

/// Sakk Pro's backup: everything the signed-in user has saved, as one JSON
/// document. Their own rows only: household members' products are theirs
/// to back up.
abstract class BackupDataSource {
  Future<Map<String, dynamic>> exportAll();
}

class BackupDataSourceImpl implements BackupDataSource {
  BackupDataSourceImpl(this._client);

  final SupabaseClient _client;

  /// Bumped if the layout changes, so a future import can tell versions apart.
  static const formatVersion = 1;

  /// Receipt and document links in the file work this long.
  static const fileLinkExpiry = Duration(days: 7);

  @override
  Future<Map<String, dynamic>> exportAll() async {
    final user = _client.auth.currentUser;
    if (user == null) throw ServerException('You must be signed in to export a backup');
    try {
      final results = await Future.wait([
        _client
            .from('products')
            .select('*, product_warranties(*), warranty_claims(*), product_documents(*)')
            .eq('user_id', user.id)
            .order('purchase_date'),
        _client.from('user_subscriptions').select('*, subscription_catalog(name)').order('next_renewal_date'),
        _client.from('installment_plans').select('*, installment_payments(*)').order('start_date'),
      ]);
      final products = results[0];

      // Documents are stored by path; give them working links too.
      final paths = [
        for (final p in products)
          for (final d in (p['product_documents'] as List? ?? const []))
            (d as Map<String, dynamic>)['file_path'] as String,
      ];
      final links = <String, String>{};
      if (paths.isNotEmpty) {
        final signed = await _client.storage.from('receipts').createSignedUrlsResult(paths, fileLinkExpiry.inSeconds);
        // A file that's gone is left out; its row still lists the path.
        for (final s in signed.whereType<SignedUrlSuccess>()) {
          links[s.path] = s.signedUrl;
        }
      }

      return {
        'app': 'sakk',
        'format_version': formatVersion,
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'account': {'id': user.id, 'email': user.email},
        'file_links_expire_at': DateTime.now().add(fileLinkExpiry).toUtc().toIso8601String(),
        'products': products,
        'subscriptions': results[1],
        'installment_plans': results[2],
        'document_links': links,
      };
    } catch (e) {
      throw ServerException('Backup export failed: $e');
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'saved_remote_data_source.dart';

class SavedRemoteDataSourceImpl implements SavedRemoteDataSource {
  SavedRemoteDataSourceImpl(this._c);
  final SupabaseClient _c;

  @override
  Future<Set<String>> savedIds() async {
    final rows = await _c.from('saved_posts').select('post_id'); // RLS: only my rows
    return rows.map((r) => r['post_id'] as String).toSet();
  }

  @override
  Future<bool> toggle(String postId) async => (await _c.rpc('toggle_save', params: {'p_post': postId})) as bool;
}

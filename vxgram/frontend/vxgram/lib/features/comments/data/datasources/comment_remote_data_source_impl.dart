import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';
import 'comment_remote_data_source.dart';

class CommentRemoteDataSourceImpl implements CommentRemoteDataSource {
  CommentRemoteDataSourceImpl(this._c);
  final SupabaseClient _c;
  static const page = 30;

  @override
  String? get currentUserId => _c.auth.currentUser?.id;

  @override
  Future<List<CommentModel>> comments(String postId, DateTime? before) async {
    final res = await _c.rpc('get_comments', params: {'p_post': postId, 'p_limit': page, 'p_before': before?.toUtc().toIso8601String()});
    return (res as List).map((e) => CommentModel.fromRpc(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<CommentModel> add(String postId, String body) async {
    final row = await _c.from('comments')
        .insert({'post_id': postId, 'user_id': _c.auth.currentUser!.id, 'body': body})
        .select('id,user_id,body,created_at,profiles(username,avatar_url)')
        .single();
    return CommentModel.fromInsert(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> delete(String commentId) async { await _c.from('comments').delete().eq('id', commentId); }
}

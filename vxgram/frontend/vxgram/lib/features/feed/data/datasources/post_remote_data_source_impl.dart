import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import 'post_remote_data_source.dart';

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  PostRemoteDataSourceImpl(this._c);
  final SupabaseClient _c;

  @override
  String? get currentUserId => _c.auth.currentUser?.id;

  @override
  Future<List<PostModel>> getPosts({required String scope, String? author, int limit = 15, DateTime? before}) async {
    final res = await _c.rpc('get_posts', params: {
      'p_scope': scope, 'p_author': author, 'p_limit': limit, 'p_before': before?.toUtc().toIso8601String(),
    });
    return (res as List).map((e) => PostModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<bool> toggleLike(String postId) async => (await _c.rpc('toggle_like', params: {'p_post': postId})) as bool;

  @override
  Future<void> deletePost(String postId) async {
    final paths = List<String>.from((await _c.rpc('delete_post', params: {'p_post': postId})) as List);
    if (paths.isNotEmpty) await _c.storage.from('posts').remove(paths);
  }
}

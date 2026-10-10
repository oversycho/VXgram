import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/new_media.dart';
import '../models/post_model.dart';
import 'post_remote_data_source.dart';

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  PostRemoteDataSourceImpl(this._c);
  final SupabaseClient _c;

  @override
  String? get currentUserId => _c.auth.currentUser?.id;

  @override
  Future<List<PostModel>> getPosts({required String scope, String? author, int limit = 15, DateTime? before}) async {
    if (scope == 'post') {
      // single post: [author] carries the post id
      final one = await _c.rpc('get_post', params: {'p_post': author});
      return (one as List).map((e) => PostModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    if (scope == 'saved') {
      final res = await _c.rpc('get_saved_posts', params: {'p_limit': limit, 'p_before': before?.toUtc().toIso8601String()});
      return (res as List).map((e) => PostModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
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

  static String _mime(String ext) {
    switch (ext.toLowerCase()) {
      case 'png': return 'image/png';
      case 'webp': return 'image/webp';
      case 'mp4': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case 'webm': return 'video/webm';
      default: return 'image/jpeg';
    }
  }

  @override
  Future<void> createPost({required String caption, required List<NewMedia> media, void Function(int done, int total)? onProgress}) async {
    final uid = _c.auth.currentUser!.id;
    final row = await _c.from('posts').insert({'user_id': uid, 'caption': caption}).select('id').single();
    final postId = row['id'] as String;
    final uploaded = <String>[];
    try {
      for (var i = 0; i < media.length; i++) {
        final m = media[i];
        final ext = m.ext.toLowerCase();
        final path = '$uid/$postId/$i.$ext';
        await _c.storage.from('posts').uploadBinary(path, m.bytes, fileOptions: FileOptions(contentType: _mime(ext)));
        uploaded.add(path);
        String? thumbPath, thumbUrl;
        if (m.thumbBytes != null) {
          thumbPath = '$uid/$postId/${i}_thumb.jpg';
          await _c.storage.from('posts').uploadBinary(thumbPath, m.thumbBytes!, fileOptions: const FileOptions(contentType: 'image/jpeg'));
          uploaded.add(thumbPath);
          thumbUrl = _c.storage.from('posts').getPublicUrl(thumbPath);
        }
        await _c.from('post_media').insert({
          'post_id': postId, 'user_id': uid, 'storage_path': path, 'url': _c.storage.from('posts').getPublicUrl(path),
          'thumb_path': thumbPath, 'thumb_url': thumbUrl,
          'media_type': m.isVideo ? 'video' : 'image', 'position': i,
        });
        onProgress?.call(i + 1, media.length);
      }
    } catch (e) {
      // roll back: no half-finished posts
      try { if (uploaded.isNotEmpty) await _c.storage.from('posts').remove(uploaded); } catch (_) {}
      try { await _c.from('posts').delete().eq('id', postId); } catch (_) {}
      rethrow;
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inbox_item_model.dart';
import 'share_remote_data_source.dart';

class ShareRemoteDataSourceImpl implements ShareRemoteDataSource {
  ShareRemoteDataSourceImpl(this._c);
  final SupabaseClient _c;

  @override
  Future<int> sharePost(String postId, List<String> receiverIds, String? message) async =>
      (await _c.rpc('share_post', params: {'p_post': postId, 'p_receivers': receiverIds, 'p_message': message})) as int;

  @override
  Future<List<InboxItemModel>> inbox() async {
    final res = await _c.rpc('get_inbox', params: {'p_limit': 50});
    return (res as List).map((e) => InboxItemModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<void> markSeen(String shareId) async { await _c.from('post_shares').update({'seen': true}).eq('id', shareId); }
}
